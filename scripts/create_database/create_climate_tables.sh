#!/bin/bash
# Reads all files in climate table directory and imports projection records 
#	from each file into a new table named for that model/emissions (i.e. the 
#	name of the file).
# All CSV files must have columns [cellid, date, pr, tasmax, tasmin]
# No other files should exist in the climate table directory.

# usage: $ ./create_climate_tables.sh <db name> <path to climate tables directory>
# example: $ ./create_climate_tables.sh nasa /home/kyle/nasa_climate/model_records

set -eu
set -o pipefail

# List variables
DB=$1
DIRECTORY=$2

# Index + constraint identifiers
IDX1="_cellid_fkey"
IDX2="_cellid_year_idx"
UNI1="_unique_cellid_date"

# Loop through tables and upload to database
for FILEPATH in $DIRECTORY/*; 
do
	# Define the file name and model name
	FILENAME=${FILEPATH##*/}
	MODEL="${FILENAME%.*}"
	
	# Create the table
	echo Creating table for $MODEL...
	psql -d $DB -c "CREATE TABLE data.\"$MODEL\" (cellid int, date date, pr real, tasmax real, tasmin real);"
	
	# Import the data from the CSV
	echo Importing climate timeseries for $MODEL...
	psql -v ON_ERROR_STOP=1 -1 -d $DB -c "\COPY data.\"$MODEL\" FROM '$FILEPATH' DELIMITER ',' CSV HEADER NULL AS 'NA';" || { echo "Failed to import climate csv file"; exit 1; }

	# Create indexes on table
	echo Adding constraints, indexes, and permissions for $MODEL table...
	
	# Name indexes + constraints
	INDEX1=$MODEL$IDX1
	INDEX2=$MODEL$IDX2
	CONSTRAINT1=$MODEL$UNI1

	# Constrain the table to unique cellid/date combination
	psql -d $DB -c "ALTER TABLE data.\"$MODEL\" ADD CONSTRAINT \"$CONSTRAINT1\" UNIQUE (cellid, date);"

	# Add indexes to table	
	psql -d $DB -c "CREATE INDEX \"$INDEX1\" ON data.\"$MODEL\"(cellid);"	
	psql -d $DB -c "CREATE INDEX \"$INDEX2\" ON data.\"$MODEL\"(cellid, date_part('year'::text, date));"

	# Grant permissions on table
	psql -d $DB -c "GRANT ALL PRIVILEGES ON data.\"$MODEL\" TO nasa_admin;
                	GRANT SELECT ON data.\"$MODEL\" TO nasa_read;
                	GRANT INSERT, UPDATE, DELETE, REFERENCES ON data.\"$MODEL\" TO nasa_write;"
	
done
