% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geometry_operation.R
\name{crop}
\alias{crop}
\title{Crop an SFE object with a geometry}
\usage{
crop(
  x,
  y = NULL,
  colGeometryName = 1L,
  sample_id = NULL,
  pred = st_intersects,
  op = st_intersection,
  xmin = deprecated(),
  xmax = deprecated(),
  ymin = deprecated(),
  ymax = deprecated()
)
}
\arguments{
\item{x}{An SFE object.}

\item{y}{An object of class \code{sf}, \code{sfg}, \code{sfc} with which to
crop the SFE object, or a bounding box with the format of the output of
\code{\link{bbox,SpatialFeatureExperiment-method}}.}

\item{colGeometryName}{Column geometry to used to indicate which cells/spots
to keep.}

\item{sample_id}{Samples to crop. Optional when only one sample is present.
Can be multiple samples, or "all", which means all samples. For multiple
samples, \code{sf} data frame \code{y} may have column \code{sample_id}
indicating which geometry subsets which sample or matrix \code{y} may
indicate sample specific bounding boxes in its column names. Only samples
included in the indicated sample IDs are subsetted. If sample is not
indicated in \code{y}, then the same geometry or bounding box is used to
subset all samples specified in the \code{sample_id} argument.}

\item{pred}{A geometric binary predicate function to indicate which
cells/spots to keep, defaults to \code{\link{st_intersects}}.}

\item{op}{A geometric operation function to crop the geometries in the SFE
object. Defaults to \code{\link{st_intersection}}.}

\item{xmin}{Deprecated. Supply the bounding box to argument \code{y} instead.}

\item{xmax}{Deprecated.}

\item{ymin}{Deprecated.}

\item{ymax}{Deprecated.}
}
\value{
An SFE object. There is no guarantee that the geometries after
  cropping are still all valid or preserve the original geometry class.
}
\description{
Returns an SFE object whose specified \code{colGeometry} returns \code{TRUE}
with a geometric predicate function (usually intersects) with another
geometry of interest. This can be used to subset an SFE object with a tissue
boundary or histological region polygon, or crop away empty spaces. After
cropping, not only will the cells/spots be subsetted, but also all geometries
will be cropped.
}
\examples{
library(SFEData)
sfe <- McKellarMuscleData("small")
# Subset sfe to only keep spots on tissue
sfe_on_tissue <- crop(sfe, tissueBoundary(sfe),
    colGeometryName = "spotPoly",
    sample_id = "Vis5A"
)
# Subset sfe to only keep what's within a bounding box
# All geometries will be cropped
# sample_id is optional when only one sample is present
sfe_cropped <- crop(sfe,
    colGeometryName = "spotPoly",
    xmin = 5500, xmax = 6500, ymin = 13500, ymax = 14500
)
}
\concept{Geometric operations}
