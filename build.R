# rebuild
system2("air", "format .")
styler::style_pkg(filetype = "Rmd")
spelling::spell_check_package()
devtools::document()
pkgdown::build_site(lazy = TRUE)
covr::report(covr::package_coverage(quiet = FALSE), "docs/v/dev/coverage.html")

# checks
devtools::check()
devtools::check_win_devel()

# releases
devtools::release()
