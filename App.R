library(shiny)
library(ggmap)
library(leaflet)
library(C3)
library(dplyr)
library(shinydashboard)
library(data.table)
library(DT)
r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

business_csv <- 'data/business_parsed.csv'
result <- fread(business_csv, header = TRUE)
categories_list = unique(unlist(strsplit(result$category, split = ":"), recursive = FALSE))
result[Grade == 1, Sanitation := 'Excellent']
result[Grade == 2, Sanitation := 'Good']
result[Grade == 3, Sanitation := 'Okay']
result[Grade == 4, Sanitation := 'Needs to Improve']
result = result[,c('business_id','name','address','city','state','postal_code','rating','review_count','price','Sanitation','location','longitude','latitude', 'category')]
setnames(result, c('name','address','city','state','postal_code','rating','review_count','price','Sanitation','location','category'), 
         c('Name','Address','City','State','Zipcode','Rating','# of Reviews', 'Price','Food Safety Rating', 'Neighborhood','Cuisine'))
getSeries <- function( n = 100, drift = 0.1, walk = 4, scale = 100){
  y <- scale * cumsum(rnorm(n= n, mean = drift, sd=sqrt(walk)))
  return(y + abs(min(y)))
}
drilldown <- fluidRow(
  column(width = 3, C3BarChartOutput('barchart', height = 250)),
  column(width = 3, C3BarChartOutput('sanitation', height = 250))
)
body <- dashboardBody(
  fluidRow(
    column(width = 9,
           box(width = NULL, solidHeader = TRUE, leafletOutput("mymap"))
           
    ),
    column(width = 3,
           selectInput('location', label = 'Location', choices = unique(result$Neighborhood), multiple=TRUE, selected = 'Pioneer Square'),
           selectInput('category', label = 'Cuisine', choices = categories_list, multiple = TRUE, selected='Asian Fusion'),
           selectInput('sanitation', label = 'Sanitation', choices = unique(result$`Food Safety Rating`), multiple=TRUE, selectize=TRUE, selected = 'Good'),
           selectInput('price', label = 'Price', choices = unique(result$Price),multiple=TRUE, selectize=TRUE, selected = c('','$','$$','$$$','$$$$')),
           sliderInput("review", label = "Rating", min = 0, max = 5, value = c(4, 5)),
           sliderInput("review_count", label = "Minimum # of Ratings", min = 0, max = 1000, value = 100)
    )
  ),
  fluidRow(
    tabBox(width = 12,
      title = "Details",
      # The id lets us use input$tabset1 on the server to find the current tab
      id = "tabset1", height = "250px",
      tabPanel("Data Table", DT::dataTableOutput('table')),
      tabPanel("Drill Down", drilldown )
    )
  )
)

ui <- dashboardPage(
  dashboardHeader(title = "Foodie Call"),
  dashboardSidebar(disable = TRUE),
  body
)


server <- function(input, output, session){
  reactiveresult <- reactive({
    result[Neighborhood %in% input$location &
             `Food Safety Rating` %in% input$sanitation &
             Price %in% input$price &
             grepl(paste(input$category, collapse="|"), Cuisine) &
             Rating >= input$review[1] &
             Rating <= input$review[2] &
             `# of Reviews` > input$review_count,!"business_id"]
  })
  output$mymap <- renderLeaflet({
    newdata = reactiveresult()
    points <- cbind(newdata$longitude, newdata$latitude)
    leaflet() %>%
      addProviderTiles(providers$Stamen.TonerLite,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addMarkers(data = points)
  })
  
  output$barchart <-renderC3BarChart({
    newdata = reactiveresult()
    cat(file=stderr(), "drawing histogram with",length(newdata$Rating), "bins", "\n")
    dataset <- count(newdata, Rating, name='count')
    cat(file=stderr(), "drawing histogram with",length(dataset), "bins", "\n")
    C3BarChart(dataset, 'Rating')
  })
  
  output$sanitation <-renderC3BarChart({
    newdata = reactiveresult()
    cat(file=stderr(), "drawing histogram with",length(newdata$Rating), "bins", "\n")
    dataset <- count(newdata, `Food Safety Rating`, name='count')
    setnames(dataset, c('Rating','count'))
    cat(file=stderr(), "drawing histogram with",length(dataset), "bins", "\n")
    C3BarChart(dataset, 'Rating')
  })

  # output$table = DT::renderDataTable(result[Neighborhood %in% input$location &
  #                                             `Food Safety Rating` %in% input$sanitation &
  #                                             Price %in% input$price &
  #                                             grepl(paste(input$category, collapse="|"), Cuisine) &
  #                                             Rating >= input$review[1] &
  #                                             Rating <= input$review[2] &
  #                                             `# of Reviews` > input$review_count,!c('business_id','latitude','longitude')], server = TRUE)
  output$table = DT::renderDataTable(reactiveresult(), server = TRUE)
  # 
  # observeEvent(input$location,{
  #   if (is.null(input$location))
  #     return()
  #   isolate({
  #     selectedCity <- geocode(c(input$location))      
  #     map <- leafletProxy("mymap") %>% clearMarkers() %>% addMarkers(data = points) %>%
  #       setView(selectedCity$lon, selectedCity$lat, zoom = 15)
  #   })
  # })
  
  observeEvent(input$pie1,{
    
    isolate({
      selectedCity <- geocode(c(input$location))      
      ranking4 = result[result$Rating > 4, ]
      points4ranking <- cbind(ranking4$longitude, ranking4$latitude)
      leafletProxy("mymap") %>% clearMarkers() %>% addCircleMarkers(data=points4ranking) %>%
        setView(selectedCity$lon, selectedCity$lat, zoom = 15)
    })
  })
}


ui_2 <- fluidPage(
  titlePanel("Foodie call"),
  sidebarLayout(
    position = "right",
    sidebarPanel(
      fluidRow(selectInput('location', 'Location', choices = unique(result$city), selected = 'Seattle')),
      
      # example use of the automatically generated output function
      #C3GaugeOutput("gauge1")
      fluidRow(C3PieOutput('pie1',height = 250)), 
      fluidRow(C3LineBarChartOutput('linebarchart', height = 250)), 
      fluidRow(C3BarChartOutput('barchart', height = 250)) 
    ),
    mainPanel(
      leafletOutput("mymap")
    )
  )
)
shinyApp(ui = ui, server = server)