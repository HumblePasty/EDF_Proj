library(tidyverse)
library(tibble)
library(EML)
library(readr)
library(readxl)
library(dplyr)

# set working directory as current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# load the data
# Biomass - Annual crops and alfalfa
biomass_annuals_alfalfa <- read.csv("../../data/kbs_msce/kbs_mcse_biomass_annual_crops_and_alfalfa.csv", header = T, skip = 29)

biomass_annuals_alfalfa <- biomass_annuals_alfalfa %>%
  slice(-1) %>%
  filter(Treatment == "T1" | Treatment == "T2" | Treatment == "T3" | Treatment == "T4") %>%
  mutate(Biomass = Biomass * 10) # multiply by 10 to convert g/m2 to kg/ha

# Biomass - Cover crops
biomass_covercrops <- read.csv("../../data/kbs_msce/kbs_mcse_biomass_cover_crop.csv", header = T, skip = 27)
biomass_covercrops <- biomass_covercrops %>%
  slice(-1) %>%
  transform(biomass_g = as.numeric(biomass_g)) %>%
  mutate(Biomass = biomass_g * 10) # multiply by 10 to convert g/m2 to kg/ha

# Biomass - non-cover crops
biomass_weeds <- read.csv("../../data/kbs_msce/40-non+crop+biomass+1715975001.csv", header = T, skip = 53)
biomass_weeds <- biomass_weeds %>%
  slice(-1) %>%
  filter(Treatment == "T1" | Treatment == "T2" | Treatment == "T3" | Treatment == "T4" | Treatment == "T7") %>%
  transform(Biomass = as.numeric(Biomass)) %>%
  mutate(Biomass = Biomass * 10) # multiply by 10 to convert g/m2 to kg/ha

# Biomass - compilation of herbaceous systems
biomass_compilation <- read.csv("../../data/kbs_msce/291-biomass+compilation+of+herbaceous+systems+1715975221.csv", header = T, skip = 26)
biomass_compilation <- biomass_compilation %>%
  slice(-1) %>%
  filter(Treatment == "T1" | Treatment == "T2" | Treatment == "T3" | Treatment == "T4" | Treatment == "T7") %>%
  transform(Biomass = as.numeric(Biomass_g)) %>%
  mutate(Biomass = Biomass * 10) # multiply by 10 to convert g/m2 to kg/ha


conc <- 0.45

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
SR_wheat <- 6.0 # Eastern Canada value; US value was 1.1
SR_wheat_sd <- 1.2 # Eastern Canada value; US value was 0.1
SR_unsorted <- 1.6
SR_unsorted_sd <- 1.2
SR_legume <- 2.2
SR_legume_sd <- 1.3
SR_red <- 3.7
# Red clover and vetch
SR_rye <- 0.4


ERtoR <- 0.65
# Crop input
df_crop <- biomass_annuals_alfalfa %>%
  # filter(Species == "Zea mays L. (*)") %>%  # corn
  # filter for seed rows
  filter(Fraction == "SEED") %>%
  # create C_p column
  mutate(C_p = Biomass * conc) %>%
  # create C_s column
  mutate(HI = case_when(
    Species == "Glycine max L. (*)" ~ HI_soy,
    Species == "Zea mays L. (*)" ~ HI_corn,
    Species == "Triticum aestivum L. (*)" ~ HI_wheat,
    .default = 0.5
  )) %>%
  mutate(C_s = C_p * HI * (1 - HI)) %>%
  # create C_r columnn
  mutate(SR_ratio = case_when(
    Species == "Glycine max L. (*)" ~ SR_soy,
    Species == "Zea mays L. (*)" ~ case_when(
      Treatment == "T1" ~ SR_corn_fert,
      Treatment == "T2" ~ SR_corn_fert,
      Treatment == "T3" ~ SR_corn_fert,
      Treatment == "T4" ~ SR_corn_unf,
      .default = 3.6
    ),
    Species == "Triticum aestivum L. (*)" ~ SR_wheat,
    .default = 1.6
  )) %>%
  mutate(C_r = C_p / (HI * SR_ratio)) %>%
  # C_e calculation
  mutate(C_e = C_r * ERtoR) %>%
  # C input
  mutate(C_input_crop = C_s + C_r + C_e)


# cover crop input
df_covercrop <- biomass_covercrops %>%
  # drop the biomass_g column
  select(-biomass_g) %>%
  # above ground biomass
  mutate(Cag = Biomass * conc) %>%
  # root biomass carbon
  mutate(SR_ratio = case_when(
    species == "Secale cereale M.Bieb." ~ SR_rye,
    species == "Trifolium pratense L." ~ SR_red,
    species == "Vicia villosa Roth" ~ SR_legume,
    .default = SR_unsorted
  )) %>%
  mutate(C_r = Cag / SR_ratio) %>%
  # C_e calculation
  mutate(C_e = C_r * ERtoR) %>%
  # C input
  mutate(C_input_cover = Cag + C_r + C_e)

weed_biomass_to_c <- 0.425
# weedy input
df_weedy <- biomass_weeds %>%
  mutate(C_input_weedy = Biomass * weed_biomass_to_c)

# compilation input
df_compilation <- biomass_compilation

# aggregate df_crop by year, treatment, replicate, and station
df_crop_temp <- df_crop %>%
  rename_all(tolower) %>%
  select(year, treatment, replicate, station, c_input_crop) %>%
  group_by(year, treatment, replicate, station) %>%
  summarise_all(sum)
# this shows that year, treatment, replicate, and station are enough for identifying a unique row

## final output
kbs_carbon_input <- df_crop %>%
  # rename all columns to be lowercase
  rename_all(tolower) %>%
  select(-fraction, -c_p, -hi, -c_s, -sr_ratio, -c_r, -c_e) %>%
  # rename the "biomass" column to "total_biomass_estimated"
  rename(total_biomass_estimated = biomass) %>%
  left_join(
    df_covercrop %>%
      rename_all(tolower) %>%
      select(year, treatment, replicate, station, c_input_cover, biomass),
      # aggregate the cover crop biomass by year, treatment, replicate, and station
      group_by(year, treatment, replicate, station) %>%
      summarise_all(sum),
    by = c("year", "treatment", "replicate", "station")
  ) %>%
  # add the biomass of the cover crop to the total biomass estimated
  mutate(total_biomass_estimated = total_biomass_estimated + biomass) %>%
  # delete the biomass_cover column
  select(-biomass) %>%
  left_join(
    df_weedy %>%
      rename_all(tolower) %>%
      select(year, treatment, replicate, station, c_input_weedy, biomass) %>%
      # aggregate the weedy biomass by year, treatment, replicate, and station
      group_by(year, treatment, replicate, station) %>%
      summarise_all(sum),
    by = c("year", "treatment", "replicate", "station")
  ) %>%
  # add the biomass of the weedy to the total biomass estimated
  mutate(total_biomass_estimated = total_biomass_estimated +
           biomass) %>%
  # delete the biomass column
  select(-biomass) %>%
  left_join(
    df_compilation %>%
      rename_all(tolower) %>%
      select(year, treatment, replicate, station, biomass) %>%
      # convert biomass_g to numeric
      mutate(biomass = as.numeric(biomass)) %>%
      # rename biomass to compilation_biomass
      rename(compilation_biomass = biomass) %>%
      # aggregate the compilation biomass by year, treatment, replicate, and station
      group_by(year, treatment, replicate, station) %>%
      summarise_all(sum),
    by = c("year", "treatment", "replicate", "station")
  )

## export the data
write.csv(kbs_carbon_input, "../../temp/kbs_carbon_input.csv")
