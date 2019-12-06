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
result[Grade == 1, Sanitation := 'Excellent']
result[Grade == 2, Sanitation := 'Good']
result[Grade == 3, Sanitation := 'Okay']
result[Grade == 4, Sanitation := 'Needs to Improve']
result = result[,c('business_id','name','address','city','state','postal_code','rating','review_count','price','Sanitation','location','longitude','latitude')]
setnames(result, c('name','address','city','state','postal_code','rating','review_count','price','Sanitation','location'), 
         c('Name','Address','City','State','Zipcode','Rating','# of Reviews', 'Price','Food Safety Rating', 'Neighborhood'))
getSeries <- function( n = 100, drift = 0.1, walk = 4, scale = 100){
  y <- scale * cumsum(rnorm(n= n, mean = drift, sd=sqrt(walk)))
  return(y + abs(min(y)))
}

body <- dashboardBody(
  fluidRow(
    column(width = 9,
           box(width = NULL, solidHeader = TRUE, leafletOutput("mymap"))
           
    ),
    column(width = 3,
           selectInput('location', label = 'Location', choices = unique(result$Neighborhood), multiple=TRUE, selected = 'Pioneer Square'),
           selectInput('sanitation', label = 'Sanitation', choices = unique(result$`Food Safety Rating`), multiple=TRUE, selectize=TRUE, selected = 'Good'),
           selectInput('price', label = 'Price', choices = unique(result$Price),multiple=TRUE, selectize=TRUE, selected = c('','$','$$','$$$','$$$$')),
           sliderInput("review", label = "Review", min = 0, max = 5, value = c(4, 5)),
           sliderInput("review_count", label = "Minimum # of Reviews", min = 0, max = 1000, value = 100)
    )
  ),
  fluidRow(
    tabBox(width = 12,
      title = "Details",
      # The id lets us use input$tabset1 on the server to find the current tab
      id = "tabset1", height = "250px",
      tabPanel("Data Table", DT::dataTableOutput('table')),
      tabPanel("Drill Down", "Key Variables")
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
  
  
  output$mymap <- renderLeaflet({
    result = result[Neighborhood %in% input$location &
                      `Food Safety Rating` %in% input$sanitation &
                      Price %in% input$price &
                      Rating >= input$review[1] &
                      Rating <= input$review[2] &
                      `# of Reviews` > input$review_count,!"business_id"]
    points <- cbind(result$longitude, result$latitude)
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
    dataset <- count(result, Rating, name='count')
    C3BarChart(dataset)
  })
  
  output$table = DT::renderDataTable(result[Neighborhood %in% input$location &
                                              `Food Safety Rating` %in% input$sanitation &
                                              Price %in% input$price &
                                              Rating >= input$review[1] &
                                              Rating <= input$review[2] &
                                              `# of Reviews` > input$review_count,!c('business_id','latitude','longitude')], server = TRUE)
  
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