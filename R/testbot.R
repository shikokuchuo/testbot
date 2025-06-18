#' Testbot
#'
#' For packages, creates an additional test file "tests/testthat/test-bot.R" to
#' bring test coverage to 100\%.
#'
#' Call this function from the top working directory of your package.
#'
#' @param client the default `NULL` uses [ellmer::chat_anthropic()], but you may
#'   pass an alternative such as [ellmer::chat_openai()].
#' @param retries integer number of times to retry if an error occurs mid-way.
#'   This may happen due to timeout or for other stochastic reasons.
#'
#' @return An ellmer 'Chat' object.
#'
#' @export
#'
testbot <- function(client = NULL, retries = 2L) {

  retries <- as.integer(retries)
  i <- 0L

  chat <- btw_client(client = client)
  retry_fn <- function(x) {
    if (i < retries) {
      i <<- i + 1L
      tryCatch(
        chat$chat(prompt_retry),
        error = retry_fn
      )
    }
    chat
  }
  tryCatch(
    chat$chat(prompt),
    error = retry_fn
  )

  chat

}

prompt_retry <- "pick up exactly where you left off"

prompt <- paste(
  "The R package in the current working directory needs to have its tests augmented to reach 100% line coverage.",
  "This needs to be realized using the minimal amount of testing code possible.",
  "Make sure the code covers all error code paths and edge cases.",
  "Formulate a succinct plan that when executed will achieve this goal.",
  "Do not write any files in generating the plan.",
  "\nNow execute the plan.",
  "Write the additional test code, without any comments, to a single new file saved at 'tests/testthat/test-bot.R'."
)
