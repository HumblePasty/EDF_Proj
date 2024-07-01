library(tidyverse)
library(tibble)
library(EML)
library(readr)
library(readxl)
library(dplyr)

# set working directory as current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# load marsden carbon data
marsden_data = read_excel("../../data/marsden/Marsden_clover_alfalfa.xlsx", sheet = "Marsden_clover_alfalfa")
marsden_metadata = read_excel("../../data/marsden/Marsden_clover_alfalfa.xlsx", sheet = "Metadata")

# set up parameters
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

# create the output table
marsden_carbon_input = tibble(
  "Year" = character(),
  "Treatment" = character(),
  "Block" = character(),
  "Plot" = character(),
  "Species" = character(),
  "C_ps" = numeric(),
  "C_r" = numeric(),
  "C_ex" = numeric(),
  "C_tot" = numeric()
)

# for rows in the marsden data, calculate the carbon input
for (i in 1:nrow(marsden_data)) {
  current_data = marsden_data[i,]
  C_ps = current_data$Biomass * conc
  C_r = C_ps * current_data$Root_Shoot
  C_ex = C_r * ERtoR
  
  # insert the data into the output table
  marsden_carbon_input = rbind(marsden_carbon_input, tibble(
    "Year" = current_data$Year,
    "Treatment" = current_data$Treatment,
    "Block" = current_data$Block,
    "Plot" = current_data$Plot,
    "Species" = current_data$Species,
    "C_ps" = C_ps,
    "C_r" = C_r,
    "C_ex" = C_ex,
    "C_total" = C_ps + C_r + C_ex
  ))
}

# export the data
write_csv(marsden_carbon_input, "../../temp/marsden_carbon_input.csv")
