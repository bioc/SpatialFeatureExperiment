# Affine transformations for both images and geometries
.transform_bbox <- function(bbox, tr) {
    if (!length(tr)) return(bbox)
    if ("name" %in% names(tr)) tr <- do.call(.get_affine_mat, c(tr, bbox = bbox))
    M <- tr$M; v <- tr$v
    bbox_sf <- st_bbox(bbox) |> st_as_sfc()
    bbox_sf <- bbox_sf * t(M) + v
    out <- st_bbox(bbox_sf) |> as.vector() |> setNames(c("xmin", "ymin", "xmax", "ymax"))
    if (out["ymax"] < out["ymin"]) out[c("ymin", "ymax")] <- unname(out[c("ymax", "ymin")])
    if (out["xmax"] < out["xmin"]) out[c("xmin", "xmax")] <- unname(out[c("xmax", "xmin")])
    out
}

.rotation_mat <- function(degrees) {
    theta <- degrees / 180 * pi
    # clockwise rotation
    matrix(c(cos(theta), -sin(theta), sin(theta), cos(theta)),
           ncol = 2)
}
# Anything where I need to move the thing to origin before transformation and
# then move it back to its original center
.center_mv <- function(bbox, M) {
    center <- bbox_center(bbox)
    v <- center - M %*% center
    list(M = M, v = v)
}

.transpose <- function(bbox) {
    M <- matrix(c(0,-1,-1,0), ncol = 2)
    .center_mv(bbox, M)
}

.mirror <- function(bbox, direction = c("vertical", "horizontal")) {
    direction <- match.arg(direction)
    M <- matrix(switch (direction,
                        vertical = c(1,0,0,-1),
                        horizontal = c(-1,0,0,1)),
                ncol = 2)
    .center_mv(bbox, M)
}

.rotate <- function(bbox, degrees) {
    M <- .rotation_mat(degrees)
    .center_mv(bbox, M)
}

.scale <- function(bbox, factor) {
    M <- matrix(c(factor, 0, 0, factor), ncol = 2)
    .center_mv(bbox, M)
}

# Translate string into matrix
.get_affine_mat <- function(name, bbox, direction = NULL, degrees = NULL,
                            factor = NULL, M = NULL, v = NULL, ...) {
    switch(name,
           translate = list(M = matrix(c(1,0,0,1), ncol = 2),
                            v = v),
           transpose = .transpose(bbox),
           mirror = .mirror(bbox, direction),
           rotate = .rotate(bbox, degrees),
           scale = .scale(bbox, factor),
           affine = list(M = M, v = v)
    )
}

.transform_geometry <- function(g, mult, add) UseMethod(".transform_geometry")

.transform_geometry.sf <- function(g, mult, add) {
    # z will not be affected if present
    mult_3d <- rbind(mult, 0) |> cbind(c(0,0,1))
    # It's fine to put it here since I don't expect more than a handful of geometries
    if (is.null(st_z_range(g))) {
        # TODO: The * is slow, from mapply
        # Consider getting the coordinates, do matrix multiplication, then use sfheaders
        g$geometry <- g$geometry * mult + add
    } else {
        g$geometry <- g$geometry * mult_3d + add
    }
    g
}

.transform_geometry.matrix <- function(g, mult, add) {
    mult <- t(mult) # Because of g %*% mult rather than mult %*% g
    mult_3d <- rbind(mult, 0) |> cbind(c(0,0,1))
    add_3d <- c(add, 0)
    if (dim(g)[2] == 2L) {
        g <- g %*% mult
        g <- sweep(g, 2, add, FUN = "+")
    } else {
        g <- g %*% mult_3d
        g <- sweep(g, 2, add_3d, FUN = "+")
    }
    g
}

# Function factory to get different kinds of transformation functions
.transform_geometry_fun <- function(name) {
    function(g, bbox, ...) {
        mat_use <- .get_affine_mat(name, bbox = bbox, ...)
        M <- mat_use$M; v <- mat_use$v
        .transform_geometry(g, M, v)
    }
}

.get_img_fun <- function(name) {
    switch(name,
           translate = translateImg,
           transpose = transposeImg,
           mirror = mirrorImg,
           rotate = rotateImg,
           scale = scaleImg,
           affine = affineImg
    )
}

.translate_geometry <- .get_img_fun("translate")

.translate_img <- .get_img_fun("translate")

.transpose_geometry <- .transform_geometry_fun("transpose")

.transpose_img <- .get_img_fun("transpose")

.mirror_geometry <- .transform_geometry_fun("mirror")
# The internal .*_img functions here also shifts the image so its relative
# position within the larger bbox of the entire sample remains the same. In
# contrast, in the exported *Img functions, the mirroring and rotation are
# performed wrt the center of the individual image.
.mirror_img <- .get_img_fun("mirror")

.rotate_geometry <- .transform_geometry_fun("rotate")

.scale_geometry <- .transform_geometry_fun("scale")

.affine_geometry <- .transform_geometry_fun("affine")

.rotate_img <- .get_img_fun("rotate")

.scale_img <- .get_img_fun("scale")

# From EBImage: affine returns the affine transformation of x, where pixels
# coordinates, denoted by the matrix px, are transformed to cbind(px, 1)%*%m.
# The transformed image will be outside the bound if it's way shifted. I can do
# the centroid preserving thing and translate the image separately later. I can
# first scale the image to the size of the bbox after transformation before
# doing the transformation; the matrix is separated into the scale part,
# initially scaled to fit into the original image, and the rest. output.dim should
# be the size of the transformed bbox in pixels
.affine_ebi <- function(img, bbox, M, v, ...) {
    # bbox argument is just for compatibility, it's ignored
    bbox_old <- ext(img)
    scale_fct <- dim(img)[1]/(bbox_old["xmax"] - bbox_old["xmin"])
    bbox_new <- .transform_bbox(bbox_old, list(M=M, v=v))
    dim_new_px <- c((bbox_new["xmax"] - bbox_new["xmin"])*scale_fct,
                    (bbox_new["ymax"] - bbox_new["ymin"])*scale_fct) |> abs()
    # abs because sf doesn't switch ymin and ymax after reflection
    # Then the v here should be the center of the image
    center_new <- dim_new_px/2
    center_old <- dim(img)/2
    # Since it's cbind(px, 1)%*%m and y is flipped
    # Here the origin is the top left, adding positive number increases px inds
    M2 <- t(matrix(c(1,0,0,-1), nrow = 2) %*% M)
    v <- center_new - M2 %*% center_old
    out <- EBImage::affine(imgRaster(img), t(cbind(M2, v)),
                           output.dim = dim_new_px)
    EBImage(img = out, ext = bbox_new) |> translateImg(v)
}

.transform <- function(sfe, sample_id, bbox, geometry_fun, img_fun,
                       resolution = 4L, maxcell = 1e7, ...) {
    # For one sample, bbox is different for each sample
    inds <- colData(sfe)$sample_id == sample_id
    spatialCoords(sfe)[inds,] <- geometry_fun(spatialCoords(sfe)[inds,], bbox = bbox, ...)
    # colGeometries
    for (n in colGeometryNames(sfe)) {
        cg <- colGeometry(sfe, n, sample_id = sample_id)
        cg <- geometry_fun(cg, bbox = bbox, ...)
        colGeometry(sfe, n, sample_id = sample_id) <- cg
    }
    # annotGeometries
    if (!is.null(annotGeometries(sfe))) {
        for (n in annotGeometryNames(sfe)) {
            ag <- annotGeometry(sfe, n, sample_id = sample_id)
            ag <- geometry_fun(ag, bbox = bbox, ...)
            annotGeometry(sfe, n, sample_id = sample_id) <- ag
        }
    }
    # rowGeometries
    rgns <- rowGeometryNames(sfe)
    if (length(sampleIDs(sfe)) == 1L)
        rg_sample <- rgns
    else
        rg_sample <- rgns[grepl(paste0("_", sample_id, "$"), rgns)]
    if (length(rg_sample)) {
        for (n in rg_sample) {
            rg <- rowGeometry(sfe, n, sample_id = sample_id)
            rg <- geometry_fun(rg, bbox = bbox, ...)
            rowGeometry(sfe, n, sample_id = sample_id) <- rg
        }
    }
    # images
    if (!isEmpty(imgData(sfe))) {
        inds <- imgData(sfe)$sample_id == sample_id
        new_imgs <- lapply(imgData(sfe)$data[inds], function(img) {
            # img_fun should use the overall bbox of the sample including images
            img_new <- img_fun(img, bbox = bbox, resolution = resolution,
                               maxcell = maxcell,...)
        })
        imgData(sfe)$data[inds] <- I(new_imgs)
    }
    sfe
}
.transform_samples <- function(sfe, sample_id, geometry_fun, img_fun,
                               resolution = 4L, maxcell = 1e7, ...) {
    sample_id <- .check_sample_id(sfe, sample_id, one = FALSE)
    bboxes <- bbox(sfe, sample_id, include_images = TRUE)
    if (is.vector(bboxes)) bboxes <- matrix(bboxes, ncol = 1,
                                            dimnames = list(names(bboxes), sample_id))
    for (s in sample_id) {
        sfe <- .transform(sfe, s, bboxes[,s], geometry_fun, img_fun,
                          resolution, maxcell, ...)
    }
    sfe
}