# List Available Frameworks

Retrieve the list of frameworks available to your account.

## Usage

``` r
receptiviti_frameworks(url = Sys.getenv("RECEPTIVITI_URL"),
  key = Sys.getenv("RECEPTIVITI_KEY"),
  secret = Sys.getenv("RECEPTIVITI_SECRET"))
```

## Arguments

- url, key, secret:

  Request arguments; same as those in
  [`receptiviti`](https://receptiviti.github.io/receptiviti-r/reference/receptiviti.md).

## Value

A character vector containing the names of frameworks available to your
account.

## Examples

``` r
if (FALSE) { # \dontrun{

# see which frameworks are available to your account
frameworks <- receptiviti_frameworks()
} # }
```
