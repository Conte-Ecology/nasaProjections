library(ncdf4)


nc1 <- nc_open("F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP/bcc-csm1-1/NE_pr_day_BCSD_historical_r1i1p1_bcc-csm1-1_2032.nc")


nc1 <- nc_open("F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP/bcc-csm1-1/NE_tasmax_day_BCSD_rcp85_r1i1p1_bcc-csm1-1_2032.nc")
nc2 <- nc_open("F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP/bcc-csm1-1/NE_tasmax_day_BCSD_rcp85_r1i1p1_bcc-csm1-1_2036.nc")

nc3 <- nc_open("F:/KPONEIL/SourceData/climate/nasa/NEX-GDDP/CNRM-CM5/NE_tasmax_day_BCSD_rcp85_r1i1p1_CNRM-CM5_2036.nc")

nc1$dim$time$calendar
nc2$dim$time$calendar
nc3$dim$time$calendar

nc1$dim$time$len
nc2$dim$time$len
nc3$dim$time$len

yearLength <- nc1$dim$time$len


nc_close(nc1)
nc_close(nc2)
