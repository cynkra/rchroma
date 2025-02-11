#' Create a Tenant
#'
#' @param client A ChromaDB client object
#' @param name The name of the tenant
#'
#' @return A tenant object containing the tenant details
#' @export
create_tenant <- function(client, name) {
  body <- list(name = name)
  resp <- make_request(client$req, "tenants", body = body, method = "POST")
  get_tenant(client, name)
}

#' Get a Tenant
#'
#' @param client A ChromaDB client object
#' @param name The name of the tenant
#'
#' @return A tenant object containing the tenant details
#' @export
get_tenant <- function(client, name) {
  endpoint <- paste0("tenants/", name)
  make_request(client$req, endpoint)
}
