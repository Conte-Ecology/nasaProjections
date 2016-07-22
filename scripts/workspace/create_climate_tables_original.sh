#!/bin/bash
# imports climate projections from different model/emissions scenario combinations
# csv file must have columns [cellid, date, pr, tasmax, tasmin]

# usage: $ ./create_climate_tables.sh <db name> <path to climate directory> <list of model/scenario names>
# example: $ ./create_climate_tables.sh climate /home/kyle/climate/models /home/kyle/climate/models.txt


set -eu
set -o pipefail

# List variables
DB=$1
FOLDER=$2
MODEL_LIST=$3

# Index identifiers
IDX1="_cellid_fkey"
IDX2="_cellid_year_idx"

# Loop through tables to upload
while read MODEL;
do 
	# Define the file name
	FILENAME=$FOLDER/$MODEL.csv

	# Add 'data' schema if we move forward with this method
	
	# Create the table
	echo Creating table for $MODEL...
	psql -d $DB -c "CREATE TABLE \"$MODEL\" (cellid int, date date, pr real, tasmax real, tasmin real);"
	
	# Import the data from the CSV
	echo Importing climate timeseries for $MODEL...
	psql -v ON_ERROR_STOP=1 -1 -d $DB -c "\COPY public.\"$MODEL\" FROM '$FILENAME' DELIMITER ',' CSV HEADER NULL AS 'NA';" || { echo "Failed to import climate csv file"; exit 1; }

	# Create indexes on table
	echo Adding constraints and indexes for $MODEL table...
	
	# Constrain the table to unique cellid/date combination
	psql -d $DB -c "ALTER TABLE public.\"$MODEL\" ADD CONSTRAINT unique_cellid_date UNIQUE (cellid, date);"
		
	# Name indexes
	INDEX1=$MODEL$IDX1
	INDEX2=$MODEL$IDX2
	
	# Add indexes to table	
	psql -d $DB -c "CREATE INDEX \"$INDEX1\" ON public.\"$MODEL\"(cellid);"	
	psql -d $DB -c "CREATE INDEX \"$INDEX2\" ON public.\"$MODEL\"(cellid, date_part('year'::text, date));"
	
done < $MODEL_LIST
