# Function to extract the area of a raster within each polygon
raster_area_within_polygons <- function(rst, polygons) {
  # Ensure the raster has the correct CRS
  cat("Setting the CRS of the raster...\n")
  if (is.na(crs(rst)) || crs(rst) == "") {
    crs(rst) <- "EPSG:4326" # Assign CRS if it's missing
  }
  # Ensure the polygons are in sf format
  cat("Converting polygons to sf format...\n")
  if (!inherits(polygons, "sf")) {
    polygons <- sf::st_as_sf(polygons)
  }
  # Check for invalid geometries
  cat("Checking for invalid geometries...\n")
  invalid_geometries <- !st_is_valid(polygons)

  # If any invalid geometries are found, you can attempt to fix them
  cat("Fixing invalid geometries...\n")
  if (any(invalid_geometries)) {
    polygons <- st_make_valid(polygons)
  }
  # cat("Simplifying polygons...\n")
  # polygons <- st_simplify(polygons, dTolerance = 100)
  # Ensure the polygons have an area column
  if (!"area" %in% colnames(polygons)) {
    cat("Calculating area of polygons...\n")
    polygons$area <- units::set_units(st_area(polygons), km^2)
  }

  # Define the global equal-area projection (Mollweide)
  target_crs <- "ESRI:54009" # Mollweide Projection

  # Project the raster
  cat("Projecting the raster...\n")
  r_projected <- terra::project(rst, target_crs)

  # Project the shapefile
  cat("Projecting the shapefile...\n")
  polygons_projected <- st_transform(polygons, crs = target_crs)

  # Compute the area of each raster cell in square kilometers
  cat("Calculating the area of each raster cell in square kilometers...\n")
  cell_areas <- terra::cellSize(r_projected, unit = "km", mask = TRUE)

  # Calculate the area of the raster within each polygon
  areas_within_polygons <- exact_extract(
    cell_areas, polygons_projected, "sum",
    default_value = 0,
    progress = TRUE
  )

  # Add the area results to the polygons data frame
  polygons_projected$area_raster_km2 <- areas_within_polygons

  # Transform back to EPSG:4326
  polygons_final <- st_transform(polygons_projected, crs = 4326)

  # Calculate the area ratio
  polygons_final$val <- polygons_final$area_raster_km2 / polygons_final$area

  return(polygons_final)
}
