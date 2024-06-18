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
kbs_ghg = read.csv("../../data/kbs_msce/28-n2o+ch4+co2+fluxes+via+static+chambers+1718296211.csv", header = T, skip = 41) %>%
  slice(-1) %>%
  # remove the unrelated columns
  select(-air_temperature_c, -moisture, -soil_temperature_c)

# create output table
kbs_ghg_flux = data.frame(
  Site = character(),
  Treatment = character(),
  Replicate = character(),
  Crop = character(),
  Year = numeric(),
  CO2_Flux = numeric(),
  N2O_Flux = numeric(),
  CH4_Flux = numeric()
)

# get a list of unique identifiers
identifiers = kbs_ghg %>%
  select(Treatment, Replicate, crop) %>%
  distinct()

# loop through all identifiers
for (i in 1:nrow(identifiers)) {
  # get the current identifier
  current_identifier = identifiers[i,]
  
  # filter the data
  current_data = kbs_ghg %>%
    filter(Treatment == current_identifier$Treatment,
           Replicate == current_identifier$Replicate,
           crop == current_identifier$crop)
  
  
}



