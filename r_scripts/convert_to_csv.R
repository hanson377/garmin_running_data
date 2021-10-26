library(stringr)
library(dplyr)

files_to_convert <- data.frame(files = list.files(path = "/Users/hanson377/Desktop/garmin/data")) ## detect raw fit files in data directory
files_to_convert <- files_to_convert %>% filter(str_detect(files,"fit")) ## filter out old csvs, only look at fit files
files_to_convert <- files_to_convert$files

files_to_convert <- data.frame(value = str_split_fixed(files_to_convert,'[.]',n=2)[,1])


## identify files already converted

previously_converted <- data.frame(files = list.files(path = "/Users/hanson377/Desktop/garmin/data")) ## detect raw fit files in data directory
previously_converted <- previously_converted %>% filter(str_detect(files,"csv")) ## filter out old csvs, only look at fit files
previously_converted <- previously_converted$files

previously_converted <- data.frame(value = str_split_fixed(previously_converted,'[.]',n=2)[,1])

##
files_to_convert <- files_to_convert %>% anti_join(previously_converted,by='value')
files_to_convert <- files_to_convert$value

for (i in files_to_convert) { ## run loop to convert fit files to csv via the fit sdk offered by garmin

string <- paste('java -jar /Users/hanson377/Desktop/garmin/fitSDK/java/FitCSVTool.jar /Users/hanson377/Desktop/garmin/data/',i,'.fit',sep='')
system(string)

}
