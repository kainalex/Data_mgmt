#libraries
library(readr)
library(plyr)
library(dplyr)
library(tidyr)
library(lubridate)
library(chron)
library(readxl)
library(rJava)
library(xlsx)

#there are three directories to change annually for this script to function
#1. multiprobe files 
#2. site data 
#3. exported product 

#1. multiprobe files location
setwd("c:/Users/kaina/Desktop/June Data Sonde")
rm(list=ls())

#build file from directory with column from names
file_names <- dir("c:/Users/kaina/Desktop/June Data Sonde")
multiprobe <- do.call(rbind, lapply(file_names, function(x) cbind(
read.csv(x, skip=12), Location=strsplit(x, '^[^_]*?[_][^_]*?(*SKIP)(*F)|_', perl=TRUE)[[1]][2])))
multiprobe$Location <- gsub(".csv", "", as.character(multiprobe$Location))
multiprobe$Location <- as.factor(multiprobe$Location)
  
#date and time format
multiprobe$Date.Time <- ymd_hms(multiprobe$Date.Time)
multiprobe$Date <- date(multiprobe$Date.Time) 
multiprobe$Date <- format(multiprobe$Date, "%m/%d/%y")
multiprobe$Date <- mdy(multiprobe$Date)
multiprobe$Time <- times(format(multiprobe$Date.Time, "%H:%M:%S")) 

#standardize column names
multiprobe =
multiprobe %>%
    rename("Depth (m)"=Depth..m...466714.) %>%
    rename("B.P. (mmHg)"=Barometric.Pressure..mm.Hg...524147.) %>%
    rename("T (oC)"=Temperature..Â.C...522109.) %>%
    rename("% D.O."=RDO.Saturation...Sat...519999.) %>%
    rename("D.O. (mg/l)"=RDO.Concentration..mg.L...519999.) %>%
    rename("Cond. (uS/cm)"=Specific.Conductivity..ÂµS.cm...522109.) %>%
    rename("pH"=pH..pH...475769.) %>%
    rename("ORP (mV)"=ORP..mV...475769.) %>%
    rename("TDS (mg/l)"=Total.Suspended.Solids..mg.L...520537.) %>% 
    rename("Turb. (NTU)"=Turbidity..NTU...520537.)

#add new columns
multiprobe$"ID #" <- seq.int(nrow(multiprobe))
multiprobe$COC <- NA
multiprobe$Lab <- NA
multiprobe$Year <- year(multiprobe$Date)
multiprobe$Month <- month(multiprobe$Date)
multiprobe$Round <- NA
multiprobe$"Pelagic / Shore" <- NA
multiprobe$"Location Name" <- NA
multiprobe$Reach <- NA
multiprobe$"Depth rounded (m)" <- round(multiprobe$`Depth (m)`)
multiprobe$"Delta Temp. (change oC/m)" <- NA
multiprobe$Stratification <- NA
multiprobe$"WVP (Torr)" <- NA
multiprobe$"Delta P" <- NA
multiprobe$"BO2 Coefficient" <- NA
multiprobe$"% N2 Sat" <- NA
multiprobe$"Tot % Sat" <- NA
multiprobe$"TDG (mmHg)" <- NA

#delete un-needed data
multiprobe <- select(multiprobe, -c(Date.Time, Pressure..mm.Hg...466714.,
                                    Battery.Capacity......524147.,
                                    External.Voltage..V...524147.,
                                    Oxygen.Partial.Pressure..Torr...519999.,
                                    pH.mV..mV...475769.,
                                    Actual.Conductivity..ÂµS.cm...522109.,
                                    Salinity..ppt...522109.,
                                    Total.Dissolved.Solids..ppt...522109.,
                                    Resistivity..Î.â..cm...522109.,
                                    Marked,
                                      #density has an exponent and breaks everything, might be able to escape?
                                      #so if column changes use to find:
                                      #which( colnames(multiprobe)=="Density..g.cmÂ³...522109.")
                                     21
                                      ))

#2. site data location and shape
site <- read_excel("C:/Users/kaina/Desktop/SiteMetadata.xlsx")
site$Date <- ymd(site$Date)
site$Location <- as.factor(site$Location)


#combine zoop tow depth
site$"Zoop Tow" <- paste(site$`Z Tow 1`, site$`Z Tow 2`, site$`Z Tow 3`, sep = ", ")

#shape
site=site %>% 
  rename("Secchi (m)"=Secchi)
site$"Surface Irradiance" <- NA
site$"Photic Zone depth (m)" <- NA

#select (there were problems parsing the string so this just uses column numbers)
site <- select(site, c(3, 4, 6, 7, 9, 10, 11, 17, 18, 19, 16))
                     
#join datasets together
#composite key code:
Limnology <- 
  multiprobe %>%
  left_join(site, by = c("Location"="Location", "Date"="Date"))

Limnology <- Limnology[c("ID #", "COC", "Lab", "Year", "Month", "Round", "Date", "Time", "Location",
                           "Pelagic / Shore", "Location Name", "Reach", "Depth rounded (m)", "Depth (m)", "B.P. (mmHg)",
                           "Delta Temp. (change oC/m)", "Stratification", "T (oC)", "% D.O.", "D.O. (mg/l)",
                           "Cond. (uS/cm)", "Turb. (NTU)", "TDG (mmHg)", "pH", "ORP (mV)", "TDS (mg/l)",
                           "WVP (Torr)", "Delta P", "BO2 Coefficient", "% N2 Sat", "Tot % Sat",
                         "Secchi (m)", "Sun", "Wind Speed", "Wind Direction", "Precipitation",
                         "Zoop Tow"
)]

Limnology$Date <- format(Limnology$Date, "%m/%d/%y")

#calculate sheet?
#you can add depth rounded=0 to remove the repeated data in the join

#flagged cells - figure out conditional highlighting on excel export?
duplicates_limno <- as.character(which(duplicated(Limnology[,c(13,9,7)])))
turbidity_exceedence <- row.names((Limnology[which(Limnology$`Turb. (NTU)`>10),]))

write.xlsx2(duplicates_limno, file="c:/Users/kaina/Desktop/limno_err.xlsx", sheetName = "duplicates", row.names=FALSE, col.names = FALSE)
write.xlsx2(turbidity_exceedence, file="c:/Users/kaina/Desktop/limno_turbidity.csv", row.names=FALSE, col.names = FALSE)

#3.excel file
write.xlsx2(x=Limnology, file="c:/Users/kaina/Desktop/Limnology_test.xlsx", row.names=FALSE, sheetName="raw")  
