# Helper function to ensure test environment is clean
cleanup_collections <- function(client) {
  message("Starting cleanup of collections...")

  # Get list of collections
  message("  Getting list of collections...")
  collections <- list_collections(client)
  message(sprintf("  Found %d collections", length(collections)))

  # Delete each collection by name
  for (collection in collections) {
    message(sprintf("  Deleting collection '%s'...", collection$name))
    delete_collection(client, collection$name)
  }

  message("Cleanup complete")
}
