if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
source("helper.R")

test_that("create_collection works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID

  # Test basic creation
  collection_name <- paste0("test_collection_", test_id)
  collection <- create_collection(client, collection_name)
  expect_type(collection, "list")
  expect_equal(collection$name, collection_name)

  # Test with metadata
  metadata <- list(description = "Test collection")
  collection_name2 <- paste0("test_collection2_", test_id)
  collection <- create_collection(client, collection_name2, metadata = metadata)
  expect_equal(collection$metadata$description, "Test collection")

  # Test with configuration
  config <- list(
    hnsw_space = "cosine"
  )
  collection_name3 <- paste0("test_collection3_", test_id)
  collection <- create_collection(
    client,
    collection_name3,
    configuration = config
  )
  expect_type(collection, "list")
  expect_equal(collection$configuration_json$hnsw_configuration$space, "cosine")

  # Test get_or_create parameter
  collection_name4 <- paste0("test_collection4_", test_id)
  collection2 <- create_collection(
    client,
    collection_name4,
    get_or_create = TRUE
  )
  expect_type(collection2, "list")
  expect_equal(collection2$name, collection_name4)

  # Test error on duplicate collection without get_or_create
  expect_error(
    create_collection(client, collection_name4),
    "UniqueConstraintError|HTTP 409"
  )
})

test_that("get_collection works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  create_collection(client, collection_name)
  collection <- get_collection(client, collection_name)
  expect_type(collection, "list")
  expect_equal(collection$name, collection_name)
})

test_that("update_collection works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)
  new_collection_name <- paste0("new_test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Update name should work silently
  expect_no_error(
    update_collection(client, collection_name, new_name = new_collection_name)
  )

  # Verify the update worked by getting the collection
  collection <- get_collection(client, new_collection_name)
  expect_equal(collection$name, new_collection_name)

  # Update metadata should work silently
  new_metadata <- list(description = "Updated collection")
  expect_no_error(
    update_collection(client, new_collection_name, new_metadata = new_metadata)
  )

  # Verify the metadata update worked
  collection <- get_collection(client, new_collection_name)
  expect_equal(collection$metadata$description, "Updated collection")
})

test_that("delete_collection works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  create_collection(client, collection_name)

  # Delete should work silently
  expect_no_error(delete_collection(client, collection_name))

  # Getting deleted collection should fail
  expect_error(
    get_collection(client, collection_name),
    "Collection .* does not exist|HTTP 400"
  )
})

test_that("list_collections works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID

  # Create some test collections
  collection_name1 <- paste0("test_collection1_", test_id)
  collection_name2 <- paste0("test_collection2_", test_id)
  create_collection(client, collection_name1)
  create_collection(client, collection_name2)

  # List all collections
  collections <- list_collections(client)
  expect_type(collections, "list")
  expect_gte(length(collections), 2)

  # Test pagination
  collections_limited <- list_collections(client, limit = 1)
  expect_equal(length(collections_limited), 1)

  collections_offset <- list_collections(client, offset = 1, limit = 1)
  expect_equal(length(collections_offset), 1)
  expect_false(identical(collections_limited[[1]], collections_offset[[1]]))
})

test_that("count_collections works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID

  # Create some test collections
  collection_name1 <- paste0("test_collection1_", test_id)
  collection_name2 <- paste0("test_collection2_", test_id)
  create_collection(client, collection_name1)
  create_collection(client, collection_name2)

  # Count collections
  count <- count_collections(client)
  expect_type(count, "integer")
  expect_gte(count, 2)
})
