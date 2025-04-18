library(terra)

# Read the stacked TIFF (assumed to have multiple bands)
stacked_file <- "data/LANDSAT_NDWI/NDWI_MultiYear.tif"
stacked_raster <- rast(stacked_file)

# Create a new band which is the sum of all bands per pixel.
# 'app' applies a function to the values of all layers at each cell.
sum_band <- app(stacked_raster, fun = function(x) sum(x, na.rm = TRUE))

# Name the new band (for example, "sum")
names(sum_band) <- "sum"

# Combine the original stacked raster with the new sum band
stacked_raster_with_sum <- c(stacked_raster, sum_band)

# Optionally, save the new multi-band image to a file.
writeRaster(stacked_raster_with_sum, "data/LANDSAT_NDWI/stacked_with_sum.tif", overwrite = TRUE)
