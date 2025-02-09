test_that("chroma_connect works", {
  client <- chroma_connect()
  expect_s3_class(client, "chroma_client")
  expect_type(client$base_url, "character")
  expect_s3_class(client$req, "httr2_request")

  # Test custom host and port
  client2 <- chroma_connect(host = "http://localhost", port = 8001L, verify = FALSE)
  expect_equal(client2$base_url, "http://localhost:8001/api/v2")

  # Test connection error
  expect_error(
    chroma_connect(port = 9999L),
    "Could not connect to ChromaDB at http://localhost:9999/api/v2"
  )
})

test_that("get_version works", {
  client <- chroma_connect()
  version <- get_version(client)
  expect_type(version, "character")
  expect_match(version, "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

test_that("get_server_info works", {
  client <- chroma_connect()
  info <- get_server_info(client)
  expect_type(info, "list")
  expect_true("max_batch_size" %in% names(info))
})

test_that("get_heartbeat works", {
  client <- chroma_connect()
  heartbeat <- get_heartbeat(client)
  expect_type(heartbeat, "double")
  expect_gte(heartbeat, 0)
})

test_that("get_auth_identity works", {
  client <- chroma_connect()
  identity <- get_auth_identity(client)
  expect_type(identity, "list")
})
