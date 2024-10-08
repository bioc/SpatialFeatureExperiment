% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/listw2sparse.R
\name{multi_listw2sparse}
\alias{multi_listw2sparse}
\title{Convert multiple listw graphs into a single sparse adjacency matrix}
\usage{
multi_listw2sparse(listws)
}
\arguments{
\item{listws}{A list of \code{listw} objects.}
}
\value{
A sparse \code{dgCMatrix} of the combined spatial neighborhood graph,
with the original spatial neighborhood graphs of the samples on the diagonal.
When the input is an SFE object, the rows and columns will match the column
names of the SFE object.
}
\description{
Each sample in the SFE object has a separate spatial neighborhood graph.
Spatial analyses performed jointly on multiple samples require a combined
spatial neighborhood graph from the different samples, where the different
samples would be disconnected components of the graph. This combined
adjacency matrix can be used in MULTISPATI PCA.
}
\examples{
# example code

}
