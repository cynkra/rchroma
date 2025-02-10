# #' Create a Collection in ChromaDB
# #'
# #' @param client A ChromaDB client object
# #' @param name The name of the collection
# #' @param metadata Optional metadata for the collection
# #' @param configuration Optional configuration for the collection. For HNSW configuration,
# #'   use a list with `hnsw_space` (e.g., "cosine", "l2", "ip").
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #' @param get_or_create Whether to get the collection if it exists (default: FALSE)
# #'
# #' @return A collection object
# #' @export
# create_collection <- function(client, name, metadata = NULL, configuration = NULL,
#                             tenant = "default", database = "default",
#                             get_or_create = FALSE) {
#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections")

#   body <- list(
#     name = name,
#     metadata = metadata,
#     get_or_create = get_or_create
#   )

#   # Add configuration if provided
#   if (!is.null(configuration)) {
#     if (!is.null(configuration$hnsw_space)) {
#       valid_spaces <- c("cosine", "l2", "ip")
#       if (!configuration$hnsw_space %in% valid_spaces) {
#         stop("Invalid hnsw_space. Must be one of: ", paste(valid_spaces, collapse = ", "))
#       }
#       body$configuration <- list(
#         hnsw_configuration = list(
#           space = configuration$hnsw_space,
#           `_type` = "HNSWConfigurationInternal"
#         ),
#         `_type` = "CollectionConfigurationInternal"
#       )
#     } else {
#       body$configuration <- configuration
#     }
#   }

#   resp <- tryCatch({
#     client$req |>
#       httr2::req_url_path_append(endpoint) |>
#       httr2::req_method("POST") |>
#       httr2::req_body_json(body) |>
#       httr2::req_perform()
#   }, error = function(e) {
#     if (inherits(e, "httr2_error")) {
#       err_body <- httr2::resp_body_json(e$resp)
#       stop(err_body$error)
#     }
#     handle_chroma_error(e, "Failed to create collection")
#   })

#   httr2::resp_body_json(resp)
# }

# #' Get a Collection
# #'
# #' @param client A ChromaDB client object
# #' @param name The name of the collection
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #'
# #' @return A collection object
# #' @export
# get_collection <- function(client, name, tenant = "default", database = "default") {
#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections/", name)

#   resp <- tryCatch({
#     client$req |>
#       httr2::req_url_path_append(endpoint) |>
#       httr2::req_method("GET") |>
#       httr2::req_perform()
#   }, error = function(e) {
#     handle_chroma_error(e, "Failed to get collection")
#   })

#   httr2::resp_body_json(resp)
# }

# #' Delete a Collection
# #'
# #' @param client A ChromaDB client object
# #' @param name The name of the collection
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #'
# #' @return Invisible NULL on success
# #' @export
# delete_collection <- function(client, name, tenant = "default", database = "default") {
#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections/", name)

#   resp <- tryCatch({
#     client$req |>
#       httr2::req_url_path_append(endpoint) |>
#       httr2::req_method("DELETE") |>
#       httr2::req_perform()
#   }, error = function(e) {
#     if (inherits(e, "httr2_error")) {
#       err_body <- httr2::resp_body_json(e$resp)
#       stop(err_body$error)
#     }
#     handle_chroma_error(e, "Failed to delete collection")
#   })

#   invisible(NULL)
# }

# #' Update a Collection
# #'
# #' @param client A ChromaDB client object
# #' @param name The name of the collection
# #' @param new_name Optional new name for the collection
# #' @param new_metadata Optional new metadata for the collection
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #'
# #' @return NULL on success (invisibly)
# #' @export
# update_collection <- function(client, name, new_name = NULL, new_metadata = NULL,
#                             tenant = "default", database = "default") {
#   # First get the collection to get its ID
#   collection <- get_collection(client, name, tenant = tenant, database = database)

#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections/", collection$id)

#   body <- list(
#     new_name = new_name,
#     new_metadata = new_metadata
#   )

#   resp <- tryCatch({
#     client$req |>
#       httr2::req_url_path_append(endpoint) |>
#       httr2::req_method("PUT") |>
#       httr2::req_body_json(body) |>
#       httr2::req_perform()
#   }, error = function(e) {
#     if (inherits(e, "httr2_error")) {
#       err_body <- httr2::resp_body_json(e$resp)
#       stop(err_body$error)
#     }
#     handle_chroma_error(e, "Failed to update collection")
#   })

#   invisible(NULL)
# }

# #' Count Collections in a Database
# #'
# #' @param client A ChromaDB client object
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #'
# #' @return Number of collections in the database
# #' @export
# count_collections <- function(client, tenant = "default", database = "default") {
#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections_count")

#   resp <- tryCatch({
#     client$req |>
#       httr2::req_url_path_append(endpoint) |>
#       httr2::req_method("GET") |>
#       httr2::req_perform()
#   }, error = function(e) {
#     handle_chroma_error(e, "Failed to count collections")
#   })

#   httr2::resp_body_json(resp)
# }

# #' List Collections in a Database
# #'
# #' @param client A ChromaDB client object
# #' @param tenant The tenant name (default: "default")
# #' @param database The database name (default: "default")
# #' @param limit Maximum number of collections to return (optional)
# #' @param offset Number of collections to skip (optional)
# #'
# #' @return List of collections
# #' @export
# list_collections <- function(client, tenant = "default", database = "default",
#                            limit = NULL, offset = NULL) {
#   endpoint <- paste0("/tenants/", tenant, "/databases/", database, "/collections")

#   # Build query parameters
#   query <- list()
#   if (!is.null(limit)) query$limit <- limit
#   if (!is.null(offset)) query$offset <- offset

#   resp <- tryCatch({
#     req <- client$req |>
#       httr2::req_url_path_append(endpoint)

#     # Add query parameters if any
#     if (length(query) > 0) {
#       req <- req |> httr2::req_url_query(!!!query)
#     }

#     req |>
#       httr2::req_method("GET") |>
#       httr2::req_perform()
#   }, error = function(e) {
#     handle_chroma_error(e, "Failed to list collections")
#   })

#   httr2::resp_body_json(resp)
# }
