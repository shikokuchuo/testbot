test_that("testbot with default client", {
  mock_chat <- list(
    chat = function(prompt) "success"
  )
  with_mocked_bindings(
    btw_client = function(client) {
      expect_null(client)
      mock_chat
    },
    {
      result <- testbot()
      expect_identical(result, mock_chat)
    }
  )
})

test_that("testbot with custom client", {
  mock_client <- list(chat = function(prompt) "success")
  mock_chat <- list(
    chat = function(prompt) "result"
  )
  
  with_mocked_bindings(
    btw_client = function(client) {
      expect_identical(client, mock_client)
      mock_chat
    },
    {
      result <- testbot(client = mock_client)
      expect_identical(result, mock_chat)
    }
  )
})

test_that("testbot retries parameter conversion", {
  mock_chat <- list(
    chat = function(prompt) "success"
  )
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 3.7)
      expect_identical(result, mock_chat)
    }
  )
})

test_that("testbot with zero retries fails immediately", {
  mock_chat <- list(
    chat = function(prompt) stop("error")
  )
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 0L)
      expect_identical(result, mock_chat)
    }
  )
})

test_that("testbot retry mechanism succeeds on second attempt", {
  call_count <- 0
  mock_chat <- list(
    chat = function(prompt) {
      call_count <<- call_count + 1
      if (call_count == 1) stop("error")
      "success"
    }
  )
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 1L)
      expect_identical(result, mock_chat)
      expect_equal(call_count, 2)
    }
  )
})

test_that("testbot successful first attempt", {
  call_count <- 0
  mock_chat <- list(
    chat = function(prompt) {
      call_count <<- call_count + 1
      "immediate success"
    }
  )
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot()
      expect_identical(result, mock_chat)
      expect_equal(call_count, 1)
    }
  )
})

test_that("testbot exhausts all retries then returns chat object", {
  call_count <- 0
  mock_chat <- list(
    chat = function(prompt) {
      call_count <<- call_count + 1
      stop("persistent error")
    }
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 2L)
      expect_identical(result, mock_chat)
      expect_equal(call_count, 3)
    }
  )
})

test_that("testbot uses correct retry prompt", {
  prompt_sequence <- character(0)
  mock_chat <- list(
    chat = function(prompt) {
      prompt_sequence <<- c(prompt_sequence, prompt)
      if (length(prompt_sequence) == 1) {
        stop("first error")
      }
      "retry success"
    }
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot()
      expect_length(prompt_sequence, 2)
      expect_true(grepl("100% line coverage", prompt_sequence[1]))
      expect_equal(prompt_sequence[2], "pick up exactly where you left off")
    }
  )
})

test_that("testbot retry counter resets between function calls", {
  call_counts <- numeric(0)
  mock_chat <- list(
    chat = function(prompt) {
      call_counts <<- c(call_counts, 1)
      if (length(call_counts) <= 2) stop("error")
      "success"
    }
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result1 <- testbot(retries = 2L)
      call_counts <<- numeric(0)
      result2 <- testbot(retries = 1L)
      expect_identical(result1, mock_chat)
      expect_identical(result2, mock_chat)
    }
  )
})

test_that("testbot with negative retries", {
  mock_chat <- list(
    chat = function(prompt) stop("error")
  )
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = -1L)
      expect_identical(result, mock_chat)
    }
  )
})

test_that("prompt constants are correct", {
  expect_type(prompt_retry, "character")
  expect_type(prompt, "character")
  expect_equal(prompt_retry, "pick up exactly where you left off")
  expect_true(grepl("100% line coverage", prompt))
  expect_true(grepl("test-bot.R", prompt))
})

test_that("testbot closure captures retry state correctly", {
  error_count <- 0
  mock_chat <- list(
    chat = function(prompt) {
      error_count <<- error_count + 1
      if (error_count <= 1) stop("error")
      "success"
    }
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 3L)
      expect_identical(result, mock_chat)
      expect_equal(error_count, 2)
    }
  )
})

test_that("testbot retry function handles nested errors", {
  attempt <- 0
  mock_chat <- list(
    chat = function(prompt) {
      attempt <<- attempt + 1
      if (attempt == 1) stop("first error")
      if (attempt == 2) stop("second error") 
      "final success"
    }
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 2L)
      expect_identical(result, mock_chat)
      expect_equal(attempt, 3)
    }
  )
})

test_that("testbot handles error in retry function boundary condition", {
  mock_chat <- list(
    chat = function(prompt) stop("always fails")
  )
  
  with_mocked_bindings(
    btw_client = function(client) mock_chat,
    {
      result <- testbot(retries = 1L)
      expect_identical(result, mock_chat)
    }
  )
})
