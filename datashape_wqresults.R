#libraries
library(plyr)
#detach("package:dplyr", unload=TRUE)
library(dplyr)
library(tidyr)
library(lubridate)
library(chron)
library(readxl)
library(rJava)
library(xlsx)
library(purrr)
library(tidyr)
library(stringr)

#NOTE: Vectors must be one data type. Because of '<' in results, xlsx exports will contain numbers
#as text. To fix, highlight all cells and use the error popup to convert to numbers.

#files location
setwd("c:/Users/kaina/Desktop/WQ")
rm(list=ls())

#build file 
file_list <- dir("c:/Users/kaina/Desktop/WQ")
WQ <- ldply(file_list, read_excel, sheet=1, skip=0)

#reshape data
WQ<-
WQ %>%
  select(ANALYTE, Result, SAMPLENAME, SAMPDATE) %>%
  spread(ANALYTE, Result)

#date and time
WQ$SAMPDATE <- mdy_hms(WQ$SAMPDATE)
WQ$SAMPDATE <- date(WQ$SAMPDATE)
WQ$SAMPDATE <- format(WQ$SAMPDATE, "%m/%d/%y")
#WQ$SAMPDATE <- mdy(WQ$SAMPDATE)

#new columns
WQ$Depth <- NA

#use dplyr::rename if plyr loaded first
WQ <- WQ %>%
  rename("Location" = SAMPLENAME) %>%
  rename("Date"=SAMPDATE) %>%
  rename("Ammonia (mg/L)"="Ammonia as N") %>%
  rename("Chlorophyll  a (ug/L)"="Chlorophyll-a") %>%
  rename("Turb (NTU)"=Turbidity) %>%
  rename("TSS (mg/L)"="Total Suspended Solids") %>%
  rename("Nitrate (mg/L)"="Nitrate as N") %>%
  rename("Nitrite (mg/L)"="Nitrite as N") %>%
  rename("Total Nitrogen (mg/L)"="Total Nitrogen") %>%
  rename("Ortho- phosphorus (mg/L)"="Ortho-phosphate as P") %>%
  rename("Phosphorus (mg/L)"="Phosphorus") %>%
  rename("Alkalinity (mg/L)"="Total Alkalinity")

WQ <- WQ %>%
  select("Date", "Location", "Depth", "Chlorophyll  a (ug/L)", "Turb (NTU)", "TSS (mg/L)",
    "Nitrate (mg/L)", "Nitrite (mg/L)", "Ammonia (mg/L)", "Total Nitrogen (mg/L)",
    "Ortho- phosphorus (mg/L)", "Phosphorus (mg/L)", "Alkalinity (mg/L)")%>%
  arrange(Date)

write.xlsx2(x=WQ, file="c:/Users/kaina/Desktop/WQ_test.xlsx", row.names=FALSE, sheetName="raw")  
