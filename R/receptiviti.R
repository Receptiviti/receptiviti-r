.onLoad <- function(lib, pkg) {
  if (Sys.getenv("RECEPTIVITI_URL") == "") Sys.setenv(RECEPTIVITI_URL = "https://api.receptiviti.com/")
}

#' Receptiviti API
#'
#' The main function to access the \href{https://www.receptiviti.com}{Receptiviti} API.
#'
#' @param text A character vector with text to be processed, path to a directory containing files, or a vector of file paths.
#' If a single path to a directory, each file is collapsed to a single text. If a path to a file or files,
#' each line or row is treated as a separate text, unless \code{collapse_lines} is \code{TRUE} (in which case,
#' files will be read in as part of bundles at processing time, as is always the case when a directory).
#' Use \code{files} to more reliably enter files, or \code{dir} to more reliably specify a directory.
#' @param output Path to a \code{.csv} file to write results to. If this already exists, set \code{overwrite} to \code{TRUE}
#' to overwrite it.
#' @param id Vector of unique IDs the same length as \code{text}, to be included in the results.
#' @param text_column,id_column Column name of text/id, if \code{text} is a matrix-like object, or a path to a csv file.
#' @param files A list of file paths, as alternate entry to \code{text}.
#' @param dir A directory to search for files in, as alternate entry to \code{text}.
#' @param file_type File extension to search for, if \code{text} is the path to a directory containing files to be read in.
#' @param encoding Encoding of file(s) to be read in. If not specified, this will be detected, which can fail,
#' resulting in mis-encoded characters; for best (and fasted) results, specify encoding.
#' @param return_text Logical; if \code{TRUE}, \code{text} is included as the first column of the result.
#' @param api_args A list of additional arguments to pass to the API (e.g., \code{list(sallee_mode = "sparse")}). Defaults to the
#' \code{receptiviti.api_args} option. Custom norming contexts can be established with the \code{\link{receptiviti_norming}}
#' function, then referred to here with the \code{custom_context} argument (only available in API V2).
#' @param frameworks A vector of frameworks to include results from. Texts are always scored with all available framework --
#' this just specifies what to return. Defaults to \code{all}, to return all scored frameworks. Can be set by the
#' \code{receptiviti.frameworks} option (e.g., \code{options(receptiviti.frameworks = c("liwc", "sallee"))}).
#' @param framework_prefix Logical; if \code{FALSE}, will remove the framework prefix from column names, which may result in duplicates.
#' If this is not specified, and 1 framework is selected, or \code{as_list} is \code{TRUE}, will default to remove prefixes.
#' @param as_list Logical; if \code{TRUE}, returns a list with frameworks in separate entries.
#' @param bundle_size Number of texts to include in each request; between 1 and 1,000.
#' @param bundle_byte_limit Memory limit (in bytes) of each bundle, under \code{1e7} (10 MB, which is the API's limit).
#' May need to be lower than the API's limit, depending on the system's requesting library.
#' @param collapse_lines Logical; if \code{TRUE}, and \code{text} contains paths to files, each file is treated as a single text.
#' @param retry_limit Maximum number of times each request can be retried after hitting a rate limit.
#' @param overwrite Logical; if \code{TRUE}, will overwrite an existing \code{output} file.
#' @param compress Logical; if \code{TRUE}, will save as an \code{xz}-compressed file.
#' @param make_request Logical; if \code{FALSE}, a request is not made. This could be useful if you want to be sure and
#' load from one of the caches, but aren't sure that all results exist there; it will error out if it encounters
#' texts it has no other source for.
#' @param text_as_paths Logical; if \code{TRUE}, ensures \code{text} is treated as a vector of file paths. Otherwise, this will be
#' determined if there are no \code{NA}s in \code{text} and every entry is under 500 characters long.
#' @param cache Path to a directory in which to save unique results for reuse; defaults to
#' \code{Sys.getenv(}\code{"RECEPTIVITI_CACHE")}. See the Cache section for details.
#' @param cache_overwrite Logical; if \code{TRUE}, will write results to the cache without reading from it. This could be used
#' if you want fresh results to be cached without clearing the cache.
#' @param cache_format Format of the cache database; see \code{\link[arrow]{FileFormat}}.
#' Defaults to \code{Sys.getenv(}\code{"RECEPTIVITI_CACHE_FORMAT")}.
#' @param clear_cache Logical; if \code{TRUE}, will clear any existing files in the cache. Use \code{cache_overwrite} if
#' you want fresh results without clearing or disabling the cache. Use \code{cache = FALSE} to disable the cache.
#' @param request_cache Logical; if \code{FALSE}, will always make a fresh request, rather than using the response
#' from a previous identical request.
#' @param cores Number of CPU cores to split bundles across, if there are multiple bundles. See the Parallelization section.
#' @param use_future Logical; if \code{TRUE}, uses a \code{future} back-end to process bundles, in which case,
#' parallelization can be controlled with the \code{\link[future]{plan}} function (e.g., \code{plan("multisession")}
#' to use multiple cores); this is required to see progress bars when using multiple cores. See the Parallelization section.
#' @param in_memory Logical; if \code{FALSE}, will write bundles to temporary files, and only load them as they are being requested.
#' @param clear_scratch_cache Logical; if \code{FALSE}, will preserve the bundles written when \code{in_memory} is \code{TRUE}, after
#' the request has been made.
#' @param verbose Logical; if \code{TRUE}, will show status messages.
#' @param key API Key; defaults to \code{Sys.getenv("RECEPTIVITI_KEY")}.
#' @param secret API Secret; defaults to \code{Sys.getenv("RECEPTIVITI_SECRET")}.
#' @param url API URL; defaults to \code{Sys.getenv("RECEPTIVITI_URL")}, which defaults to
#' \code{"https://api.receptiviti.com/"}.
#' @param version API version; defaults to \code{Sys.getenv("RECEPTIVITI_VERSION")}, which defaults to
#' \code{"v1"}.
#' @param endpoint API endpoint (path name after the version); defaults to \code{Sys.getenv("RECEPTIVITI_ENDPOINT")},
#' which defaults to \code{"framework"}.
#' @param include_headers Logical; if \code{TRUE}, \code{receptiviti_status}'s verbose message will include
#' the HTTP headers.
#'
#' @returns A \code{data.frame} with columns for \code{text} (if \code{return_text} is \code{TRUE}; the originally entered text),
#' \code{id} (if one was provided), \code{text_hash} (the MD5 hash of the text), a column each for relevant entries in \code{api_args},
#' and scores from each included framework (e.g., \code{summary.word_count} and \code{liwc.i}). If \code{as_list} is \code{TRUE},
#' returns a list with a named entry containing such a \code{data.frame} for each framework.
#'
#' @section Cache:
#' If the \code{cache} argument is specified, results for unique texts are saved in an
#' \href{https://arrow.apache.org}{Arrow} database in the cache location
#' (\code{Sys.getenv(}\code{"RECEPTIVITI_CACHE")}), and are retrieved with subsequent requests.
#' This ensures that the exact same texts are not re-sent to the API.
#' This does, however, add some processing time and disc space usage.
#'
#' If \code{cache} is \code{TRUE}, a default directory (\code{receptiviti_cache}) will be looked for
#' in the system's temporary directory (which is usually the parent of \code{tempdir()}).
#' If this does not exist, you will be asked if it should be created.
#'
#' The primary cache is checked when each bundle is processed, and existing results are loaded at
#' that time. When processing many bundles in parallel, and many results have been cached,
#' this can cause the system to freeze and potentially crash.
#' To avoid this, limit the number of cores, or disable parallel processing.
#'
#' The \code{cache_format} arguments (or the \code{RECEPTIVITI_CACHE_FORMAT} environment variable) can be used to adjust the format of the cache.
#'
#' You can use the cache independently with \code{open_database(Sys.getenv("RECEPTIVITI_CACHE"))}.
#'
#' You can also set the \code{clear_cache} argument to \code{TRUE} to clear the cache before it is used again, which may be useful
#' if the cache has gotten big, or you know new results will be returned. Even if a cached result exists, it will be
#' reprocessed if it does not have all of the variables of new results, but this depends on there being at least 1 uncached
#' result. If, for instance, you add a framework to your account and want to reprocess a previously processed set of texts,
#' you would need to first clear the cache.
#'
#' Either way, duplicated texts within the same call will only be sent once.
#'
#' The \code{request_cache} argument controls a more temporary cache of each bundle request. This is cleared when the
#' R session ends. You might want to set this to \code{FALSE} if a new framework becomes available on your account
#' and you want to process a set of text you already processed in the current R session without restarting.
#'
#' Another temporary cache is made when \code{in_memory} is \code{FALSE}, which is the default when processing
#' in parallel (when \code{cores} is over \code{1} or \code{use_future} is \code{TRUE}). This contains
#' a file for each unique bundle, which is read in as needed by the parallel workers.
#'
#' @section Parallelization:
#' \code{text}s are split into bundles based on the \code{bundle_size} argument. Each bundle represents
#' a single request to the API, which is why they are limited to 1000 texts and a total size of 10 MB.
#' When there is more than one bundle and either \code{cores} is greater than 1 or \code{use_future} is \code{TRUE} (and you've
#' externally specified a \code{\link[future]{plan}}), bundles are processed by multiple cores.
#'
#' If you have texts spread across multiple files, they can be most efficiently processed in parallel
#' if each file contains a single text (potentially collapsed from multiple lines). If files contain
#' multiple texts (i.e., \code{collapse_lines = FALSE}), then texts need to be read in before bundling
#' in order to ensure bundles are under the length limit.
#'
#' Whether processing in serial or parallel, progress bars can be specified externally with
#' \code{\link[progressr]{handlers}}; see examples.
#' @examples
#' \dontrun{
#'
#' # check that the API is available, and your credentials work
#' receptiviti_status()
#'
#' # score a single text
#' single <- receptiviti("a text to score")
#'
#' # score multiple texts, and write results to a file
#' multi <- receptiviti(c("first text to score", "second text"), "filename.csv")
#'
#' # score many texts in separate files
#' ## defaults to look for .txt files
#' file_results <- receptiviti(dir = "./path/to/txt_folder")
#'
#' ## could be .csv
#' file_results <- receptiviti(
#'   dir = "./path/to/csv_folder",
#'   text_column = "text", file_type = "csv"
#' )
#'
#' # score many texts from a file, with a progress bar
#' ## set up cores and progress bar
#' ## (only necessary if you want the progress bar)
#' future::plan("multisession")
#' progressr::handlers(global = TRUE)
#' progressr::handlers("progress")
#'
#' ## make request
#' results <- receptiviti(
#'   "./path/to/largefile.csv",
#'   text_column = "text", use_future = TRUE
#' )
#' }
#' @importFrom curl new_handle curl_fetch_memory curl_fetch_disk handle_setopt
#' @importFrom jsonlite toJSON fromJSON read_json
#' @importFrom utils object.size
#' @importFrom digest digest
#' @importFrom parallel detectCores makeCluster clusterExport parLapplyLB parLapply stopCluster
#' @importFrom progressr progressor
#' @importFrom stringi stri_enc_detect
#' @export

receptiviti <- function(text = NULL, output = NULL, id = NULL, text_column = NULL, id_column = NULL, files = NULL, dir = NULL,
                        file_type = "txt", encoding = NULL, return_text = FALSE, api_args = getOption("receptiviti.api_args", list()),
                        frameworks = getOption("receptiviti.frameworks", "all"), framework_prefix = TRUE, as_list = FALSE,
                        bundle_size = 1000, bundle_byte_limit = 75e5, collapse_lines = FALSE, retry_limit = 50, clear_cache = FALSE,
                        clear_scratch_cache = TRUE, request_cache = TRUE, cores = detectCores() - 1, use_future = FALSE,
                        in_memory = TRUE, verbose = FALSE, overwrite = FALSE, compress = FALSE, make_request = TRUE,
                        text_as_paths = FALSE, cache = Sys.getenv("RECEPTIVITI_CACHE"), cache_overwrite = FALSE,
                        cache_format = Sys.getenv("RECEPTIVITI_CACHE_FORMAT", "parquet"), key = Sys.getenv("RECEPTIVITI_KEY"),
                        secret = Sys.getenv("RECEPTIVITI_SECRET"), url = Sys.getenv("RECEPTIVITI_URL"),
                        version = Sys.getenv("RECEPTIVITI_VERSION"), endpoint = Sys.getenv("RECEPTIVITI_ENDPOINT")) {
  # check input
  if (!is.null(output)) {
    if (!file.exists(output) && file.exists(paste0(output, ".xz"))) output <- paste0(output, ".xz")
    if (!overwrite && file.exists(output)) stop("output file already exists; use overwrite = TRUE to overwrite it", call. = FALSE)
  }
  if (isTRUE(cache)) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("install the `arrow` package to enable the cache", call. = FALSE)
    }
    temp <- dirname(tempdir())
    if (basename(temp) == "working_dir") temp <- dirname(dirname(temp))
    cache <- paste0(temp, "/receptiviti_cache")
    if (!dir.exists(cache)) {
      if (interactive() && !isFALSE(getOption("receptiviti.cache_prompt")) &&
        grepl("^(?:[Yy1]|$)", readline("Do you want to establish a default cache? [Y/n] "))) {
        dir.create(cache, FALSE)
      } else {
        options(receptiviti.cache_prompt = FALSE)
        cache <- FALSE
      }
    }
  }
  st <- proc.time()[[3]]
  res <- manage_request(
    text,
    id = id, text_column = text_column, id_column = id_column, files = files, dir = dir,
    file_type = file_type, encoding = encoding, api_args = api_args, bundle_size = bundle_size,
    bundle_byte_limit = bundle_byte_limit, collapse_lines = collapse_lines,
    retry_limit = retry_limit, clear_cache = clear_cache, clear_scratch_cache = clear_scratch_cache,
    request_cache = request_cache, cores = cores, use_future = use_future, in_memory = in_memory,
    verbose = verbose, make_request = make_request, text_as_paths = text_as_paths, cache = cache,
    cache_overwrite = cache_overwrite, cache_format = cache_format, key = key, secret = secret,
    url = url, version = version, endpoint = endpoint
  )
  data <- res$data
  final_res <- res$final_res

  # update cache
  if (is.character(cache) && cache != "") {
    cache <- normalizePath(cache, "/", FALSE)
    text_hash <- bin <- NULL
    if (verbose) message("checking cache (", round(proc.time()[[3]] - st, 4), ")")
    initialized <- dir.exists(paste0(cache, "/bin=h"))
    if (initialized) {
      db <- arrow::open_dataset(cache, partitioning = arrow::schema(bin = arrow::string()), format = cache_format)
      if (db$num_cols != (ncol(final_res) - 1)) {
        if (verbose) message("clearing existing cache since columns did not align (", round(proc.time()[[3]] - st, 4), ")")
        dir.create(cache, FALSE)
        initialized <- FALSE
      }
    }
    exclude <- c("id", names(api_args))
    if (!initialized) {
      su <- !colnames(final_res) %in% exclude
      if (sum(su) > 2) {
        initial <- final_res[1, su]
        initial$text_hash <- ""
        initial$bin <- "h"
        initial[, !colnames(initial) %in% c(
          "summary.word_count", "summary.sentence_count"
        ) & !vapply(initial, is.character, TRUE)] <- .1
        initial <- rbind(initial, final_res[, colnames(initial)])
        if (verbose) {
          message(
            "initializing cache with ", nrow(final_res), " result",
            if (nrow(final_res) > 1) "s", " (", round(proc.time()[[3]] - st, 4), ")"
          )
        }
        arrow::write_dataset(
          initial, cache,
          format = cache_format, partitioning = "bin",
          basename_template = paste0("0-{i}.", cache_format)
        )
      }
    } else {
      fresh <- final_res[
        !duplicated(final_res$text_hash), !colnames(final_res) %in% names(api_args),
        drop = FALSE
      ]
      cached <- dplyr::filter(db, bin %in% unique(fresh$bin), text_hash %in% fresh$text_hash)
      if (!any(dim(cached) == 0) || nrow(cached) != nrow(fresh)) {
        uncached_hashes <- if (nrow(cached)) {
          !fresh$text_hash %in% dplyr::collect(dplyr::select(cached, text_hash))[[1]]
        } else {
          rep(TRUE, nrow(fresh))
        }
        if (any(uncached_hashes)) {
          if (verbose) {
            message(
              "updating cache with ", sum(uncached_hashes), " result",
              if (sum(uncached_hashes) > 1) "s", " (", round(proc.time()[[3]] - st, 4), ")"
            )
          }
          arrow::write_dataset(
            fresh[uncached_hashes, !colnames(fresh) %in% exclude], cache,
            format = cache_format, partitioning = "bin",
            basename_template = paste0(as.numeric(Sys.time()), "-{i}.", cache_format)
          )
        }
      }
    }
  }

  # prepare final results
  if (verbose) message("preparing output (", round(proc.time()[[3]] - st, 4), ")")
  rownames(final_res) <- final_res$id
  rownames(data) <- data$id
  data$text_hash <- structure(final_res$text_hash, names = data[final_res$id, "text"])[data$text]
  final_res <- cbind(
    data[, c(if (return_text) "text", if (res$provided_id) "id", "text_hash"), drop = FALSE],
    final_res[
      structure(final_res$id, names = final_res$text_hash)[data$text_hash],
      !colnames(final_res) %in% c("id", "bin", "text_hash", "custom"),
      drop = FALSE
    ]
  )
  row.names(final_res) <- NULL
  if (!is.null(output)) {
    if (!grepl("\\.csv", output, TRUE)) output <- paste0(output, ".csv")
    if (compress && !grepl(".xz", output, fixed = TRUE)) output <- paste0(output, ".xz")
    if (grepl(".xz", output, fixed = TRUE)) compress <- TRUE
    if (verbose) message("writing results to file: ", output, " (", round(proc.time()[[3]] - st, 4), ")")
    dir.create(dirname(output), FALSE, TRUE)
    if (overwrite) unlink(output)
    if (compress) output <- xzfile(output)
    arrow::write_csv_arrow(final_res, file = output)
  }

  if (is.character(frameworks) && frameworks[1] != "all") {
    if (verbose) message("selecting frameworks (", round(proc.time()[[3]] - st, 4), ")")
    vars <- colnames(final_res)
    sel <- grepl(paste0("^(?:", paste(tolower(frameworks), collapse = "|"), ")"), vars)
    if (any(sel)) {
      if (missing(framework_prefix) && (length(frameworks) == 1 && frameworks != "all")) framework_prefix <- FALSE
      sel <- unique(c("text", "id", "text_hash", names(api_args), vars[sel]))
      sel <- sel[sel %in% vars]
      final_res <- final_res[, sel]
    } else {
      warning("frameworks did not match any columns -- returning all", call. = FALSE)
    }
  }
  if (as_list) {
    if (missing(framework_prefix)) framework_prefix <- FALSE
    inall <- c("text", "id", "text_hash", names(api_args))
    cols <- colnames(final_res)
    inall <- inall[inall %in% cols]
    pre <- sub("\\..*$", "", cols)
    pre <- unique(pre[!pre %in% inall])
    final_res <- lapply(structure(pre, names = pre), function(f) {
      res <- final_res[, c(inall, grep(paste0("^", f), cols, value = TRUE))]
      if (!framework_prefix) colnames(res) <- sub("^.+\\.", "", colnames(res))
      res
    })
  } else if (!framework_prefix) colnames(final_res) <- sub("^.+\\.", "", colnames(final_res))
  if (verbose) message("done (", round(proc.time()[[3]] - st, 4), ")")
  invisible(final_res)
}
