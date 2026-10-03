# Export every Shiny app under apps/ into docs/ with Shinylive.
# docs/ is published by GitHub Pages (branch main, folder /docs):
#   https://ksatohds.github.io/webR/        <- site/index.html (list of apps)
#   https://ksatohds.github.io/webR/<app>/  <- apps/<app>/
#   Files under site/ are copied into docs/ as they are (e.g. site/CART/data/ -> docs/CART/data/)
#
# Usage (in this folder): Rscript build.R
#         a single app:   Rscript build.R CART

library(shinylive)

apps <- commandArgs(trailingOnly = TRUE)
if (length(apps) == 0) apps <- list.dirs("apps", recursive = FALSE, full.names = FALSE)

dir.create("docs", showWarnings = FALSE)
for (app in apps) {
  unlink(file.path("docs", app), recursive = TRUE)
  shinylive::export(file.path("apps", app), "docs", subdir = app, quiet = FALSE)
}

# Copy everything under site/ (index page, example data, ...) into docs/
for (f in list.files("site", recursive = TRUE)) {
  dir.create(dirname(file.path("docs", f)), showWarnings = FALSE, recursive = TRUE)
  file.copy(file.path("site", f), file.path("docs", f), overwrite = TRUE)
}
# Turn off Jekyll on GitHub Pages (otherwise files whose names start with "_" are not served)
file.create("docs/.nojekyll")

cat("shinylive", as.character(packageVersion("shinylive")),
    "/ assets", shinylive::assets_version(), "\n")
