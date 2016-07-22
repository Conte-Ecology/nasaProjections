NASA Climate Projections
========================

In Progress...


# Description
This repository houses the scripts used to process the climate projection data 
on a 25 sq km resolution. The daily time series data for 3 different climate 
variables (precipitation, minimum temperature, maximum temperature) are provided 
in the form of NetCDF files. A single file contains the daily data for one 
climate variable over one year for one model/emissions scenario combination. 
Each time series is associated with the lat/lon coordinates of the centroid of 
the spatial grid cell. The 1950 - 2005 time period represents the "historical" 
period of the climate model while the 2006 - 2100 time period represents the 
projected period. 

Climate NetCDF files are aggregated by model/scenario, creating a single CSV 
containing all climate variables over the entire time series. Users of this 
data should be aware of the distinction between "historical" and projected data 
described in the previous section. The CSV is then loaded into the PostgreSQL 
database as a new table. Each table has 5 columns: 
- cellid - The unique climate grid cell ID
- date - The date associated with climate record
- pr - Daily precipition (mm)
- tasmax - Maximum daily temperature (degrees C)
- tasmin - Minimum daily temperature (degrees C)

| cellid |   date	  |     pr   |  tasmax | tasmin  |
|:------:|:--------:|:--------:|:-------:|:-------:|
|  733   | 1/1/1950	| 0.327715 | 7.72772 | 3.26541 |
|  732   | 1/1/1950	| 0.268319 | 7.80816 | 3.23666 |
|  739   | 1/1/1950	| 0.234809 | 8.15731 | 3.26116 |
|  738   | 1/1/1950	| 0.202288 | 8.52435 | 3.10851 |
|  744   | 1/1/1950	| 0.171578 | 8.95794 | 3.20104 |

Table 1 - Climate table example

A separate spatial relationship table is created to match the catchment 
FEATUREIDs from the [NHDHRDV2](http://conte-ecology.github.io/shedsGisData/). 
Catchments are paired with the "cellid" of the grid cell that their centroid 
falls within. The "cross_grid" table has 4 columns: 
featureid - The unique catchment ID
cellid - The unique climate grid cell ID
lat - The latitude of the climate grid cell centroid
lon - The longitude of the climate grid cell centroid

| featureid |   lon   |   lat  | cellid |
|:---------:|:-------:|:------:|:-----: |
| 201407661 | -68.375	| 48.125 |	3428  |
| 201407662	| -68.375	| 48.125 |	3428  |
| 201407707	| -68.625	| 48.125 |	3430  |
| 201407728	| -68.375	| 47.875 |	3429  |
| 201407770	| -68.625	| 47.875 |	118   |

Table 2 - Cross grid table example

The cross_grid table may be used with the individual climate time series tables 
to query the records assigned to specific catchments.


# Data Source
The climate data originates from the 
[NASA Earth Exchange Global Daily Downscaled Climate Projections](https://nex.nasa.gov/nex/projects/1356/#) 
dataset. The raw projections have been downscaled and clipped to the NHDHRDV2 
study area by Ambarish Karmalkar at UMass Amherst (citation. department?). The 
subset of the orignal climate data serves as input to the 


# Create Climate Tables
The processing scripts are structured to handle a number of models with the 
same spatial coverage. The netcdf files for each model scenario are stored in 
a single directory. All model scenario folders are stored in the same parent 
directory. This storage format allows the script to loop through each model 
scenario separately and access all of its files. The output CSV is given the 
same name as the model scenario folder. This name will also be used for the 
table name if uploaded to a database.

The scripts in this section are stored in the `create_records` sub-directory.


## 1) Create spatial grid

### Description
The spatial grid associated with the climate models is extracted from a sample 
NetCDF file using the `extractGrid.R` script. This script exports the 
"gridCentroids.csv" file to be used in determining spatial relationships with 
the catchments. The spatial grid is consistent across all NetCDF files for all 
model/scenario combinations. For this reason, it is only necessary to use a 
single NetCDF file to define the universally applied climate grid cells.

### Steps to execute
To run, open the `extractGrid.R` script and set the following variables in the 
"Specify inputs" section: 

- netcdfPath - the file path to the sample NetCDF file defining the climate grid
- outputDirectory - the directory where the spatial grid table will be written

The entire script is then executed in R.

### Output 
The output table is named `gridCentroids.csv` and has two columns for "lat"" and 
"lon" coordinates. Unique IDs are assigned later.


## 2) Establish spatial relationships

### Description
A table relating the catchments to climate grid is developed. The spatial grid 
created in step one is used along with the catchments spatial layer to generate 
the output table. The relationships are determined by where in the climate grid 
the catchment centroids fall. In this process, a unique "cellID" is assigned to 
each of the climate grid cells. Each unique catchment "FEATUREID" is assigned a 
climate grid "cellID".

### Steps to execute
To run, open the `spatialReleationships.py` script and set the following variables 
in the "Specify inputs" section. 

- catchments - the spatial catchments layer (shapefile or geodatabase feature)
- gridPointsTable - the spatial grid table created in the previous step
- outputDirectory - the directory where the relationship table will be written

The entire script is then executed in Arc Python. 

### Output
The `catchmentsGridTable.dbf` is ouput to the specified "outputDirectory". This table 
has columns for the unique IDs for the catchments ("FEATUREID") and grid cells ("cellID") 
along with the "lat" and "lon" of the grid cell centroid. 


## 3) Convert Table Format

### Description
When directly outputting a CSV from ArcGIS, column formatting is problematic 
due to the presence of commas in large integers. This short script is intended 
to reformat the table from DBF to CSV for upload to the database.

### Steps to execute
To run, open the `spatialGridFormat.R` script and set the following variables 
in the "Specify inputs" section.

- baseDirectory - the directory containing the `catchmentsGridTable.dbf` output 
by the previous script

The entire script is then executed in R. 

### Output
The `catchmentsGridTable.csv` is ouput to the same directory as the DBF version 
of the same table. The columns are the same as the DBF table.


## 4) Aggregate Records

### Description
Each model/emissions scenario has around 450 raw NetCDF files for the historic 
and prediction periods. There is one file per year for each of 3 climate 
variables. This script loops through each of these files aggregating the 
records into one table for output. The table format is a daily time series of 
each of the 3 climate variables for each grid cell as shown in Table 1. The 
records are only kept in the aggregation if the climate grid cell overlaps with 
a part of the catchments layer polygon. The script is designed to loop through 
and aggregate climate records for all of the model scenario folders in the 
parent directory.

### Steps to execute
To run, open the `aggregateRecords.R` script and set the following variables 
in the "Specify inputs" section.

- sourceDirectory - The file path to the parent directory containing all of the 
model scenario folders. 
- variables - A list of the climate variables to process.  
- gridTable - The file path to the DBF table, created in step 2, identifying 
which climate grid cell each catchment is falls into. 
- outputDirectory - The directory where the CSV files of aggregated climate 
records for each model will be written.

The entire script is then executed in R. 

### Output
One CSV file for each model scenario ID (taken from the folder names) will be 
created. Table 1 describes the format of each of the files. 


# Create Climate Projections Database
The tables created in the previous section are uploaded to the `nasa` database 
located on osensei. The database is structured such that for each climate 
model/scenario there is one table in the "data" schema with an identical name. 
The time series in each of these tables are associated with a grid cell defined 
by the "cellid" column. The cellids are matched to the catchment featureids in 
the `cross_grid` table in the "public" schema. A sample query is made available 
for reference as ________________.

The scripts in this section are stored in the `create_database` sub-directory.
<br><br>

## 1) Create Database

### Description
The `nasa` database is created and the "data" schema is added to the database.

### Steps to execute
Execute the `create_database.sh` script in the bash. It does not take any 
arguments.

### Output
The empty `nasa` database is created.
<br><br>

## 2) Create Group Roles

### Description
Roles are created for granting permissions in the database. These roles are 
modeled after those in the `sheds` database on felek.

### Steps to execute
Execute the `create_all_roles.sh` script in the bash with the only input being 
the name of the database. The shell script calls the individual SQL scripts in 
the same directory to setup the roles.

### Output
The "nasa_admin", "nasa_read", and "nasa_write" roles are created for the 
database.


## 3) Grant Roles to Users

### Description
The group roles are granted to individual users of the database.

### Steps to execute
Execute the `grant_group_roles.sh` script in the bash with the only input being 
the name of the database. The users granted permissions can be changed in the 
script.

### Output
Specified users are assigned to the group roles.


## 4) Upload Climate Tables

### Description
The CSV files created in the previous section are uploaded as individual 
tables. The script references the directory containing the CSV files rather 
than the individual files themselves. This step makes it important to have 
a folder containing all climate record CSV files with no other files in it. 

### Steps to execute
Execute the `create_climate_tables.sh` in the shell. The script takes the 
database name as the first argument and the path to the directory containing 
all of the climate record CSV files as the second argument. 

### Output
One table for each of the CSV files is created. The table names are the same 
as the the CSV file name. Since some of the names contain a hyphen, the tables 
will need to be referred to with double quotation marks in queries 
(e.g. `SELECT * FROM "ACCESS1-0";`)


## 5) Create Cross Grid Table

# Description
The cross grid table is created to pair the climate time series with catchment 
featureids based on their spatial location in relation to the climate grid. The 
`catchmentsGridTable.csv` table created in the pervious section is uploaded.

### Steps to execute
Execute the `create_cross_grid_table.sh` in the shell. The script takes the 
database name and the filepath to the cross grid CSV file as inputs. 

### Output
The `cross_grid` table is created in the "public" schema. 

## 6) Query examples

### Description
Some example queries are written in SQL to test the time to return records and 
provide users with a script to work with for pulling records.

### Steps to execute

### Output


# Assumptions & Notes

- The spatial grid related to the climate date is identical across all 
variable/year combinations for all model/scenario combinations.

- In models that do not account for leap years, February 29th is the date 
ommited. This is accomplished by identifying the number of days in known 
leap years and then altering the calendar if it is a day short.

- Some models only go up to 2099.


# Contact Info
Kyle O'Neil  
koneil@usgs.gov  

