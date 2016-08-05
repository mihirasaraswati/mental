library(dplyr)
library(metricsgraphics)

#load station number - name -visn crosswalk from data dictionary
sta <- xlsx::read.xlsx("NepecPtsdDataDictionary.xlsx", sheetIndex=4, stringsAsFactors=FALSE)

# create a data.frame with the Item (measure) defintions
defs <- read.csv("NepecPtsdDataDictionary-Edit.csv", stringsAsFactors = FALSE)

#load le data
mental <- jsonlite::fromJSON("NEPEC_AnnualDataSheet_MH_FY15.json")

#combine mental and sta
mental <- left_join(mental, sta, by="Station")
#remove sta data.frame
rm(sta)
#rearrange columns 
mental <- mental[, c(6,3,7,1,2,4,5)]

#remove % and , signs from values and then set to numeric data type (this is needed to sort and perform computations)
mental$Value <- gsub("%", "", mental$Value)
mental$Value <- gsub(",", "", mental$Value)
mental$Value <- as.numeric(mental$Value)

#create a color vector for histogram

mycolrs <- data.frame(Colors=c("#2c7bb6", "#fdae61", "#ffffbf", "#abd9e9", "#d7191c"),
                      Category = sort(unique(mental$Category)),
                      stringsAsFactors = FALSE)
items <-unique(mental$Item)

bardata <-  filter(mental, Item == items[1]) %>% 
  arrange(Value)

mjs_plot(data = bardata, x="Value", y="Station.Name") %>% 
  mjs_bar(binned = FALSE) %>% 
  mjs_axis_x(min_x =0, max_x=100) %>% 
  mjs_axis_y()