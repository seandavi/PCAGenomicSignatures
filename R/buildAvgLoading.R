#' Calculate Silhouette Information of RAVs
#'
#' @description The silhouette value is a measure of how similar an object is to
#' its own cluster (cohesion) compared to other clusters (separation). The silhouette
#' ranges from -1 to +1, where a high value indicates that the object is well matched
#' to its own cluster and poorly matched to neighboring clusters.
#'
#' @param dat A matrix with all the top PCs from training data to be clustered.
#' @param kmeansRes Output from \code{stats::kmeans}.
#'
#' @return Silhouette-class object, which is an n x 3 matrix with attributes.
#'
#' @seealso \code{\link[stats]{kmeans}}
#'
.calculateSilhouetteWidth <- function (dat, kmeansRes) {
    swRes <- cluster::silhouette(x = kmeansRes$cluster,
                                 dist = cluster::daisy(dat))
    SW <- summary(swRes)
    return(SW)
}

#' Find the studies contributing each RAV
#'
#' @param RAVmodel PCAGenomicSignatures object.
#' @param ind A numeric vector containing the RAV indexes. Under the default (\code{NULL}),
#' studies associated with all the RAV indexes will be returned as a list.
#' @param studyTitle Default is \code{FALSE}. This parameter is effective only when
#' the \code{index} value is specificed. If it's \code{TRUE}, the output will be
#' a data frame with the study
#'
#' @return A list of character vector. Under the default condition (\code{ind = NULL}),
#' all the RAVs will be checked for their contributing studies and the length
#' of the list will be same as the number of RAVs (= \code{metadata(x)$k}). If you
#' provide the \code{ind} argument, studies associated with only the specified RAVs
#' will be returned.
#'
#' @note Mainly used for model building, within \link{buildAvgLoading}.
#' @export
findStudiesInCluster <- function(RAVmodel, ind = NULL, studyTitle = FALSE) {

    if (is(RAVmodel,"PCAGenomicSignatures")) {
        x <- S4Vectors::metadata(RAVmodel)
        k <- x$k   # the number of clusters
    } else if (is.list(RAVmodel)) {   # [internal] this is for model building
        x <- RAVmodel
        x$size <- table(RAVmodel$cluster)
        k <- length(unique(RAVmodel$cluster))
    }

    # z is a binary matrix showing the cluster membership of PCs
    z <- matrix(0, ncol = k, nrow = sum(x$size))
    for (i in seq_along(x$cluster)) {
        z[i, x$cluster[i]] <- 1
    }
    colnames(z) <- paste0("Cl", k, "_",
                          formatC(seq_len(k), width=2, format="d", flag="0"))
    rownames(z) <- names(x$cluster)

    if (is.null(ind)) {
        studies <- list()
        for (i in seq_len(ncol(z))) {
            studies[[i]] <- rownames(z)[which(z[,i] == 1)]
            studies[[i]] <- lapply(studies[[i]],
                                   function(x) {unlist(strsplit(x, "\\."))[1]})
            studies[[i]] <- unique(unlist(studies[[i]]))
            names(studies)[i] <- colnames(z)[i]
            res <- studies
        }
    } else {
        for (i in ind) {
            studies <- rownames(z[which(z[,i] == 1),])
            studies <- lapply(studies,
                              function(x) {unlist(strsplit(x, "\\."))[1]})
            res <- studies <- unique(unlist(studies))
        }

        if (studyTitle) {
            dir <- system.file("extdata", package = "GenomicSuperSignature")
            studyMeta <- utils::read.table(file.path(dir, "studyMeta.tsv"))
            studyMeta <- studyMeta[,c("studyName", "title")]
            res <- studyMeta[which(studyMeta$studyName %in% studies),]
        }
    }
    return(res)
}


#' Calculate average loadings of each cluster
#'
#' @param dat A data frame. Each row represents principle components from different
#' training datasets. Each column represents genes used for PCA analysis.
#' @param k The number of clusters used for hierarchical clustering
#' @param n The number of top principle components from each datasets used for
#' model building. Default is 20.
#' @param study Under default (\code{TRUE}), studies involved in each cluster
#' will be added in the output.
#' @param cluster Provide pre-defined cluster membership of your data.
#'
#' @return
#' A named list of 6 elements is returned. It contains:
#' \describe{
#'    \item{\code{cluster}}{A numeric vector on cluster membership of PCs}
#'    \item{\code{size}}{A integer vector on the size of clusters}
#'    \item{\code{avgLoading}}{A matrix of average loadings. Columns for clusters and rows for genes}
#'    \item{\code{k}}{The number of clusters}
#'    \item{\code{n}}{The number of top PCs used for clustering}
#'    \item{\code{studies}}{A list of character vector containing studies in each cluster}
#' }
#'
#' @export
buildAvgLoading <- function(dat, k, n = 20, cluster = NULL, study = TRUE) {

    # Input validation
    if (missing(k)) {stop("`k` must be provided.")}
    if (!is.null(cluster)) {
        k <- length(unique(cluster))
        x <- table(cluster) %>% as.data.frame()
        res <- list(cluster = cluster, size = x$Freq)
    } else {
        stop("Error: Cluster membership of elements should be provided through 'cluster' argument.")
    }
    stopifnot(length(study) == 1L, !is.na(study), is.logical(study))


    # Separate the PC table into each cluster
    cl_ls <- vector(mode = "list", length = k)
    for (i in seq_len(k)) {
        datName <- paste0("Cl", k, "_",
                          formatC(i, width = 2, format = "d", flag = "0"))
        cl_ls[[i]] <- dat[, res$cluster==i, drop=FALSE] %>% t
        names(cl_ls)[i] <- datName
    }

    # the number of unique datasets in each cluster
    unique_sets <- vector(length = k)
    for (i in seq_len(k)) {
        dat <- cl_ls[[i]]
        dataSetName <- gsub(".PC\\d+$", "", rownames(dat))
        uniqueDataSetName <- length(unique(dataSetName))
        unique_sets[i] <- uniqueDataSetName
    }

    # Calculate the average of loadings in each cluster
    names(cl_ls) <- paste0(names(cl_ls), " (", res$size, "/", unique_sets, ")")
    l <- ncol(dat)   # the number of genes for average loading
    avg.loadings <- vapply(cl_ls, colMeans, FUN.VALUE = numeric(l))

    # Save avgloading, and 'studies in cluster'
    res$avgLoading <- as.matrix(avg.loadings)
    res$k <- k
    res$n <- n

    # # Silhouette Width
    # sw <- .calculateSilhouetteWidth(dat, res)
    # res$sw <- sw

    if (study) {res$studies <- findStudiesInCluster(res)}
    return(res)
}

