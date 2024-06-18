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
grace_ghg = read_excel("../../data/gracenet/natres.xlsx", sheet = "MeasGHGFlux")

# create final output table
gracenet_gas_flux = data.frame(SiteID = character(),
                               `Exp Unit ID` = character(),
                               `Year` = character(),
                               `Treatment ID` = character(),
                               `Crop` = character())
# and then the numeric columns

# filter for the interested sites
grace_ghg = grace_ghg %>%
  filter(SiteID %in% c(
    "IAAMBRUN", "INWLACRE", "MNMOBRR", "MNMOFS", "NELITCSE", "NEMEIRR", "NEMERREM", "NEMLTCRS")) %>% # sites of interest
  # remove the unrelated columns
  select(-`Air Temp degC`, -`Soil Temp degC`, -`Soil Moisture % vol`, -`Soil Moisture Depth cm`,
         -`N2O Interp=0 Obs=1`, -`CO2 Interp=0 Obs=1`, -`CH4 Interp=0 Obs=1`, 
         -`Air Temp STD degC`, -`Soil Temp STD degC`, -`Soil Moisture STD % vol`)

# get a list of unique identity
grace_ghg_identity = grace_ghg %>%
  select(SiteID, `Exp Unit ID`, `Treatment ID`, `Crop`, `Chamber Placement`) %>%
  unique()

# create two new columns for the start date and end date
grace_ghg_identity = grace_ghg_identity %>%
  mutate(`Start Date` = as.Date(NA),
         `End Date` = as.Date(NA),
         `Number of Observations` = as.integer(NA))


# for every identity, make estimates on the GHG emissions
for (i in 1:nrow(grace_ghg_identity)) {
  # get the current identity
  current_identity = grace_ghg_identity[i, ]
  
  # filter the data for the current identity
  current_data = grace_ghg %>%
    filter(SiteID == current_identity$SiteID,
           `Exp Unit ID` == current_identity$`Exp Unit ID`,
           `Treatment ID` == current_identity$`Treatment ID`,
           # `Crop` == current_identity$Crop,
           # if Crop is not NA, use it as a filter
           if (!is.na(current_identity$Crop)) `Crop` == current_identity$Crop else TRUE,
           `Chamber Placement` == current_identity$`Chamber Placement`)
  
  # add the start date and end date to the identity list
  grace_ghg_identity[i, ]$`Start Date` = as.Date(min(current_data$Date))
  grace_ghg_identity[i, ]$`End Date` = as.Date(max(current_data$Date))
  # add the number of observations
  grace_ghg_identity[i, ]$`Number of Observations` = nrow(current_data)
  
  # get the chamber placement
  chamber_placements = unique(current_data$`Chamber Placement`)
  
  # get the list of measurements datetimes
  datelist = unique(current_data$Date)
  # get the date range from the datelist
  date_range = range(datelist)
  # get a list of full days in the date range
  full_days = seq(from = date_range[1], to = date_range[2], by = "day")
  
  # sort current_data in ascending order of Date
  current_data = current_data %>%
    arrange(Date)
  
  # N2O annual output
  temp_data = current_data %>%
    drop_na(`N2O gN/ha/d`)
  # if less than 2 rows of data is available, pass and continue to the next gas
  if (nrow(temp_data) < 2) {
    n2o_annual_output = NA
    n2o_se = NA
  }
  else {
    tryCatch({
      n2o_model = smooth.spline(x = as.numeric(temp_data$Date), y = temp_data$`N2O gN/ha/d`)
    }, error = function(e) {
      # if the spline model fails, use a linear model
      n2o_model = lm(`N2O gN/ha/d` ~ Date, data = temp_data)
    })
    # get the interpolated values for the full days
    n2o_interpolated = predict(n2o_model, x = as.numeric(full_days))$y
    # sum the interpolated values to get the annual output
    n2o_annual_output = sum(n2o_interpolated)
    # add the standard error
    n2o_se = sd(n2o_interpolated)
  }
  
  # CO2 annual output
  temp_data = current_data %>%
    drop_na(`CO2 gC/ha/d`)
  # if less than 2 rows of data is available, pass and continue to the next gas
  if (nrow(temp_data) < 2) {
    co2_annual_output = NA
    co2_se = NA
  }
  else {
    tryCatch({
      co2_model = smooth.spline(x = as.numeric(temp_data$Date), y = temp_data$`CO2 gC/ha/d`)
    }, error = function(e) {
      co2_model = lm(`CO2 gC/ha/d` ~ Date, data = temp_data)
    })
    # get the interpolated values for the full days
    co2_interpolated = predict(co2_model, x = as.numeric(full_days))$y
    # sum the interpolated values to get the annual output
    co2_annual_output = sum(co2_interpolated)
    # add the standard error
    co2_se = sd(co2_interpolated)
  }
  
  # CH4 annual output
  temp_data = current_data %>%
    drop_na(`CH4 gC/ha/d`)
  # if less than 2 rows of data is available, pass
  if (nrow(temp_data) < 2) {
    ch4_annual_output = NA
    ch4_se = NA
  }
  else {
    tryCatch({
      ch4_model = smooth.spline(x = as.numeric(temp_data$Date), y = temp_data$`CH4 gC/ha/d`)
    }, error = function(e) {
      ch4_model = lm(`CH4 gC/ha/d` ~ Date, data = temp_data)
    })
    # get the interpolated values for the full days
    ch4_interpolated = predict(ch4_model, x = as.numeric(full_days))$y
    # sum the interpolated values to get the annual output
    ch4_annual_output = sum(ch4_interpolated)
    # add the standard error
    ch4_se = sd(ch4_interpolated)
  }
  
  # add the data to the final output table
  gracenet_gas_flux = rbind(gracenet_gas_flux, data.frame(SiteID = current_identity$SiteID,
                                                           `Exp Unit ID` = current_identity$`Exp Unit ID`,
                                                           `Time Range` = paste(date_range[1], date_range[2], sep = " - "),
                                                           `Treatment ID` = current_identity$`Treatment ID`,
                                                           `Crop` = current_identity$Crop,
                                                           `N2O gN/ha/total` = n2o_annual_output,
                                                           `N2O gN/ha/total SE` = n2o_se,
                                                           `CO2 gC/ha/total` = co2_annual_output,
                                                           `CO2 gC/ha/total SE` = co2_se,
                                                           `CH4 gC/ha/total` = ch4_annual_output,
                                                           `CH4 gC/ha/total SE` = ch4_se))
}


# export the final output table
write_csv(gracenet_gas_flux, "../../temp/gracenet_gas_emission.csv")
write_csv(grace_ghg_identity, "../../temp/gracenet_gas_emission_identity.csv")

