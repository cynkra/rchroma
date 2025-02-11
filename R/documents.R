#' Add Documents to a Collection
#'
#' @param client A ChromaDB client object
#' @param collection_name Name of the collection
#' @param documents List of documents to add
#' @param ids Vector of unique IDs for the documents (required)
#' @param metadatas List of metadata for each document (optional)
#' @param embeddings Optional pre-computed embeddings
#' @param uris Optional vector of URIs associated with the documents
#' @param tenant The tenant name (default: "default")
#' @param database The database name (default: "default")
#'
#' @return TRUE on success
#' @export
add_documents <- function(
  client,
  collection_name,
  documents,
  ids,
  metadatas = NULL,
  embeddings = NULL,
  uris = NULL,
  tenant = "default_tenant",
  database = "default_database"
) {
  # First get the collection to get its ID
  collection <- get_collection(
    client,
    collection_name,
    tenant = tenant,
    database = database
  )

  endpoint <- paste0(
    "/tenants/",
    tenant,
    "/databases/",
    database,
    "/collections/",
    collection$id,
    "/add"
  )

  body <- list(
    documents = documents,
    ids = ids,
    metadatas = metadatas,
    embeddings = embeddings,
    uris = uris
  )

  make_request(client$req, endpoint, body = body, method = "POST")
}

#' Update Documents in a Collection
#'
#' @param client A ChromaDB client object
#' @param collection_name Name of the collection
#' @param ids Vector of document IDs to update
#' @param documents List of new document contents
#' @param metadatas List of new metadata
#' @param embeddings Optional new pre-computed embeddings
#' @param tenant The tenant name (default: "default")
#' @param database The database name (default: "default")
#'
#' @return NULL invisibly on success
#' @export
update_documents <- function(
  client,
  collection_name,
  ids,
  documents = NULL,
  metadatas = NULL,
  embeddings = NULL,
  tenant = "default_tenant",
  database = "default_database"
) {
  # First get the collection to get its ID
  collection <- get_collection(
    client,
    collection_name,
    tenant = tenant,
    database = database
  )

  endpoint <- paste0(
    "/tenants/",
    tenant,
    "/databases/",
    database,
    "/collections/",
    collection$id,
    "/update"
  )

  # Ensure ids is a list
  if (is.character(ids)) {
    ids <- as.list(ids)
  }

  body <- list(
    ids = ids,
    documents = documents,
    metadatas = metadatas,
    embeddings = embeddings
  )
  resp <- make_request(client$req, endpoint, body = body, method = "POST")
  invisible(NULL)
}

#' Delete Documents from a Collection
#'
#' @param client A ChromaDB client object
#' @param collection_name Name of the collection
#' @param ids Vector of document IDs to delete
#' @param where Optional filtering conditions
#' @param tenant The tenant name (default: "default")
#' @param database The database name (default: "default")
#'
#' @return NULL invisibly on success
#' @export
delete_documents <- function(
  client,
  collection_name,
  ids = NULL,
  where = NULL,
  tenant = "default_tenant",
  database = "default_database"
) {
  # First get the collection to get its ID
  collection <- get_collection(
    client,
    collection_name,
    tenant = tenant,
    database = database
  )

  endpoint <- paste0(
    "/tenants/",
    tenant,
    "/databases/",
    database,
    "/collections/",
    collection$id,
    "/delete"
  )
  body <- list()
  if (!is.null(ids)) {
    if (is.character(ids)) {
      ids <- as.list(ids)
    }
    body$ids <- ids
  }
  if (!is.null(where)) body$where <- where
  resp <- make_request(client$req, endpoint, body = body, method = "POST")
  invisible(NULL)
}

#' Upsert Documents to a Collection
#'
#' @param client A ChromaDB client object
#' @param collection_name Name of the collection
#' @param documents List of documents to upsert
#' @param metadatas List of metadata for each document
#' @param ids Vector of unique IDs for the documents
#' @param embeddings Optional pre-computed embeddings
#' @param uris Optional vector of URIs associated with the documents
#'
#' @return Response from the API
#' @export
upsert_documents <- function(
  client,
  collection_name,
  documents,
  metadatas = NULL,
  ids = NULL,
  embeddings = NULL,
  uris = NULL
) {
  endpoint <- paste0("/collections/", collection_name, "/upsert")

  if (is.null(ids)) {
    ids <- paste0("id_", seq_along(documents))
  }

  body <- list(
    documents = documents,
    ids = ids
  )

  if (!is.null(metadatas)) body$metadatas <- metadatas
  if (!is.null(embeddings)) body$embeddings <- embeddings
  if (!is.null(uris)) body$uris <- uris

  make_request(client$req, endpoint, body = body, method = "POST")
}
