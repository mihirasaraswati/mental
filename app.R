#Welcome to my little shiny app! @ Mihir Iyer
#

# data load & prep --------------------------------------------------------

library(shiny)
library(shinythemes)
library(dplyr)
library(metricsgraphics)

#load station number - name -visn crosswalk from data dictionary
sta <- xlsx::read.xlsx("~/Rprojects/MentalHealth/NepecPtsdDataDictionary.xlsx", sheetIndex=4, stringsAsFactors=FALSE)

# create a data.frame with the Item (measure) defintions
defs <- read.csv("~/Rprojects/MentalHealth/NepecPtsdDataDictionary-Edit_v2.0.csv", stringsAsFactors = FALSE)

#load le data
mental <- jsonlite::fromJSON("~/Rprojects/MentalHealth/NEPEC_AnnualDataSheet_MH_FY15.json")

# assign data types 
# mental$Category <- factor(mental$Category)
# mental$Item <- factor(mental$Item)
# mental$ValueType <- factor(mental$ValueType)

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

# create a new variable to store a formatted as character data type for display in the data table
TblVal <- character(nrow(mental))
#add TblVal to the mental data frame
mental <-data.frame(mental, TblVal, stringsAsFactors = FALSE)
#add commas to Number value type and remove any white spaces
mental$TblVal[which(mental$ValueType == "Number")] <- trimws(format(mental$Value[which(mental$ValueType == "Number")], big.mark = ",", drop0trailing = TRUE ), which="both")
#add % sign to Percent value type
mental$TblVal[which(mental$ValueType == "Percent")] <- paste(mental$Value[which(mental$ValueType == "Percent")], "%")
#remove TblVal vector
rm(TblVal)

### SHINY Bits ###

# UI application --------------------------------------------------------

ui <- shinyUI(fluidPage(theme = shinytheme("spacelab"),
                      fluidRow(titlePanel("VA National Mental Health Statistics - 2015"), 
                               style='padding:14px;'
                               ),
                      fluidRow(column(textOutput("descNEPEC"),
                                      br(),
                                      a("Please visit the NEPEC website to learn more.", href="http://www.ptsd.va.gov/PTSD/about/divisions/evaluation/index.asp", target="_blank"),
                                      width=6, 
                                      offset=0.5)
                               ), 
                      fluidRow(br(),
                               br(),
                        column(wellPanel(uiOutput("categoryBox")),
                               wellPanel(uiOutput("itemBox")),
                               conditionalPanel(
                                 condition = "input.item != 'Select a measure'",
                                 wellPanel(tags$label("Measure definition"),
                                           textOutput("defText")
                                           )
                                 ),
                               wellPanel(tags$label("Methodological notes"),
                                         textOutput("methNotes01"),
                                         br(),
                                         textOutput("methNotes02"),
                                         br(),
                                         textOutput("methNotes03"),
                                         br(),
                                         textOutput("methNotes04")
                                         ),
                               width=3),
                        column(
                          conditionalPanel(
                            condition = "input.item != 'Select a measure'",
                          h3("Distribution of VA Medical Centers"), 
                               metricsgraphicsOutput("histPlot")
                                ), 
                               width=6),
                        column(
                          conditionalPanel(
                            condition = "input.item != 'Select a measure'",
                          h3("VAMC-level Statistics"),
                               dataTableOutput("rankTable")
                               ), 
                          width=3
                        )
                      )

                      )
            )

# Define SERVER logic required to draw a histogram and display a datatable----------------------

server <- shinyServer(function(input, output){
  
  # NEPEC BACKGROUND TEXT - create an output variable to display some background info on the NEPEC
  output$descNEPEC <- renderText("VA's Northeast Program Evaluation Center (NEPEC) has broad responsibilities for evaluating mental health programs including PTSD clinical programs. In April 2016, NEPEC released mental health statistics for fiscal year 2015 - the annual datasheet. This dataset consists of VA Medical Center level statistics on the prevalence, mental health utilization, non-mental health utilization, mental health workload, and psychological testing of Veterans with a possible or confirmed diagnosis of mental illness.")
  
  # METHODOLOGICAL NOTES  - an output variable to display the methodological notes on the dataset
  output$methNotes01 <- renderText( "1. Compensation and pension exams and chart consults were included in all past reporting and the current Data Sheet, i.e. encounters in which one of the following stop codes are in the secondary position: 443- 448,450. Of the 95,557,325 total outpatient encounters in 2015, 1,101,782 (i.e. 1.2%) were such encounters.")
  
  output$methNotes02 <- renderText("2. Equivalent numbers for mental health encounters were respectively, 20,797,166 and 201,407 (i.e. 0.97% of all mental health encounters).")
  
  output$methNotes03 <- renderText("3. Among the 5,770,750 Veterans who are counted as using VHA services, 69,730 (i.e. 1.2%) did not have any contact with the VHA besides a compensation and pension exam or chart consult.")
  
  output$methNotes04 <- renderText("4. Of the 1,614,763 Veterans who had an mental health inpatient stay, residential stay, or outpatient encounter, 72,615 (4.5%) only had a mental health encounter which was compensation and pension exam or chart consult.")
  
  #CATEGORY PICKER - create drop-down box to allow picking a measure Category
  output$categoryBox <- renderUI(
    selectInput(inputId = "category", 
                label = "Step 1: Select a measure category", 
                selected = "Select a category",
                choices =c("Select a category", sort(unique(mental$Category)))
    )
  )
  
  #ITEM PICKER - create a drop-down to allow picking an Item, this box is dependent on the Category selection
  output$itemBox <- renderUI(
    selectInput(inputId = "item",
                label = "Step 2: Select a measure",
                selected = "Select a measure",
                choices= c("Select a measure", unique(mental$Item[which(mental$Category == input$category)]))
                )
      )

  #MEASURE DEFINITION - display the definition of the selected measure
  userdef <- reactive(defs$Definition[which(defs$Item == input$item)])
  #select definition of the measure for display
  output$defText <- renderText(userdef())
  

  #DATASET - create a reactive dataset based on the selected Item
  tbldata <- reactive({
    userdata <- filter(mental, Item==input$item)
    userdata <- arrange(userdata, desc(Value))
    return(userdata)
  })

  #HISTOGRAM PLOT - create a metricsgraphics hist plot
  output$histPlot <- renderMetricsgraphics({
    #conditional statement to display dataTABLE when a measure is selected
    if(is.null(input$item)){return()
    }else(mjs_plot(tbldata()$Value, format="count") %>% 
            mjs_histogram(bins = 10) %>%
            mjs_labs(x=input$item, y="Number of VAMCs")
    )
  })

  
  #RANKING TABLE - create a table that lists the facilities and their corresponding measure value
  plotdata <- reactive({
      mnky <- select(tbldata(), c(VISN, Station.Name, TblVal))
      colnames(mnky) <- c("VISN", "Medical Center", "Value")
      return(mnky)
  })

  output$rankTable <- renderDataTable({ 
    #conditional statement to display dataTABLE when a measure is selected
    if(is.null(input$item)){return()
    }else(plotdata())
    
  })
  
})

# Run the application 
shinyApp(ui = ui, server = server)