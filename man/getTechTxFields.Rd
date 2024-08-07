% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{getTechTxFields}
\alias{getTechTxFields}
\title{Get relevant fields and file paths for transcript spots}
\usage{
getTechTxFields(tech, data_dir = NULL)
}
\arguments{
\item{tech}{Name of the commercial technology, must be one of Vizgen, Xenium,
and CosMX.}

\item{data_dir}{Top level directory of the output.}
}
\value{
A named list with elements:
\describe{
\item{\code{spatialCoordsNames}}{A character vector for column names for the
xyz coordinates of the transcript spots.}
\item{\code{gene_col}}{Column name for gene IDs.}
\item{\code{cell_col}}{Column name for cell IDs.}
\item{\code{fn}}{File path of the transcript spot file.}
}
}
\description{
Get column names for x, y, and z coordinates, gene IDs, and cell IDs from the
transcript file and get file paths for transcript spot coordinates given
technology.
}
