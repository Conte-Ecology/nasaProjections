# ===========
# Description
# ===========
# This script reads the spatial variables from a sample netCDF file in the NASA 
#   climate projections dataset and exports a CSV of the lat/lon coordinates 
#   associated with the grid cell centroids. This script is specific to this 
#   netCDF format and is not universally applicable to the file type.


# ==============
# Load libraries
# ==============
# Clear workspace
rm(list = ls())

library(ncdf4)


# ==============
# Specify inputs
# ==============

# Path to sample netCDF file
netcdfPath <- "F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP/ACCESS1-0/NE_pr_day_BCSD_historical_r1i1p1_ACCESS1-0_1950.nc"

# Driectory where the CSV file will be exported
outputDirectory <- "C:/KPONEIL/climate/NASA_projections/spatial"


# ====================
# Process spatial grid
# ====================

ncdf <- nc_open(file.path(netcdfPath))

lon <- ncvar_get(nc    = ncdf,
                 varid = "lon",
                 start = 1,
                 count = ncdf$var$lon$varsize[2])

lat <- ncvar_get(nc    = ncdf,
                 varid = "lat",
                 start = 1,
                 count = ncdf$var$lat$varsize[2])


points <- expand.grid(lon, 
                      lat, 
                      KEEP.OUT.ATTRS = FALSE)

names(points) <- c("lon", "lat")


# =================
# Export grid table
# =================
write.csv(points, 
          file = file.path(outputDirectory, "gridCentroids.csv"), 
          row.names = F)