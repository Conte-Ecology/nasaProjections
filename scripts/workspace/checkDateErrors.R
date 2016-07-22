rm(list = ls())

library(lubridate)


baseDirectory <- "C:/KPONEIL/climate/NASA_projections/clean"

allFiles <- list.files(baseDirectory)

options(warn = 1)

master <- list()

countNA <- as.data.frame(matrix(ncol = 1, nrow = length(allFiles)))

for ( i in seq_along(allFiles)){

  record <- read.csv(file.path(baseDirectory, allFiles[i]))

  a <- length(which(is.na(record$date)))
  
  print(a)
  countNA[i,1] <- a

  master[[i]] <- ymd(unique(record$date))
  names(master)[i] <- allFiles[i]
  
  rm(record)
  gc()
}
