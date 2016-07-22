#!/bin/bash
# Grants group roles with database-level permissions to users
# usage: ./grant_group_roles.sh <dbname>

DB=$1

psql -d $DB -c "GRANT nasa_admin TO kyle, jeff;
                GRANT nasa_read TO dan, rachel;"
