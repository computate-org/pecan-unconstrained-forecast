#!/usr/bin/env Rscript
## Forecast helper script around 05_SDA_Workflow_NA

## ---------------------------------- Libraries -----------------------------------------
library("magrittr")
library("dplyr")
library("arrow")
library("lubridate")
library("tidyr")

## ---------------------------------- Configuration -------------------------------------
# Read environment variables
project_dir <- Sys.getenv("PROJECT_DIR")
pecan_home <- Sys.getenv("PECAN_HOME")
minio_host <- Sys.getenv("MINIO_HOST")
minio_port <- Sys.getenv("MINIO_PORT")
minio_key <- Sys.getenv("MINIO_KEY")
minio_secret <- Sys.getenv("MINIO_SECRET")
minio_arrow_bucket <- Sys.getenv("MINIO_ARROW_BUCKET")

# Load settings
set <- readRDS(file.path(project_dir,"pecan.RDS"))

## -------------------------------- Helper Functions -------------------------------------
# Minio helper function for paths
minio_path <- function(...) paste(minio_arrow_bucket, ..., sep = "/")

# Minio helper function for URIs
minio_uri <- function(...) {
  template <- "s3://%s:%s@%s?scheme=https&endpoint_override=%s%s%s"
  sprintf(template, minio_key, minio_secret, minio_path(...), minio_host, ":", minio_port)
}

minio_uri_public <- function(...) {
  template <- "s3://%s?scheme=http&endpoint_override=%s%s%s"
  sprintf(template, minio_path(...), minio_host, ":", minio_port)
}

## ---------------------------- Initial Configuration (one-time setup) --------------------------
## Uncomment the section below and run once to update local paths
#  set$outdir = project_dir
#  for(i in seq_along(set$pfts)){
#    set$pfts[[i]]$posterior.files = file.path(project_dir,"pfts",basename(set$pfts[[i]]$posterior.files))
#  }
#  set$model$binary = file.path(project_dir,"model",basename(set$model$binary))
#  set$model$jobtemplate = file.path(project_dir,"template.job")
#  for(i in seq_along(set$run)){
#    set$run[[i]]$inputs$pft.site = file.path(project_dir,"site_pft.csv")
#    set$run[[i]]$inputs$poolinitcond$path = file.path(project_dir,"IC",basename(set$run[[i]]$inputs$poolinitcond$path))
#    set$run[[i]]$inputs$met$path = file.path(project_dir,"GEFS")
#  }
#  saveRDS(set,file=file.path(project_dir,"pecan.RDS"))
##  * update set$database$bety$host
##  * set up separate cron jobs for input prep (met, constraints)

## --------------------------------- Today's Settings ------------------------------------
runDays = as.Date('2022-05-22')  # for test case
FORCE = FALSE  # Flag to decide if existing runs should be overwritten

## check for missed days
start_date = runDays
success = FALSE
NoMet = read.csv(file.path(project_dir,"NO_MET"),header=FALSE)[,1]
while(!success & runDays - start_date < lubridate::days(35) ){
  this.out = dir(file.path(paste0(project_dir,"/FNA",start_date),"out"),full.names = TRUE)
  if(length(this.out) > 0 & !FORCE) { ## this day ran successfully
    success = TRUE
    break
  }
  start_date = start_date - lubridate::days(1)
}
runDays = seq(from=start_date,to=runDays,by="1 day")


## --------------------------------- Run Forecast ------------------------------------------
for (s in seq_along(runDays)) {
  ## did we do this run already?
  now  = paste0(project_dir,"/FNA",runDays[s])
  print(now)
  this.out = dir(file.path(now,"out"),full.names = TRUE)
  if(length(this.out) > 0 & !FORCE) break

  ## find previous run
  yesterday = runDays[s] - lubridate::days(1)
  while(as.character(yesterday) %in% NoMet & yesterday - runDays[s] < lubridate::days(35) ){
    yesterday = yesterday - lubridate::days(1)
  }
  prev = paste0(project_dir,"/FNA",yesterday)
  if(dir.exists(prev)){
    ## is there output there?
    prev.out = dir(file.path(prev,"out"),full.names = TRUE)
    if(length(prev.out)>0){
      prev.files = sapply(as.list(prev.out),function(x){length(dir(x,pattern = "*.nc"))})
      if(min(prev.files)>0){

        #########   RUN FORECAST   ########
        msg = system2(file.path(pecan_home,"modules/assim.sequential/inst/hf_landscape/05_SDA_Workflow_NA.R"),
                      paste("--start.date",runDays[s],
                            "--prev",prev,
                            "--settings",file.path(project_dir,"pecan.RDS")),
                      wait=TRUE,
                      stdout="stdout.log",
                      stderr="stderr.log")
        print(msg)

      }
    } else { break }
  }
}

## ---------------------------- Push Output to MinIO in EFI Standard -------------------------
## Source helper functions
source(file.path(pecan_home,"modules/assim.sequential/inst/hf_landscape/PEcAn2EFI.R"))

## loop over dates
for (s in seq_along(runDays)) {
  ## did we do this run already?
  now  = paste0(project_dir,"/FNA",runDays[s])
  print(now)
  this.out = dir(file.path(now,"out"),full.names = TRUE)
  if(length(this.out) == 0){
    print("no output")
    next
  }

  ## did we write this run to minio already?
  if(!FORCE){  ## if not overwriting
    ens = arrow::open_dataset(minio_uri_public(), format = "parquet" ) %>%
      dplyr::filter(lubridate::as_datetime(reference_datetime) == runDays[s]) %>%
      dplyr::distinct(parameter) %>% dplyr::collect()
    if(length(ens$parameter)>0) {
      print(paste("skipping",length(ens$parameter)))
      next
    }
  }

  ## identify runs in the output folder
  runs     =        sapply(strsplit(this.out,"/"),function(x){x[grep("ENS",x)]})
  site_ids = unique(sapply(strsplit(runs    ,"-"),function(x){as.numeric(x[3])}))
  ens_ids  = unique(sapply(strsplit(runs    ,"-"),function(x){as.numeric(x[2])}))

  ## read output, convert to EFI standard
  out = list()
  for(i in seq_along(runs)){
    out[[runs[i]]] = PEcAn2EFI.ens(outdir = file.path(now,"out"),
                                   run.id = runs[i],
                                   start_date = runDays[s])
  }
  out = dplyr::bind_rows(out)
  if(!is.numeric(nrow(out)) | nrow(out) == 0) next  ## don't insert empty days into minio
  out = out %>% relocate(parameter) %>%
    relocate(site_id) %>%
    relocate(time_bounds) %>% rename(datetime=time_bounds) %>%
    relocate(reference_datetime)
  out = tidyr::pivot_longer(out,5:ncol(out),names_to = "variable",values_to = "prediction")

  ## push to container in parquet format
  out %>% dplyr::group_by(reference_datetime) %>% arrow::write_dataset(minio_uri(),format="parquet", hive_style=FALSE)

}


