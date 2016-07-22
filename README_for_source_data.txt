# --
Data - NASA Earth Exchange Global Daily Downscaled Climate Projections
https://nex.nasa.gov/nex/projects/1356/

# --
The naming convention is as follows:

Example filename: 
DH_pr_dly_BCSD_historical_r1i1p1_ACCESS1-0.nc [ dimensions: 672(time) x 49(lats) x 72(lons) ]

DH         - added DH to indicate the region extracted for Dan Hocking; bounding box: [-84.4,-66.51,36.01,48.09]
pr         - variable name; will be 'pr' (precipitation), 'tasmax', 'tasmin', 'tas' (mean temperature that will be calculated from tasmax and tasmin).
fly        - daily (also can provide monthly means based on daily means)
BCSD       - method used by NEX to produce this data
historical - simulation for 1950-2005 (672 months), the future projections will be either ‘rcp85’ or ‘rcp45’ for the period 2006-2100.
r1i1p1     - realizations ID; it won't change in your case.
ACCESS1-0  - model name

# --
Script used to produce .nc files:
dataForDanHocking.py