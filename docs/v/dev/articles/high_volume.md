# High Volume

*Built with R 4.4.2*

------------------------------------------------------------------------

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

## Cache as Output

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
library(receptiviti)

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
#> 1  4ab51432a48a54d4fd780d226d0c3f1c                  4
#> 2  4845354bad8717fcd19ca95313715734                  4
#> 3  786744d45ec2d0e302394dc2ececa004                  4
#> 4  bb2ced7fa2cf67ec2aa974bac3cfb609                  4
#> 5  507616854eb89e3d12e49001fe4333c8                  4
#> 6  b80b47a8f2def76f4c256108053dda50                  4
#> 7  3c3d708014a7c25ee468afbd32843dab                  4
#> 8  fbc965c3d7b8cb1f487789bb9a313efa                  4
#> 9  11fa50aa3392a971cb0dc098d8efc5a4                  4
#> 10 72c5453f604e9493e3d7619542272068                  4
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

## Manual Chunking

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
#> Rows: 5 Columns: 1569
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr    (4): id, text_hash, interpersonal_circumplex.category, interpersonal_...
#> dbl (1565): summary.word_count, summary.words_per_sentence, summary.sentence...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 5 × 1,569
#>   id                         text_hash summary.word_count summary.words_per_se…¹
#>   <chr>                      <chr>                  <dbl>                  <dbl>
#> 1 ../../test_texts/example_… 4ab51432…                  4                      4
#> 2 ../../test_texts/example_… 4845354b…                  4                      4
#> 3 ../../test_texts/example_… 786744d4…                  4                      4
#> 4 ../../test_texts/example_… bb2ced7f…                  4                      4
#> 5 ../../test_texts/example_… 50761685…                  4                      4
#> # ℹ abbreviated name: ¹​summary.words_per_sentence
#> # ℹ 1,565 more variables: summary.sentence_count <dbl>,
#> #   summary.six_plus_words <dbl>, summary.capitals <dbl>, summary.emojis <dbl>,
#> #   summary.emoticons <dbl>, summary.hashtags <dbl>, summary.urls <dbl>,
#> #   personality.extraversion <dbl>, personality.active <dbl>,
#> #   personality.assertive <dbl>, personality.cheerful <dbl>,
#> #   personality.energetic <dbl>, personality.friendly <dbl>, …
```
