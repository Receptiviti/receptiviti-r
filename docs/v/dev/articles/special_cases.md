# Special Cases

*Built with R 4.5.2*

------------------------------------------------------------------------

## Norming Contexts

Some measures are
[normed](https://docs.receptiviti.com/the-receptiviti-api/normed-vs-dictionary-counted-measures)
against a sample of text. These samples may be more or less appropriate
to your texts.

### Built-In

The default context is meant for general written text, and there is
another built-in context for general spoken text:

``` r
library(receptiviti)

text <- "Text to be normed differently."
written <- receptiviti(text, version = "v2")
spoken <- receptiviti(text, version = "v2", context = "spoken")

# select a few categories that differ between contexts
differing <- which(written != spoken)[1:10]

# note that the text hashes are sensitive to the set context
as.data.frame(t(rbind(written = written, spoken = spoken)[, differing]))
#>                                             written
#> text_hash          45bbf3011f5ef8bb027af931a202afc6
#> norming                                     written
#> big_5.extraversion                         29.63096
#> big_5.active                               41.53482
#> big_5.assertive                            17.80752
#> big_5.cheerful                             40.89578
#> big_5.energetic                            60.73497
#> big_5.friendly                             44.65852
#> big_5.sociable                              18.1215
#> big_5.openness                             7.772951
#>                                              spoken
#> text_hash          d89df4983ee8808bc1006c014ae142ca
#> norming                                      spoken
#> big_5.extraversion                         31.72386
#> big_5.active                               42.88861
#> big_5.assertive                            21.65620
#> big_5.cheerful                             39.88416
#> big_5.energetic                            64.80285
#> big_5.friendly                             45.00795
#> big_5.sociable                              17.8745
#> big_5.openness                             8.280626
```

### Custom

You can also norm against your own sample, which involves first
establishing a context, then scoring against it.

Use the `receptiviti_norming` function to establish a custom context:

``` r
context_text <- c(
  "Text with normed in it.",
  "Text with differently in it."
)

# set lower word count filter for this toy sample
context_status <- receptiviti_norming(
  name = "custom_example",
  text = context_text,
  options = list(min_word_count = 1),
  verbose = FALSE
)

# the `second_pass` result shows what was analyzed
context_status$second_pass
#>                          body_hash submitted_samples analyzed_samples
#> 1 a8ad333a99c513c46f270f369dc39dc2                 2                2
#>   analyzed_word_count filtered_blank filtered_word_count filtered_punctuation
#> 1                  10              0                   0                    0
```

Then use the `custom_context` argument to specify that norming context
when scoring:

``` r
custom <- receptiviti(text, version = "v2", custom_context = "custom_example")

as.data.frame(t(rbind(custom = custom[, differing])))
#>                                              custom
#> text_hash          3dee016e73a68569d7cd31e1564c84a3
#> norming                       custom/custom_example
#> big_5.extraversion                                0
#> big_5.active                                      0
#> big_5.assertive                                  50
#> big_5.cheerful                                   50
#> big_5.energetic                                  50
#> big_5.friendly                                   50
#> big_5.sociable                                    0
#> big_5.openness                                    0
```

## High Volume

The Receptiviti API has
[limits](https://docs.receptiviti.com/api-reference/framework-bulk) on
bundle requests, so the
[`receptiviti()`](https://receptiviti.github.io/receptiviti-r/reference/receptiviti.md)
function splits texts into acceptable bundles, to be spread across
multiple requests.

This means the only remaining limitation on the number of texts that can
be processed comes from the memory of the system sending requests.

The basic way to work around this limitation is to fully process smaller
chunks of text.

There are a few ways to avoid loading all texts and results.

### Cache as Output

Setting the `collect_results` argument to `False` avoids retaining all
batch results in memory as they are receive, but means results are not
returned, so the they have to be collected in the cache.

If texts are also too big to load into memory, they can be loaded from
files at request time. By default, when multiple files pointed to as
`text`, the actual texts are only loaded when they are being sent for
scoring, which means only `bundle_size` \* `cores` texts are loaded at a
time.

We can start by writing some small text examples to files:

``` r
base_dir <- "../../"
text_dir <- paste0(base_dir, "test_texts/")
dir.create(text_dir, FALSE, TRUE)

for (i in seq_len(10)) {
  writeLines(
    paste0("An example text ", i, "."),
    paste0(text_dir, "example_", i, ".txt")
  )
}
```

And then minimally load these and their results by saving results to a
Parquet dataset.

Disabling the `request_cache` will also avoid storing a copy of raw
results.

``` r
db_dir <- paste0(base_dir, "test_results")
dir.create(db_dir, FALSE, TRUE)

receptiviti(
  dir = text_dir, collect_results = FALSE, cache = db_dir,
  request_cache = FALSE, cores = 1
)
```

Results are now available in the cache directory, which you can load in
using the request function again:

``` r
# adding make_request=False just ensures requests are not made if not found
results <- receptiviti(dir = text_dir, cache = db_dir, make_request = FALSE)
results[, 2:4]
#>                           text_hash summary.word_count
#> 1  5f9b76d1c846acd9d5b7c8c91e230114                  4
#> 2  17c69948eccbd6e4077dcb529a0ba68f                  4
#> 3  87682e4113d7bf58377e1f2c6037bc99                  4
#> 4  99f34e51e2e12696b153e664fd01ed9c                  4
#> 5  db8f2e1d82674f51920c2e6b9d1e0f57                  4
#> 6  b7ed3ead170a92fbdc7b945a067dd181                  4
#> 7  1ae462819e36f657305695a8ac63858a                  4
#> 8  7c3bb4bd1dd6955041e2649cc7e99c51                  4
#> 9  6382fa2141d3ae2b313c9295fd76aaf1                  4
#> 10 bb9d24d530c37a7e2e5b8e7f852abe43                  4
#>    summary.words_per_sentence
#> 1                           4
#> 2                           4
#> 3                           4
#> 4                           4
#> 5                           4
#> 6                           4
#> 7                           4
#> 8                           4
#> 9                           4
#> 10                          4
```

### Manual Chunking

A more flexible approach would be to process smaller chunks of text
normally, and handle loading and storing results yourself.

In this case, it may be best to disable parallelization (if you’re
parallelizing manually), and explicitly disable the primary cache (in
case it’s specified in an environment variable).

``` r
res_dir <- paste0(base_dir, "text_results_manual")
dir.create(res_dir, FALSE, TRUE)

# using the same files as before
files <- list.files(text_dir, full.names = TRUE)

# process 5 files at a time
for (i in seq(1, 10, 5)) {
  file_subset <- files[seq(i, i + 4)]
  results <- receptiviti(
    files = file_subset, id = file_subset,
    cores = 1, cache = FALSE, request_cache = FALSE
  )
  vroom::vroom_write(
    results, paste0(res_dir, "/files_", i, "-", i + 5, ".csv.xz"), ","
  )
}
```

Now results will be stored in smaller files:

``` r
vroom::vroom(paste0(res_dir, "/files_1-6.csv.xz"))
#> Rows: 5 Columns: 199
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr   (2): id, text_hash
#> dbl (197): summary.word_count, summary.words_per_sentence, summary.sentence_...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 5 × 199
#>   id                         text_hash summary.word_count summary.words_per_se…¹
#>   <chr>                      <chr>                  <dbl>                  <dbl>
#> 1 ../../test_texts/example_… 5f9b76d1…                  4                      4
#> 2 ../../test_texts/example_… 17c69948…                  4                      4
#> 3 ../../test_texts/example_… 87682e41…                  4                      4
#> 4 ../../test_texts/example_… 99f34e51…                  4                      4
#> 5 ../../test_texts/example_… db8f2e1d…                  4                      4
#> # ℹ abbreviated name: ¹​summary.words_per_sentence
#> # ℹ 195 more variables: summary.sentence_count <dbl>,
#> #   summary.six_plus_words <dbl>, summary.capitals <dbl>, summary.emojis <dbl>,
#> #   summary.emoticons <dbl>, summary.hashtags <dbl>, summary.urls <dbl>,
#> #   personality.extraversion <dbl>, personality.active <dbl>,
#> #   personality.assertive <dbl>, personality.cheerful <dbl>,
#> #   personality.energetic <dbl>, personality.friendly <dbl>, …
```
