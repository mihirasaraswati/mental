#Welcome to my little shiny app! @ Mihir Iyer
#oye!

# data load & prep --------------------------------------------------------

library(shiny)
library(shinythemes)
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

### SHINY Bits ###

# UI application --------------------------------------------------------

ui <- shinyUI(fluidPage(theme = shinytheme("spacelab"),
                        tags$head(
                          tags$style(HTML("
      .mg-histogram .mg-bar rect {
          fill: #ff00ff;
          shape-rendering: auto;
      }

      .mg-histogram .mg-bar rect.active {
          fill: #00f0f0;
      }"))),
                        fluidRow(titlePanel("VA National Mental Health Statistics Explorer"), 
                                 style='padding:14px;'
                        ),
                        fluidRow(column("In April 2016, VA's Northeast Program Evaluation Center (NEPEC) released mental health statistics for fiscal year 2015 - the annual datasheet. This dataset consists of VA Medical Center level statistics on the prevalence, mental health utilization, non-mental health utilization, mental health workload, and psychological testing of Veterans with a possible or confirmed diagnosis of mental illness. This application is designed to help explore these mental health measures. To get started pick a measure category and then a measure to see the distribution and ranking of medical centers.",
                                        br(),
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
                                     h3("Distribution of Medical Centers"), 
                                     em(h4(textOutput("histTitle"))),
                                     metricsgraphicsOutput("histPlot")),
                                   width=5),
                                 column(
                                   conditionalPanel(
                                     condition = "input.item != 'Select a measure'",
                                     h3("Medical Center Results"),
                                     em(h4(textOutput("tblTitle"))),
                                     dataTableOutput("rankTable")
                                   ), 
                                   width=4
                                 )
                        )
                        
)
)

# SERVER logic ---------------------

server <- shinyServer(function(input, output){
  
  
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
  
  #PLOT SUBTITLE - create custom plot subtitle to indicate whether the measure is reported as a number or pecentage
  subTitleText <- reactive({
    unique(mental$ValueType[which(mental$Item == input$item)])
  })
  #for the table
  output$tblTitle <- renderText(
    paste("(Reported as a ", subTitleText(), ")", sep="")
  )
  #for the histogram
  output$histTitle <- renderText(
    paste("(Reported as a ", subTitleText(), ")", sep="")
  )
  
  #DATASET - create a reactive dataset based on the selected Item
  zedata <- reactive({
    userdata <- filter(mental, Item==input$item)
    userdata <- select(userdata, c(VISN, Station.Name, Value))
    colnames(userdata) <- c("VISN", "Medical Center", "Value")
    return(userdata)
  })
  
  #HISTOGRAM COLOR - select the color based on the category selected 
  
  mycolr <- renderText({
    filter(mycolrs, Category == test) %>% 
      select(Colors)
  })
  
  
  #HISTOGRAM PLOT - create a metricsgraphics hist plot
  output$histPlot <- renderMetricsgraphics({
    #conditional statement to display dataTABLE when a measure is selected
    if(is.null(input$item)){return()
    }else(mjs_plot(zedata()$Value, format="count") %>% 
            mjs_histogram(bins = 10) %>%
            mjs_labs(x=input$item, y="Number of VA Medical Centers")
    )
  })
  
  
  #RANKING TABLE - create a table that lists the facilities and their corresponding measure value
  
  output$rankTable <- renderDataTable({
    #conditional statement to display dataTABLE when a measure is selected
    if(is.null(input$item)){return()
    }else(zedata()) 
  }, options=list(order=list(2, 'desc'), 
                  pageLength = 25))
})

# Run the application 
shinyApp(ui = ui, server = server)