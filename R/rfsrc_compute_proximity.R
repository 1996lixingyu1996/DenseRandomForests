#' @export
rfsrc_compute_proximity <- function(membership=NULL, inbag=NULL, oob=c("ALL","OOB")){
  if(is.null(membership)){
    stop("membership is null!")
  }
  
  if(oob=="OOB" & is.null(inbag)){
    stop("inbag is null when OOB is true!")
  }
  if(is.data.frame(membership)){
    membership = as.matrix(membership)
  }
  if(oob == "OOB"){
    if(is.data.frame(inbag)){
      inbag = as.matrix(inbag)
    }
  }

  if(!is.integer(membership)){
    storage.mode(membership) <- "integer"
  }
  if(!is.integer(inbag)){
    storage.mode(inbag) <- "integer"
  }
  
  ntree = ncol(membership)
  n = nrow(membership)
  
  if (oob == "ALL"){
    result = tryCatch({.Call("compute_proximity_all", (as.matrix(membership)),
                             as.integer(n),as.integer(ntree))})
  }else{
    result = tryCatch({.Call("compute_proximity_oob", (as.matrix(membership)),
                             (as.matrix(inbag)),as.integer(n),as.integer(ntree))})
  }
  result
}
