-- Sample Query 
-- ============
-- This query selects full records for specified featureids. The user must 
--   define the "feature_list" table to determine which records get selected. 
--   This is a table with a single column of featureids named "featureid".

--  Generates a random "feature_list" of featureids to pull records for. Skip 
--    this step if "feature_list" has already been created.
SELECT featureid 
  INTO feature_list 
  FROM cross_grid 
  WHERE random() < 0.01 
  LIMIT 1000;  

-- Select all records from a single model into a new table called 
--   "select_records". The table name is specfied, with doublt quotes, in the 
--   FROM clause on the 3rd line.
WITH s AS (
  SELECT * 
  FROM "CCSM4"
  WHERE cellid IN (
    SELECT cellid 
	FROM cross_grid
	WHERE featureid IN (
	  SELECT featureid 
	  FROM feature_list
	)
  )
)
SELECT s.*, c.featureid INTO select_records
FROM s
LEFT JOIN (
  SELECT cellid, featureid  
  FROM cross_grid 
    WHERE featureid IN (
	  SELECT featureid 
	  FROM feature_list)
  ) c ON s.cellid = c.cellid;