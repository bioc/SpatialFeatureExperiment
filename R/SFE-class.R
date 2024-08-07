#' The SpatialFeatureExperiment class
#'
#' This class inherits from the \code{\link{SpatialExperiment}} (SPE) class,
#' which in turn inherits from \code{\link{SingleCellExperiment}} (SCE).
#' \code{SpatialFeatureExperiment} stores geometries of spots or cells in
#' \code{sf} objects which form columns of a \code{DataFrame} which is in turn a
#' column of the \code{int_colData} \code{DataFrame} of the underlying SCE
#' object, just like \code{reducedDim} in SCE. Geometries of the tissue outline,
#' pathologist annotations, and objects (e.g. nuclei segmentation in a Visium
#' dataset) are stored in \code{sf} objects in a named list called
#' \code{annotGeometries} in \code{int_metadata}.
#'
#' @rdname SpatialFeatureExperiment-class
#' @include utils.R
#' @importFrom methods setClass new setAs setMethod setGeneric setReplaceMethod
#' callNextMethod is
#' @importClassesFrom SpatialExperiment SpatialExperiment
#' @exportClass SpatialFeatureExperiment
#' @concept SpatialFeatureExperiment class
setClass("SpatialFeatureExperiment", contains = "SpatialExperiment")

#' Constructor of SpatialFeatureExperiment object
#'
#' Create a \code{SpatialFeatureExperiment} object.
#'
#' @inheritParams SummarizedExperiment::SummarizedExperiment
#' @inheritParams SpatialExperiment::SpatialExperiment
#' @param colGeometries Geometry of the entities that correspond to the columns
#'   of the gene count matrix, such as cells and Visium spots. It must be a
#'   named list of one of the following: \describe{ \item{An \code{sf} data
#'   frame}{The geometry column specifies the geometry of the entities.}
#'   \item{An ordinary data frame specifying centroids}{Column names for the
#'   coordinates are specified in the \code{spatialCoordsNames} argument. For
#'   Visium and ST, in addition to the centroid coordinate data frame, the spot
#'   diameter in the same unit as the coordinates can be specified in the
#'   \code{spotDiamter} argument.} \item{An ordinary data frame specifying
#'   polygons}{Also use \code{spatialCoordsNames}. There should an additional
#'   column "ID" to specify which vertices belong to which polygon. The
#'   coordinates should not be in list columns. Rather, the data frame should
#'   look like it is passed to \code{ggplot2::geom_polygon}. If there are holes,
#'   then there must also be a column "subID" that differentiates between the
#'   outer polygon and the holes.}} In all cases, the data frame should specify
#'   the same number of geometries as the number of columns in the gene count
#'   matrix. If the column "barcode" is present, then it will be matched to
#'   column names of the gene count matrix. Otherwise, the geometries are
#'   assumed to be in the same order as columns in the gene count matrix. If the
#'   geometries are specified in an ordinary data frame, then it will be
#'   converted into \code{sf} internally. Named list of data frames because each
#'   entity can have multiple geometries, such as whole cell and nuclei
#'   segmentations. The geometries are assumed to be POINTs for centroids and
#'   POLYGONs for segmentations. If polygons are specified in an ordinary data
#'   frame, then anything with fewer than 3 vertices will be removed. For
#'   anything other than POINTs, attributes of the geometry will be ignored.
#' @param rowGeometries Geometry associated with genes or features, which
#'   correspond to rows of the gene count matrix.
#' @param annotGeometries Geometry of entities that do not correspond to columns
#'   or rows of the gene count matrix, such as tissue boundary and pathologist
#'   annotations of histological regions, and nuclei segmentation in a Visium
#'   dataset. Also a named list as in \code{colGeometries}. The ordinary data
#'   frame may specify POINTs, POLYGONs, or LINESTRINGs, or their MULTI
#'   versions. Each data frame can only specify one type of geometry. For MULTI
#'   versions, there must be a column "group" to identify each MULTI geometry.
#' @param spatialGraphs A named list of \code{listw} objects (see \code{spdep})
#'   for spatial neighborhood graphs.
#' @param annotGeometryType Character vector specifying geometry type of each
#'   element of the list if \code{annotGeometry} is specified. Each element of
#'   the vector must be one of POINT, LINESTRING, POLYGON, MULTIPOINT,
#'   MULTILINESTRING, and MULTIPOLYGON. Must be either length 1 (same for all
#'   elements of the list) or the same length as the list. Ignored if the
#'   corresponding element is an \code{sf} object.
#' @param spatialCoordsNames A \code{character} vector of column names if
#'   \code{*Geometries} arguments have ordinary data frames, to identify the
#'   columns in the ordinary data frames that specify the spatial coordinates.
#'   If \code{colGeometries} is not specified, then this argument will behave as
#'   in \code{\link{SpatialExperiment}}, but \code{colGeometries} will be given
#'   precedence if provided.
#' @param spatialCoords A numeric matrix containing columns of spatial
#'   coordinates, as in \code{\link{SpatialExperiment}}. The coordinates are
#'   centroids of the entities represented by the columns of the gene count
#'   matrix. If \code{colGeometries} is also specified, then it will be given
#'   priority and a warning is issued. Otherwise, the \code{sf} representation
#'   of the centroids will be stored in the \code{colGeometry} called
#'   \code{centroids}.
#' @param spotDiameter Spot diameter for technologies with arrays of spots of
#'   fixed diameter per slide, such as Visium, ST, DBiT-seq, and slide-seq. The
#'   diameter must be in the same unit as the coordinates in the *Geometry
#'   arguments. Ignored for geometries that are not POINT or MULTIPOINT.
#' @param unit Unit the coordinates are in, either microns or pixels in full
#'   resolution image.
#' @param ... Additional arguments passed to the \code{\link{SpatialExperiment}}
#'   and \code{\link{SingleCellExperiment}} constructors.
#' @return A SFE object. If neither \code{colGeometries} nor \code{spotDiameter}
#'   is specified, then a \code{colGeometry} called "centroids" will be made,
#'   which is essentially the spatial coordinates as sf POINTs. If
#'   \code{spotDiameter} is specified, but not \code{colGeometries}, then the
#'   spatial coordinates will be buffered by half the diameter to get spots with
#'   the desired diameter, and the resulting \code{colGeometry} will be called
#'   "spotPoly", for which there's a convenience getter and setter,
#'   \code{\link{spotPoly}}.
#' @importFrom SpatialExperiment SpatialExperiment spatialCoords<-
#' @importFrom SingleCellExperiment int_colData int_elementMetadata int_metadata
#'   int_metadata<- int_elementMetadata<- int_colData<-
#' @importFrom sf st_point st_sfc st_sf st_polygon st_buffer st_linestring
#'   st_multipoint st_multilinestring st_multipolygon st_coordinates st_centroid
#'   st_geometry_type st_geometry st_is_valid st_geometrycollection
#' @importFrom S4Vectors DataFrame SimpleList
#' @concept SpatialFeatureExperiment class
#' @export
#' @examples
#' library(Matrix)
#' data("visium_row_col")
#' coords1 <- visium_row_col[visium_row_col$col < 6 & visium_row_col$row < 6, ]
#' coords1$row <- coords1$row * sqrt(3)
#' cg <- df2sf(coords1[, c("col", "row")], c("col", "row"), spotDiameter = 0.7)
#'
#' set.seed(29)
#' col_inds <- sample(seq_len(13), 13)
#' row_inds <- sample(seq_len(5), 13, replace = TRUE)
#' values <- sample(seq_len(5), 13, replace = TRUE)
#' mat <- sparseMatrix(i = row_inds, j = col_inds, x = values)
#' colnames(mat) <- coords1$barcode
#' rownames(mat) <- sample(LETTERS, 5)
#' rownames(cg) <- colnames(mat)
#'
#' sfe <- SpatialFeatureExperiment(list(counts = mat),
#'     colData = coords1,
#'     spatialCoordsNames = c("col", "row"),
#'     spotDiameter = 0.7
#' )
#' sfe2 <- SpatialFeatureExperiment(list(counts = mat),
#'     colGeometries = list(foo = cg)
#' )
SpatialFeatureExperiment <- function(assays,
                                     colData = DataFrame(), rowData = NULL,
                                     sample_id = "sample01",
                                     spatialCoordsNames = c("x", "y"),
                                     spatialCoords = NULL,
                                     colGeometries = NULL, rowGeometries = NULL,
                                     annotGeometries = NULL,
                                     spotDiameter = NA_real_,
                                     annotGeometryType = "POLYGON",
                                     spatialGraphs = NULL,
                                     unit = c("full_res_image_pixel", "micron"),
                                     ...) {
    if (!length(colData)) {
        colData <- make_zero_col_DFrame(nrow = ncol(assays[[1]]))
    }
    if (any(!spatialCoordsNames %in% names(colData))) {
        scn_use <- NULL
    } else {
        scn_use <- spatialCoordsNames
    }
    if (is.null(colGeometries)) {
        spe <- SpatialExperiment(
            assays = assays, colData = colData,
            rowData = rowData, sample_id = sample_id,
            spatialCoords = spatialCoords,
            spatialCoordsNames = scn_use, ...
        )
    } else {
        if (!is.null(spatialCoords)) {
            warning("Ignoring spatialCoords; coordinates are specified in colGeometries.")
        }
        colGeometries <- .df2sf_list(
            colGeometries, spatialCoordsNames,
            spotDiameter, "POLYGON"
        )
        spe_coords <- st_coordinates(st_centroid(st_geometry(colGeometries[[1]])))
        spe <- SpatialExperiment(
            assays = assays, colData = colData,
            rowData = rowData, sample_id = sample_id,
            spatialCoords = spe_coords,
            spatialCoordsNames = NULL, ...
        )
    }
    rownames(spatialCoords(spe)) <- colnames(assays[[1]])
    sfe <- .spe_to_sfe(
        spe, colGeometries, rowGeometries, annotGeometries,
        spatialCoordsNames, annotGeometryType,
        spatialGraphs, spotDiameter, unit
    )
    return(sfe)
}

#' @importFrom grDevices col2rgb
.spe_to_sfe <- function(spe, colGeometries, rowGeometries, annotGeometries,
                        spatialCoordsNames, annotGeometryType, spatialGraphs,
                        spotDiameter, unit) {
    if (is.null(colGeometries)) {
      cg_name <- if (is.na(spotDiameter)) "centroids" else "spotPoly"
      colGeometries <- list(foo = .sc2cg(spatialCoords(spe), spotDiameter))
      names(colGeometries) <- cg_name
    }
    if (!is.null(rowGeometries)) {
        rowGeometries <- .df2sf_list(rowGeometries, spatialCoordsNames,
            spotDiameter = NA, geometryType = "POLYGON"
        )
    }
    if (!is.null(annotGeometries)) {
        annotGeometries <- .df2sf_list(annotGeometries, spatialCoordsNames,
            spotDiameter = NA,
            geometryType = annotGeometryType
        )
    }
    if (nrow(imgData(spe))) {
        # Convert to SpatRaster
        img_data <- imgData(spe)$data
        new_imgs <- lapply(seq_along(img_data), function(i) {
            img <- img_data[[i]]
            if (is(img, "LoadedSpatialImage")) {
                im <- imgRaster(img)
                rgb_v <- col2rgb(im)
                nrow <- dim(im)[2]
                ncol <- dim(im)[1]
                r <- t(matrix(rgb_v["red",], nrow = nrow, ncol = ncol))
                g <- t(matrix(rgb_v["green",], nrow = nrow, ncol = ncol))
                b <- t(matrix(rgb_v["blue",], nrow = nrow, ncol = ncol))
                arr <- simplify2array(list(r, g, b))
                im_new <- rast(arr)
                terra::RGB(im_new) <- seq_len(3)
            } else if (is(img, "RemoteSpatialImage") || is(img, "StoredSpatialImage")) {
                suppressWarnings(im_new <- rast(imgSource(img)))
            } else if (!is(img, "SpatRasterImage")) {
                warning("Don't know how to convert image ", i, " to SpatRaster, ",
                        "dropping image.")
                im_new <- NULL
            }
            # Use scale factor for extent
            ext(im_new) <- as.vector(ext(im_new))/imgData(spe)$scaleFactor[i]
            im_new
        })
        inds <- !vapply(new_imgs, is.null, FUN.VALUE = logical(1))
        new_imgs <- new_imgs[inds]
        new_imgs <- lapply(new_imgs, function(im) {
            new("SpatRasterImage", im)
        })
        imgData(spe) <- imgData(spe)[inds,]
        if (length(new_imgs)) imgData(spe)$data <- new_imgs
    }
    sfe <- new("SpatialFeatureExperiment", spe)
    colGeometries(sfe, withDimnames = FALSE) <- colGeometries
    rowGeometries(sfe, withDimnames = FALSE) <- rowGeometries
    annotGeometries(sfe) <- annotGeometries
    spatialGraphs(sfe) <- spatialGraphs
    int_metadata(sfe)$unit <- unit
    int_metadata(sfe)$SFE_version <- packageVersion("SpatialFeatureExperiment")
    return(sfe)
}

.names_types <- function(l) {
    types <- vapply(l, function(t) as.character(st_geometry_type(t, by_geometry = FALSE)),
        FUN.VALUE = character(1)
    )
    paste(paste0(names(l), " (", types, ")"), collapse = ", ")
}

#' Get unit of a SpatialFeatureExperiment
#'
#' Length units can be microns or pixels in full resolution image in SFE
#' objects.
#'
#' @param x A \code{SpatialFeatureExperiment} object.
#' @return A string for the name of the unit. At present it's merely a
#'   string and \code{udunits} is not used.
#' @export
#' @aliases unit
#' @concept SpatialFeatureExperiment class
#' @examples
#' library(SFEData)
#' sfe <- McKellarMuscleData(dataset = "small")
#' SpatialFeatureExperiment::unit(sfe)
setMethod("unit", "SpatialFeatureExperiment",
          function(x) int_metadata(x)$unit)

#' Print method for SpatialFeatureExperiment
#'
#' Printing summaries of \code{colGeometries}, \code{rowGeometries}, and
#' \code{annotGeometries} in addition to what's shown for
#' \code{SpatialExperiment}. Geometry names and types are printed.
#'
#' @param object A \code{SpatialFeatureExperiment} object.
#' @return None (invisible \code{NULL}).
#' @concept SpatialFeatureExperiment class
#' @export
#' @examples
#' library(SFEData)
#' sfe <- McKellarMuscleData(dataset = "small")
#' sfe # The show method is implicitly called
setMethod(
    "show", "SpatialFeatureExperiment",
    function(object) {
        callNextMethod()
        cat("\nunit:", unit(object))
        cg_names <- names(int_colData(object)$colGeometries)
        rg_names <- names(int_elementMetadata(object)$rowGeometries)
        ag_names <- names(int_metadata(object)$annotGeometries)
        skip_geometries <- length(cg_names) < 1 & length(rg_names) < 1 &
            is.null(ag_names)
        if (!skip_geometries) {
            cat("\nGeometries:\n")
            if (length(cg_names)) {
                cat("colGeometries:", .names_types(colGeometries(object, withDimnames = FALSE)), "\n")
            }
            if (length(rg_names)) {
                cat("rowGeometries:", .names_types(rowGeometries(object, withDimnames = FALSE)), "\n")
            }
            if (!is.null(ag_names)) {
                cat(
                    "annotGeometries:", .names_types(annotGeometries(object)),
                    "\n"
                )
            }
        }
        # What to do with the graphs?
        if (!is.null(int_metadata(object)$spatialGraphs)) {
            cat("\nGraphs:")
            df <- int_metadata(object)$spatialGraphs
            for (s in colnames(df)) {
                cat("\n", s, ": ", sep = "")
                out <- vapply(rownames(df), function(r) {
                    l <- df[r, s][[1]]
                    if (length(l)) {
                        paste0(r, ": ", paste(names(l), collapse = ", "))
                    } else {
                        NA_character_
                    }
                }, FUN.VALUE = character(1))
                out <- out[!is.na(out)]
                cat(paste(out, collapse = "; "))
            }
        }
    }
)
