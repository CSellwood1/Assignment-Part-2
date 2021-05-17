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
#copy over 160 images per species into new folders with a loop to delete these from the original folders
for(folder in 1:output_n){
  for(image in 641:800){
    src_image  <- paste0("images/", spp_list[folder], "/spp_", image, ".jpg")
    dest_image <- paste0("test/"  , spp_list[folder], "/spp_", image, ".jpg")
    file.copy(src_image, dest_image)
    file.remove(src_image)}}

#now we'll start training the model

#need keras
library(keras)
#need to scale the images
img_width <- 150
img_height <- 150
target_size <- c(img_width, img_height)
channels <- 3 #recolour to GRB 
# Rescale colour hue from 255 to between zero and 1
train_data_gen = image_data_generator(
  rescale = 1/255,
  validation_split = 0.2)

#load in training images
#use seed of 42 for randomness
train_image_array_gen <- flow_images_from_directory(image_files_path, 
                                                    train_data_gen,
                                                    target_size = target_size,
                                                    class_mode = "categorical",
                                                    classes = spp_list,
                                                    subset = "training",
                                                    seed = 42)
#load in validation images
valid_image_array_gen <- flow_images_from_directory(image_files_path, 
                                                    train_data_gen,
                                                    target_size = target_size,
                                                    class_mode = "categorical",
                                                    classes = spp_list,
                                                    subset = "validation",
                                                    seed = 42)
#check the images have flowed correctly
cat("Number of images per class:")
table(factor(train_image_array_gen$classes))
