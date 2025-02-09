#' Create a Tenant
#'
#' @param client A ChromaDB client object
#' @param name The name of the tenant
#'
#' @return A tenant object containing the tenant details
#' @export
create_tenant <- function(client, name) {
  endpoint <- "/tenants"

  body <- list(name = name)

  # Create tenant (returns null)
  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_method("POST") |>
      httr2::req_body_json(body) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to create tenant")
  })

  # Get tenant details
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
  endpoint <- paste0("/tenants/", name)

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_method("GET") |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get tenant")
  })

  httr2::resp_body_json(resp)
}