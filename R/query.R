#' Query Documents in a Collection
#'
#' @param client A ChromaDB client object
#' @param collection_name Name of the collection
#' @param query_embeddings List of query embeddings (must be a list of numeric vectors)
#' @param n_results Number of results to return per query (default: 10)
#' @param where Optional filtering conditions
#' @param where_document Optional document-based filtering conditions
#' @param include Optional vector of what to include in results. Possible values:
#'   "documents", "embeddings", "metadatas", "distances", "uris", "data"
#'   (default: c("documents", "metadatas", "distances"))
#' @param tenant The tenant name (default: "default")
#' @param database The database name (default: "default")
#'
#' @details
#' Note that ChromaDB's API only accepts embeddings for queries. If you want to query using
#' text, you need to first convert your text to embeddings using an embedding model
#' (e.g., using OpenAI's API, HuggingFace's API, or a local model).
#'
#' Example:
#' ```r
#' # First convert text to embeddings using your preferred method
#' text_embedding <- your_embedding_function("your search text")
#' # Then query using the embedding
#' result <- query(client, "my_collection",
#'                query_embeddings = list(text_embedding))
#' ```
#'
#' @return A list containing the query results. Each element (documents, metadatas, distances)
#'         is a nested list, so use double brackets [[]] to access individual elements.
#' @export
query <- function(
  client,
  collection_name,
  query_embeddings,
  n_results = 10L,
  where = NULL,
  where_document = NULL,
  include = c("documents", "metadatas", "distances"),
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
    "/query"
  )

  # Ensure query_embeddings is a list of numeric vectors
  if (!is.list(query_embeddings)) {
    stop("query_embeddings must be a list of numeric vectors")
  }
  if (!all(sapply(query_embeddings, is.numeric))) {
    stop("All elements in query_embeddings must be numeric vectors")
  }

  # Ensure include is a list
  if (is.character(include)) {
    include <- as.list(include)
  }

  body <- list(
    query_embeddings = query_embeddings,
    n_results = n_results,
    include = include,
    where = where,
    where_document = where_document
  )
  make_request(client$req, endpoint, body = body, method = "POST")
}
