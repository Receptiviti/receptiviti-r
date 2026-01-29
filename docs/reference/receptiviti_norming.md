# View or Establish Custom Norming Contexts

Custom norming contexts can be used to process later texts by specifying
the `custom_context` API argument in the `receptiviti` function (e.g.,
`receptiviti("text to score", version = "v2", options = list(custom_context = "norm_name"))`,
where `norm_name` is the name you set here).

## Usage

``` r
receptiviti_norming(name = NULL, text = NULL, options = list(),
  delete = FALSE, name_only = FALSE, id = NULL, text_column = NULL,
  id_column = NULL, files = NULL, dir = NULL, file_type = "txt",
  collapse_lines = FALSE, encoding = NULL, bundle_size = 1000,
  bundle_byte_limit = 7500000, retry_limit = 50,
  clear_scratch_cache = TRUE, use_future = FALSE, in_memory = TRUE,
  url = Sys.getenv("RECEPTIVITI_URL"), key = Sys.getenv("RECEPTIVITI_KEY"),
  secret = Sys.getenv("RECEPTIVITI_SECRET"), verbose = TRUE)
```

## Arguments

- name:

  Name of a new norming context, to be established from the provided
  `text`. Not providing a name will list the previously created
  contexts.

- text:

  Text to be processed and used as the custom norming context. Not
  providing text will return the status of the named norming context.

- options:

  Options to set for the norming context (e.g.,
  `list(min_word_count = 350,` `max_punctuation = .25)`).

- delete:

  Logical; If `TRUE`, will request to remove the `name` context.

- name_only:

  Logical; If `TRUE`, will return a character vector of names only,
  including those of build-in contexts.

- id, text_column, id_column, files, dir, file_type, collapse_lines,
  encoding:

  Additional arguments used to handle `text`; same as those in
  [`receptiviti`](https://receptiviti.github.io/receptiviti-r/reference/receptiviti.md).

- bundle_size, bundle_byte_limit, retry_limit, clear_scratch_cache,
  use_future, in_memory:

  Additional arguments used to manage the requests; same as those in
  [`receptiviti`](https://receptiviti.github.io/receptiviti-r/reference/receptiviti.md).

- key, secret, url:

  Request arguments; same as those in
  [`receptiviti`](https://receptiviti.github.io/receptiviti-r/reference/receptiviti.md).

- verbose:

  Logical; if `TRUE`, will show status messages.

## Value

Nothing if `delete` if `TRUE`. Otherwise, if `name` is not specified, a
character vector containing names of each available norming context
(built-in and custom). If `text` is not specified, the status of the
named context in a `list`. If `text`s are provided, a `list`:

- `initial_status`: Initial status of the context.

- `first_pass`: Response after texts are sent the first time, or `NULL`
  if the initial status is `pass_two`.

- `second_pass`: Response after texts are sent the second time.

## Examples

``` r
if (FALSE) { # \dontrun{

# get status of all existing custom norming contexts
contexts <- receptiviti_norming(name_only = TRUE)

# create or get the status of a single custom norming context
status <- receptiviti_norming("new_context")

# send texts to establish the context

## these texts can be specified just like
## texts in the main receptiviti function

## such as directly
full_status <- receptiviti_norming("new_context", c(
  "a text to set the norm",
  "another text part of the new context"
))

## or from a file
full_status <- receptiviti_norming(
  "new_context", "./path/to/text.csv",
  text_column = "texts"
)

## or from multiple files in a directory
full_status <- receptiviti_norming(
  "new_context",
  dir = "./path/to/txt_files"
)
} # }
```
