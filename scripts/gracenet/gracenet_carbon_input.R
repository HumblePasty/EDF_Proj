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
grace_treatment <- read_excel("../../data/gracenet/natres.xlsx", sheet = "Treatments")
grace_harvest = read_excel("../../data/gracenet/natres.xlsx", sheet = "MeasHarvestFraction")

grace_experiment = read_excel("../../data/gracenet/natres.xlsx", sheet = "ExperUnits")
grace_ghg = read_excel("../../data/gracenet/natres.xlsx", sheet = "MeasGHGFlux")

# get a unique list of crop types
crop_types = grace_harvest$Crop %>%
  unique()

# create a new dataframe to store the input data
# the dataframe should have identity columns and the fraction parts columns
df_input = data.frame(SiteID = character(),
                      `Exp Unit ID` = character(),
                      `Sampling Date` = character(),
                      `Treatment ID` = character(),
                      `Crop` = character())

# for each crop type, create columns for the fraction parts
for (crop in crop_types) {
  # filter the data for the specific crop type
  crop_data = grace_harvest %>%
    filter(Crop == crop) %>%
    # filter the sites IAAMBRUN, INWLACRE, MNMOBRR, MNMOFS, NELITCSE, NEMEIRR, NEMERREM, NEMLTCRS,
    filter(SiteID %in% c(
      "IAAMBRUN", "INWLACRE", "MNMOBRR", "MNMOFS", "NELITCSE", "NEMEIRR", "NEMERREM", "NEMLTCRS")) %>%
    # select columns
    select(SiteID, `Exp Unit ID`, `Sampling Date`,`Treatment ID`, `Crop`, `Plant Fraction`, # identity columns
           # numeric columns include "Frac Dry Matt kg/ha"       
           # [9] "Frac Moist %"               "Frac C kgC/ha"              "Frac N kgN/ha"              "Grain Weight mg/kernel"    
           # [13] "Frac Dry Matt STD kg/ha"    "Frac Moist STD %"           "Frac C STD kgC/ha"          "Frac N STD kgN/ha"         
           # [17] "Grain Weight STD mg/kernel"
           `Frac Dry Matt kg/ha`, `Frac Moist %`, `Frac C kgC/ha`, `Frac N kgN/ha`) %>%
    # convert the numeric columns to numeric and replace NA with 0
    mutate(`Frac Dry Matt kg/ha` = as.numeric(`Frac Dry Matt kg/ha`),
           `Frac Moist %` = as.numeric(`Frac Moist %`),
           `Frac C kgC/ha` = as.numeric(`Frac C kgC/ha`),
           `Frac N kgN/ha` = as.numeric(`Frac N kgN/ha`)
    ) %>%
    # for the numeric columns, replace NA with 0
    mutate_at(vars(`Frac Dry Matt kg/ha`, `Frac Moist %`, `Frac C kgC/ha`, `Frac N kgN/ha`), ~replace_na(., 0)) %>%
    # aggregate by SiteID, Exp Unit ID, Treatment ID, Plant Fraction
    group_by(SiteID, `Exp Unit ID`, `Sampling Date`,`Treatment ID`, `Crop`, `Plant Fraction`) %>%
    # summarise the numeric columns
    summarise_all(sum)
  
  # get a list of unique identity
  identity = crop_data %>%
    select(SiteID, `Exp Unit ID`, `Sampling Date`,`Treatment ID`, `Crop`) %>%
    unique()
    
  # for each identity, create a dataframe with the fraction parts
  for (i in 1:nrow(identity)) {
    # get the identity
    id = identity[i, ]
    
    # filter the data for the specific identity
    id_data = crop_data %>%
      filter(SiteID == id$SiteID, `Exp Unit ID` == id$`Exp Unit ID`,
             `Sampling Date` == id$`Sampling Date`, `Treatment ID` == id$`Treatment ID`,
             Crop == id$Crop)
    # get the unique fraction parts
    fraction_parts = id_data$`Plant Fraction` %>%
      unique()
    for (part in fraction_parts) {
      # filter the data for the specific fraction part
      part_data = id_data %>%
        filter(`Plant Fraction` == part)
      # create new column [part]_biomass
      id_data[[paste0(part, "_biomass")]] = part_data$`Frac Dry Matt kg/ha` %>%
        sum()
      # create new column [part]_carbon_kgC/ha
      id_data[[paste0(part, "_carbon_kgC/ha")]] = part_data$`Frac C kgC/ha` %>%
        sum()
      # create new column [part]_nitrogen_kgN/ha
      id_data[[paste0(part, "_nitrogen_kgN/ha")]] = part_data$`Frac N kgN/ha` %>%
        sum()
    }
    # merge into df_input
    id_data = id_data %>%
      select(-`Plant Fraction`, -`Frac Dry Matt kg/ha`, -`Frac Moist %`, -`Frac C kgC/ha`, -`Frac N kgN/ha`)
    df_input = rbind(df_input, id_data[1,])
  }
}

# drop row if any identity is NA
df_input = df_input %>%
  filter(!is.na(SiteID), !is.na(`Exp Unit ID`), !is.na(`Sampling Date`), !is.na(`Treatment ID`), !is.na(`Crop`))

# replace na with 0 for the numeric columns
df_input = df_input %>%
  mutate_at(vars(ends_with("_biomass"), ends_with("_carbon_kgC/ha"), ends_with("_nitrogen_kgN/ha")), ~replace_na(., 0))

# final process
# ideally, for a specific experiment, we have sample in 5 years (2008 - 2012)
# if we have more than one sample in a year, we should merge the columns together
year_data = data.frame()
for (year in unique(year(df_input$`Sampling Date`))) {
  # filter the data for the specific year
  year_data_temp = df_input %>%
    # filter for the specific year
    filter(grepl(as.character(year), `Sampling Date`)) %>%
    # aggregate by SiteID, Exp Unit ID, Treatment ID, Crop
    group_by(SiteID, `Exp Unit ID`, `Treatment ID`, `Crop`) %>%
    select(-`Sampling Date`) %>%
    summarise_all(sum) %>%
    # create a new column, Sampling Year
    mutate(`Sampling Year` = year) %>%
    # put this column after the Exp Unit ID column
    select(SiteID, `Exp Unit ID`, `Sampling Year`, `Treatment ID`, `Crop`, everything())
  # merge the data
  year_data = rbind(year_data, year_data_temp)
}

# sort df_input by exp unit id and then sampling year
year_data = year_data %>%
  arrange(`Exp Unit ID`, `Sampling Year`)

# export the data
write_csv(year_data, "../../temp/gracenet_carbon_input.csv")

# clear all variables in the environment
rm(list = ls())

# load the processed data
df_input = read_csv("../../temp/gracenet_carbon_input.csv")

# now start computing carbon input based on Bolinder et al.

# define parameters
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

# the problem here is to find out how to estimate C_p, C_s, C_r, C_e for each type of crop
# let's loop through each identity (rows in df_input) and compute the carbon input
for (i in 1:nrow(df_input)) {
  # identify the crop type
  crop_type = df_input[i, ]$Crop
  # use different algorithms to compute C_p, C_s, C_r, C_e for each crop type
  case_when(
    crop_type == "Zea mays (Corn)" ~ {
      df_input[i, ]$C_p = df_input[i, ]$`Grain_carbon_kgC/ha`
      df_input[i, ]$C_s = df_input[i, ]$`Stover_carbon_kgC/ha`
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
    crop_type == "Glycine max (Soybean)" ~ {
      # for soybean, we use the following values
      # C_p = 0.45, C_s = 0.45, C_r = 0.1, C_e = 0
      df_input[i, ]$C_p = 0.45
      df_input[i, ]$C_s = 0.45
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
    crop_type == "Sorghum vulgare sudanense (Sudangrass)" ~ {
      # for wheat, we use the following values
      # C_p = 0.45, C_s = 0.45, C_r = 0.1, C_e = 0
      df_input[i, ]$C_p = 0.45
      df_input[i, ]$C_s = 0.45
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
    crop_type == "Restored Prairie" ~ {
      # for sunflower, we use the following values
      # C_p = 0.45, C_s = 0.45, C_r = 0.1, C_e = 0
      df_input[i, ]$C_p = 0.45
      df_input[i, ]$C_s = 0.45
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
    crop_type == "Triticum aestivum (Wheat)" ~ {
      # for sunflower, we use the following values
      # C_p = 0.45, C_s = 0.45, C_r = 0.1, C_e = 0
      df_input[i, ]$C_p = 0.45
      df_input[i, ]$C_s = 0.45
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
    crop_type == "Medicago sativa (Alfalfa)" ~ {
      # for sunflower, we use the following values
      # C_p = 0.45, C_s = 0.45, C_r = 0.1, C_e = 0
      df_input[i, ]$C_p = 0.45
      df_input[i, ]$C_s = 0.45
      df_input[i, ]$C_r = 0.1
      df_input[i, ]$C_e = 0
    },
  )
}

# export the data
write_csv(df_input, "../../temp/gracenet_carbon_input.csv")