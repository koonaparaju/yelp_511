library(shiny)
library(ggmap)
library(leaflet)
library(C3)
library(dplyr)
library(shinydashboard)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

business_csv <- 'data/business_parsed.csv'
result <- read.csv(business_csv, header = TRUE, sep = ',')

getSeries <- function( n = 100, drift = 0.1, walk = 4, scale = 100){
  y <- scale * cumsum(rnorm(n= n, mean = drift, sd=sqrt(walk)))
  return(y + abs(min(y)))
}

body <- dashboardBody(
  fluidRow(
    column(width = 9,
           box(width = NULL, solidHeader = TRUE, leafletOutput("mymap")),
           tabBox(
             title = "Details",
             # The id lets us use input$tabset1 on the server to find the current tab
             id = "tabset1", height = "250px",
             tabPanel("Map", "Key Variables"),
             tabPanel("Data Table", "")
           )
           ),
    column(width = 3,
           box(width = NULL),
           selectInput('location', 'Location', choices = unique(result$location), selected = 'Pioneer Square'),
           
           C3PieOutput('pie1',height = 250),
           C3BarChartOutput('barchart', height = 250)
           )
  )
)

ui <- dashboardPage(
  dashboardHeader(title = "Foodie Call"),
  dashboardSidebar(disable = TRUE),
  body
)


server <- function(input, output, session){
  #output$distplot <- renderPlot({
  #  location = input$location
  #  get_stamenmap(us, zoom = 5, maptype = "toner-lite") %>% ggmap() 
  #})
  # data for C3LineBarChart & stackedAreaChart
  Data <- reactive({
    
    invalidateLater(3000)
    
    n         <- 100
    Start    <- as.Date("2016-01-01")
    Time     <- Start + 1:n
    Counts   <- data.frame(
      GREEN = getSeries(n = n, drift = 0.05, walk = 10, scale = 100),
      AMBER = getSeries(n = n, drift = 0.2, walk = 4, scale = 40),
      RED   = getSeries(n = n, drift = 0.1, walk = 4, scale = 20)
    )
    
    Total  <- apply(Counts,1,sum)
    Perc   <- Counts / Total
    
    list(Counts = Counts, Perc = Perc, Total = Total, Time = Time)
  })
  
  # points <- eventReactive(input$recalc, {
  #   cbind(result$longitude, result$latitude)
  # }, ignoreNULL = FALSE)
  points <- cbind(result$longitude, result$latitude)
  
  output$mymap <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Stamen.TonerLite,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addMarkers(data = points)
  })
  output$pie1 <- renderC3Pie({ 
    #invalidateLater(3000, session)
    value <- data.frame(a=runif(1,0,10),b=runif(1,0,10),c=runif(1,0,10))
    C3Pie(values = value)
  })
  output$linebarchart <- renderC3LineBarChart({
    
    dataset <- data.frame(Time  = Data()$Time,
                          GREEN = Data()$Perc$GREEN,
                          AMBER = Data()$Perc$AMBER,
                          RED   = Data()$Perc$RED,
                          Total = Data()$Total)
    
    colors      <- list(Total = "gray", GREEN = "#2CA02C", AMBER = "#FF7F0E", RED = "Red")
    
    C3LineBarChart(dataset = dataset, colors = colors)
  })
  
  output$barchart <-renderC3BarChart({
    dataset <- count(result, rating, name='count')
    C3BarChart(dataset)
  })
  observeEvent(input$location,{
    if (is.null(input$location))
      return()
    isolate({
      selectedCity <- geocode(c(input$location))      
      map <- leafletProxy("mymap") %>% clearMarkers() %>% addMarkers(data = points) %>%
      setView(selectedCity$lon, selectedCity$lat, zoom = 15)
    })
  })
  
  observeEvent(input$pie1,{
  
    isolate({
      selectedCity <- geocode(c(input$location))      
      ranking4 = result[result$rating > 4, ]
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