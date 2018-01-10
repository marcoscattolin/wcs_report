library(tidyverse)              #version 1.1.1
library(readxl)                 #version 1.0.0
library(lubridate)              #version 1.6.0
library(stringr)                #version 1.2.0
library(ISOweek)
library(curl)


message("\n\n\n\n\n\n\n-------- STARTING SCRIPT --------")
source("scripts/helpers/wcs_reporting_functions.R")




# DOWNLOAD WCS DATA -------------------------------------------------------
message("------ DOWNLOADING WCS DATA -------\n")
download_wcs(remove_temporary = F)
enrich_wcs()
wcs_save_dataset()
message("------ DOWNLOADING WCS DATA: DONE -------\n")


# END OF SCRIPT -----------------------------------------------------------
cat("Script completed, hit Return to finish...")
a <- readLines(file("stdin"),1)
