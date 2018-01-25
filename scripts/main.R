library(tidyverse)              #version 1.1.1
library(readxl)                 #version 1.0.0
library(lubridate)              #version 1.6.0
library(stringr)                #version 1.2.0
library(ISOweek)
library(curl)


message("\n\n\n\n\n\n\n-------- STARTING SCRIPT --------")
source("scripts/helpers/wcs_reporting_functions.R")




# DOWNLOAD WCS DATA -------------------------------------------------------
message("Downloadiding WCS data ...\n")
download_wcs(remove_temporary = T)
message("Downloaded WCS data!\n")
enrich_wcs()
strings_cutoff()
message("Saving data...\n")
wcs_save_dataset()
message("Data saved\n")


# END OF SCRIPT -----------------------------------------------------------
cat("Script completed, hit Return to finish...")
a <- readLines(file("stdin"),1)
