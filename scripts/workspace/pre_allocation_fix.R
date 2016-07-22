head(main[which(is.na(main$pr)),])

max(which(is.na(main$pr)))


main[1079660:1079700,]

main[1082625:1082630,]


1082628 - 1079671

main[1079660:1079700,]




pos <- as.data.frame(matrix(nrow = 3, ncol = 3))


y <- 2

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



# Pre-allocate full-record vector
# -------------------------------
# Create storage object for all years
if(!exists("main2")){
  main2 <- as.data.frame(matrix(nrow = nrow(yearRecord)*length(allYears), ncol = 5))
  
  names(main2) <- c("cellid", "date", variables)
}


# Join years
# ----------
# Dump year record into storage object
if(!exists("mainBeg")){
  mainBeg <- 1
} else ( 
  mainBeg <- mainEnd + 1
)
mainEnd <- mainBeg + nrow(yearRecord)*y

  

main2[mainBeg:mainEnd,] <- yearRecord  

pos[y,1] <- mainBeg
pos[y,2] <- mainEnd
pos[y,3] <- nrow(yearRecord)

rm(yearRecord)
