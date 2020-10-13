s2p_get_cache <- function(cache = rappdirs::user_cache_dir(appname='pca_genomic_signatures')) {
  BiocFileCache::BiocFileCache(cache=cache)
}

#' @importFrom BiocFileCache bfcneedsupdate bfcdownload bfcadd bfcquery bfcrpath
#'
s2p_cached_url <- function(url, rname = url, ask_on_update=FALSE,
                           max_cache_age=getOption('sars2pack.max_cache_age', '2 days'),
                           ...) {
  bfc = s2p_get_cache()
  bfcres = bfcquery(bfc,rname,'rname')

  rid = bfcres$rid
  # Not found
  fileage = 0
  if(!length(rid)) {
    rid = names(bfcadd(bfc, rname, url))
  }
  # if needs update, do the download
  if(bfcneedsupdate(bfc, rid)) {
    bfcdownload(bfc, rid, ask=FALSE, ...)
    print("downloading")
  }
  bfcrpath(bfc, rids = rid)
}




#' Download a PCAGenomicSignatures model
#'
#' @param prior The name of gene sets used to annotate PCAGenomicSignatures. Currently
#' there are two available options.
#' \itemize{
#'     \item \code{C2} : MSigDB C2 (curated gene sets)
#'     \item \code{PLIERpriors} : bloodCellMarkersIRISDMAP, svmMarkers, and canonicalPathways
#' }
#' @return PCAGenomicSignatures object in \code{.rds} format saved in the current location.
#'
#' @export
getModel <- function(prior = c("C2", "PLIERpriors")) {

  if (!prior %in% c("C2", "PLIERpriors")) {
    stop("Prior you entered isn't available yet.")
  }

  bucket_name <- "pca_genomic_signatures"
  fname <- paste0("PCAmodel_", prior, ".rds")
  fpath <- file.path('https://storage.googleapis.com',bucket_name, fname)

  fpath = s2p_cached_url(fpath)

  return(fpath)
}






# Download datasets used PCAGenomicSignatures manuscript
#
# getDataset <- function() {
# }