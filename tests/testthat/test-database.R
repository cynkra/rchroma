if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
source("helper.R")

test_that("create_database works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID

  tenant_name <- paste0("test_tenant_", test_id)
  db_name <- paste0("test_database_", test_id)

  # Create tenant first
  create_tenant(client, tenant_name)

  # Create database should work silently
  expect_no_error(
    create_database(client, db_name, tenant = tenant_name)
  )

  # Creating same database should fail
  expect_error(
    create_database(client, db_name, tenant = tenant_name),
    "UniqueConstraintError: Database .* already exists|HTTP 409"
  )

  # Create database in default tenant should work silently
  expect_no_error(
    create_database(client, db_name)
  )
})

test_that("get_database works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID

  tenant_name <- paste0("test_tenant_", test_id)
  db_name <- paste0("test_database_", test_id)

  # Create tenant and database
  create_tenant(client, tenant_name)
  create_database(client, db_name, tenant = tenant_name)

  # Get database should work silently
  expect_no_error(
    get_database(client, db_name, tenant = tenant_name)
  )

  # Getting non-existent database should fail
  expect_error(
    get_database(client, "nonexistent_database", tenant = tenant_name),
    "NotFoundError: Database nonexistent_database not found|HTTP 404"
  )

  # Get database from default tenant should work silently
  create_database(client, db_name)
  expect_no_error(
    get_database(client, db_name)
  )
})
