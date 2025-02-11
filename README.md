
# rchroma <img src="man/figures/logo.png" align="right" height="139" alt="" />

[![R-CMD-check](https://github.com/cynkra/rchroma/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cynkra/rchroma/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/cynkra/rchroma/branch/main/graph/badge.svg)](https://app.codecov.io/gh/cynkra/rchroma?branch=main)

An R client for ChromaDB, a modern vector database for storing and
querying embeddings.

## Installation

You can install the development version of rchroma from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("cynkra/rchroma")
```

## Usage

First, make sure you have a ChromaDB server running. Then you can
connect to it:

``` r
library(rchroma)

# Connect to ChromaDB (default: localhost:8000)
client <- chroma_connect()

# Create a new collection
create_collection(client, "my_collection")

# Add documents
documents <- c(
  "The quick brown fox jumps over the lazy dog",
  "Pack my box with five dozen liquor jugs"
)
add_documents(client, "my_collection", documents)

# Add documents with metadata
documents <- c("Document 1", "Document 2")
metadatas <- list(
  list(source = "book", year = 2024),
  list(source = "article", year = 2023)
)
add_documents(client, "my_collection", documents, metadatas = metadatas)

# Query the collection
results <- query_collection(
  client,
  "my_collection",
  query_texts = "fox",
  n_results = 2
)

# Query with filters
results <- query_collection(
  client,
  "my_collection",
  query_texts = "document",
  where = list(year = list("$gte" = 2024))
)

# Get collection details
details <- get_collection_details(client, "my_collection")
n_docs <- count_documents(client, "my_collection")

# Delete documents
delete_documents(client, "my_collection", ids = c("id_1", "id_2"))

# Delete collection
delete_collection(client, "my_collection")
```

## Features

- Connect to ChromaDB server
- Create and manage collections
- Add documents with optional metadata and embeddings
- Update existing documents
- Delete documents or entire collections
- Query collections using similarity search
- Filter results using metadata
- Get collection details and document counts

## API Functions

### Connection

- `chroma_connect()`: Create a new connection to ChromaDB

### Collections

- `create_collection()`: Create a new collection
- `get_collection()`: Get an existing collection
- `get_or_create_collection()`: Get or create a collection
- `delete_collection()`: Delete a collection
- `list_collections()`: List all collections
- `get_collection_details()`: Get collection details
- `count_documents()`: Count documents in a collection

### Documents

- `add_documents()`: Add documents to a collection
- `update_documents()`: Update existing documents
- `delete_documents()`: Delete documents from a collection
- `query_collection()`: Query documents in a collection

## License

MIT
