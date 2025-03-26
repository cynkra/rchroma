docker_available <- function() {
  docker_check <- system(
    "docker --version",
    intern = TRUE,
    ignore.stderr = TRUE
  )

  # Check if there's a result
  if (length(docker_check) == 0) {
    cli::cli_abort(
      "docker is not available. Please install it or adjust your PATH."
    )
  }
}
#' Start ChromaDB Docker Container
#'
#' This function uses Docker to start a ChromaDB server container in the background.
#'
#' @param port The port for the ChromaDB container.
#' @param volume_host_dir A string specifying the host directory to persist data.
#' @param is_persistent Logical; whether to enable persistence. Defaults to `TRUE`.
#' @param anonymized_telemetry Logical; whether to enable anonymous telemetry. Defaults to `FALSE`.
#' @param version A string specifying the version of the ChromDB Docker image. Default is `"0.6.3"`.
#' @param container_name A string specifying the name for the Docker container. Default is `"chromadb"`.
#'
#' @return Invisibly returns `TRUE` if the container is already running or started successfully.
#' @export
#'
chroma_docker_run <- function(
  port = 8000,
  volume_host_dir = "./chroma",
  is_persistent = TRUE,
  anonymized_telemetry = FALSE,
  version = "0.6.3",
  container_name = "chromadb"
) {
  docker_available()
  port <- glue::glue("{port}:{port}")
  image <- glue::glue("chromadb/chroma:{version}")
  persist_directory <- "/chroma/chroma"

  is_running <- chroma_docker_running(container_name)

  if (is_running) {
    cli::cli_alert_warning(
      "Docker container {container_name} is already running."
    )
    return(invisible(TRUE))
  }

  docker_args <- c(
    "run",
    "-d",
    "--rm",
    "--name",
    container_name,
    "-p",
    port,
    "-v",
    paste0(
      normalizePath(volume_host_dir, mustWork = FALSE),
      ":",
      persist_directory
    ),
    "-e",
    paste0("IS_PERSISTENT=", toupper(as.character(is_persistent))),
    "-e",
    paste0("PERSIST_DIRECTORY=", persist_directory),
    "-e",
    paste0(
      "ANONYMIZED_TELEMETRY=",
      toupper(as.character(anonymized_telemetry))
    ),
    image
  )

  cli::cli_alert_info("Starting new ChromaDB container...")
  result <- processx::run("docker", docker_args, error_on_status = TRUE)

  cli::cli_alert_success("Container {container_name} started successfully.")
  invisible(TRUE)
}

#' Check ChromaDB Docker Container Status
#'
#' This function checks the status of the ChromaDB Docker container.
#'
#' @param container_name A string specifying the name of the Docker container to check.
#'
#' @return TRUE if container is running and FALSE otherwise.
#' @export
chroma_docker_running <- function(container_name = "chromadb") {
  docker_available()
  running_result <- tryCatch(
    {
      result <- processx::run(
        "docker",
        c(
          "ps",
          "-q",
          "--filter",
          paste0("name=", container_name),
          "--filter",
          "status=running"
        ),
        error_on_status = FALSE
      )
      result$stdout
    },
    error = function(e) ""
  )

  if (nzchar(running_result)) {
    TRUE
  } else {
    FALSE
  }
}

#' Stop ChromaDB Docker Container
#'
#' This function stops the running ChromaDB Docker container.
#' It uses the `processx` package to issue the Docker stop command.
#'
#' @param container_name A string specifying the name of the Docker container to stop.
#'
#' @return Invisibly returns `TRUE` if the container was stopped or is not running.
#' @export

chroma_docker_stop <- function(container_name = "chromadb") {
  docker_available()
  if (chroma_docker_running(container_name)) {
    processx::run("docker", c("stop", container_name), error_on_status = TRUE)
    cli::cli_alert_success("Container {container_name} has been stopped.")
  } else {
    cli::cli_alert_warning("{container_name} not running.")
  }
  invisible(TRUE)
}

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
          "2. Run ChromaDB using the Docker helper function:\n",
          "   chroma_docker_run()\n\n",
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

#' @export
print.chroma_client <- function(x, ...) {
  cat("<chromadb connection>")
  invisible(x)
}
