# yelp_511
## Introduction
This project is part of course 511 (Data Visulization for Data Science) at University of Washington. The goal of this project is to build a data viz that incorpaorates some of the concepts learned in the course. We are using following data sets 

https://www.yelp.com/dataset/challenge
https://data.kingcounty.gov/Health-Wellness/Food-Establishment-Inspection-Data/f29f-zza5

# Commands to add a new html widget 
Deatails from url https://shiny.rstudio.com/articles/js-build-widget.html
devtools::create("C3")  'Creates folder C3, only need to do it once'
scaffoldWidget("C3LineBarChart",edit=FALSE) 'Creates a widget with the name' 

# Installing the new widget 
devtools::install()                                      
library(C3)
this needs to be run everytime. 