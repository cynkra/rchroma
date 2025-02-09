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
chroma_connect <- function(host = "http://localhost", port = 8000L,
                         api_path = "/api/v2", verify = TRUE) {
  base_url <- paste0(host, ":", port, api_path)
  req <- httr2::request(base_url)

  # Test connection if verify is TRUE
  if (verify) {
    tryCatch({
      httr2::req_perform(req)
    }, error = function(e) {
      msg <- paste0(
        "Could not connect to ChromaDB at ", base_url, "\n\n",
        "To run ChromaDB:\n",
        "1. Install Docker from https://www.docker.com\n",
        "2. Run ChromaDB using Docker:\n",
        "   docker run -p 8000:8000 chromadb/chroma\n\n",
        "Original error: ", e$message
      )
      stop(msg)
    })
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
get_version <- function(client) {
  endpoint <- "/version"

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get server version")
  })

  httr2::resp_body_json(resp)
}

#' Reset ChromaDB Database
#'
#' This function resets the entire database. Use with caution as this will delete all data.
#' Note: This function requires setting ALLOW_RESET=TRUE in the environment variables
#' or allow_reset=True in the ChromaDB Settings.
#'
#' @param client A ChromaDB client object
#'
#' @return TRUE on success
#' @export
reset_database <- function(client) {
  endpoint <- "/reset"

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_method("POST") |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to reset database")
  })

  httr2::resp_body_json(resp)
}

#' Get ChromaDB Server Information
#'
#' Returns server capabilities and settings.
#'
#' @param client A ChromaDB client object
#'
#' @return List containing server information
#' @export
get_server_info <- function(client) {
  endpoint <- "/pre-flight-checks"

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get server information")
  })

  httr2::resp_body_json(resp)
}

#' Check ChromaDB Server Heartbeat
#'
#' @param client A ChromaDB client object
#'
#' @return Server heartbeat response as a numeric value
#' @export
get_heartbeat <- function(client) {
  endpoint <- "/heartbeat"

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get server heartbeat")
  })

  httr2::resp_body_json(resp)$`nanosecond heartbeat`
}

#' Get Authentication Identity
#'
#' @param client A ChromaDB client object
#'
#' @return Authentication identity information
#' @export
get_auth_identity <- function(client) {
  endpoint <- "/auth/identity"

  resp <- tryCatch({
    client$req |>
      httr2::req_url_path_append(endpoint) |>
      httr2::req_perform()
  }, error = function(e) {
    handle_chroma_error(e, "Failed to get authentication identity")
  })

  httr2::resp_body_json(resp)
}

# Helper function for consistent error handling
handle_chroma_error <- function(e, action) {
  # For httr2 errors, parse the JSON response
  if (inherits(e, "httr2_error")) {
    err_body <- tryCatch({
      httr2::resp_body_json(e$resp)
    }, error = function(e2) {
      list(error = "UnknownError", message = httr2::resp_body_string(e$resp))
    })

    if (!is.null(err_body$error) && !is.null(err_body$message)) {
      stop(paste0(err_body$error, ": ", err_body$message), call. = FALSE)
    } else if (!is.null(err_body$detail)) {
      if (is.list(err_body$detail) && length(err_body$detail) > 0) {
        # Extract type and message from first detail entry
        detail <- err_body$detail[[1]]
        stop(paste0(detail$type, ": ", detail$msg), call. = FALSE)
      } else {
        stop(err_body$detail, call. = FALSE)
      }
    } else {
      stop(httr2::resp_body_string(e$resp), call. = FALSE)
    }
  } else {
    stop(e$message, call. = FALSE)
  }
}
