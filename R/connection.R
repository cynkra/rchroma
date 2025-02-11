#' ChromaDB Client
#'
#' Create a new ChromaDB client connection
#'
#' @param host The host URL of the ChromaDB server. Default is "http://localhost".
#' @param port The port number of the ChromaDB server. Default is 8000.
#' @param api_path The API path. Default is "/api/v2".
#' @param verify Whether to verify the connection. Default is TRUE.
#'
#' @return A ChromaDB client object
#' @export
chroma_connect <- function(
  host = "http://localhost",
  port = 8000L,
  api_path = "/api/v2",
  verify = TRUE
) {
  base_url <- paste0(host, ":", port, api_path)
  req <- httr2::request(base_url)

  # Test connection if verify is TRUE
  if (verify) {
    tryCatch(
      {
        httr2::req_perform(req)
      },
      error = function(e) {
        msg <- paste0(
          "Could not connect to ChromaDB at ",
          base_url,
          "\n\n",
          "To run ChromaDB:\n",
          "1. Install Docker from https://www.docker.com\n",
          "2. Run ChromaDB using Docker:\n",
          "   docker run -p 8000:8000 chromadb/chroma\n\n",
          "Original error: ",
          e$message
        )
        stop(msg)
      }
    )
  }

  structure(
    list(
      base_url = base_url,
      req = req
    ),
    class = "chroma_client"
  )
}

#' Get ChromaDB Server Version
#'
#' @param client A ChromaDB client object
#'
#' @return Server version string
#' @export
version <- function(client) {
  make_request(client$req, "version")
}

#' Reset ChromaDB
#'
#' This function resets the entire ChromaDB instance. Use with caution as this will delete all data.
#' Note: This function requires setting ALLOW_RESET=TRUE in the environment variables
#' or allow_reset=True in the ChromaDB Settings.
#'
#' @param client A ChromaDB client object
#'
#' @return TRUE on success
#' @export
reset <- function(client) {
  make_request(client$req, "reset", method = "POST")
}

#' Get ChromaDB Server Information
#'
#' Returns server capabilities and settings.
#'
#' @param client A ChromaDB client object
#'
#' @return List containing server information
#' @export
pre_flight_checks <- function(client) {
  make_request(client$req, "pre-flight-checks")
}

#' Check ChromaDB Server Heartbeat
#'
#' @param client A ChromaDB client object
#'
#' @return Server heartbeat response as a numeric value
#' @export
heartbeat <- function(client) {
  resp <- make_request(client$req, "heartbeat")
  resp$`nanosecond heartbeat`
}

#' Get Authentication Identity
#'
#' @param client A ChromaDB client object
#'
#' @return Authentication identity information
#' @export
get_auth_identity <- function(client) {
  make_request(client$req, "auth/identity")
}
