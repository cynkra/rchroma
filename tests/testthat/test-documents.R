if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
source("helper.R")

test_that("add_documents works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection first
  create_collection(client, collection_name)

  # Basic document addition
  docs <- c("doc1", "doc2")
  ids <- c("id1", "id2")
  result <- add_documents(client, collection_name, documents = docs, ids = ids)
  expect_true(result)

  # Add with metadata
  docs <- c("doc3", "doc4")
  ids <- c("id3", "id4")
  metadatas <- list(
    list(source = "test1"),
    list(source = "test2")
  )
  result <- add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    metadatas = metadatas
  )
  expect_true(result)

  # Add with embeddings
  docs <- c("doc5", "doc6")
  ids <- c("id5", "id6")
  embeddings <- list(c(1, 0, 0), c(0, 1, 0))
  result <- add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    embeddings = embeddings
  )
  expect_true(result)

  # Add with URIs
  docs <- c("doc7", "doc8")
  ids <- c("id7", "id8")
  uris <- c("http://example.com/1", "http://example.com/2")
  result <- add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    uris = uris
  )
  expect_true(result)

  # IDs are required
  expect_error(
    add_documents(client, collection_name, documents = c("doc9")),
    "is missing, with no default"
  )
})

test_that("update_documents works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Add initial documents
  docs <- c("doc1", "doc2")
  ids <- c("id1", "id2")
  add_documents(client, collection_name, documents = docs, ids = ids)

  # Update documents should work silently
  new_docs <- c("updated1", "updated2")
  expect_no_error(
    update_documents(client, collection_name, documents = new_docs, ids = ids)
  )

  # Update metadata should work silently
  new_metadata <- list(
    list(updated = TRUE),
    list(updated = TRUE)
  )
  expect_no_error(
    update_documents(
      client,
      collection_name,
      ids = ids,
      metadatas = new_metadata
    )
  )

  # Update embeddings should work silently
  new_embeddings <- list(c(0, 0, 1), c(0, 0, 2))
  expect_no_error(
    update_documents(
      client,
      collection_name,
      ids = ids,
      embeddings = new_embeddings
    )
  )

  # Update non-existent document should work silently (API behavior)
  expect_no_error(
    update_documents(client, collection_name, ids = c("nonexistent_id"))
  )
})

test_that("update_documents fails correctly for non-existent collection", {
  client <- chroma_connect()
  expect_error(
    update_documents(
      client,
      "nonexistent_collection",
      ids = c("nonexistent_id")
    ),
    "InvalidCollection: Collection nonexistent_collection does not exist.|HTTP 400"
  )
})

test_that("delete_documents works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  collection_name <- paste0("test_collection_", test_id)

  # Create collection
  create_collection(client, collection_name)

  # Add documents
  docs <- c("doc1", "doc2", "doc3")
  ids <- c("id1", "id2", "id3")
  metadatas <- list(
    list(source = "test"),
    list(source = "test"),
    list(source = "other")
  )
  add_documents(
    client,
    collection_name,
    documents = docs,
    ids = ids,
    metadatas = metadatas
  )

  # Delete specific documents should work silently
  expect_no_error(
    delete_documents(client, collection_name, ids = c("id1", "id2"))
  )

  # Delete with where filter should work silently
  expect_no_error(
    delete_documents(
      client,
      collection_name,
      where = list(source = list("$eq" = "test"))
    )
  )

  # Delete non-existent document should work silently (API behavior)
  expect_no_error(
    delete_documents(client, collection_name, ids = c("nonexistent_id"))
  )
})
