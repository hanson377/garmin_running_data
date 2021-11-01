library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)

## postgres db libraries
library(DBI)
library(tidyr)
library(odbc)

## set up post gres connections
source("/Users/hanson377/Desktop/script_parameters/postgres_keys.R")

con <- DBI::dbConnect(odbc::odbc(),
  driver = "PostgreSQL Driver",
  database = "garmin_data",
  UID    = pg_name,
  PWD    = pg_password,
  host = pg_host,
  port = pg_port)


## pull in all csv files

files_to_import <- data.frame(filename = list.files(path = "/Users/hanson377/Desktop/garmin/data")) ## detect raw fit files in data directory
files_to_import <- files_to_import %>% filter(str_detect(filename,"csv")) ## filter out old csvs, only look at fit files

## identify files not already in data warehouse
files_in_db <- dbGetQuery(con, "SELECT distinct filename FROM running_data")

files_to_import <- files_to_import %>% anti_join(files_in_db,by='filename')
files_to_import <- files_to_import$filename ## convert to list for loop below

## run loop

df <- NA
for (i in files_to_import) {

string <- paste('/Users/hanson377/Desktop/garmin/data/',i,sep='')
temp_df <- read.csv(string)
temp_df$filename <- i

df <- rbind(df,temp_df)


}
###

## extract split data
splits <- subset(df,Type == 'Data' & Message == 'record')
splits <- splits %>% group_by(filename) %>% mutate(row_number = row_number())

## calculate distance related data
distances <- splits %>%
  select(filename,row_number,cumu_distance_meters = Value.4) %>%
    mutate(cumu_distance_miles = cumu_distance_meters*0.000621371)  %>%
      arrange(filename,cumu_distance_meters) %>%
        mutate(distance_segment_miles = cumu_distance_miles-lag(cumu_distance_miles))



## function for pulling value of interest

wrangleField <- function(string_value){

  df <- splits[ , grepl( "Field." , names( splits ) ) ]
  df[] <- lapply(df, as.character)

  ## identify all possible columns with heart rate
  fields_to_pull <- unique(colnames(df)[max.col(df==string_value)])
  values_to_pull <- str_split_fixed(fields_to_pull,'[.]',n=2)[,2]

  hr_df <- data.frame(filename=NA,row_number=NA,field=NA,value=NA)

  for (i in values_to_pull){

    field <- paste('Field.',i,sep='')
    value <- paste('Value.',i,sep='')

    temp <- splits %>% dplyr::select(filename,row_number,field = {{field}},value = {{value}})

    hr_df <- rbind(hr_df,temp)


  }
  hr_df <- hr_df %>% filter(field==string_value & is.na(field) == FALSE)
  return(hr_df)
}
heart_rate <- wrangleField('heart_rate')
vertical_oscillation <- wrangleField('vertical_oscillation')
step_length <- wrangleField('step_length')
enhanced_altitude <- wrangleField('enhanced_altitude')
cadence <- wrangleField('cadence')
timestamp <- wrangleField('timestamp')

## rename accordingly
heart_rate <- heart_rate %>% select(filename,row_number,heart_rate=value)
vertical_oscillation <- vertical_oscillation %>% select(filename,row_number,vertical_oscillation_mm=value)
step_length <- step_length %>% select(filename,row_number,step_length_mm=value)
enhanced_altitude <- enhanced_altitude %>% select(filename,row_number,enhanced_altitude_m=value)
cadence <- cadence %>% select(filename,row_number,cadence_rpm=value)
timestamp <- timestamp %>% select(filename,row_number,timestamp=value)


## join onto base of distance
final_df <- distances %>% left_join(heart_rate,by=c('filename','row_number'))
final_df <- final_df %>% left_join(vertical_oscillation,by=c('filename','row_number'))
final_df <- final_df %>% left_join(step_length,by=c('filename','row_number'))
final_df <- final_df %>% left_join(enhanced_altitude,by=c('filename','row_number'))
final_df <- final_df %>% left_join(cadence,by=c('filename','row_number'))
final_df <- final_df %>% left_join(timestamp,by=c('filename','row_number'))

## convert to numerics
final_df$timestamp <- as_datetime(as.numeric(final_df$timestamp),origin = '1990-01-01',tz='MST')
final_df$row_number <- as.numeric(final_df$row_number)
final_df$cumu_distance_meters <- as.numeric(final_df$cumu_distance_meters)
final_df$cumu_distance_miles <- as.numeric(final_df$cumu_distance_miles)
final_df$distance_segment_miles <- as.numeric(final_df$distance_segment_miles)

final_df$heart_rate <- as.numeric(final_df$heart_rate)
final_df$vertical_oscillation_mm <- as.numeric(final_df$vertical_oscillation_mm)
final_df$step_length_mm <- as.numeric(final_df$step_length_mm)
final_df$enhanced_altitude_m <- as.numeric(final_df$enhanced_altitude_m)
final_df$cadence_rpm <- as.numeric(final_df$cadence_rpm)

## calculatre time intervals
final_df <- final_df %>%
  arrange(filename,row_number) %>%
    group_by(filename) %>%
      mutate(time_s = difftime(timestamp, lag(timestamp), units = "secs"))

final_df$time_s <- as.numeric(final_df$time_s)




# append this data to table
dbWriteTable(con, "running_data", final_df, append = TRUE,row.names =FALSE)

## test that data is live
data_test <- dbGetQuery(con, "SELECT * FROM running_data")
