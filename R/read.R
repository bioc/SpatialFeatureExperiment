#' Read 10X Visium data as SpatialFeatureExperiment
#'
#' Read Space Ranger output as a SpatialFeatureExperiment object, where spots
#' are represented with polygons in the colGeometry called "spotPoly". Other
#' geometries can be added later after the dataset is read. If \code{data =
#' "filtered"}, then spatial neighborhood graphs of the spots are also computed
#' and stored in the colGraph called "visium" in all samples for downstream
#' spatial analyses.
#'
#' @inheritParams SpatialExperiment::read10xVisium
#' @inheritParams findVisiumGraph
#' @importFrom SpatialExperiment read10xVisium
#' @importFrom rjson fromJSON
#' @return A SpatialFeatureExperiment object
#' @export
read10xVisiumSFE <- function(samples = "",
                             sample_id = paste0("sample", sprintf("%02d", seq_along(samples))),
                             type = c("HDF5", "sparse"),
                             data = c("filtered", "raw"),
                             images = "lowres",
                             load = TRUE, style = "W", zero.policy = NULL) {
  # Read one sample at a time, in order to get spot diameter one sample at a time
  sfes <- lapply(seq_along(samples), function(i) {
    o <- read10xVisium(samples[i], sample_id[i], type, data, images, load)
    # Transpose coordinates
    spatialCoords(o) <- spatialCoords(o)[,c(2,1)]
    scalefactors <- fromJSON(file = file.path(samples[i], "spatial", "scalefactors_json.json"))
    .spe_to_sfe(o, colGeometries = NULL, rowGeometries = NULL, annotGeometries = NULL,
                spatialCoordsNames = NULL, annotGeometryType = NULL, spatialGraphs = NULL,
                spotDiameter = scalefactors[["spot_diameter_fullres"]],
                unit = "full_res_image_pixels")
  })
  out <- do.call(cbind, sfes)
  if (data == "filtered") {
    colGraphs(out, sample_id = "all", name = "visium") <-
      findVisiumGraph(out, sample_id = "all", style = style, zero.policy = zero.policy)
  }
  out
}