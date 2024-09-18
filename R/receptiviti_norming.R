#' View or Establish Custom Norming Contexts
#'
#' @param name Name of a new norming context, to be established from the provided \code{text}.
#' Not providing a name will list the previously created contexts.
#' @param text Text to be processed and used as the custom norming context.
#' Not providing text will return the status of the named norming context.
#' @param options Options to set for the norming context (e.g.,
#' \code{list(word_count_filter = 350,} \code{punctuation_filter = .25)}).
#' @param id,text_column,id_column,files,dir,file_type,collapse_lines,encoding Additional
#' arguments used to handle \code{text}; same as those in \code{\link{receptiviti}}.
#' @param bundle_size,bundle_byte_limit,retry_limit,clear_scratch_cache,cores,use_future,in_memory
#' Additional arguments used to manage the requests; same as those in
#' \code{\link{receptiviti}}.
#' @param key,secret,url Request arguments; same as those in \code{\link{receptiviti}}.
#' @param verbose Logical; if \code{TRUE}, will show status messages.
#' @returns If \code{name} is not specified, a \code{data.frame} containing the statuses of each
#' available custom norming context. If \code{text} is not specified, the status of the
#' named context in a \code{list}. If \code{text}s are provided, a \code{list}:
#' \itemize{
#'    \item \code{initial_status}: Initial status of the context.
#'    \item \code{first_pass}: Response after texts are sent the first time, or
#'      \code{NULL} if the initial status is \code{pass_two}.
#'    \item \code{second_pass}: Response after texts are sent the second time.
#' }
#' @examples
#' \dontrun{
#' # get status of all existing custom norming contexts
#' contexts <- receptiviti_norming()
#'
#' # create or get the status of a single custom norming context
#' status <- receptiviti_norming("new_context")
#'
#' # establish a new custom norming context
#' full_status <- receptiviti_norming("new_context", c(
#'   "a text to set the norm",
#'   "another text part of the new context"
#' ))
#' }
#' @export

receptiviti_norming <- function(name = NULL, text = NULL, options = list(), id = NULL, text_column = NULL,
                                id_column = NULL, files = NULL, dir = NULL,
                                file_type = "txt", collapse_lines = FALSE, encoding = NULL,
                                bundle_size = 1000, bundle_byte_limit = 75e5, retry_limit = 50,
                                clear_scratch_cache = TRUE, cores = detectCores() - 1, use_future = FALSE, in_memory = TRUE,
                                url = Sys.getenv("RECEPTIVITI_URL"), key = Sys.getenv("RECEPTIVITI_KEY"),
                                secret = Sys.getenv("RECEPTIVITI_SECRET"), verbose = TRUE) {
  if (key == "") stop("specify your key, or set it to the RECEPTIVITI_KEY environment variable", call. = FALSE)
  if (secret == "") stop("specify your secret, or set it to the RECEPTIVITI_SECRET environment variable", call. = FALSE)
  if (!is.null(name) && grepl("[^a-z0-9_.-]", name)) {
    stop(
      "`name` can only include lowercase letters, numbers, hyphens, underscores, or periods",
      call. = FALSE
    )
  }
  handler <- curl::new_handle(httpauth = 1, userpwd = paste0(key, ":", secret))
  url <- paste0(
    if (!grepl("http", tolower(url), fixed = TRUE)) "https://",
    sub("/+[Vv]\\d+(?:/.*)?$|/+$", "", url), "/v2/norming/"
  )
  if (!grepl("^https?://[^.]+[.:][^.]", url, TRUE)) stop("url does not appear to be valid: ", url)

  # list current contexts
  if (verbose) message("requesting list of existing custom norming contexts")
  req <- curl::curl_fetch_memory(url, handler)
  if (req$status_code != 200) {
    stop(
      "failed to make norming list request: ", req$status_code,
      call. = FALSE
    )
  }
  norms <- jsonlite::fromJSON(rawToChar(req$content))
  if (length(norms)) {
    if (verbose && is.null(name)) {
      message(
        "custom norming context(s) found: ", paste(norms$name, collapse = ", ")
      )
    }
  } else {
    if (verbose && is.null(name)) message("no custom norming contexts found")
    norms <- NULL
  }
  if (is.null(name)) {
    return(norms)
  }

  if (name %in% norms$name) {
    status <- as.list(norms[norms$name == name, ])
  } else {
    # establish a new context if needed
    if (verbose) message("requesting creation of custom context ", name)
    curl::handle_setopt(
      handler,
      copypostfields = jsonlite::toJSON(c(name = name, options), auto_unbox = TRUE)
    )
    req <- curl::curl_fetch_memory(url, handler)
    if (req$status_code != 200) {
      message <- list(error = rawToChar(req$content))
      if (substr(message$error, 1, 1) == "{") message$error <- jsonlite::fromJSON(message$error)
      stop("failed to make norming creation request: ", message$error, call. = FALSE)
    }
    status <- jsonlite::fromJSON(rawToChar(req$content))
  }
  if (verbose) {
    message(
      "status of ", name, ": ", jsonlite::toJSON(status, pretty = TRUE, auto_unbox = TRUE)
    )
  }
  if (is.null(text)) {
    return(invisible(status))
  }
  if (status$status == "completed") {
    warning("status is `completed`, so cannot sent text")
    return(invisible(list(
      initial_status = status,
      first_pass = NULL,
      second_pass = NULL
    )))
  }
  if (status$status == "pass_two") {
    first_pass <- NULL
  } else {
    if (verbose) message("sending first-pass samples for ", name)
    first_pass <- manage_request(
      text, id = id, text_column = text_column, id_column = id_column, files = files, dir = dir,
      file_type = file_type, collapse_lines = collapse_lines, encoding = encoding,
      bundle_size = bundle_size, bundle_byte_limit = bundle_byte_limit, retry_limit = retry_limit,
      clear_scratch_cache = clear_scratch_cache, cores = cores, use_future = use_future,
      in_memory = in_memory, url = paste0(url, name, "/one"), key = key, secret = secret,
      verbose = verbose, to_norming = TRUE
    )$final_res
  }
  second_pass <- NULL
  if (!is.null(first_pass$analyzed) && all(first_pass$analyzed == 0)) {
    warning("no texts were successfully analyzed in the first pass, so second pass was skipped")
  } else {
    if (verbose) message("sending second-pass samples for ", name)
    second_pass <- manage_request(
      text, id = id, text_column = text_column, id_column = id_column, files = files, dir = dir,
      file_type = file_type, collapse_lines = collapse_lines, encoding = encoding,
      bundle_size = bundle_size, bundle_byte_limit = bundle_byte_limit, retry_limit = retry_limit,
      clear_scratch_cache = clear_scratch_cache, cores = cores, use_future = use_future,
      in_memory = in_memory, url = paste0(url, name, "/two"), key = key, secret = secret,
      verbose = verbose, to_norming = TRUE
    )$final_res
  }
  if (!is.null(second_pass$analyzed) && all(second_pass$analyzed == 0)) {
    warning("no texts were successfully analyzed in the second pass")
  }
  invisible(list(
    initial_status = status,
    first_pass = first_pass,
    second_pass = second_pass
  ))
}
