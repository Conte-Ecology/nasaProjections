# ===========
# Description
# ===========
# Investigating calendar discrepancies between and within the different 
#   model/scenarios.


# ==============
# Load libraries
# ==============
# Clear workspace
rm(list = ls())

library(ncdf4)
library(reshape2)
library(lubridate)
library(dplyr)
library(foreign)

# Set warnings to show up immediately
options(warn = 1)


# ==============
# Specify inputs
# ==============
# The directory containing the model folders with raw netcdf files
sourceDirectory <- "F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP"

# Variables 
variables <- c("pr", "tasmax", "tasmin")

# Output location
outputDirectory <- "C:/KPONEIL/climate/NASA_projections/clean"


# ==========
# Processing
# ==========
# Get model names
modelNames <- list.files(sourceDirectory)

# Loop through models
for (m in seq_along(modelNames)){
  
  # Get model info
  # --------------
  modelName <- modelNames[m]  
  
  modelFolder <- file.path(sourceDirectory, modelName)
  
  modelFiles <- list.files(modelFolder)
  
  
  # Determine model years
  # ---------------------
  yearList <- c()
  
  for (f in seq_along(modelFiles)){
    
    file <- modelFiles[f]
    
    # String indexing to pull years
    spaces <- nchar(file)
    
    yearList <- c(yearList, 
                  as.numeric(substr(file, 
                                    spaces - 6, 
                                    spaces - 3)))
  }
  
  yearsTable <- table(yearList)
  
  missingYears <- names(yearsTable)[which(yearsTable < length(variables))]
  
  if(length(missingYears) > 0){
    stop(paste0("Variable record missing for ", 
                missingYears, 
                ". Check source files."))
  }
  
  endYr <- max(yearList)
  begYr <- min(yearList)
  
  allYears <- (begYr:endYr)
  
  # Status update
  print(paste0("Procesing files for model '", 
               modelName,
               "."))
  
  
  calendarStats <- as.data.frame(matrix(nrow = length(allYears)*length(variables), ncol = 5))
  names(calendarStats) <- c("model", "year", "variable", "calendar", "yearLength")
  
  
  # Year loop
  # ---------
  for (y in seq_along(allYears)){  
    
    # Current year
    year <- allYears[y]
    
    # Variable loop
    # -------------
    # Loop through climate variables for current year
    for (variable in variables){
      
      # Load netCDF
      # -----------
      # Select the filename based on the variable and year
      fileName <- modelFiles[intersect(grep(variable          , modelFiles), 
                                       grep(as.character(year), modelFiles))]  
      
      netcdf <- nc_open(file.path(modelFolder, fileName))
      
      
      # Date information
      calendar <- netcdf$dim$time$calendar
      yearLength <- netcdf$dim$time$len   
      
      
      curRow <- min(which(is.na(calendarStats$year)))
      
      calendarStats$model[curRow] <- modelName
      calendarStats$year[curRow] <- year
      calendarStats$variable[curRow] <- variable
      calendarStats$calendar[curRow] <- calendar
      calendarStats$yearLength[curRow] <- yearLength
      
      nc_close(netcdf)
    }# End variable loop
  }# End year loop
  
  if(!exists("allStats")) {
    allStats <- calendarStats
  }else{
    allStats <- rbind(allStats, calendarStats)
  }
} # End model loop

# allStats$leapYear <- leap_year(allStats$year)

write.csv(allStats, file = file.path(outputDirectory, "Calendar Stats Table.csv"))



# allStats[which(allStats$yearLength < 365),]


