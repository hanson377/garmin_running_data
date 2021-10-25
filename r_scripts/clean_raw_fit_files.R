library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)

df <- read.csv('/Users/hanson377/Desktop/7688312594_ACTIVITY.csv')

## extract split data
splits <- subset(df,Type == 'Data' & Message == 'record')
splits <- splits %>% mutate(row_number = row_number())

## calculate distance related data
distances <- splits %>%
  select(row_number,cumu_distance_meters = Value.4) %>%
    mutate(cumu_distance_miles = cumu_distance_meters*0.000621371)  %>%
      arrange(cumu_distance_meters) %>%
        mutate(distance_segment_miles = cumu_distance_miles-lag(cumu_distance_miles))



## function for pulling value of interest

wrangleField <- function(string_value){

  df <- splits[ , grepl( "Field." , names( splits ) ) ]
  df[] <- lapply(df, as.character)

  ## identify all possible columns with heart rate
  fields_to_pull <- unique(colnames(df)[max.col(df==string_value)])
  values_to_pull <- str_split_fixed(fields_to_pull,'[.]',n=2)[,2]

  hr_df <- NA

  for (i in values_to_pull){

    field <- paste('Field.',i,sep='')
    value <- paste('Value.',i,sep='')

    temp <- splits %>% select(row_number,field = {{field}},value = {{value}})

    hr_df <- rbind(hr_df,temp)


  }
  hr_df <- hr_df %>% filter(field==string_value)
  return(hr_df)
}
heart_rate <- wrangleField('heart_rate')
vertical_oscillation <- wrangleField('vertical_oscillation')
step_length <- wrangleField('step_length')
enhanced_altitude <- wrangleField('enhanced_altitude')
cadence <- wrangleField('cadence')
timestamp <- wrangleField('timestamp')

## rename accordingly
heart_rate <- heart_rate %>% select(row_number,heart_rate=value)
vertical_oscillation <- vertical_oscillation %>% select(row_number,vertical_oscillation_mm=value)
step_length <- step_length %>% select(row_number,step_length_mm=value)
enhanced_altitude <- enhanced_altitude %>% select(row_number,enhanced_altitude_m=value)
cadence <- cadence %>% select(row_number,cadence_rpm=value)
timestamp <- timestamp %>% select(row_number,timestamp=value)


## join onto base of distance
final_df <- distances %>% left_join(heart_rate,by='row_number')
final_df <- final_df %>% left_join(vertical_oscillation,by='row_number')
final_df <- final_df %>% left_join(step_length,by='row_number')
final_df <- final_df %>% left_join(enhanced_altitude,by='row_number')
final_df <- final_df %>% left_join(cadence,by='row_number')
final_df <- final_df %>% left_join(timestamp,by='row_number')

## convert to numerics
final_df$timestamp <- as_datetime(as.numeric(final_df$timestamp),origin = '1990-01-01',tz='MST')
final_df$row_number <- as.numeric(final_df$row_number)
final_df$cumu_distance_meters <- as.numeric(final_df$cumu_distance_meters)
final_df$cumu_distance_miles <- as.numeric(final_df$cumu_distance_miles)
final_df$distance_segment_miles <- as.numeric(final_df$distance_segment_miles)

final_df$heart_rate <- as.numeric(final_df$heart_rate)
final_df$vertical_oscillation <- as.numeric(final_df$vertical_oscillation)
final_df$step_length <- as.numeric(final_df$step_length)
final_df$enhanced_altitude <- as.numeric(final_df$enhanced_altitude)
final_df$cadence <- as.numeric(final_df$cadence)

## calculatre time intervals
final_df <- final_df %>% arrange(row_number)
final_df$time_s <- as.numeric(difftime(final_df$timestamp, lag(final_df$timestamp), units = "secs"))

## finally, pull metadata
run_id <- df %>% filter(Message == 'file_id' & Type == 'Data') %>% select(field = Field.1, value = Value.1)

## tack it on
final_df$run_id <- run_id$value
