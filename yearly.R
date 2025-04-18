# -------------------------------------------------------
# FOR MAC OS users
# -------------------------------------------------------
# brew reinstall gcc
# brew install gdal
# https://github.com/r-lib/usethis/issues/1970#issuecomment-2471529856
# brew install libgit2
# brew install udunits

install.packages("sf", configure.args = c(
    "--with-proj-include=/opt/homebrew/include",
    "--with-proj-lib=/opt/homebrew/lib",
    "--with-sqlite3-lib=/opt/homebrew/lib",
    "--with-sqlite3-include=/opt/homebrew/include"
))
install.packages("terra", configure.args = c(
    "--with-proj-include=/opt/homebrew/include",
    "--with-proj-lib=/opt/homebrew/lib",
    "--with-sqlite3-lib=/opt/homebrew/lib",
    "--with-sqlite3-include=/opt/homebrew/include"
))
# -------------------------------------------------------

install.packages(
  c("dplyr", "exactextractr", "raster"),
  dependencies = TRUE
)
install.packages("tidyverse")
source("helpers.R")
library(dplyr)
library(exactextractr)
library(raster)
library(sf)
library(terra)
library(tidyverse)

admin_roi <- st_read("data/ADMIN/villages_bgd.gpkg") %>%
  dplyr::filter(adm2_name %in% c("Khulna", "Satkhira"))

keep_cols <- c(
  'geo_id',
  "adm1_name",
  "adm2_name",
  "adm3_name",
  "adm4_name",
  "country_iso3",
  "area"
)

results <- admin_roi[, keep_cols]

# Read the single stacked TIFF (one file with multiple bands)
stacked_file <- "data/LANDSAT_NDWI/NDWI_MultiYear.tif"
stacked_raster <- terra::rast(stacked_file)

# Get number of bands in the stacked raster
n_bands <- terra::nlyr(stacked_raster)

# Loop over each band in the stacked raster
for (band in 1:n_bands) {
  cat("Processing band:", band, "/", n_bands, "\n")

  # Extract the individual band (a single-layer SpatRaster)
  current_band <- terra::subset(stacked_raster, band)
  # terra::plot(current_band)
  # Define a threshold (e.g., keep values greater than 0)
  threshold_value <- 0
  binary_raster <- as.numeric(current_band > threshold_value)
  binary_raster[binary_raster == 0] <- NA
  # terra::plot(binary_raster)

  # Extract the year from the band name.
  # Here we assume that the band name contains a 4-digit year.
  band_name <- names(stacked_raster)[band]
  year <- as.numeric(str_extract(band_name, "\\d{4}"))

  result <- raster_area_within_polygons(binary_raster, admin_roi)
  # Optional: Visualize
  # terra::plot(result["val"])

  # Convert result to data frame and add year column
  results[[paste0("aqua_area_", year)]] <- result[["area_raster_km2"]] %>% st_drop_geometry()
  results[[paste0("aqua_pct_", year)]] <- result[["val"]] %>% st_drop_geometry()
}

st_write(results, "output/results.gpkg")
write.csv(results %>% st_drop_geometry(), "output/results.csv")

transform_for_location <- function(data) {
  transformed_data <- data %>%
    dplyr::select(-c(
      geo_id, adm1_name, adm2_name, adm3_name, adm4_name, country_iso3, area
    )) %>%
    tidyr::pivot_longer(
      cols = starts_with("aqua_"),
      names_to = c("variable", "type", "year"),
      names_sep = "_"
    ) %>%
    dplyr::mutate(year = as.integer(year)) %>%
    dplyr::group_by(year, type) %>%
    dplyr::reframe(
      value = if (type[1] == "area") sum(value, na.rm = TRUE) else mean(value, na.rm = TRUE)
    ) %>%
    tidyr::pivot_wider(
      names_from = type,
      values_from = value
    ) %>%
    dplyr::select(year, area, pct)
  return(transformed_data)
}

dacope <- results %>%
  dplyr::filter(adm4_name == "Dacope") %>%
  transform_for_location()
assasuni <- results %>%
  dplyr::filter(adm4_name == "Assasuni") %>%
  transform_for_location()

pratap_nagar <- results %>%
  dplyr::filter(adm4_name == "Pratap Nagar") %>%
  transform_for_location()

khulna <- results %>%
  dplyr::filter(adm2_name == "Khulna") %>%
  transform_for_location()

satkhira <- results %>%
  dplyr::filter(adm2_name == "Satkhira") %>%
  transform_for_location()

write.csv(dacope %>% st_drop_geometry(), "output/dacope.csv")
write.csv(assasuni %>% st_drop_geometry(), "output/assasuni.csv")
write.csv(pratap_nagar %>% st_drop_geometry(), "output/pratap_nagar.csv")
write.csv(khulna %>% st_drop_geometry(), "output/khulna.csv")
write.csv(satkhira %>% st_drop_geometry(), "output/satkhira.csv")
