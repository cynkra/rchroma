make_request <- function(
  base,
  endpoint,
  query = list(),
  body = NULL,
  method = "GET"
) {
  req <- httr2::req_url_path_append(base, endpoint)
  req <- httr2::req_url_query(req, !!!query)
  req <- httr2::req_method(req, method)
  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body)
  }
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) handle_chroma_error(e)
  )

  httr2::resp_body_json(resp)
}

# Helper function for consistent error handling
handle_chroma_error <- function(e) {
  if (inherits(e, "httr2_error")) {
    err_body <- tryCatch(
      {
        httr2::resp_body_json(e$resp)
      },
      error = function(e2) {
        list(error = "UnknownError", message = httr2::resp_body_string(e$resp))
      }
    )

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
