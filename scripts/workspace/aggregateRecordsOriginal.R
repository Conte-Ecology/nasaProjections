# ====================
# Future modifications
# ====================

# - Add in capacity to loop through all model/scenario combinations (either by 
#     adding a list of names or by reading folders)
# - Assign dates based on the type of calendar used by the model (either dropping 
#     Dec 31st or Feb 29th in leap years). This can be indexed by $dim$time$calendar


# ===========
# Description
# ===========
# This script accesses the individual NetCDF climate files and aggregates the 
#   records by each model/emissions scenario combination. The 450 individual 
#   files (1 file per year/variable combination) are combined to a single CSV 
#   for upload to the database.


# ==============
# Load libraries
# ==============
# Clear workspace
rm(list = ls())

library(ncdf4)
library(reshape2)
library(lubridate)
library(dplyr)


# ==============
# Specify inputs
# ==============

baseDirectory <- "F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP"

# Variables 
variables <- c("pr", "tasmax", "tasmin")

# Table to limit the record to the catchment grid cells  
gridTable <- read.csv("C:/KPONEIL/climate/NASA_projections/spatial/catchmentsGridTable.csv")

# Output location
outputDirectory <- "C:/KPONEIL/climate/NASA_projections/clean"

  
# ==========
# Processing
# ==========

# Get model names
modelNames <- list.files(baseDirectory)

# Select the unique cells in the study area
grid <- unique(gridTable[,c("lon", "lat", "cellID")])

# Loop through NetCDF files for the model
S <- proc.time()[3]

# Loop through models
for (m in seq_along(modelNames)){
  
  m = 1

  # Get model info
  # --------------
  modelName <- modelNames[m]  
  
  modelFolder <- file.path(baseDirectory, modelName)
  
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
      calendar <- netcdf$dim$time$calendar
      yearLength <- netcdf$dim$time$len   

      
      # Pre-allocate variable dataframe
      # -------------------------------
      # Create storage object for single climate variable
      record <- as.data.frame(matrix(nrow = recordCount, 
                                     ncol = 4)
      )

      
      # Format variables
      # ----------------
      # Correction for no leap year scenarios
      if (calendar  == "noleap"  | calendar  == "365_day"){
        doys <- c(1:59, 61:366)
      } else{
        doys <- 1:yearLength
      }
      
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
        
        # Reorder columns
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
    
    
    # Check for date errors
    # ---------------------
    # Calendar type - Ensure that the calendar is one of the types that has been 
    #   considered in regards to handling leap years.
    calendarTypes <- c("noleap", 
                       "365_day", 
                       "proleptic_gregorian", 
                       "gregorian", 
                       "standard")
    
    if (!calendar %in% calendarTypes){
      warning(paste0("Calendar for the model '", 
                     modelName, 
                     "' is not one of the approved types. Reference year: ", 
                     year, 
                     ". Reference variable: ", 
                     variable, 
                     "."))
    }
    
    # Days in year - make sure the date column matches the number of days in the 
    #   year as specified by the netcdf documentation.
    if (yearLength != length(unique(yearRecord$date))){
      stop("The dates in the year ", 
           year, 
           " for model '", 
           modelName, 
           "' do not match the netcdf documentation.")
    } 

    
    # Pre-allocate full-record vector
    # -------------------------------
    # Create storage object for all years
    if(!exists("main")){
      main <- as.data.frame(matrix(nrow = nrow(yearRecord)*length(allYears), ncol = 5))
      
      names(main) <- c("cellid", "date", variables)
    }
    
  
    # Join years
    # ----------
    # Dump year record into storage object
    mainBeg <- (y-1)*nrow(yearRecord) + 1
    mainEnd <- nrow(yearRecord)*y
    
    main[mainBeg:mainEnd,] <- yearRecord  
  
    rm(yearRecord)
  }# End year loop

  # ===============
  # Unit conversion
  # ===============
  # Kelvin to Celsius
  main$tasmax <- main$tasmax - 273.15
  main$tasmin <- main$tasmin - 273.15
  
  
  # ===================
  # Export record table
  # ===================
  write.csv(main, 
            file = file.path(outputDirectory, paste0(modelName, ".csv")), 
            row.names = F)
  
E <- proc.time()[3]  

} # End model loop


