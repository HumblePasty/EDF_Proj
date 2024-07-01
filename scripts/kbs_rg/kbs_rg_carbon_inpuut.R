library(tidyverse)
library(tibble)
library(EML)
library(readr)
library(readxl)
library(dplyr)

# set working directory as current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# read in the data for KBS_RG
# due to lack of agronomic data, the carbon should be estimated with harvest data
# load the yield data
kbs_rg_yield = read.csv("../../data/kbs_rg/77-agronomic+yields+1719274639.csv", header = T, skip = 31) %>%
  slice(-1)

# create carbon output table
marsden_carbon_input = tibble(
  "date" = character(),
  "yeaer" = character(),
  "plot" = character(),
  "location" = character(),
  "treatment" = character(),
  "replicate" = character(),
  "irrigated" = character(),
  "crop" = character(),
  "fertilizer_rate_kg_ha" = numeric(),
  "yield_kg_ha" = numeric(),
  "C_grain" = numeric(),
  "C_s" = numeric(),
  "C_r" = numeric(),
  "C_ex" = numeric(),
  "C_total" = numeric()
)

# for each row, estimate the 