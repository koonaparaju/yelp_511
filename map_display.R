library("rjson")
business_csv <- '/Users/venkatakoonaparaju/Downloads/yelp_dataset/business_parsed.csv'

result <- read.csv(business_csv, header = TRUE, sep = ',')
library("ggmap")

head(result)
us <- c(left = -125, bottom = 25.75, right = -67, top = 49)
get_stamenmap(us, zoom = 5, maptype = "toner-lite") %>% ggmap() 

get_googlemap("seattle washington", zoom = 12) %>% ggmap()

qmplot(longitude, latitude, data=result, maptype = "toner-lite")


