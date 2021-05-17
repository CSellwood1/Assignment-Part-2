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
output_n #definitely makes three
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
train_data_gen = image_data_generator(rescale = 1/255, validation_split = 0.2)

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
## Class labels vs index mapping
train_image_array_gen$class_indices #shows all 3 species
#check a single image
plot(as.raster(train_image_array_gen[[1]][[1]][9,,,]))

#set up model

#define parameters
# number of training samples
train_samples <- train_image_array_gen$n
# number of validation samples
valid_samples <- valid_image_array_gen$n
#set up number of epochs and batch size
batch_size<- 32
epochs<- 10
##

#create the model structure
model <- keras_model_sequential()#define the model

# add layers
model %>%
  layer_conv_2d(filter = 32, kernel_size = c(3,3), input_shape = c(img_width, img_height, channels), activation = "relu") %>%
  
  # Second hidden layer
  layer_conv_2d(filter = 16, kernel_size = c(3,3), activation = "relu") %>%
  
  # Use max pooling
  layer_max_pooling_2d(pool_size = c(2,2)) %>%
  layer_dropout(0.25) %>%
  
  # Flatten max filtered output into feature vector 
  # and feed into dense layer
  layer_flatten() %>%
  layer_dense(100, activation = "relu") %>%
  layer_dropout(0.5) %>%
  
  # Outputs from dense layer are projected onto output layer
  layer_dense(output_n, activation = "softmax") 

#check the structure
print(model) #think it looks fine

# Compile the model
model %>% compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_rmsprop(lr = 0.0001, decay = 1e-6),
  metrics = "accuracy")

# Train the model with fit_generator
history <- model %>% fit_generator(
  # training data
  train_image_array_gen,
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # validation data
  validation_data = valid_image_array_gen,
  validation_steps = as.integer(valid_samples / batch_size),
  
  # print progress
  verbose = 2)

#assess results
plot(history) #this shows validation accuracy peaks at around 55-60%, training keeps increasing
#loss keeps decreasing for both datasets

###

#save the model

#need to unload imager to prevent function confusion
detach("package:imager", unload = TRUE)
#save
save.image("bugs.RData")
###

#time to test the model
path_test <- "test"

test_data_gen <- image_data_generator(rescale = 1/255)

test_image_array_gen <- flow_images_from_directory(path_test,
                                                   test_data_gen,
                                                   target_size = target_size,
                                                   class_mode = "categorical",
                                                   classes = spp_list,
                                                   shuffle = FALSE, # do not shuffle the                                                                          images around
                                                   batch_size = 1,  # Only 1 image at a time
                                                   seed = 123)
#found the correct number of images
#now run through all the test images
model %>% evaluate_generator(test_image_array_gen, steps = test_image_array_gen$n)
#gave an accuracy of 51.04%, loss of 0.9998

###

#make a confusion matrix

#predict the bug species for each image in the test folders
predictions <- model %>% 
  predict_generator(
    generator = test_image_array_gen,
    steps = test_image_array_gen$n
  ) %>% as.data.frame
#make a table of the results
colnames(predictions) <- spp_list
#create a confusion matrix, takes the highest probability from each row
# Create 3 x 3 table to store data
confusion <- data.frame(matrix(0, nrow=3, ncol=3), row.names=spp_list)
colnames(confusion) <- spp_list

obs_values <- factor(c(rep(spp_list[1], 160),
                       rep(spp_list[2], 160),
                       rep(spp_list[3], 160)))
pred_values <- factor(colnames(predictions)[apply(predictions, 1, which.max)])

library(caret)
conf_mat <- confusionMatrix(data = pred_values, reference = obs_values)
conf_mat