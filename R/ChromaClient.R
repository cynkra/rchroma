make_request <- function(base, endpoint, params = list(), type = "GET") {
  req <- httr2::req_url_path_append(base, endpoint)
  req <- httr2::req_method(req, type)

  if (length(params != 0)) {
    if (type == "POST") {
      req <- httr2::req_body_json(req, !!!params)
    } else if (type == "GET") {
      req <- httr2::req_url_query(req, !!!params)
    }
  }
  resp <- httr2::req_perform(req) #TODO: add error handler
  httr2::resp_body_json(resp)
}

#' @description
#' This R6 class provides methods to connect and interact with a running ChromaDB instance.
#'
#' @export
ChromaClient <- R6::R6Class(
  "ChromaClient",
  public = list(
    #' @field base_url The base URL of the ChromaDB instance.
    base_url = NULL,
    #' @field req A request object created with `httr2::request()`.
    req = NULL,
    #' @title Initialize the ChromaClient instance
    #'
    #' @description
    #' This function initializes a connection to the ChromaDB API.
    #'
    #' @param host The hostname of the ChromaDB server (default: `"http://localhost"`).
    #' @param port The port on which ChromaDB is running (default: `8000`).
    #' @param api_path API path for ChromaDB (default: `"/api/v2"`).
    #' @return A ChromaClient object.
    ############# connection.R #############
    initialize = function(
      host = "http://localhost",
      port = 8000L,
      api_path = "/api/v2"
    ) {
      self$base_url <- glue::glue("{host}:{port}{api_path}")
      self$req <- httr2::request(self$base_url)
    },
    #' @description Validate a ChromaDB connection
    #' @return TBD
    validate = function() {
      tryCatch(
        {
          resp <- httr2::req_perform(self$req)
          if (httr2::resp_status(resp) == 200) {
            cli::cli_alert_success("ChromaDB is running")
          }
        },
        error = function(e) {
          cli::cli_abort(
            paste0(
              "Could not connect to ChromaDB at ",
              self$base_url,
              "\n\n",
              "To run ChromaDB:\n",
              "1. Install Docker from https://www.docker.com\n",
              "2. Run ChromaDB using Docker:\n",
              "   docker run -p 8000:8000 chromadb/chroma\n\n",
              "Original error: ",
              e$message
            )
          )
        }
      )
    },
    #' @description Get ChromaDB Server Version
    #'
    #' @return Server version string
    version = function() {
      make_request(self$req, "version")
    },
    #' @description Get ChromaDB Server Information
    #'
    #' @details Returns server capabilities and settings.
    #'
    #'
    #' @return List containing server information
    server_info = function() {
      make_request(self$req, "pre-flight-checks")
    },
    #' @description Check ChromaDB Server Heartbeat
    #'
    #' @return Server heartbeat response as a numeric value
    heartbeat = function() {
      resp <- make_request(self$req, "heartbeat")
      resp$`nanosecond heartbeat`
    },
    #' @description Get Authentication Identity
    #'
    #' @return Authentication identity information
    auth_identity = function() {
      make_request(self$req, "auth/identity")
    },
    #' @description Reset ChromaDB Database
    #'
    #' @details This function resets the entire database. Use with caution as this will delete all data.
    #' Note: This function requires setting ALLOW_RESET=TRUE in the environment variables
    #' or allow_reset=True in the ChromaDB Settings.
    #'
    #'
    #' @return TRUE on success
    reset_database = function() {
      make_request(self$req, "rest", type = "POST")
    },
    ############# collections.R #############
    #' @description Create a Collection in ChromaDB
    #'
    #' @param name The name of the collection
    #' @param metadata Optional metadata for the collection
    #' @param configuration Optional configuration for the collection. For HNSW configuration,
    #'   use a list with `hnsw_space` (e.g., "cosine", "l2", "ip").
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #' @param get_or_create Whether to get the collection if it exists (default: FALSE)
    #'
    #' @return A collection object
    create_collection = function(
      name,
      metadata = NULL,
      configuration = NULL,
      tenant = "default",
      database = "default",
      get_or_create = FALSE
    ) {
      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections"
      )

      params <- list(
        name = name,
        metadata = metadata,
        get_or_create = get_or_create
      )

      if (!is.null(configuration)) {
        if (!is.null(configuration$hnsw_space)) {
          valid_spaces <- c("cosine", "l2", "ip")
          if (!configuration$hnsw_space %in% valid_spaces) {
            cli::cli_abort(
              "Invalid hnsw_space. Must be one of: ",
              paste(valid_spaces, collapse = ", ")
            )
          }
          params$configuration <- list(
            hnsw_configuration = list(
              space = configuration$hnsw_space,
              `_type` = "HNSWConfigurationInternal"
            ),
            `_type` = "CollectionConfigurationInternal"
          )
        } else {
          params$configuration <- configuration
        }
      }
      make_request(self$req, endpoint, params = params, type = "POST")
    },
    #' @description Get a Collection
    #'
    #' @param name The name of the collection
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #'
    #' @return A collection object
    get_collection = function(name, tenant = "default", database = "default") {
      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/{name}"
      )
      make_request(self$req, endpoint)
    },
    #' @description Delete a Collection
    #'
    #' @param name The name of the collection
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #'
    #' @return Invisible NULL on success
    delete_collection = function(
      name,
      tenant = "default",
      database = "default"
    ) {
      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/{name}"
      )
      make_request(self$req, endpoint, type = "DELETE")
    },
    #' @description Update a Collection
    #'
    #' @param name The name of the collection
    #' @param new_name Optional new name for the collection
    #' @param new_metadata Optional new metadata for the collection
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #'
    #' @return NULL on success (invisibly)
    update_collection = function(
      name,
      new_name = NULL,
      new_metadata = NULL,
      tenant = "default",
      database = "default"
    ) {
      collection <- self$get_collection(
        self$req,
        name,
        tenant = tenant,
        database = database
      )

      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/{collection$id}"
      )

      params <- list(
        new_name = new_name,
        new_metadata = new_metadata
      )

      make_request(self$req, endpoint, params = params, type = "PUT")
    },
    #' @description Count Collections in a Database
    #'
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #'
    #' @return Number of collections in the database
    count_collections = function(tenant = "default", database = "default") {
      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections_count"
      )
      make_request(self$req, endpoint)
    },
    #' @description List Collections in a Database
    #'
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #' @param limit Maximum number of collections to return (optional)
    #' @param offset Number of collections to skip (optional)
    #'
    #' @return List of collections
    list_collections = function(
      tenant = "default",
      database = "default",
      limit = NULL,
      offset = NULL
    ) {
      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/"
      )
      params <- list(
        limit = limit,
        offset = offset
      )

      make_request(self$req, endpoint, params = params)
    },
    #' @description Create a Database
    #'
    #' @param name The name of the database
    #' @param tenant The tenant name
    #'
    #' @return NULL invisibly on success
    create_database = function(name, tenant = "default") {
      endpoint <- glue::glue("/tenants/{tenant}/databases")

      params <- list(name = name)
      make_request(self$resp, endpoint, params, type = "POST")
      invisible(NULL)
    },
    #' @description Get a Database
    #'
    #' @param name The name of the database
    #' @param tenant The tenant name
    #'
    #' @return TODO
    #' @export
    get_database = function(name, tenant = "default") {
      endpoint <- glue::glue("/tenants/{tenant}/databases/{name}")
      make_request(self$req, endpoint)
    },
    ################ documents.R ################
    #' @description Add Documents to a Collection
    #'
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
    add_documents = function(
      collection_name,
      documents,
      ids,
      metadatas = NULL,
      embeddings = NULL,
      uris = NULL,
      tenant = "default",
      database = "default"
    ) {
      collection <- self$get_collection(
        collection_name,
        tenant = tenant,
        database = database
      )

      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/collection$id}/add"
      )

      params <- list(
        documents = documents,
        ids = ids,
        metadatas = metadatas,
        embeddings = embeddings,
        uris = uris
      )

      make_request(self$req, endpoint, params = params, type = "POST")
    },
    #' @description Update Documents in a Collection
    #'
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
    update_documents = function(
      collection_name,
      ids,
      documents = NULL,
      metadatas = NULL,
      embeddings = NULL,
      tenant = "default",
      database = "default"
    ) {
      collection <- self$get_collection(
        client,
        collection_name,
        tenant = tenant,
        database = database
      )

      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/{collection$id}/update"
      )
      if (is.character(ids)) {
        ids <- as.list(ids)
      }
      params <- list(
        ids = ids,
        documents = documents,
        metadatas = metadatas,
        embeddings = embeddings
      )
      make_request(sel$req, endpoint, params, type = "POST")
    },
    #' @description Delete Documents from a Collection
    #'
    #' @param collection_name Name of the collection
    #' @param ids Vector of document IDs to delete
    #' @param where Optional filtering conditions
    #' @param tenant The tenant name (default: "default")
    #' @param database The database name (default: "default")
    #'
    #' @return NULL invisibly on success
    #' @export
    delete_documents = function(
      collection_name,
      ids,
      where = NULL,
      tenant = "default",
      database = "default"
    ) {
      collection <- self$get_collection(
        client,
        collection_name,
        tenant = tenant,
        database = database
      )

      endpoint <- glue::glue(
        "/tenants/{tenant}/databases/{database}/collections/{collection$id}/delete"
      )
      if (is.character(ids)) {
        ids <- as.list(ids)
      }
      params <- list(
        ids = ids,
        where = where
      )
      make_request(sel$req, endpoint, params, type = "POST") #TODO: check if needs to be delete
    },
    ################ query ################
    #' @description Query Documents in a Collection
    #'
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
    #' result <- query_collection(client, "my_collection",
    #'                          query_embeddings = list(text_embedding))
    #' ```
    #'
    #' @return A list containing the query results. Each element (documents, metadatas, distances)
    #'         is a nested list, so use double brackets [[]] to access individual elements.
    #' @export
    query_collection = function(
      collection_name,
      query_embeddings,
      n_results = 10L,
      where = NULL,
      where_document = NULL,
      include = c("documents", "metadatas", "distances"),
      tenant = "default",
      database = "default"
    ) {
      collection <- self$get_collection(
        client,
        collection_name,
        tenant = tenant,
        database = database
      )

      endpoint <- paste0(
        "/tenants/{tenant}/databases/{database}/collections/{collection$id}/query"
      )

      # Ensure query_embeddings is a list of numeric vectors
      if (!is.list(query_embeddings)) {
        cli::cli_abort(
          "{.var query_embeddings} must be a list of numeric vectors"
        )
      }
      if (!all(sapply(query_embeddings, is.numeric))) {
        cli::cli_abort(
          "All elements in {.var query_embeddings} must be numeric vectors"
        )
      }

      # Ensure include is a list
      if (is.character(include)) {
        include <- as.list(include)
      }

      params <- list(
        query_embeddings = query_embeddings,
        n_results = n_results,
        include = include,
        where = where,
        where_document = where_document
      )
      make_request(self$req, endpoint, params, type = "POST")
    },
    ############## tenants.R ##############
    #' @description Create a Tenant
    #'
    #' @param name The name of the tenant
    #'
    #' @return TODO
    #' @export
    create_tenant = function(name) {
      endpoint <- "/tenants"

      params <- list(name = name)
      make_request(self$req, endpoint, params, "POST")
    },
    #' @description Get a Tenant
    #'
    #' @param name The name of the tenant
    #'
    #' @return A tenant object containing the tenant details
    #' @export
    get_tenant = function(name) {
      endpoint <- glue::glue("/tenants/{name}")
      make_request(self$req, endpoint)
    }
  )
)
