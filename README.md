# Aquaculture
Analysis of aquaculture land use

## Data sources
### Administrative layers
Can be found online (https://www.geoboundaries.org)

i.e. Bangladesh Admin 4 Level (villages)
```
Runfola D, Anderson A, Baier H, Crittenden M, Dowker E, Fuhrig S, et al. (2020)
geoBoundaries: A global database of political administrative boundaries.
PLoS ONE 15(4): e0231866. https://doi.org/10.1371/journal.pone.0231866.
https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/9469f09592ced973a3448cf66b6100b741b64c0d/releaseData/gbOpen/BGD/ADM4/geoBoundaries-BGD-ADM4-all.zip
```

### Historical Landcover Rasters
For an historical analysis of the land use, we rely on LANDSAT images using Google Earth Engine.

We selected the Region of Interest using `FAO/GAUL/2015/level1`.

We then created a 0 to 4m elevation mask based on the Digital Elevation Model (DEM) from `COPERNICUS/DEM/GLO30`.

We loaded the Landsat images, filtered the clouds, applied some quality filters and applied the mask on a median composite per studied year.

We then calculated the Normalized Difference Water Index (NDWI) to identify the area covered with water.

A simple index using Green and NIR bands:
$$ NDWI = {Green−NIRGreen \over Green+NIR} $$

For Landsat MSS:
$$ NDWI = {SR_B3−SR_B5 \over SR_B3+SR_B5} $$

The code can be found here:
https://code.earthengine.google.com/?accept_repo=users/loicbaron/aquaculture


## Requirements
Admin vectors and Landcover rasters datasets of the Region of Interest (ROI) must be located in the data folder
- LANDSAT rasters `data/LANDSAT_NDWI`
- Admin layer i.e. `data/ADMIN/villages_bgd.gpkg`


# -------------------------------------------------------
# FOR MAC OS users
# -------------------------------------------------------

```
brew install r

brew reinstall gcc
brew install gdal
brew install libgit2
brew install udunits
```
https://github.com/r-lib/usethis/issues/1970#issuecomment-2471529856
