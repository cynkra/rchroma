
# rchroma <a href="https://cynkra.github.io/rchroma/"><img src="man/figures/logo.png" align="right" height="139" alt="rchroma website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/cynkra/rchroma/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cynkra/rchroma/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/cynkra/rchroma/branch/main/graph/badge.svg)](https://app.codecov.io/gh/cynkra/rchroma?branch=main)
<!-- badges: end -->

rchroma provides a clean interface to
[ChromaDB](https://www.trychroma.com/), a modern vector database for
storing and querying embeddings.

## Installation

You can install rchroma from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("cynkra/rchroma")
```

## Usage

``` r
library(rchroma)

# Connect to ChromaDB
client <- chroma_connect()

# Create a collection and add documents
create_collection(client, "my_collection")
add_documents(
  client,
  "my_collection",
  documents = c(
    "The quick brown fox jumps over the lazy dog",
    "Pack my box with five dozen liquor jugs"
  )
)

# Query similar documents
query_collection(
  client,
  "my_collection",
  query_texts = "fox",
  n_results = 2
)
```

Learn more in `vignette("introduction")`.
