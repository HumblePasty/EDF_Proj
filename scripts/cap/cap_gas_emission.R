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
cap_ghg = read_excel("../../data/cap_data/C_Data_2011-2015_0.xlsx", sheet = "GHG") %>%
  as.data.frame() %>%
  slice(-1:-2)

# create final output table
cap_gas_flux = data.frame(
    # identifier columns
    `Site` = character(),
    `Experiment` = character(),
    `Year` = character(),
    `Time.Range` = character(),
    `Chamber` = character(),
    `Crop` = character(),
    # numeric columns
    `CO2.Flux` = numeric(),
    `CO2.SE` = numeric(),
    `CH4.Flux` = numeric(),
    `CH4.SE` = numeric(),
    `N2O.Flux` = numeric(),
    `N2O.SE` = numeric(),
    `NH3.Flux` = numeric(),
    `NH3.SE` = numeric()
  )

# select effective data
cap_ghg_data = cap_ghg %>%
  select(Site = uniqueid, Experiment = plotid, date, year, Chamber = position,
         CO2.Flux = GHG01, N2O.Flux = GHG03, NH3.Flux = GHG05, CH4.Flux = GHG07)

# create a list of unique identifiers
identifiers = cap_ghg_data %>%
  select(Site, Experiment, Chamber) %>%
  distinct() %>%
  # create two new columns for start and end date
  mutate(`Start.Date` = as.Date(NA), 
         `End.Date` = as.Date(NA),
         `Number of Observations` = as.integer(NA))

# for each unique identifier, calculate the mean and standard error of the gas fluxes
for (i in 1:nrow(identifiers)) {
  # select data for the current identifier
  current_data = cap_ghg_data %>%
    filter(Site == identifiers$Site[i], Experiment == identifiers$Experiment[i], Chamber == identifiers$Chamber[i])
  
  identifiers$`Start.Date`[i] = min(current_data$date)
  identifiers$`End.Date`[i] = max(current_data$date)
  identifiers$`Number of Observations`[i] = nrow(current_data)
  
  # sort the data by date
  current_data = current_data %>%
    arrange(date)
  
  # get a list of unique dates
  dates = current_data %>%
    select(date) %>%
    distinct()
  
  # get time range
  time_range = paste(min(dates$date), max(dates$date), sep = "-")
  
  # get a list of full dates
  full_dates = seq.Date(from = as.Date(min(dates$date)), to = as.Date(max(dates$date)), by = "day")
  
  # get a list of unique years
  years = current_data %>%
    select(year) %>%
    distinct()
  
  # CO2 output
  # filter out rows with missing CO2 data
  flux_data = current_data %>%
    filter(!is.na(CO2.Flux))
  # if less than 2 CO2 data points, set CO2.Flux and CO2.SE to NA
  if (nrow(flux_data) < 2) {
    CO2.Model = NA
  } else {
    CO2.Model = 1
    # use spline interpolation as default method
    tryCatch(
      {
        model = smooth.spline(x = as.numeric(flux_data$date), y = flux_data$CO2.Flux)
      },
      # if errot, use the linear model
      error = function(e) {
        model = lm(flux_data$CO2.Flux ~ as.numeric(flux_data$date), data = flux_data)
      }
    )
    CO2_interpolated = predict(model, as.numeric(full_dates))
  }
  
  # CH4 output
  # filter out rows with missing CH4 data
  flux_data = current_data %>%
    filter(!is.na(CH4.Flux))
  # if less than 2 CH4 data points, set CH4.Flux and CH4.SE to NA
  if (nrow(flux_data) < 2) {
    CH4.Model = NA
  } else {
    CH4.Model = 1
    # use spline interpolation as default method
    tryCatch(
      {
        model = smooth.spline(x = as.numeric(flux_data$date), y = flux_data$CH4.Flux)
      },
      # if errot, use the linear model
      error = function(e) {
        model = lm(flux_data$CH4.Flux ~ as.numeric(flux_data$date), data = flux_data)
      }
    )
    CH4_interpolated = predict(model, as.numeric(full_dates))
  }
  
  
  # N2O output
  # filter out rows with missing N2O data
  flux_data = current_data %>%
    filter(!is.na(N2O.Flux))
  # if less than 2 N2O data points, set N2O.Flux and N2O.SE to NA
  if (nrow(flux_data) < 2) {
    N2O.Model = NA
  } else {
    N2O.Model = 1
    # use spline interpolation as default method
    tryCatch(
      {
        model = smooth.spline(x = as.numeric(flux_data$date), y = flux_data$N2O.Flux)
      },
      # if errot, use the linear model
      error = function(e) {
        model = lm(flux_data$N2O.Flux ~ as.numeric(flux_data$date), data = flux_data)
      }
    )
    N2O_interpolated = predict(model, as.numeric(full_dates))
  }
  
  # NH3 output
  # filter out rows with missing NH3 data
  flux_data = current_data %>%
    filter(!is.na(NH3.Flux))
  # if less than 2 NH3 data points, set NH3.Flux and NH3.SE to NA
  if (nrow(flux_data) < 2) {
    NH3.Model = NA
  } else {
    NH3.Model = 1
    # use spline interpolation as default method
    tryCatch(
      {
        model = smooth.spline(x = as.numeric(flux_data$date), y = flux_data$NH3.Flux)
      },
      # if errot, use the linear model
      error = function(e) {
        model = lm(flux_data$NH3.Flux ~ as.numeric(flux_data$date), data = flux_data)
      }
    )
    NH3_interpolated = predict(model, as.numeric(full_dates))
  }
  
  # add the calculated values to the final output table
  # aggregate by each year
  for (year in years$year) {
    # create the time range for the current year
    start_date = if (year == min(years)) {
      as.Date(min(dates$date))
    } else {
      as.Date(paste(year, "-01-01", sep = ""))
    }
    end_date = if (year == max(years)) {
      as.Date(max(dates$date))
    } else {
      as.Date(paste(year, "-12-31", sep = ""))
    }
    temp_time_range = paste(start_date, end_date, sep = "~")
    # filter the interpolated data within the current time range
    if (!is.na(CO2.Model)) {
      CO2_interpolated_year = CO2_interpolated %>%
        as.data.frame() %>%
        filter(as.Date(full_dates) >= start_date & as.Date(full_dates) <= end_date)
      CO2.Flux = sum(CO2_interpolated_year$y)
      CO2.SE = sd(CO2_interpolated_year$y)
    } else {
      CO2.Flux = NA
      CO2.SE = NA
    }
    if (!is.na(CH4.Model)) {
      CH4_interpolated_year = CH4_interpolated %>%
        as.data.frame() %>%
        filter(as.Date(full_dates) >= start_date & as.Date(full_dates) <= end_date)
      CH4.Flux = sum(CH4_interpolated_year$y)
      CH4.SE = sd(CH4_interpolated_year$y)
    } else {
      CH4.Flux = NA
      CH4.SE = NA
    }
    if (!is.na(N2O.Model)) {
      N2O_interpolated_year = N2O_interpolated %>%
        as.data.frame() %>%
        filter(as.Date(full_dates) >= start_date & as.Date(full_dates) <= end_date)
      N2O.Flux = sum(N2O_interpolated_year$y)
      N2O.SE = sd(N2O_interpolated_year$y)
    } else {
      N2O.Flux = NA
      N2O.SE = NA
    }
    if (!is.na(NH3.Model)) {
      NH3_interpolated_year = NH3_interpolated %>%
        as.data.frame() %>%
        filter(as.Date(full_dates) >= start_date & as.Date(full_dates) <= end_date)
      NH3.Flux = sum(NH3_interpolated_year$y)
      NH3.SE = sd(NH3_interpolated_year$y)
    } else {
      NH3.Flux = NA
      NH3.SE = NA
    }
    
    cap_gas_flux = rbind(cap_gas_flux, data.frame(
      `Site` = identifiers$Site[i],
      `Experiment` = identifiers$Experiment[i],
      `Year` = year,
      `Time.Range` = temp_time_range,
      `Chamber` = identifiers$Chamber[i],
      `Crop` = NA,
      `CO2.Flux` = CO2.Flux,
      `CO2.SE` = CO2.SE,
      `CH4.Flux` = CH4.Flux,
      `CH4.SE` = CH4.SE,
      `N2O.Flux` = N2O.Flux,
      `N2O.SE` = N2O.SE,
      `NH3.Flux` = NH3.Flux,
      `NH3.SE` = NH3.SE
    ))
  }
}

# write the final output table to a CSV file
write.csv(cap_gas_flux, "../../temp/cap_gas_emission.csv")
write.csv(identifiers, "../../temp/cap_gas_emission_identifiers.csv")
