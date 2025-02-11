if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
source("helper.R")

test_that("create_tenant works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  tenant_name <- paste0("test_tenant_", test_id)

  # Create tenant
  tenant <- create_tenant(client, tenant_name)
  expect_type(tenant, "list")
  expect_equal(tenant$name, tenant_name)

  # Creating same tenant should fail
  expect_error(
    create_tenant(client, tenant_name),
    paste0(
      "UniqueConstraintError: Tenant ",
      tenant_name,
      " already exists|HTTP 409"
    )
  )
})

test_that("get_tenant works", {
  client <- chroma_connect()
  test_id <- basename(tempfile("test")) # Generate unique test ID
  tenant_name <- paste0("test_tenant_", test_id)

  # Create and get tenant
  create_tenant(client, tenant_name)
  tenant <- get_tenant(client, tenant_name)
  expect_type(tenant, "list")
  expect_equal(tenant$name, tenant_name)

  # Getting non-existent tenant should fail
  expect_error(
    get_tenant(client, "nonexistent_tenant"),
    "NotFoundError: Tenant nonexistent_tenant not found|HTTP 404"
  )
})
