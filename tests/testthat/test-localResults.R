library(SingleCellExperiment)
library(S4Vectors)
library(sf)

sfe <- readRDS(system.file("extdata/sfe_toy.rds",
    package = "SpatialFeatureExperiment"
))

test_that("Get List of length 0 when localResults are absent", {
    foo <- localResults(sfe)
    expect_true(is(foo, "List"))
    expect_equal(length(foo), 0L)
})

set.seed(29)
toy_res1 <- matrix(rnorm(10),
    nrow = 5, ncol = 2,
    dimnames = list(colnames(sfe), c("meow", "purr"))
)
toy_res1b <- matrix(rgamma(10, shape = 2),
    nrow = 5, ncol = 2,
    dimnames = list(colnames(sfe), c("meow", "purr"))
)
toy_df1 <- DataFrame(gene1 = I(toy_res1), gene2 = I(toy_res1b))

toy_res2 <- matrix(rpois(10, lambda = 2),
    nrow = 5, ncol = 2,
    dimnames = list(colnames(sfe), c("sassy", "tortitude"))
)
toy_df2 <- DataFrame(gene1 = I(toy_res2))

# Setters----------
test_that("localResults setter, all results", {
    localResults(sfe) <- list(foo = toy_df1, bar = toy_df2)
    lrs <- int_colData(sfe)$localResults
    expect_true(is(lrs, "DFrame"))
    expect_equal(names(lrs), c("foo", "bar"))
    expect_equal(lrs$foo, toy_df1)
    expect_equal(lrs$bar, toy_df2)
})

test_that("localResult setter, one type, one feature, one sample, not geometry", {
    localResult(sfe, "foo", feature = "gene1") <- toy_res1
    lrs <- int_colData(sfe)$localResults
    expect_s4_class(lrs, "DFrame")
    expect_equal(names(lrs), "foo")
    lr <- lrs[["foo"]]
    expect_s4_class(lr, "DFrame")
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1, toy_res1)
    # Also need to test adding results when some features already have results.
    localResult(sfe, "foo", feature = "gene2") <- toy_res2
    lrs <- int_colData(sfe)$localResults
    expect_equal(names(lrs), "foo")
    expect_equal(lrs$foo$gene2, toy_res2)
    # And replacing results for a feature that already has results.
    localResult(sfe, "foo", feature = "gene1") <- toy_res1b
    lrs <- int_colData(sfe)$localResults
    expect_equal(lrs$foo$gene1, toy_res1b)
    # Adding another type when a type already exists
    localResult(sfe, "bar", feature = "gene1") <- toy_res2
    lrs <- int_colData(sfe)$localResults
    expect_equal(names(lrs), c("foo", "bar"))
    expect_equal(lrs$bar$gene1, toy_res2)
})

test_that("localResults setter, one type, multiple features, one sample, not geometry", {
    localResults(sfe, name = "foo") <- as.list(toy_df1)
    lrs <- int_colData(sfe)$localResults
    expect_s4_class(lrs, "DFrame")
    expect_equal(names(lrs), "foo")
    lr <- lrs[["foo"]]
    expect_s4_class(lr, "DFrame")
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene1, toy_res1)
    expect_equal(lr$gene2, toy_res1b)
    # Additional type
    localResults(sfe, name = "bar") <- as.list(toy_df2)
    lrs <- int_colData(sfe)$localResults
    expect_equal(names(lrs), c("foo", "bar"))
    expect_equal(lrs$bar$gene1, toy_res2)
    # Changing existing type
    localResults(sfe, name = "bar") <- as.list(toy_df1)
    lr <- int_colData(sfe)$localResults$bar
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene1, toy_res1)
    expect_equal(lr$gene2, toy_res1b)
})

test_that("localResults setter, when a feature is not a valid R object name", {
    values <- as.list(toy_df1)
    names(values)[2] <- "gene-2"
    localResults(sfe, name = "foo", features = names(values)) <- values
    lr <- int_colData(sfe)$localResults$foo
    expect_equal(names(lr), c("gene1", "gene-2"))
})

cg_toy <- readRDS(system.file("extdata/cg_toy.rds",
    package = "SpatialFeatureExperiment"
))
ag <- readRDS(system.file("extdata/ag.rds",
    package = "SpatialFeatureExperiment"
))
# Should have passed unit tests for dimGeometries and annotGeometries
colGeometry(sfe, "cg") <- cg_toy
annotGeometry(sfe, "ag") <- ag

test_that("localResults setter, one type, one feature, colGeometry", {
    localResult(sfe, "foo", feature = "gene1", colGeometryName = "cg") <- toy_res1
    cg <- colGeometry(sfe, "cg")
    expect_true(setequal(names(cg), c("geometry", "localResults")))
    lrs <- cg$localResults
    expect_s3_class(lrs, "data.frame")
    expect_equal(names(lrs), "foo")
    expect_equal(names(lrs$foo), "gene1")
    expect_equal(lrs$foo$gene1, toy_res1, ignore_attr = "class")
    # I don't care about the "AsIs" thing.
    # Additional feature for the same type
    localResult(sfe, "foo", feature = "gene2", colGeometryName = "cg") <-
        toy_res1b
    lrs <- colGeometry(sfe, "cg")$localResults
    expect_equal(names(lrs), "foo")
    expect_equal(names(lrs$foo), c("gene1", "gene2"))
    expect_equal(lrs$foo$gene1, toy_res1, ignore_attr = "class")
    expect_equal(lrs$foo$gene2, toy_res1b, ignore_attr = "class")
    # Additional type
    localResult(sfe, "bar", feature = "gene1", colGeometryName = "cg") <- toy_res2
    lrs <- colGeometry(sfe, "cg")$localResults
    expect_equal(names(lrs), c("foo", "bar"))
    expect_equal(names(lrs$bar), "gene1")
    expect_equal(lrs$bar$gene1, toy_res2, ignore_attr = "class")
})

test_that("localResults setter, one type, one feature, annotGeometry", {
    localResult(sfe, "foo", feature = "gene1", annotGeometryName = "ag") <-
        toy_res1[1, , drop = FALSE]
    # Need to deal with the case of one row matrix so users don't need to know drop = FALSE
    ag <- annotGeometry(sfe, "ag")
    expect_true(setequal(names(ag), c("sample_id", "geometry", "localResults")))
    lrs <- ag$localResults
    expect_s3_class(lrs, "data.frame")
    expect_equal(names(lrs), "foo")
    expect_equal(names(lrs$foo), "gene1")
    expect_equal(lrs$foo$gene1, toy_res1[1, , drop = FALSE], ignore_attr = "class")
})

test_that("Not translating geometries after removing empty space", {
    sfe_shifted <- removeEmptySpace(sfe)
    # colGeometry
    bbox_cg <- st_as_sfc(st_bbox(colGeometry(sfe_shifted)))
    localResult(sfe_shifted, "foo", feature = "gene1", colGeometryName = "cg") <- toy_res1
    bbox_cg2 <- st_as_sfc(st_bbox(colGeometry(sfe_shifted)))
    expect_equal(bbox_cg, bbox_cg2)

    # annotGeometry
    bbox_ag <- st_as_sfc(st_bbox(annotGeometry(sfe_shifted)))
    localResult(sfe_shifted, "foo", feature = "gene1", annotGeometryName = "ag") <-
        toy_res1[1, , drop = FALSE]
    bbox_ag2 <- st_as_sfc(st_bbox(annotGeometry(sfe_shifted)))
    expect_equal(bbox_ag, bbox_ag2)
})

sfe3 <- readRDS(system.file("extdata/sfe_multi_sample.rds",
    package = "SpatialFeatureExperiment"
))
# Should have passed the colGeometry unit test
colGeometry(sfe3, type = "coords", sample_id = "all", withDimnames = FALSE) <-
    cg_toy

test_that("localResult setter for one of two samples, one feature, not in geometries", {
    localResult(sfe3, "foo", "gene1", sample_id = "sample02") <- toy_res1[4:5, ]
    lr <- int_colData(sfe3)$localResults$foo
    expect_true(all(is.na(lr$gene1[seq_len(3), ])))
    expect_equal(lr$gene1[4:5, ], toy_res1[4:5, ])
    # Additional sample, same feature
    localResult(sfe3, "foo", "gene1", sample_id = "sample01") <-
        toy_res1[seq_len(3), ]
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
    # Additional feature, same type
    localResult(sfe3, "foo", "gene2", sample_id = "sample01") <-
        toy_res1b[seq_len(3), ]
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene2[seq_len(3), ], toy_res1b[seq_len(3), ],
        ignore_attr = TRUE
    )
    # I don't really care about rownames there
    expect_true(all(is.na(lr$gene2[4:5, ])))
    # Additional type
    localResult(sfe3, "bar", "gene1", sample_id = "sample01") <-
        toy_res2[seq_len(3), ]
    expect_equal(names(int_colData(sfe3)$localResults), c("foo", "bar"))
    lr <- int_colData(sfe3)$localResults$bar
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1[seq_len(3), ], toy_res2[seq_len(3), ],
        ignore_attr = "class"
    )
    expect_true(all(is.na(lr$gene1[4:5, ])))
})

test_that("localResults setter for one of two samples, multiple features, not in geometries", {
    localResults(sfe3, sample_id = "sample02", name = "foo") <-
        as.list(toy_df1[4:5, ])
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_true(all(is.na(lr$gene1[seq_len(3), ])))
    expect_true(all(is.na(lr$gene2[seq_len(3), ])))
    expect_equal(lr$gene1[4:5, ], toy_res1[4:5, ])
    expect_equal(lr$gene2[4:5, ], toy_res1b[4:5, ])
    # Additional sample, same type
    localResults(sfe3, sample_id = "sample01", name = "foo") <-
        as.list(toy_df1[seq_len(3), ])
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b, ignore_attr = "class")
    # Additional type
    localResults(sfe3, sample_id = "sample01", name = "bar") <-
        as.list(toy_df2[seq_len(3), , drop = FALSE])
    expect_equal(names(int_colData(sfe3)$localResults), c("foo", "bar"))
    lr <- int_colData(sfe3)$localResults$bar
    expect_equal(lr$gene1[seq_len(3), ], toy_res2[seq_len(3), ],
        ignore_attr = "class"
    )
    expect_true(all(is.na(lr$gene1[4:5, ])))
})

test_that("localResult setter for all samples, one feature, not in geometries", {
    localResult(sfe3, feature = "gene1", sample_id = "all", type = "bar") <-
        toy_res2
    lr <- int_colData(sfe3)$localResults$bar
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1, toy_res2, ignore_attr = "class")
    # Additional feature, same type
    localResult(sfe3, feature = "gene2", sample_id = "all", type = "bar") <-
        toy_res1
    lr <- int_colData(sfe3)$localResults$bar
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene2, toy_res1, ignore_attr = "class")
    # Additional type
    localResult(sfe3, feature = "gene1", sample_id = "all", type = "foo") <-
        toy_res1b
    expect_equal(names(int_colData(sfe3)$localResults), c("bar", "foo"))
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1, toy_res1b, ignore_attr = "class")
})

test_that("localResults setter for all samples, multiple features, not in geometries", {
    localResults(sfe3, sample_id = "all", name = "foo") <- toy_df1
    lr <- int_colData(sfe3)$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene1, toy_res1)
    expect_equal(lr$gene2, toy_res1b)
})

test_that("localResults setter for one of two samples, one feature, in colGeometry", {
    localResult(sfe3, "foo", "gene1",
        colGeometryName = "coords",
        sample_id = "sample01"
    ) <- toy_res1[seq_len(3), ]
    cg <- colGeometry(sfe3, "coords", sample_id = "all")
    expect_true(setequal(names(cg), c("geometry", "localResults")))
    lrs <- cg$localResults
    expect_s3_class(lrs, "data.frame")
    expect_equal(names(lrs), "foo")
    expect_equal(names(lrs$foo), "gene1")
    expect_equal(lrs$foo$gene1[seq_len(3), ], toy_res1[seq_len(3), ],
        ignore_attr = TRUE
    )
    expect_true(all(is.na(lrs$foo$gene1[4:5, ])))
    # Additional sample, same feature, same type
    localResult(sfe3, "foo", "gene1",
        colGeometryName = "coords",
        sample_id = "sample02"
    ) <- toy_res1[4:5, ]
    lr <- colGeometry(sfe3, "coords", sample_id = "all")$localResults$foo
    expect_equal(lr$gene1, toy_res1, ignore_attr = TRUE)
    # Additional feature, same type
    localResult(sfe3, "foo", "gene2",
        colGeometryName = "coords",
        sample_id = "sample01"
    ) <- toy_res1b[seq_len(3), ]
    lr <- colGeometry(sfe3, "coords", sample_id = "all")$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene2[seq_len(3), ], toy_res1b[seq_len(3), ],
        ignore_attr = TRUE
    )
    # I don't really care about rownames there
    expect_true(all(is.na(lr$gene2[4:5, ])))
    # Additional type
    localResult(sfe3, "bar", "gene1",
        colGeometryName = "coords",
        sample_id = "sample01"
    ) <- toy_res2[seq_len(3), ]
    cg <- colGeometry(sfe3, "coords", sample_id = "all")
    expect_equal(names(cg$localResults), c("foo", "bar"))
    lr <- cg$localResults$bar
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1[seq_len(3), ], toy_res2[seq_len(3), ],
        ignore_attr = TRUE
    )
    expect_true(all(is.na(lr$gene1[4:5, ])))
})

test_that("localResults setter for one of two samples, multiple features, in colGeometry", {
    cg_lrs <- toy_df1[seq_len(3), ]
    localResults(sfe3,
        name = "foo", colGeometryName = "coords",
        sample_id = "sample01"
    ) <- as.list(cg_lrs)
    cg <- colGeometry(sfe3, "coords", sample_id = "all")
    expect_true(setequal(names(cg), c("geometry", "localResults")))
    lrs <- cg$localResults
    expect_s3_class(lrs, "data.frame")
    expect_equal(names(lrs), "foo")
    expect_equal(as.list(lrs$foo[seq_len(3), ]), as.list(cg_lrs),
        ignore_attr = TRUE
    )
    expect_true(all(is.na(lrs$foo$gene1[4:5, ])))
    expect_true(all(is.na(lrs$foo$gene2[4:5, ])))
})

test_that("localResult setter for all samples, one feature, colGeometry", {
    localResult(sfe3,
        feature = "gene1", type = "foo", sample_id = "all",
        colGeometryName = "coords"
    ) <- toy_res1
    lr <- colGeometry(sfe3, "coords", sample_id = "all")$localResults$foo
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
})

test_that("localResults setter for all samples, multiple features, colGeometry", {
    localResults(sfe3,
        name = "foo", sample_id = "all",
        colGeometryName = "coords"
    ) <- toy_df1
    lr <- colGeometry(sfe3, "coords", sample_id = "all")$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b, ignore_attr = "class")
})

ag2 <- readRDS(system.file("extdata/ag_samples.rds",
    package = "SpatialFeatureExperiment"
))
annotGeometry(sfe3, "ag", sample_id = "all") <- ag2
test_that("localResults setter for one of two samples, one feature, in annotGeometry", {
    ag_test <- toy_res1[1, , drop = FALSE]
    localResult(sfe3, "foo", "gene1",
        annotGeometryName = "ag",
        sample_id = "sample01"
    ) <- ag_test
    ag <- annotGeometry(sfe3, "ag", sample_id = "all")
    expect_true(setequal(names(ag), c("sample_id", "geometry", "localResults")))
    lrs <- ag$localResults
    expect_s3_class(lrs, "data.frame")
    expect_equal(names(lrs), "foo")
    expect_equal(names(lrs$foo), "gene1")
    expect_equal(lrs$foo$gene1[1, ], as.vector(ag_test), ignore_attr = TRUE)
    expect_true(all(is.na(lrs$foo$gene1[2, ])))
})

test_that("localResult setter for all samples, one feature, annotGeometry", {
    localResult(sfe3,
        type = "foo", feature = "gene1", annotGeometryName = "ag",
        sample_id = "all"
    ) <- toy_res1b[seq_len(2), ]
    ag <- annotGeometry(sfe3, "ag", sample_id = "all")
    lr <- ag$localResults$foo
    expect_equal(names(lr), "gene1")
    expect_equal(lr$gene1, toy_res1b[seq_len(2), ], ignore_attr = "class")
})

test_that("localResult setter for all samples, multiple features, annotGeometry", {
    localResults(sfe3,
        sample_id = "all", name = "foo",
        annotGeometryName = "ag"
    ) <- toy_df1[seq_len(2), ]
    ag <- annotGeometry(sfe3, "ag", sample_id = "all")
    lr <- ag$localResults$foo
    expect_equal(names(lr), c("gene1", "gene2"))
    expect_equal(lr$gene1, toy_res1[seq_len(2), ], ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b[seq_len(2), ], ignore_attr = "class")
})

# What if the various geometries and local results collectively grow larger than
# the matrices in the assays?
# Does DelayedArray work with int_colData?
# Maybe. Anything can go as columns of DataFrames, as long it has a length method.
# Maybe that can work with on disk GIS databases if I try.

# Getters--------
# Should have passed the previous tests
localResults(sfe) <- list(foo = toy_df1, bar = toy_df2)
test_that("localResults getter, all results", {
    lrs <- localResults(sfe, withDimnames = FALSE)
    expect_true(is(lrs, "List"))
    expect_equal(length(lrs), 2L)
    expect_equal(names(lrs), c("foo", "bar"))
    expect_equal(lrs$foo, toy_df1)
    expect_equal(lrs$bar, toy_df2)
})

test_that("localResults getter, by name and features", {
    lrs <- localResults(sfe, name = "foo")
    expect_true(is.list(lrs))
    expect_equal(names(lrs), c("gene1", "gene2"))
    expect_equal(lrs$gene1, toy_res1)
    expect_equal(lrs$gene2, toy_res1b)
    # Specify feature
    lr <- localResults(sfe, name = "foo", features = "gene1")
    expect_equal(lr[["gene1"]], toy_res1)
})

test_that("localResult getter, one sample", {
    lr <- localResult(sfe, feature = "gene1")
    expect_equal(lr, toy_res1)
    lr2 <- localResult(sfe, "bar", feature = "gene1")
    expect_equal(lr2, toy_res2)
    lr3 <- localResult(sfe, 2L, feature = "gene1")
    expect_equal(lr3, toy_res2)
})

test_that("localResultFeatures", {
    expect_equal(localResultFeatures(sfe, "foo"), names(toy_df1))
    # Return NULL when type is absent
    expect_true(is.null(localResultFeatures(sfe, "meow")))
})

test_that("localResultAttrs", {
    expect_equal(localResultAttrs(sfe, "foo", "gene1"), c("meow", "purr"))
    expect_true(is.null(localResultAttrs(sfe, "meow", "gene1")))
    expect_true(is.null(localResultAttrs(sfe, "foo", "gene3")))
})

localResults(sfe3) <- list(bar = toy_df2)
test_that("localResults getter for one of the two samples", {
    lr_sample02 <- localResults(sfe3, "bar", sample_id = "sample02")
    expect_equal(nrow(lr_sample02[["gene1"]]), 2L)
    expect_equal(lr_sample02[["gene1"]], toy_res2[4:5, ])
})

localResults(sfe, name = "foo", colGeometryName = "cg") <- toy_df1
test_that("localResults getter for colGeometry, one sample", {
    # All features
    lr <- localResults(sfe, name = "foo", colGeometryName = "cg")
    expect_true(is.list(lr))
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b, ignore_attr = "class")
    # One feature
    lr <- localResult(sfe, "foo", "gene1", colGeometryName = "cg")
    expect_equal(lr, toy_res1, ignore_attr = "class")
})

test_that("localResultFeatures for colGeometry", {
    expect_equal(localResultFeatures(sfe, "foo", colGeometryName = "cg"),
                 names(toy_df1))
    expect_true(is.null(localResultFeatures(sfe, "purr", colGeometryName = "cg")))
})

test_that("localResultAttrs for colGeometry", {
    expect_equal(localResultAttrs(sfe, "foo", "gene2", colGeometryName = "cg"),
                 c("meow", "purr"))
    expect_true(is.null(localResultAttrs(sfe, "purr", "gene1",
                                         colGeometryName = "cg")))
    expect_true(is.null(localResultAttrs(sfe, "foo", "gene3",
                                         colGeometryName = "cg")))
})

localResults(sfe3,
    name = "foo", colGeometryName = "coords",
    sample_id = "all"
) <- toy_df1
test_that("localResults getter for colGeometry, one of two samples", {
    lr <- localResults(sfe3,
        sample_id = "sample02", name = "foo",
        colGeometryName = "coords"
    )
    expect_true(is.list(lr))
    expect_equal(lr$gene1, toy_res1[4:5, ], ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b[4:5, ], ignore_attr = "class")
    # One feature
    lr <- localResult(sfe3,
        feature = "gene1", sample_id = "sample02",
        type = "foo", colGeometryName = "coords"
    )
    expect_equal(lr, toy_res1[4:5, ], ignore_attr = "class")
})

test_that("localResults getter for colGeometry, all samples", {
    lr <- localResults(sfe3,
        sample_id = "all", name = "foo",
        colGeometryName = "coords"
    )
    expect_true(is.list(lr))
    expect_equal(lr$gene1, toy_res1, ignore_attr = "class")
    expect_equal(lr$gene2, toy_res1b, ignore_attr = "class")
    # One feature
    lr <- localResult(sfe3,
        sample_id = "all", type = "foo",
        feature = "gene1", colGeometryName = "coords"
    )
    expect_equal(lr, toy_res1, ignore_attr = "class")
})

localResults(sfe, name = "bar", annotGeometryName = "ag") <- toy_df1[1, ]
test_that("localResults getter for annotGeometry, one sample", {
    lr <- localResult(sfe,
        type = "bar", feature = "gene2",
        annotGeometryName = "ag"
    )
    expect_equal(lr[1, ], toy_res1b[1, ], ignore_attr = "class")
})

test_that("localResultFeatures for annotGeometry", {
    expect_equal(localResultFeatures(sfe, "bar", annotGeometryName = "ag"),
                 names(toy_df1))
    expect_true(is.null(localResultFeatures(sfe, "purr",
                                            annotGeometryName = "ag")))
})

test_that("localResultAttrs for annotGeometry", {
    expect_equal(localResultAttrs(sfe, "bar", "gene2",
                                  annotGeometryName = "ag"),
                 c("meow", "purr"))
    expect_true(is.null(localResultAttrs(sfe, "purr", "gene1",
                                         annotGeometryName = "ag")))
    expect_true(is.null(localResultAttrs(sfe, "bar", "gene3",
                                         annotGeometryName = "ag")))
})

localResults(sfe3,
    name = "foo", annotGeometryName = "ag",
    sample_id = "all"
) <- toy_df1[seq_len(2), ]
test_that("localResults getter for annotGeometry, one of two samples", {
    lr <- localResult(sfe3,
        type = "foo", feature = "gene1",
        annotGeometryName = "ag",
        sample_id = "sample02"
    )
    expect_equal(lr[1, ], toy_res1[2, ], ignore_attr = "class")
})

test_that("localResults getter for annotGeometry, all samples", {
    lr <- localResult(sfe3,
        type = "foo", feature = "gene2",
        annotGeometryName = "ag",
        sample_id = "all"
    )
    expect_equal(lr, toy_res1b[seq_len(2), ], ignore_attr = "class")
})

test_that("localResultNames", {
    nms <- localResultNames(sfe)
    expect_equal(nms, c("foo", "bar"))
    localResultNames(sfe) <- c("Moran", "Geary")
    expect_equal(names(int_colData(sfe)$localResults), c("Moran", "Geary"))
})

test_that("When features are absent in the results", {
    # Error when all absent
    expect_error(
        localResult(sfe, type = "foo", feature = "purr"),
        "None of the features"
    )
    # Warning when some absent
    expect_warning(
        localResults(sfe, name = "foo", features = c("gene1", "purr")),
        "are absent in"
    )
})

test_that("When a type of localResult is absent", {
    expect_error(localResult(sfe, type = "purr", feature = "purr"), "not in")
})
