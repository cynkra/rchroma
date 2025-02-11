if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
source("helper.R")

test_that("query works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Add documents with embeddings
  docs <- c("apple fruit", "banana fruit", "carrot vegetable")
  ids <- c("id1", "id2", "id3")
  embeddings <- list(
    c(1.0, 0.0, 0.0), # apple
    c(0.8, 0.2, 0.0), # banana (similar to apple)
    c(0.0, 0.0, 1.0) # carrot (different)
  )
  add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    embeddings = embeddings
  )

  # Query with embeddings
  result <- query(
    client,
    collection_name,
    query_embeddings = list(c(1.0, 0.0, 0.0)), # should match apple best
    n_results = 2
  )
  expect_type(result, "list")
  expect_true(all(c("documents", "metadatas", "distances") %in% names(result)))
  expect_equal(length(result$documents[[1]]), 2)
  expect_equal(result$documents[[1]][[1]], "apple fruit") # should be closest match

  # Query non-existent collection should fail
  expect_error(
    query(
      client,
      "nonexistent_collection",
      query_embeddings = list(c(1.0, 0.0, 0.0))
    ),
    "Collection nonexistent_collection does not exist|HTTP 400"
  )
})

test_that("query with filters works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Add documents with embeddings and metadata
  docs <- c("doc1", "doc2", "doc3")
  ids <- c("id1", "id2", "id3")
  embeddings <- list(
    c(1.0, 0.0, 0.0),
    c(0.0, 1.0, 0.0),
    c(0.0, 0.0, 1.0)
  )
  metadatas <- list(
    list(category = "A", year = 2024),
    list(category = "B", year = 2023),
    list(category = "A", year = 2022)
  )
  add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    embeddings = embeddings,
    metadatas = metadatas
  )

  # Query with where filter
  result <- query(
    client,
    collection_name,
    query_embeddings = list(c(1.0, 0.0, 0.0)),
    where = list(year = list("$gte" = 2024))
  )
  expect_type(result, "list")
  expect_equal(length(result$documents[[1]]), 1)
  expect_equal(result$documents[[1]][[1]], "doc1")

  # Query with where_document filter
  result <- query(
    client,
    collection_name,
    query_embeddings = list(c(1.0, 0.0, 0.0)),
    where_document = list("$contains" = "doc1")
  )
  expect_type(result, "list")
  expect_equal(length(result$documents[[1]]), 1)
  expect_equal(result$documents[[1]][[1]], "doc1")
})

test_that("query include parameter works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Add documents with all possible attributes
  docs <- c("doc1", "doc2")
  ids <- c("id1", "id2")
  embeddings <- list(c(1.0, 0.0), c(0.0, 1.0))
  metadatas <- list(
    list(source = "test1"),
    list(source = "test2")
  )
  uris <- c("http://example.com/1", "http://example.com/2")
  add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    embeddings = embeddings,
    metadatas = metadatas,
    uris = uris
  )

  # Test different include combinations
  includes <- list(
    c("documents", "embeddings"),
    c("metadatas", "distances"),
    c("uris", "data"),
    c("documents", "embeddings", "metadatas", "distances", "uris", "data")
  )

  for (include in includes) {
    result <- query(
      client,
      collection_name,
      query_embeddings = list(c(1.0, 0.0)),
      include = include
    )
    expect_type(result, "list")
    expect_true(all(include %in% names(result)))
  }

  # Test invalid include parameter
  expect_error(
    query(
      client,
      collection_name,
      query_embeddings = list(c(1.0, 0.0)),
      include = c("invalid")
    ),
    "Input should be 'documents', 'embeddings'|HTTP"
  )
})
