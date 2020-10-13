#' Search the top enriched pathways for RAV
#'
#' @param PCAmodel PCAGenomicSignatures object.
#' @param ind An integer for RAV you want to check the enriched pathways.
#' @param n A number of top enriched pathways to output. Default is 5.
#' @param abs Default is \code{FALSE}. If it's set to \code{TRUE}, the enriched
#' pathways will be listed based on \code{abs(NES)}.
#'
#' @return A data frame with \code{n} rows and 4 columns; Description, NES, pvalue, and qval
#'
#' @examples
#' data(miniPCAmodel)
#' library(bcellViper)
#' data(bcellViper)
#' annotatePCcluster(miniPCAmodel, ind = 695)
#' #                 Description      NES pvalue      qvalues
#' # 1 IRIS_Bcell-Memory_IgG_IgA 2.763472  1e-10 5.824561e-09
#' # 2              DMAP_BCELLA3 2.726775  1e-10 5.824561e-09
#' # 3     IRIS_Bcell-Memory_IgM 2.701570  1e-10 5.824561e-09
#' # 4          IRIS_Bcell-naive 2.699145  1e-10 5.824561e-09
#' # 5              DMAP_BCELLA4 2.698821  1e-10 5.824561e-09
#'
#' @export
annotatePCcluster <- function(PCAmodel, ind, n = 5, abs = FALSE) {
  cl_name <- paste0("PCcluster", ind)
  annotatedCluster <- gsea(PCAmodel)[[cl_name]]
  if (isTRUE(abs)) {
    topAnnotation <- annotatedCluster[order(abs(annotatedCluster$NES), decreasing = TRUE),,drop = FALSE][1:n,]
  } else {
    topAnnotation <- annotatedCluster[order(annotatedCluster$NES, decreasing = TRUE),,drop = FALSE][1:n,]
  }
  rownames(topAnnotation) <- NULL
  return(topAnnotation)
}