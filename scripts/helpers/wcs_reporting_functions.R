
get_path <- function(key, base_path = "k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/wcs_report/"){
        
        
        
        if(!exists("paths")){
                path_file <- paste0(base_path,"data/wcs_paths.xlsx")
                paths <<- read_excel(path_file, sheet = "Paths")
        }
        
        
        res <- paths %>% 
                filter(pointer == key) %>% 
                pull(path) 
        
        
        if(length(res) == 0){
                stop(paste0("Not found file pointer to ",key))
        } else {if(key == "wcs_remote_url"){
                        res
                } else {paste0(base_path,res)}
        }
        
        
        
}


# WCS REPORT -------------------------------------------------------
download_wcs <- function(remove_temporary = T){
        
        url <- get_path("wcs_remote_url")
        h <- new_handle()
        handle_setopt(h, ssl_verifypeer = F)
        curl_download(url, get_path("wcs_temp_xls"), handle = h)
        
        wcs <<- read_excel(get_path("wcs_temp_xls"), sheet = 1)
        
        if(remove_temporary){
                file.remove(get_path("wcs_temp_xls"))
        }
        
        
}

enrich_wcs <- function(){
        
        codes <- read_excel(get_path("wcs_params"), sheet = "sap_ship_code")
        
        #extract brand
        wcs <- wcs %>% 
                mutate(wcs_brand = str_sub(ORDER_ID,3,4))
        
        #add ship codes mapping
        wcs <- wcs %>% 
                filter(!is.na(SAP_SHIP_CODE)) %>% 
                left_join(codes, by = "SAP_SHIP_CODE")
        
        # add shops
        # wcs <- ecommerce %>% 
        #         select(shipping_shop_code,shipping_shop_text) %>% 
        #         distinct() %>% 
        #         filter(!is.na(shipping_shop_code)) %>% 
        #         left_join(wcs,., by = c("SAP_STORE_ID" = "shipping_shop_code"))
        
        
        #add countries
        # wcs <- ecommerce %>%  
        #         select(country_code,country_text) %>%
        #         distinct() %>% 
        #         inner_join(wcs,., by = c("COUNTRY" = "country_code"))
        
        #add brand code and text
        # wcs <- wcs %>% 
        #         mutate(brand_code = str_sub(string = ORDER_ID,start = 3,end = 4)) %>% 
        #         mutate(brand_code = case_when(brand_code == "PR" ~ "P",brand_code == "MM" ~ "M", TRUE ~ "Unknown")) %>% 
        #         left_join(ecommerce %>% select(brand_code,brand_text) %>% distinct(), by = "brand_code")
        
        #add tax rate and shipping rate
        wcs <- wcs %>% 
                mutate_at(vars(TOTALPRODUCT,SALES_TAXES,SHIPPING_CHARGE,SHIPPING_TAXES,PROMOTION), as.numeric) %>% 
                mutate(tax_rate = SALES_TAXES/TOTALPRODUCT) %>% 
                mutate(shipping_tax_rate = SHIPPING_TAXES/TOTALPRODUCT) %>% 
                mutate(shipping_charge_rate = SHIPPING_CHARGE/TOTALPRODUCT) %>% 
                mutate(promotion_rate = PROMOTION/TOTALPRODUCT)
        
        #add elapsed and dates
        wcs <- wcs %>% 
                mutate(TIMEPLACED = ymd_hms(TIMEPLACED),
                       LASTUPDATE = ymd_hms(LASTUPDATE),
                       PAYMENT_LASTUPDATE = ymd_hms(PAYMENT_LASTUPDATE)) %>% 
                mutate(elapsed_placed_last_update_secs = as.numeric(difftime(LASTUPDATE,TIMEPLACED))) %>% 
                mutate(date_placed = as.Date(TIMEPLACED))
        
        #normalize zip codes
        wcs <- wcs %>%
                mutate(normalized_zip = case_when(
                        COUNTRY == "JP" ~ SHIPPING_ZIPCODE,
                        COUNTRY == "SE" ~ SHIPPING_ZIPCODE,
                        COUNTRY == "CA" ~ str_sub(SHIPPING_ZIPCODE,1,3),
                        COUNTRY == "GR" ~ str_replace(SHIPPING_ZIPCODE,"[^A-Z0-9a-z]",""),
                        COUNTRY == "IE" ~ paste0(str_sub(SHIPPING_ZIPCODE,1,3)," ",str_sub(SHIPPING_ZIPCODE,4,7)),
                        COUNTRY == "GB" ~ str_sub(SHIPPING_ZIPCODE,1,-4) %>% str_extract(.,"^[A-Z0-9]*"),
                        TRUE ~ str_extract(SHIPPING_ZIPCODE,"^[A-Z0-9]*")))
        
        #add china city
        cities <- read_excel(get_path("china_zipcodes"), col_types = "text")
        
        cities <- cities %>% 
                mutate(china_zip_clean = str_sub(`Zip Code`,end = -3))
        
        wcs <- wcs %>% 
                mutate(china_zip_clean = case_when(COUNTRY == "CN" ~ str_sub(as.character(SHIPPING_ZIPCODE),end = -3), TRUE ~ "")) %>% 
                left_join(cities, by = "china_zip_clean") %>% 
                mutate(normalized_city = case_when(COUNTRY == "CN" ~ City, TRUE ~ SHIPPING_CITY))
        
        
        #add reference dates
        wcs <<- wcs #%>% 
                #mutate(ref_day = ref_day) %>% 
                #left_join(ecommerce %>% select(date,isoyear,isoweek,ytd,mtd) %>% distinct(), by = c("date_placed" = "date"))
        
        
}

strings_cutoff <- function(cutoff = 180){
        
        #truncate strings longer than cutoff characters 
        wcs <<- wcs %>% 
                mutate_if(is.character, ~ case_when(str_length(.) > cutoff ~ str_sub(1,cutoff), TRUE ~ .))
}

wcs_save_dataset <- function(string_cutoff = 180){
        
        
        write.csv2(wcs, file = get_path("wcs_output"), na = "", row.names = F)
        
}
