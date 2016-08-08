# This script prepares the data for the shiny app. There two datasets one with the mental statistics and the other the definitions of the mental health measures. The files are saved as *.rds as they are more efficient than Excel. Enjoy!

library(dplyr)

#load station number - name -visn crosswalk from data dictionary
sta <- xlsx::read.xlsx("NepecPtsdDataDictionary.xlsx", sheetIndex=4, stringsAsFactors=FALSE)

# create a data.frame with the Item (measure) defintions
defs <- read.csv("NepecPtsdDataDictionary-Edit.csv", stringsAsFactors = FALSE)


#read the data from catalog.data.gov 
# mental <- jsonlite::fromJSON("https://raw.githubusercontent.com/vacobrydsk/VHA-Files/master/NEPEC_AnnualDataSheet_MH_FY15.json")

#load le data locally (less resource intensive)
mental <- jsonlite::fromJSON("NEPEC_AnnualDataSheet_MH_FY15.json")

#combine mental and sta
mental <- left_join(mental, sta, by="Station")

#rearrange columns 
mental <- mental[, c(6,3,7,1,2,4,5)]

#remove % and , signs from values and then set to numeric data type (this is needed to sort and perform computations)
mental$Value <- gsub("%", "", mental$Value)
mental$Value <- gsub(",", "", mental$Value)
mental$Value <- as.numeric(mental$Value)


#SAVE data
saveRDS(mental, "Data_Mental_Post.rds")
saveRDS(defs, "Data_MeasureDefs.rds")

#Cleanup workspace
# rm(mental, defs, sta)
