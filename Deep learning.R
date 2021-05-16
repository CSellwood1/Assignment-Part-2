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

#now lets separate out 20% of the images for training
image_files_path <- "images" # path to folder with bug photos
spp_list <- dir(image_files_path) #picks up names by folder names
output_n <- length(spp_list) #gives output of 3 for 3 species
#make new folders for test images
for(folder in 1:output_n){dir.create(paste("test", spp_list[folder], sep="/"), recursive=TRUE)}
