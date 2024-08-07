% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/image.R
\name{SFE-image}
\alias{SFE-image}
\alias{addImg,SpatialFeatureExperiment-method}
\alias{transposeImg,SpatialFeatureExperiment-method}
\alias{mirrorImg,SpatialFeatureExperiment-method}
\alias{rotateImg,SpatialFeatureExperiment-method}
\alias{translateImg,SpatialFeatureExperiment-method}
\alias{scaleImg,SpatialFeatureExperiment-method}
\alias{affineImg,SpatialFeatureExperiment-method}
\title{Methods for handling image-related data}
\usage{
\S4method{addImg}{SpatialFeatureExperiment}(x, imageSource, sample_id = 1L, image_id, extent = NULL, scale_fct = 1)

\S4method{transposeImg}{SpatialFeatureExperiment}(
  x,
  sample_id = 1L,
  image_id = NULL,
  maxcell = 1e+07,
  filename = ""
)

\S4method{mirrorImg}{SpatialFeatureExperiment}(
  x,
  sample_id = 1L,
  image_id = NULL,
  direction = "vertical",
  maxcell = 1e+07,
  filename = ""
)

\S4method{rotateImg}{SpatialFeatureExperiment}(x, sample_id = 1L, image_id = NULL, degrees, maxcell = 1e+07)

\S4method{translateImg}{SpatialFeatureExperiment}(x, sample_id = 1L, image_id = NULL, v)

\S4method{scaleImg}{SpatialFeatureExperiment}(x, sample_id = 1L, image_id = NULL, factor)

\S4method{affineImg}{SpatialFeatureExperiment}(x, sample_id = 1L, image_id = NULL, M, v)
}
\arguments{
\item{x}{A SFE object.}

\item{imageSource}{a character string specifying an image file name 
(.png, .jpg or .tif) or URL to source the image from}

\item{sample_id}{Which sample the image is associated with. Use
\code{\link{sampleIDs}} to get sample IDs present in the SFE object.}

\item{image_id}{Image ID, such as "lowres" and "hires" for Visium data and
"DAPI" and "PolyT" for Vizgen MERFISH data.}

\item{extent}{A numeric vector of length 4 with names of the set xmin, ymin,
xmax, and ymax, specifying the extent of the image.}

\item{scale_fct}{Scale factor -- multiply pixel coordinates in full
resolution image by this scale factor should yield pixel coordinates in a
different resolution. \code{extent} takes precedence over \code{scale_fct}.}

\item{maxcell}{Max number of pixels to load \code{SpatRasterImage} into
memory. The default 1e7 is chosen because this is the approximate number of
pixels in the medium resolution image at \code{resolution = 4L} in Xenium
OME-TIFF to make different methods of this function consistent.}

\item{filename}{character. Output filename}

\item{direction}{character. Should (partially) match "vertical" to flip by rows, or "horizontal" to flip by columns}

\item{degrees}{How many degrees to rotate. Positive number means clockwise
and negative number means counterclockwise.}

\item{v}{A numeric vector of length 2 specifying the vector in the xy plane
to translate the SFE object.}

\item{factor}{Numeric, scaling factor.}

\item{M}{A 2x2 numeric matrix for the linear transformation in the xy plane.}
}
\description{
Generics of these functions are defined in \code{SpatialExperiment}, except
for \code{transposeImg}. These SFE methods cater to the new image-related
classes in SFE. The SPE method for \code{getImg}, \code{rmvImg}, and
\code{imgRaster} don't need to be modified for SFE and are hence not
implemented here, but are simply re-exported.
}
\details{
Method of \code{\link{transposeImg}}, \code{\link{mirrorImg}}, and
\code{\link{rotateImg}} perform the method on all images within the SFE
object that are specified with \code{sample_id} and \code{image_id}. For
images that are not loaded into memory, \code{rotateImg} will load
\code{SpatRasterImage} into memory and all image operations except translate
will load \code{BioFormatsImage} into memory.
}
\note{
If the image is already a GeoTIFF file that already has an extent, then
the extent associated with the file will be honored and the \code{extent} and
\code{scale_fct} arguments are ignored. Transposing the image is just like
transposing a matrix. It's flipped about the line going from the top left to
the bottom right.
}
\examples{
library(SFEData)
sfe <- McKellarMuscleData("small")
img_path <- system.file(file.path("extdata", "sample01", "outs", "spatial",
"tissue_lowres_image.png"), package = "SpatialFeatureExperiment")
sfe <- addImg(sfe, img_path, sample_id = "Vis5A", image_id = "lowres", scale_fct =
0.023)
img <- getImg(sfe)
# SpatRasterImage method
img_t <- transposeImg(img)
# SFE method
sfe <- transposeImg(sfe, sample_id = "Vis5A", image_id = "lowres")
}
\seealso{
Other image methods: 
\code{\link{affineImg}()},
\code{\link{cropImg}()},
\code{\link{dim,BioFormatsImage-method}},
\code{\link{ext}()},
\code{\link{imgRaster}()},
\code{\link{imgSource}()},
\code{\link{mirrorImg}()},
\code{\link{rotateImg}()},
\code{\link{scaleImg}()},
\code{\link{translateImg}()},
\code{\link{transposeImg}()}
}
\concept{Image methods}
\concept{image methods}
