#' Internal functions also used in Voyager
#'
#' Not meant for the user, but exporting to be used internally in Voyager. But
#' one day I may clean these up and remove the internal note for people building
#' on top of SFE.
#'
#' @name internal-Voyager
#' @keywords internal
#' @return Internal
NULL

#' @rdname internal-Voyager
#' @export
.value2df <- function(value, use_geometry, feature = NULL) {
    # Should return data frame for one type, each column is for a feature
    if (!is.data.frame(value) && !is(value, "DFrame")) {
        df_fun <- if (use_geometry) data.frame else DataFrame
        if (is.list(value)) {
            value <- lapply(
                value,
                function(v) {
                    if (is.atomic(v) && is.vector(v)) {
                        v
                    } else {
                        I(v)
                    }
                }
            )
        }
        if (is.matrix(value)) value <- setNames(list(I(value)), feature)
        if (is.vector(value) && is.atomic(value)) {
            value <- setNames(list(value), feature)
        }
        value <- df_fun(value, check.names = FALSE)
    }
    value
}

#' @rdname internal-Voyager
#' @export
.check_features <- function(x, features, colGeometryName = NULL,
                            swap_rownames = NULL) {
    # Check if features are in the gene count matrix or colData.
    # If not found, then assume that they're in the colGeometry
    if (is.null(features)) features <- rownames(x)
    features_assay <- intersect(features, rownames(x))
    if (!length(features_assay) && !is.null(swap_rownames) &&
        swap_rownames %in% names(rowData(x))) {
        .warn_symbol_duplicate(x, features, swap_rownames = swap_rownames)
        features_assay <- rownames(x)[match(features, rowData(x)[[swap_rownames]])]
        features_assay <- features_assay[!is.na(features_assay)]
        if (all(is.na(features_assay))) features_assay <- NULL
    }
    features_coldata <- intersect(features, names(colData(x)))
    if (is.null(colGeometryName)) {
        features_colgeom <- NULL
    } else {
        cg <- colGeometry(x, type = colGeometryName, sample_id = "all")
        features_colgeom <- intersect(features, names(st_drop_geometry(cg)))
    }
    out <- list(
        assay = features_assay,
        coldata = features_coldata,
        colgeom = features_colgeom
    )
    if (all(lengths(out) == 0L)) {
        stop("None of the features are found in the SFE object.")
    }
    return(out)
}

#' @rdname internal-Voyager
#' @export
.warn_symbol_duplicate <- function(x, symbols, swap_rownames = "symbol") {
    all_matches <- rowData(x)[[swap_rownames]][rowData(x)[[swap_rownames]] %in% symbols]
    which_duplicated <- duplicated(all_matches)
    genes_show <- all_matches[which_duplicated]
    if (anyDuplicated(all_matches)) {
        warning(
            "Gene symbol is duplicated for ",
            paste(genes_show, collapse = ", "),
            ", the first match is used."
        )
    }
}

#' @rdname internal-Voyager
#' @export
.symbol2id <- function(x, features, swap_rownames) {
    if (!any(features %in% rownames(x)) && !is.null(swap_rownames) &&
        swap_rownames %in% names(rowData(x))) {
        .warn_symbol_duplicate(x, features, swap_rownames = swap_rownames)
        ind <- features %in% rowData(x)[[swap_rownames]]
        features[ind] <- rownames(x)[match(features[ind], rowData(x)[[swap_rownames]])]
    }
    features
}

#' @rdname internal-Voyager
#' @export
.check_sample_id <- function(x, sample_id, one = TRUE, mustWork = TRUE) {
    if (is.null(sample_id)) {
        sample_id <- sampleIDs(x)
        if (length(sample_id) > 1L) {
            stop(
                "There are more than one sample in this object.",
                " sample_id must be specified"
            )
        }
    } else if (identical(sample_id, "all")) {
        sample_id <- sampleIDs(x)
    } else if (is.numeric(sample_id)) {
        sample_id <- sampleIDs(x)[sample_id]
    } else if (!all(sample_id %in% sampleIDs(x)) && mustWork) {
        sample_use <- intersect(sample_id, sampleIDs(x))
        if (!length(sample_use)) {
            stop("None of the samples are present in the SFE object.")
        }
        sample_show <- setdiff(sample_id, sampleIDs(x))
        warning(
            "Sample(s) ", paste(sample_show, sep = ","),
            " is/are absent from the SFE object."
        )
        sample_id <- sample_use
    }
    if (one) {
        if (length(sample_id) > 1L) {
            stop("Only one sample can be specified at a time.")
        }
    }
    sample_id
}

#' @rdname internal-Voyager
#' @export
.rm_empty_geometries <- function(g, MARGIN) {
    empty_inds <- st_is_empty(g)
    if (MARGIN < 3) {
        if (any(empty_inds)) {
            stop("Empty geometries found in dimGeometry.")
        }
    } else {
        g <- g[!empty_inds, ]
    }
    g
}

#' @rdname internal-Voyager
#' @export
.check_rg <- function(type, x, sample_id) {
    if (identical(sample_id, "all")) {
        .check_rg_sample_all(type, x)
    } else if (!identical(sample_id, "all")) {
        sample_id <- .check_sample_id(x, sample_id, TRUE)
        # By convention, should be name_sample to distinguish between samples for
        # rowGeometries of the same name
        type <- .check_rg_type(type, x, sample_id)
    }
    type
}
