## this script scrapes the prices of similar items at mcdonalds across metros

#####################################################################
#load key library
library(dplyr)

############################################################################# everything should be automatic from here


## function to wait until page load
waitUntilLoad <- function(css_value,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'css selector', value = css_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen or attempts reaches an arbitrary 1k times
  }
  if (counter < attempt_limit) {print('successful find')}
  else {return(paste('counter reached limit: ',attempt_limit,sep=''))}
}

waitAndClick <- function(css_value,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'css selector', value = css_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen
  }
  if (counter < attempt_limit) {remDr$findElement("css selector",value = css_value)$clickElement()}
  else {return(paste('counter reached limit: ',attempt_limit,sep=''))}
}

waitAndInput <- function(css_value,input,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'css selector', value = css_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen
  }
  if (counter < attempt_limit) {print('successful find')}
  else {return(paste('counter reached limit: ',attempt_limit,sep=''))}

  field <- remDr$findElement("css selector",value = css_value)
  field$sendKeysToElement(list(input,key='enter'))
}

waitAndScrape <- function(css_value,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'css selector', value = css_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen
  }
  if (counter < attempt_limit) {string <- toString(remDr$findElement("css selector",value = css_value)$getElementText())}
  else {string <- paste('counter reached limit: ',attempt_limit,sep='')}

  return(string)
}

scrapeCity <- function(city,search_address,item_number) {

  website <- paste('https://www.grubhub.com/food/mcdonalds/',city,sep='')
  price_string <- paste('#menuItem-',item_number,' > div:nth-child(3) > span:nth-child(2) > span:nth-child(1) > span:nth-child(1)',sep='')
  item_string <- paste('#menuItem-',item_number,' > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > a:nth-child(1)',sep='')

  remDr$navigate(website)
  waitAndClick('a.c-button:nth-child(2)',1000) ## sometimes a popup appears, this closes that if it does exist
  waitUntilLoad(".s-btn-primary",50)

  waitAndClick('.addressInput-textInput',500)
  waitAndInput(".addressInput-textInput",search_address,1000)


  restaurant <- waitAndScrape(".u-text-wrap",1000)
  location <- waitAndScrape("span.u-stack-x-4 > a:nth-child(2)",1000)
  price <- waitAndScrape(price_string,1000)
  item <- waitAndScrape(item_string,1000)

  df <- data.frame(city,restaurant,location,price,item)

  return(df)
}


## xpath

waitAndClickXpath <- function(xpath_value,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'xpath', value = xpath_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen
  }
  if (counter < attempt_limit) {print('successful find')}
  else {return(paste('counter reached limit: ',attempt_limit,sep=''))}

remDr$findElement("xpath",value = xpath_value)$clickElement()
}

waitAndScrapeXpath <- function(xpath_value,attempt_limit) {

  webElem <-NULL
  counter <- 0

  while(is.null(webElem) & counter < attempt_limit){
    webElem <- tryCatch({remDr$findElement(using = 'xpath', value = xpath_value)},
    error = function(e){NULL})
    counter <- sum(counter, 1)
   #loop until login button is seen
  }
  string <- toString(remDr$findElement("xpath",value = xpath_value)$getElementText())
  return(string)
}
