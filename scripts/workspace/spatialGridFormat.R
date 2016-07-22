# ===========
# Description
# ===========
# This script is intended to circumvent the column format issue of exporting 
#   CSV files from ArcGIS. A DBF file is converted to CSV for upload to the 
#   database.


# ==============
# Load libraries
# ==============
rm(list = ls())

library(foreign)


# ==============
# Specify inputs
# ==============
# The directory containing the "catchmentsGridTable.dbf" file 
baseDirectory <- "C:/KPONEIL/climate/NASA_projections/spatial"


# ==============
# Convert format
# ==============
gridTable <- read.dbf(file.path(baseDirectory, "catchmentsGridTable.dbf"))

write.csv(gridTable, 
          file = file.path(baseDirectory, "catchmentsGridTable.csv"), 
          row.names = F)
