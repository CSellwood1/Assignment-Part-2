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
forest_recs <-  get_inat_obs(taxon_name  = "Pentatoma rufipes",
                            bounds = gb_ll,
                            quality = "research",
                            maxresults = 800)
#get some sloe bug images
sloe_recs <-  get_inat_obs(taxon_name  = "Dolycoris baccarum",
                            bounds = gb_ll,
                            quality = "research",
                            maxresults = 800)
download_images(spp_recs = green_recs, spp_folder = "green")
download_images(spp_recs = forest_recs, spp_folder = "forest")
download_images(spp_recs = sloe_recs, spp_folder = "sloe")
