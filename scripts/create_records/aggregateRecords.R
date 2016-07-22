# ===========
# Description
# ===========
# This script accesses the individual NetCDF climate files and aggregates the 
#   records by each model/emissions scenario combination. The roughly 450 
#   individual files (1 file per year/variable combination) are combined into 
#   a single CSV for upload to the database.
# The models are indexed by directory location. All models in the same location 
#   (sourceDirectory) are looped through and aggregated.
# The temperature variables are corrected from Kelvin to Celsuis.


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


# ==============
# Specify inputs
# ==============
# The directory containing the model folders with raw netcdf files
sourceDirectory <- "F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP"

# Variables 
variables <- c("pr", "tasmax", "tasmin")

# Table to limit the record to the catchment grid cells  
gridTable <- read.dbf("C:/KPONEIL/climate/NASA_projections/spatial/catchmentsGridTable.dbf")

# Output location
outputDirectory <- "C:/KPONEIL/climate/NASA_projections/clean"


# =====
# Setup
# =====
# Set warnings to show up immediately
options(warn = 1)

# Create the log file for all warnings/errors
logFile <- file.path(outputDirectory, "log.txt")

# Create connection to log file and write all errors/warnings to it directly
logConnect <- file(logFile, open="wt")
sink(logConnect, type="message")

# Get model names
modelNames <- list.files(sourceDirectory)

# Save run times
runTimes <- as.data.frame(matrix(nrow = length(modelNames), ncol = 2))
names(runTimes) <- c("Model", "Hours")

# Select the unique cells in the study area
grid <- unique(gridTable[,c("lon", "lat", "cellID")])


# ==========
# Processing
# ==========
# Loop through models
for (m in seq_along(modelNames)){
  
  # Start time
  S <- proc.time()[3]
  
  
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
    
    # use string manipulation to index the years
    spaces <- nchar(file)
    
    yearList <- c(yearList, 
                  as.numeric(substr(file, 
                                    spaces - 6, 
                                    spaces - 3)))
  }
  
  yearsTable <- table(yearList)
  
  missingYears <- names(yearsTable)[which(yearsTable < length(variables))]
  
  # Error check: Missing files
  if(length(missingYears) > 0){
    stop(paste0("Variable record missing for ", 
                missingYears, 
                ". Check source files."))
  }
  
  allYears <- (min(yearList):max(yearList))

  
  # Year loop
  # ---------
  for (y in seq_along(allYears)){  
    
    # Current year
    year <- allYears[y]
    
    # Status update
    print(paste0("Procesing files for model '", 
                 modelName, 
                 "' in year ", 
                 year,
                 "."))

    
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

      
      # Determine variable sizes
      # ------------------------
      # Climate variable
      for (h in 1:length(netcdf$var)) {
        if (netcdf$var[[h]]$name == variable) {
          varIndex <- h
        }
      }
      valSize <- netcdf$var[[varIndex]]$varsize
      
      # Latitude
      for (h in 1:length(netcdf$var)) {
        if (netcdf$dim[[h]]$name == "lat") {
          latIndex <- h
        }
      }
      latSize <- netcdf$dim[[latIndex]]$len
      
      # Longitude
      for (h in 1:length(netcdf$var)) {
        if (netcdf$dim[[h]]$name == "lon") {
          lonIndex <- h
        }
      }
      lonSize <- netcdf$dim[[lonIndex]]$len
      
      # Number of grid cells
      cellCount = latSize*lonSize
      
      # Number of records
      recordCount = valSize[1]*valSize[2]*valSize[3]
  
      
      # Read in variables
      # -----------------
      # Climate values
      values <- ncvar_get(nc    = netcdf,
                          varid = variable,
                          start = c(1, 1, 1),
                          count = c(valSize[1], 
                                    valSize[2], 
                                    valSize[3]))
      
      # Latitude
      lat <- ncvar_get(nc    = netcdf,
                       varid = "lat",
                       start = 1,
                       count = latSize[2])
      
      #Longitude
      lon <- ncvar_get(nc    = netcdf,
                       varid = "lon",
                       start = 1,
                       count = lonSize[2])
 
      # Close the NetCDF connection
      nc_close(netcdf)
    
      
      # Date information
      # ----------------
      calendar <- netcdf$dim$time$calendar
      yearLength <- netcdf$dim$time$len   
            
      # Day of year list
      if (leap_year(year) & yearLength < 366){
        doys <- c(1:59, 61:366)
      } else{
        doys <- 1:yearLength
      }

      
      # Pre-allocate variable dataframe
      # -------------------------------
      # Create storage object for single climate variable
      record <- as.data.frame(matrix(nrow = recordCount, 
                                     ncol = 4)
      )
      
      
      # Format variables
      # ----------------
      # The matrix slices are reshaped into long format
      for (d in 1:length(values[1,1,])){

        # Select & label slice
        slice <- values[,,d]
        
        colnames(slice) <- lat
        row.names(slice) <- lon
        
        # Reshape slice
        meltedSlice <- melt(slice)
      
        # Add date
        meltedSlice$date <- paste(parse_date_time(paste0(year, "-", doys[d]), 
                                                  "y-j", 
                                                  tz = "EST"))
        
        # Reorder/name columns
        meltedSlice <- meltedSlice[,c(1,2,4,3)]
      
        # Dump into storage object
        beg <- (d-1)*cellCount + 1
        end   <- cellCount*d
        
        record[beg:end,] <- meltedSlice
        
        names(record) <- c("lon", "lat", "date", variable)
      }
      
      # Only output cells with catchments present in them
      filteredRecord <- inner_join(record, grid, by = c("lon", "lat"))
      
      trimRecord <- filteredRecord[,c("cellID", "date", variable)]
      
      
      # Join climate variables
      # ----------------------
      if(!exists("yearRecord")){
        yearRecord <- trimRecord
      } else{
        yearRecord <- left_join(yearRecord, 
                                trimRecord, 
                                by = c("cellID", "date"))
      }
      
      rm(filteredRecord, trimRecord)
    
    }# End variable loop
    
    
    # Check for Errors
    # ----------------
    # Make note of NA values that get written to the CSV
    if (any(is.na(yearRecord))){
      warning("The year ", 
              year, 
              " for model '", 
              modelName, 
              "' contains NA values.")
    }  
    
    # Make sure the date column matches the number of days in the year as 
    #   specified by the netcdf documentation.
    if (yearLength != length(unique(yearRecord$date))){
      warning("The dates in the year ", 
              year, 
              " for model '", 
              modelName, 
              "' do not match the netcdf documentation.")
    } 
    
    
    # Unit conversion
    # ---------------
    # Kelvin to Celsius
    yearRecord$tasmax <- yearRecord$tasmax - 273.15
    yearRecord$tasmin <- yearRecord$tasmin - 273.15


    # Export record table
    # -------------------
    output <- file.path(outputDirectory, paste0(modelName, ".csv"))
    
    if (!file.exists(output)){
      write.csv(yearRecord, 
                file = output, 
                row.names = F)
    } else{
      write.table(yearRecord, 
                  file = output,
                  sep = ",",
                  append = T,
                  row.names = F,
                  col.names = F)
    } 
    
    rm(yearRecord)    

  }# End year loop

  E <- proc.time()[3]  
  
  runTimes$Model[m] <- modelName
  runTimes$Hours[m] <- (E-S)/3600

} # End model loop

# Write model run times table
write.csv(runTimes, 
          file = file.path(outputDirectory, "Model Run Times.csv"),
          row.names = F)

# Close log connection
sink(type="message")
close(logConnect)
