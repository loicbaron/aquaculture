source("helpers.R")
library(dplyr)
library(exactextractr)
library(raster)
library(sf)
library(terra)

src_dir <- "data/LANDSAT_NDWI"
raster_files <- list.files(
  normalizePath(src_dir),
  pattern = "\\.(tif|tiff)$",
  ignore.case = TRUE,
  full.names = TRUE
)
admin_roi <- st_read("data/ADMIN/villages_bgd.gpkg") %>%
  dplyr::filter(adm2_name == "Khulna")

# Initialize an empty list to store results
results_list <- list()

for (f in raster_files) {
  cat("Processing:", basename(f), "\n")
  land_cover <- terra::rast(f)
  # terra::plot(land_cover)

  # Get the year based on filename i.e. 1996_LANDSAT_NDWI.tif
  year <- as.numeric(strsplit(basename(f), "_")[[1]][1])

  # Define a threshold (e.g., keep values greater than 0)
  threshold_value <- 0
  binary_raster <- land_cover > threshold_value
  # terra::plot(binary_raster)
  result <- raster_area_within_polygons(binary_raster, admin_roi)
  # Optional: Visualize
  terra::plot(result["val"])

  # Convert result to data frame and add year column
  result_df <- as.data.frame(result) %>%
    dplyr::mutate(year = year)

  # Store in list
  results_list[[as.character(year)]] <- result_df
}

# Combine all results into a single data frame
final_results <- dplyr::bind_rows(results_list)
