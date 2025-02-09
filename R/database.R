#' Create a Database
#'
#' @param client A ChromaDB client object
#' @param name The name of the database
#' @param tenant The tenant name
#'
#' @return NULL invisibly on success
#' @export
create_database <- function(client, name, tenant = "default") {
  endpoint <- paste0("/tenants/", tenant, "/databases")

  body <- list(name = name)

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_method("POST") |>
      httr2::req_body_json(body) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to create database")
  })

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
get_database <- function(client, name, tenant = "default") {
  endpoint <- paste0("/tenants/", tenant, "/databases/", name)

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_method("GET") |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get database")
  })

  invisible(NULL)
}