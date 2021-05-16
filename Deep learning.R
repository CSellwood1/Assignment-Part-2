#assignment part 2 - deep learning models

library(rinat)
library(sf)
source("download_images.R") #for downloading image from CS
gb_ll <- readRDS("gb_simple.RDS") #for mapping

#get some green shield bug images
green_recs <-  get_inat_obs(taxon_name  = "Palomena prasina",
                                bounds = gb_ll,
                                quality = "research",
                                maxresults = 800)
#get some forest bug images
green_recs <-  get_inat_obs(taxon_name  = "Pentatoma rufipes",
                            bounds = gb_ll,
                            quality = "research",
                            maxresults = 800)
#get some sloe bug images
green_recs <-  get_inat_obs(taxon_name  = "Dolycoris baccarum",
                            bounds = gb_ll,
                            quality = "research",
                            maxresults = 800)
