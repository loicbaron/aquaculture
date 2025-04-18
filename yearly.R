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

mkdirs("data/LANDSAT_NDWI_binary")
src_dir <- "data/LANDSAT_NDWI"
raster_files <- list.files(
  normalizePath(src_dir),
  pattern = "\\.(tif|tiff)$",
  ignore.case = TRUE,
  full.names = TRUE
)

admin_roi <- st_read("data/ADMIN/villages_bgd.gpkg") %>%
  dplyr::filter(adm2_name == "Khulna")

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

for (f in raster_files) {
  cat("Processing:", basename(f), "\n")
  land_cover <- terra::rast(f)
  # terra::plot(land_cover)
  # Define a threshold (e.g., keep values greater than 0)
  threshold_value <- 0
  binary_raster <- as.numeric(land_cover > threshold_value)
  binary_raster[binary_raster == 0] <- NA
  terra::plot(binary_raster)

  # Get the year based on filename i.e. 1996_LANDSAT_NDWI.tif
  year <- as.numeric(strsplit(basename(f), "_")[[1]][1])

  result <- raster_area_within_polygons(binary_raster, admin_roi)
  # Optional: Visualize
  terra::plot(result["val"])

  # Convert result to data frame and add year column
  results[[paste0("aqua_area_", year)]] <- result[["area_raster_km2"]] %>% st_drop_geometry()
  results[[paste0("aqua_pct_", year)]] <- result[["val"]] %>% st_drop_geometry()
}

st_write(results, "output/results_khulna.gpkg")
write.csv(results %>% st_drop_geometry(), "output/my_data.csv")

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
khulna <- results %>%
  dplyr::filter(adm2_name == "Khulna") %>%
  transform_for_location()
