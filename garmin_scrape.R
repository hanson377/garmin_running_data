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
remDr$navigate('https://connect.garmin.com/signin/')

## search restaurants denver
waitAndInput('input#username.login_email','hanson377@gmail.com',1000)
