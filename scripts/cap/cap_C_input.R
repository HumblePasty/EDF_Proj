library(tidyverse)
library(tibble)
library(EML)
library(readr)
library(readxl)
library(dplyr)

# set working directory as current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# load data sheets
cap_path = "../cap_data/C_Data_2011-2015_0.xlsx"
cap_plot_entity = read_excel(cap_path, sheet = "Plot Identifiers") %>%
  as.data.frame() %>%
  slice(-1:-2)

cap_plot_agronomic = read_excel(cap_path, sheet = "Agronomic") %>%
  as.data.frame() %>%
  slice(-1:-2)

##### calculate C input for different parts

# # for corn input C, use the sum of cob and vegetative parts
# cap_carbon_input = cap_plot_agronomic %>%
#   select(uniqueid, plotid, year, AGR09, AGR24) %>% # select columns
#   # alter na values to 0
#   mutate(AGR09 = ifelse(is.na(AGR09), 0, AGR09),
#          AGR24 = ifelse(is.na(AGR24), 0, AGR24)) %>%
#   # convert to numeric
#   mutate(AGR09 = as.numeric(AGR09),
#          AGR24 = as.numeric(AGR24)) %>%
#   # rename columns
#   rename(c_input_vegetative_corn = AGR09,
#          c_input_cob_corn = AGR24) %>%
#   mutate(c_input_corn = c_input_vegetative_corn + c_input_cob_corn)  # vegetative + cob
# 
# # for the soybean input, use the vegetative part solely
# c_input_soybean = cap_plot_agronomic %>%
#   select(AGR11) %>% # select columns
#   # alter na values to 0
#   mutate(AGR11 = ifelse(is.na(AGR11), 0, AGR11)) %>%
#   # convert to numeric
#   mutate(AGR11 = as.numeric(AGR11))
# cap_carbon_input$c_input_soybean = c_input_soybean$AGR11

##### estiate the root part of the carbon based on Bolinder et al. 2009
# C_p = C_grain = Y_p * conc_rate
# C_s = Y_p(1-HI)/HI*conc_rate = C_p * (1-HI)/HI
# C_r = Y_p(S:R*HI)*conc_rate = C_p / (S:R*HI)
# C_e = C_r * Y_e = C_r * ERtoR

## setup parameters
# Carbon concentrations - all values from Bolinder
conc <- 0.45       # C concentration

# HI values
HI_corn <- 0.5
HI_soy <- 0.4
HI_wheat <- 0.4

# S:R values
SR_corn_fert <- 4.7
SR_corn_fert_sd <- 2.1
SR_corn_unf <- 3.6
SR_corn_unf_sd <- 1.3
SR_soy <- 5.2
SR_soy_sd <- 3.1
SR_wheat <- 6.0       # Eastern Canada value; US value was 1.1
SR_wheat_sd <- 1.2    # Eastern Canada value; US value was 0.1
SR_unsorted <- 1.6
SR_unsorted_sd <- 1.2
SR_legume <- 2.2
SR_legume_sd <- 1.3
# Red clover and vetch
SR_rye <- 0.4
# Comes after soybean in rotation

# Ratio of extra-root biomass to root biomass
ERtoR <- 0.65


### calculate corn input c
df_corn = cap_plot_agronomic %>%
  select(uniqueid, plotid, year, AGR24, AGR23, AGR09, AGR33, AGR17, AGR18) %>% # select columns
  # merge with the "nitrogen" column from the cap_plot_entity data based on uniqueid and plotid
  left_join(
    cap_plot_entity %>% 
      select(uniqueid, plotid, nitrogen), 
    by = c("uniqueid", "plotid")
    ) %>%
  # alter na values to 0
  mutate(AGR24 = ifelse(is.na(AGR24), 0, AGR24), # cob carbon
         AGR23 = ifelse(is.na(AGR23), 0, AGR23), # grain carbon
         AGR09 = ifelse(is.na(AGR09), 0, AGR09), # vegetative carbon
         AGR33 = ifelse(is.na(AGR33), 0, AGR33), # dry grain yield, kg/ha
         AGR17 = ifelse(is.na(AGR17), 0, AGR17), # grain yield at 15.5% moisture, kg/ha
         AGR18 = ifelse(is.na(AGR18), 0, AGR18) # grain moisture, g/kg
         ) %>%
  # convert to numeric
  mutate(AGR24 = as.numeric(AGR24),
         AGR23 = as.numeric(AGR23),
         AGR09 = as.numeric(AGR09),
         AGR33 = as.numeric(AGR33),
         AGR17 = as.numeric(AGR17),
         AGR18 = as.numeric(AGR18)
         ) %>%
  # rename columns
  rename(c_input_corn_cob = AGR24,
         c_input_corn_grain = AGR23,
         c_input_corn_vegetative = AGR09,
         c_input_corn_yield_dry = AGR33,
         c_input_corn_yield_raw = AGR17,
         c_input_corn_moisture = AGR18
         ) %>%
  # create 4 parts C_p, C_s, C_r, C_e
  mutate(
       # for C_p calculation, if c_input_corn_grain is not 0, use it
       # otherwise use c_input_corn_yield_dry to estimate
       # otherwise use c_input_corn_yield_raw to estimate
       # otherwise use 0
       C_p = case_when(
         c_input_corn_grain > 0 ~ c_input_corn_grain,
         c_input_corn_yield_dry > 0 ~ c_input_corn_yield_dry * conc,
         c_input_corn_yield_raw > 0 ~ c_input_corn_yield_raw * (1 - c_input_corn_moisture / 1000) * conc,
         .default = 0
       ),
       # for C_s input, if carbon data is available, use it
       # otherwise use the calculated value
       C_s = case_when(
         c_input_corn_vegetative > 0 ~ c_input_corn_vegetative + c_input_corn_cob,
         .default = C_p * (1 - HI_corn) / HI_corn
       ),
       # For C_r calculation, use differet SR values based on whether nitrogen fertilizer was applied or not
       # "NIT1" means no nitrogen fertilizer was applied
       SR_rates = case_when(
         nitrogen == "NIT1" ~ SR_corn_unf, # No nitrogen fertilizer applied
         nitrogen == "NIT2" ~ SR_corn_fert, # MRTN application of N fertilizer
         nitrogen == "NIT3" ~ SR_corn_fert, # Sensor based N application - MO/OH recommendation
         nitrogen == "NIT4" ~ SR_corn_fert, # Sensor based N application - OK recommendation
         .default = SR_corn_unf
       ),
       SR_rates_SV = ifelse(nitrogen == "NIT1", SR_corn_unf_sd, SR_corn_fert_sd),
       C_r = C_p / (SR_rates * HI_corn), # C_r_SV = SR_rates_SV * HI_corn
       # For C_e calculation, use the formula C_e = C_r * ERtoR
       C_e = C_r * ERtoR
     ) %>%
  # sum and create the input carbon column
  # C_input = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1
  mutate(c_input_corn = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1)



### calculate soybean input c
df_soybean = cap_plot_agronomic %>%
  select(uniqueid, plotid, year, AGR27, AGR11, AGR34, AGR19, AGR20) %>% # select columns
  # alter na values to 0
  mutate(
    AGR27 = ifelse(is.na(AGR27), 0, AGR27), # soy grain carbon
    AGR11 = ifelse(is.na(AGR11), 0, AGR11), # soy vegetative carbon
    AGR34 = ifelse(is.na(AGR34), 0, AGR34), # soy dry grain yield, kg/ha
    AGR19 = ifelse(is.na(AGR19), 0, AGR19), # soy grain yield at 13.5% moisture, kg/ha
    AGR20 = ifelse(is.na(AGR20), 0, AGR20) # soy grain moisture, g/kg
    ) %>%
  # convert to numeric
  mutate(
    AGR27 = as.numeric(AGR27),
    AGR11 = as.numeric(AGR11),
    AGR34 = as.numeric(AGR34),
    AGR19 = as.numeric(AGR19),
    AGR20 = as.numeric(AGR20)
    ) %>%
  # rename columns
  rename(
    c_input_soybean_grain = AGR27,
    c_input_soybean_vegetative = AGR11,
    c_input_soybean_yield_dry = AGR34,
    c_input_soybean_yield_raw = AGR19,
    c_input_soybean_moisture = AGR20
    ) %>%
  # create 4 parts C_p, C_s, C_r, C_e
  mutate(
      C_p = case_when(
             c_input_soybean_grain > 0 ~ c_input_soybean_grain,
             c_input_soybean_yield_dry > 0 ~ c_input_soybean_yield_dry * conc,
             c_input_soybean_yield_raw > 0 ~ c_input_soybean_yield_raw * (1 - c_input_soybean_moisture / 1000) * conc,
             .default = 0
           ),
      C_s = case_when(
             c_input_soybean_vegetative > 0 ~ c_input_soybean_vegetative,
             .default = C_p * (1 - HI_soy) / HI_soy
           ),
      SR_rates = SR_soy,
      C_r = C_p / (SR_rates * HI_soy),
      C_e = C_r * ERtoR
    ) %>%
  # sum and create the input carbon column
  # C_input = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1
  mutate(c_input_soybean = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1)


### calculate wheat input carbon
df_wheat = cap_plot_agronomic %>%
  select(uniqueid, plotid, year, AGR21, AGR22) %>% # select columns
  # alter na values to 0
  mutate(
    AGR21 = ifelse(is.na(AGR21), 0, AGR21), # wheat grain yield at 13.5% MB, kg/ha
    AGR22 = ifelse(is.na(AGR22), 0, AGR22) # wheat moisture, g/kg
    ) %>%
  # convert to numeric
  mutate(
    AGR21 = as.numeric(AGR21),
    AGR22 = as.numeric(AGR22)
    ) %>%
  # rename columns
  rename(
    wheat_yield_raw = AGR21,
    wheat_moisture = AGR22
  ) %>%
  # calculate dry matter yield for further calculations
  mutate(
    wheat_yield_dry = wheat_yield_raw * (1 - wheat_moisture / 1000)
  ) %>%
  # create 4 parts C_p, C_s, C_r, C_e
  mutate(C_p = wheat_yield_dry * conc,
         C_s = C_p * (1 - HI_wheat) / HI_wheat,
         # C_s_calculated = c_input_wheat_vegetative, # a different method to calculate C_s
         SR_rates = SR_wheat,
         C_r = C_p / (SR_rates * HI_wheat),
         C_e = C_r * ERtoR) %>%
  # sum and create the input carbon column
  # C_input = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1
  mutate(c_input_wheat = C_p * 0 + C_s * 1 + C_r * 1 + C_e * 1)


cover_biomass_to_C = 0.65 # conversion factor from biomass to C for cover crops

### calculate cover crop input carbon
df_cover = cap_plot_agronomic %>%
  select(uniqueid, plotid, year,AGR06, AGR07, AGR41, AGR43, AGR46) %>% # select columns
  # alter na values to 0
  mutate(
    AGR06 = ifelse(is.na(AGR06), 0, AGR06), # fall biomass, rye
    AGR07 = ifelse(is.na(AGR07), 0, AGR07), # spring biomass, rye
    AGR41 = ifelse(is.na(AGR41), 0, AGR41), # fall biomass, red clover or mixed cover
    AGR43 = ifelse(is.na(AGR43), 0, AGR43), # fall carbon, red clover or mixed cover
    AGR46 = ifelse(is.na(AGR46), 0, AGR46) # spring carbon, red clover or mixed cover
    ) %>%
  # convert to numeric
  mutate(
    AGR06 = as.numeric(AGR06),
    AGR07 = as.numeric(AGR07),
    AGR41 = as.numeric(AGR41),
    AGR43 = as.numeric(AGR43),
    AGR46 = as.numeric(AGR46)
    ) %>%
  # rename columns
  rename(
    c_fall_biomass_rye = AGR06,
    c_spring_biomass_rye = AGR07,
    c_fall_biomass_red_mixed = AGR41,
    c_fall_carbon_red_mixed = AGR43,
    c_spring_carbon_red_mixed = AGR46
    ) %>%
  # sum and create the input carbon column
  mutate(c_input_cover = 
           (c_fall_biomass_rye + c_spring_biomass_rye) * cover_biomass_to_C + 
           c_fall_carbon_red_mixed + c_spring_carbon_red_mixed
         )

### calculate weedy input carbon
df_weedy = cap_plot_agronomic %>%
  select(uniqueid, plotid, year, AGR40) %>% # select columns
  # alter na values to 0
  mutate(
    AGR40 = ifelse(is.na(AGR40), 0, AGR40) # weedy carbon
    ) %>%
  # convert to numeric
  mutate(
    AGR40 = as.numeric(AGR40)
    ) %>%
  # rename columns
  rename(
    c_input_weedy = AGR40
    ) %>%
  # multiply by 0.45
  mutate(c_input_weedy = c_input_weedy * 0.45)


# merge all total carbon inputs into one dataframe and fit into the database
cap_carbon_input = df_corn %>%
  select(uniqueid, plotid, year, c_input_corn) %>%
  left_join(
    df_soybean %>% select(uniqueid, plotid, year, c_input_soybean),
    by = c("uniqueid", "plotid", "year")
  ) %>%
  left_join(
    df_wheat %>% select(uniqueid, plotid, year, c_input_wheat),
    by = c("uniqueid", "plotid", "year")
  ) %>%
  left_join(
    df_cover %>% select(uniqueid, plotid, year, c_input_cover),
    by = c("uniqueid", "plotid", "year")
  ) %>%
  left_join(
    df_weedy %>% select(uniqueid, plotid, year, c_input_weedy),
    by = c("uniqueid", "plotid", "year")
  ) %>%
  # calc the total C input
  mutate(
    C_input_total = c_input_corn + c_input_soybean + c_input_wheat + c_input_cover + c_input_weedy,
    C_output = 0 # TBD by further discussion
  ) %>%
  # identify which crop was grown, when a crop was grown, the carbon input for that crop is not 0
  # if all are 0, then it is a no crop plot
  mutate(
    Crop_temp = case_when(
      c_input_corn > 0 ~ "Zea mays (Corn)",
      c_input_soybean > 0 ~ "Glycine max (Soybean)",
      c_input_wheat > 0 ~ "Triticum aestivum (Wheat)",
      # c_input_cover > 0 ~ "cover",
      # c_input_weedy > 0 ~ "weedy",
      .default = "No crop"
    ) # here I used the infer method, maybe should use original data instead
  ) %>%
  # merge with entity features
  left_join(
    cap_plot_entity %>%
      select(uniqueid, plotid,
             rep,
             tillage,
             rotation,
             drainage,
             nitrogen,
             landscape,
             `2011crop`,
             `2012crop`,
             `2013crop`,
             `2014crop`,
             `2015crop`
             ),
    by = c("uniqueid", "plotid")
  ) %>%
  mutate( # alter the crop names
    Crop = case_when(
      year == 2011 ~ `2011crop`,
      year == 2012 ~ `2012crop`,
      year == 2013 ~ `2013crop`,
      year == 2014 ~ `2014crop`,
      year == 2015 ~ `2015crop`,
      .default = "No crop"
    )
  ) %>%
  mutate( # alter the crop names
    Crop = case_when(
      Crop == "Corn" ~ "Zea mays (Corn)",
      Crop == "Soybean" ~ "Glycine max (Soybean)",
      Crop == "Wheat" ~ "Triticum aestivum (Wheat)",
      .default = Crop
    )
  ) %>%
  # delete the 2011crop, 2012crop, 2013crop, 2014crop, 2015crop columns
  select(-`2011crop`, -`2012crop`, -`2013crop`, -`2014crop`, -`2015crop`)

# export the carbon input data
write_csv(cap_carbon_input, "cap_carbon_input.csv")
