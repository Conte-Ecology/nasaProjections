library(ncdf4)



baseDirectory <- "F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP"

# Variables 
variables <- c("pr", "tasmax", "tasmin")


modelNames <- list.files(baseDirectory)



timeStats <- data.frame(matrix(ncol = 3, nrow = length(modelNames)))
names(timeStats) <- c("Model", "Calendar", "Units")


for (i in seq_along(modelNames)){
  
  modelFolder <- file.path(baseDirectory, modelNames[i])

  fileName <- file.path(modelFolder, list.files(modelFolder)[1])
    
  netcdf <- nc_open(fileName)
  
  timeStats$Model[i] <- modelNames[i]
  timeStats$Calendar[i] <- netcdf$dim$time$calendar
  timeStats$Units[i] <- netcdf$dim$time$units
  
  
  
  
  
  
  nc_close(netcdf)
}







variable <- "pr"
year <- 1960



# Checking leap year rules...
# ---------------------------
for (i in seq_along(modelNames)){
  
  modelFolder <- file.path(baseDirectory, modelNames[i])
  
  allFiles <- list.files(modelFolder)
  
  filePath <- file.path(modelFolder,
                        allFiles[intersect(grep(variable          , allFiles), 
                                           grep(as.character(year), allFiles))]
                        )
    
  netcdf <- nc_open(filePath)
  
  print(modelNames[i])
  print(netcdf$dim$time$calendar)
  #print(netcdf$dim$time$units)
  print(netcdf$dim$time$len)
  cat(sep = "\n\n")
  nc_close(netcdf)
}


# no_leap years
# -------------
model <- "bcc-csm1-1"


all <- c()

for (year in 1959:1961){

  modelFolder <- file.path(baseDirectory, model)

  allFiles <- list.files(modelFolder)

  filePath <- file.path(modelFolder,
                        allFiles[intersect(grep(variable          , allFiles), 
                                           grep(as.character(year), allFiles))]
                      )
  netcdf <- nc_open(filePath)


  values <- ncvar_get(nc    = netcdf,
                      varid = "time",
                      start = 1,
                      count = 365)
  nc_close(netcdf)
  
  all <- c(all, as.vector(unlist(values)))
}

max(all - (all-1))







# Calendar identifiers
# --------------------

# 1. proleptic_gregorian
# 2. noleap
# 3. 365_day
# 4. gregorian
# 5. standard



# noleap/365_day - Omit Feb 29th or Dec 31st?
# standard/gregorian/proleptic_gregorian - regular leap years. 

# New formula for calculating leap years:
# - The year is evenly divisible by 4;
# - If the year can be evenly divided by 100, it is NOT a leap year, unless;
# - The year is also evenly divisible by 400: Then it is a leap year



Assumptions:
noleap/365_day - ignore feb 29th



# standard and gregorian are the same
# no_leap and 365_day



http://cfconventions.org/Data/cf-conventions/cf-conventions-1.6/build/cf-conventions.html#calendar


4.4.1. Calendar

In order to calculate a new date and time given a base date, base time and a time increment one must know what calendar to use. For this purpose we recommend that the calendar be specified by the attribute calendar which is assigned to the time coordinate variable. The values currently defined for calendar are:
  
  gregorian or standard
Mixed Gregorian/Julian calendar as defined by Udunits. This is the default.

proleptic_gregorian
A Gregorian calendar extended to dates before 1582-10-15. That is, a year is a leap year if either (i) it is divisible by 4 but not by 100 or (ii) it is divisible by 400.

noleap or 365_day
Gregorian calendar without leap years, i.e., all years are 365 days long.

all_leap or 366_day
Gregorian calendar with every year being a leap year, i.e., all years are 366 days long.

360_day
All years are 360 days divided into 30 day months.

julian
Julian calendar.

none
No calendar.

The calendar attribute may be set to none in climate experiments that simulate a fixed time of year. The time of year is indicated by the date in the reference time of the units attribute. The time coordinate that might apply in a perpetual July experiment are given in the following example.








