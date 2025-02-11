#' Create a Database
#'
#' @param client A ChromaDB client object
#' @param name The name of the database
#' @param tenant The tenant name
#'
#' @return NULL invisibly on success
#' @export
create_database <- function(client, name, tenant = "default_tenant") {
  endpoint <- paste0("/tenants/", tenant, "/databases")

  body <- list(name = name)
  resp <- make_request(client$req, endpoint, body = body, method = "POST")
  invisible(NULL)
}

#' Get a Database
#'
#' @param client A ChromaDB client object
#' @param name The name of the database
#' @param tenant The tenant name
#'
#' @return NULL invisibly on success
#' @export
get_database <- function(client, name, tenant = "default_tenant") {
  endpoint <- paste0("/tenants/", tenant, "/databases/", name)
  make_request(client$req, endpoint)
}
