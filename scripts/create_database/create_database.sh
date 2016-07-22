#!/bin/bash
# Creates the database for the NASA climate projection data
# usage: ./create_database.sh

# Create database
createdb nasa

# Add data schema to database
psql -d nasa -c "CREATE SCHEMA data;"
				
               # ALTER DATABASE nasa SET search_path TO public,data;"