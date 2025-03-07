library("terra")

src_dir <- "data/LANDSAT_NDWI"
raster_files <- list.files(
  normalizePath(src_dir),
  pattern = "\\.(tif|tiff)$",
  ignore.case = TRUE,
  full.names = TRUE
)
for (f in raster_files) {
  cat(basename(f))
  land_cover <- terra::rast(f)
  # terra::plot(land_cover)

  # Get the year based on filename i.e. 1996_LANDSAT_NDWI.tif
  year <- strsplit(basename(f), "_")[[1]][1]

  # Define a threshold (e.g., keep values greater than 0)
  threshold_value <- 0
  binary_raster <- land_cover > threshold_value
  # terra::plot(binary_raster)
}
