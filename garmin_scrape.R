## purpose: this script scrapes the prices of big macs from a few random cities in the US

#load key libraries
library(RSelenium)
library(mailR)
library(dplyr)
library(kableExtra)
library(stringr)
library(odbc)
library(DBI)

# load functions from this repository
source('/Users/hanson377/Documents/GitHub/garmin_running_data/r_scripts/functions.R')

## start remote browser session via firefox
rD <- rsDriver(browser="firefox", port=4545L, verbose=F)
remDr <- rD[["client"]]

## go to google
remDr$navigate('https://connect.garmin.com/')

## search restaurants denver

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

waitAndInput('username','hanson377@gmail.com',1000)

#password
waitAndClick('button.c0149:nth-child(1)',1000)
waitAndClick('.js-activityNameEditPlaceholder > a:nth-child(1)',1000)
waitAndClick('div.dropdown:nth-child(5) > button:nth-child(1) > i:nth-child(1)',1000)
waitAndClick('#btn-export-original > a:nth-child(1)',1000)
