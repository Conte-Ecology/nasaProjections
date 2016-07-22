# ===========
# Description
# ===========
# This script uses the catchments layer along with the previously generated 
#	climate grid layer to produce a table representing the spatial relationship 
#	between the two layers.


# ==============
# Specify inputs
# ==============
# Catchments layer
catchments = "C:/KPONEIL/HRD/V2/products/hydrography.gdb/Catchments"

# Grid points table
gridPointsTable = "C:/KPONEIL/climate/NASA_projections/spatial/gridCentroids.csv"

# Directory to export to 
outputDirectory = "C:/KPONEIL/climate/NASA_projections/spatial"


# ==================
# Create directories
# ==================
# Workspace geodatabase
workspace_db = outputDirectory + "/workspace.gdb"
if not arcpy.Exists(workspace_db): arcpy.CreateFileGDB_management (outputDirectory, "workspace", "CURRENT")


# ================
# Define functions
# ================
# Delete all fields except those specified
def deleteExtraFields(layer, fieldsToKeep):
	fields = arcpy.ListFields(layer) 
	dropFields = [x.name for x in fields if x.name not in fieldsToKeep]
	arcpy.DeleteField_management(layer, dropFields)


# ==================
# Spatial processing
# ==================

# Determine catchment centroids
# -----------------------------
centroids = arcpy.FeatureToPoint_management(catchments, 
											  workspace_db + "/centroids",
											  "INSIDE")	

# Create climate grid
# -------------------
# Create spatial layer from coordinates (currently assuming NAD83 geographic coordinate system)											  
arcpy.MakeXYEventLayer_management(gridPointsTable,
								  "lon",
								  "lat",
								  "gridPointsLyr",
								  "GEOGCS['GCS_North_American_1983',DATUM['D_North_American_1983',SPHEROID['GRS_1980',6378137.0,298.257222101]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]];-400 -400 1000000000;-100000 10000;-100000 10000;8.98315284119521E-09;0.001;0.001;IsHighPrecision")

gridPoints = arcpy.FeatureClassToFeatureClass_conversion("gridPointsLyr", 
														 workspace_db, 
														 "grid_points")

# Generate cell polygons					
gridCells = arcpy.CreateThiessenPolygons_analysis(gridPoints, 
												  workspace_db + "/grid", 
												  "ALL")

# Add a new unique ID field
arcpy.AddField_management(gridCells, 
						  "cellID", 
						  "LONG", 
						  9)
						  
arcpy.CalculateField_management(gridCells, 
								"cellID", 
								"!OBJECTID!", 
								"PYTHON_9.3")
												  
# Map catchments to climate grid
# ------------------------------
catchmentGrid = arcpy.SpatialJoin_analysis(centroids, 
										   gridCells, 
										   workspace_db + "/catchment_grid",
										   "JOIN_ONE_TO_ONE",
										   "KEEP_ALL",
										   "#",
										   "COMPLETELY_WITHIN")
										   
finalTable = arcpy.TableToTable_conversion(catchmentGrid, 
										   outputDirectory, 
										   "catchmentsGridTable.dbf")

										   
# Delete unnecessary fields
# -------------------------
deleteExtraFields(finalTable, 
				  ["OID", "FEATUREID", "lat", "lon", "cellID"])	
