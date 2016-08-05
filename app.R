#Welcome to my little shiny app! @ Mihir Iyer
#oye!

# Data Load & Prep --------------------------------------------------------

library(shiny)
library(shinythemes)
library(dplyr)
library(metricsgraphics)

#read data (rds files are prepared by the Code_Data_Prep.R script see github repo for deets)
mental <- readRDS("Data_Mental_Post.rds")
defs <- readRDS("Data_MeasureDefs.rds")

#create a color vector for histogram
mycolrs <- data.frame(Colors=c("#2c7bb6", "#fdae61", "#ffffbf", "#abd9e9", "#d7191c"),
                      Category = sort(unique(mental$Category)),
                      stringsAsFactors = FALSE)

### SHINY Bits ###

# UI application --------------------------------------------------------

ui <- shinyUI(fluidPage(theme = shinytheme("cosmo"),
                        tags$head(
                          tags$style(HTML(".mg-histogram .mg-bar rect {
                                          fill: #006d2c;
                                          shape-rendering: auto;
                                          }
                                          
                                          .mg-histogram .mg-bar rect.active {
                                          fill: #31a354;
                                          }"
                                          )
                          )
                          ),
                        fluidRow(titlePanel("VA National Mental Health Statistics Explorer"), 
                                 style='padding:14px;'
                        ),
                        fluidRow(column(includeMarkdown("NEPEC_Description.md"),
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
                                                  includeMarkdown("Meth_Notes.md")
                                        ),
                                        width=3),
                                 column(
                                   conditionalPanel(
                                     condition = "input.item != 'Select a measure'",
                                     h3("Distribution of Medical Centers"), 
                                     em(h4(textOutput("histTitle"))),
                                     metricsgraphicsOutput("histPlot"),
                                     br(),
                                     tags$label("How to interpret:"),
                                     includeMarkdown("Interpret.md")
                                   ),
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
shinyApp(ui = ui, server = server )