context("db_query")

local({
  skip_on_cran()
  file <- system.file("examples/omdb.json", package = "sofa")
  strs <- readLines(file)

  ## create a database
  if ("omdb" %in% db_list(sofa_conn)) {
    invisible(db_delete(sofa_conn, dbname = "omdb"))
  }
  invisible(db_create(sofa_conn, dbname = 'omdb'))

  ## add some documents
  invisible(db_bulk_create(sofa_conn, "omdb", strs))
})

test_that("db_query - selector param works", {
  skip_on_cran()

  aa <- db_query(sofa_conn, 'omdb', selector = list(`_id` = list(`$gt` = NULL)))

	expect_is(aa, "list")
	expect_true('docs' %in% names(aa))
  expect_is(aa$docs, 'list')
  expect_is(aa$docs[[1]], "list")

  expect_true(all(c("Title", "Writer", "imdbRating") %in% names(aa$docs[[1]])))
})

test_that("db_query - query as text string works", {
  skip_on_cran()

  aa <- db_query(
    sofa_conn, 'omdb', query = '{
      "selector": {
        "_id": {
          "$gt": null
        }
      }
    }'
  )

  expect_is(aa, "list")
  expect_true('docs' %in% names(aa))
  expect_is(aa$docs, 'list')
  expect_is(aa$docs[[1]], "list")

  expect_true(all(c("Title", "Writer", "imdbRating") %in% names(aa$docs[[1]])))
})

test_that("db_query - a regex query works", {
  skip_on_cran()

  aa <- db_query(
    sofa_conn, 'omdb', selector = list(
      Director = list(`$regex` = "^R")
    )
  )

  expect_is(aa, "list")
  expect_true('warning' %in% names(aa))
  expect_true('docs' %in% names(aa))
  expect_is(aa$docs, 'list')
  expect_is(aa$docs[[1]], "list")

  expect_equal(length(aa$docs), 11)

  expect_true(all(c("Title", "Writer", "imdbRating") %in% names(aa$docs[[1]])))
})

test_that("db_query - fields param works", {
  skip_on_cran()

  aa <- db_query(
    sofa_conn, dbname = "omdb", selector = list(
      Director = list(`$regex` = "^R")
    ), fields = c("_id", "Director"))

  expect_is(aa, "list")
  expect_true('warning' %in% names(aa))
  expect_true('docs' %in% names(aa))
  expect_is(aa$docs, 'list')
  expect_is(aa$docs[[1]], "list")

  expect_equal(length(aa$docs), 11)

  expect_true(all(c("_id", "Director") %in% names(aa$docs[[1]])))
})

test_that("db_query - bookmark param works", {
  skip_on_cran()

  aa <- db_query(
    sofa_conn, dbname = "omdb", selector = list(
      Director = list(`$regex` = "^R")
    ), fields = c("_id", "Director"), limit = 5)
  bb <- db_query(sofa_conn, dbname = "omdb", selector = list(
      Director = list(`$regex` = "^R")
    ), fields = c("_id", "Director"),
    bookmark = aa$bookmark)

  expect_is(bb, "list")
  expect_true('warning' %in% names(bb))
  expect_true('docs' %in% names(bb))
  ver <- as.numeric(substring(sofa_conn$ping()$version, 1, 1))
  if (ver >= 3) expect_true('bookmark' %in% names(bb))
  expect_is(bb$docs, 'list')
  expect_is(bb$docs[[1]], "list")

  expect_equal(length(bb$docs), 6)

  expect_true(all(c("_id", "Director") %in% names(bb$docs[[1]])))
})

test_that("db_query fails well", {
  expect_error(db_query(), "argument \"cushion\" is missing")
  expect_error(db_query(sofa_conn), "argument \"dbname\" is missing")

  skip_on_cran()
  
  # execution_stats should be logical
  expect_error(db_query(sofa_conn, "asdf", execution_stats = 234))
  # bookmark should be character
  expect_error(db_query(sofa_conn, "asdf", bookmark = 234))

  expect_error(db_query(sofa_conn, "asdfds"), "Database does not exist")
})

cleanup_dbs("omdb")
