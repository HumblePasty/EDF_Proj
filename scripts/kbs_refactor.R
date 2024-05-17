# Load packages
library(tidyverse)
library(tibble)
library(EML)

# import data
# set working directory as current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# Biomass - Annual crops and alfalfa
biomass_annuals_alfalfa <- read.csv("KBS MSCE/kbs_mcse_biomass_annual_crops_and_alfalfa.csv", header = T, skip = 29)

biomass_annuals_alfalfa <- biomass_annuals_alfalfa %>%
  slice(-1) %>%
  filter(Treatment == "T1" | Treatment == "T2" | Treatment == "T3" | Treatment == "T4") %>%
  mutate(Biomass = Biomass * 10)  #multiply by 10 to convert g/m2 to kg/ha

# Biomass - Cover crops
biomass_covercrops <- read.csv("KBS MSCE/kbs_mcse_biomass_cover_crop.csv", header = T, skip = 27)
biomass_covercrops <- biomass_covercrops %>%
  slice(-1) %>%
  transform(biomass_g = as.numeric(biomass_g)) %>%
  mutate(Biomass = biomass_g * 10)  #multiply by 10 to convert g/m2 to kg/ha