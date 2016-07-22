#!/bin/bash
# imports the cross table linking climate records to catchment featureids
# csv file must have columns [featureid, lat, lon, cellid]

# usage: $ ./create_cross_grid_table.sh <db name> <path to csv file>
# example: $ ./create_cross_grid_table.sh nasa /home/kyle/nasa_climate/tables/catchmentsGridTable.csv


set -eu
set -o pipefail

DB=$1
FILENAME=$2

# Create table
echo Creating cross-grid table
psql -d $DB -c "CREATE TABLE public.cross_grid (featureid numeric, lon real, lat real, cellid int);"
	
# Import the data from the CSV
echo Importing cross-grid table...
psql -v ON_ERROR_STOP=1 -1 -d $DB -c "\COPY public.cross_grid FROM '$FILENAME' DELIMITER ',' CSV HEADER NULL AS 'NA';" || { echo "Failed to import climate csv file"; exit 1; }

# Clean up the table
# ------------------
echo Fixing column types, creating indexes, and granting permissions...

# Fix column type conflict
psql -d $DB -c "ALTER TABLE public.cross_grid ALTER COLUMN featureid TYPE BIGINT;"

# Constrain FEATUREIDs to unique values
psql -d $DB -c "ALTER TABLE public.cross_grid ADD CONSTRAINT unique_featureid UNIQUE (featureid);"

# Create indexes on table
psql -d $DB -c "CREATE INDEX cross_grid_featureid_fkey ON public.cross_grid(featureid);"		
psql -d $DB -c "CREATE INDEX cross_grid_featureid_cellid_idx ON public.cross_grid(featureid, cellid);"		

# Grant permissions on table
psql -d $DB -c "GRANT ALL PRIVILEGES ON public.cross_grid TO nasa_admin;
                GRANT SELECT ON public.cross_grid TO nasa_read;
                GRANT INSERT, UPDATE, DELETE, REFERENCES ON public.cross_grid TO nasa_write;"