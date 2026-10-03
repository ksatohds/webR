# apps/ 以下の各 Shiny アプリを Shinylive で docs/ に書き出す
# docs/ は GitHub Pages (main ブランチ /docs) で公開する
#   https://ksatohds.github.io/webR/        <- site/index.html (アプリ一覧)
#   https://ksatohds.github.io/webR/<app>/  <- apps/<app>/
#   site/ 以下のファイルはそのまま docs/ にコピー（例: site/CART/data/ -> docs/CART/data/）
#
# 使い方: このファイルのあるフォルダで Rscript build.R
#         特定のアプリだけ: Rscript build.R CART

library(shinylive)

apps <- commandArgs(trailingOnly = TRUE)
if (length(apps) == 0) apps <- list.dirs("apps", recursive = FALSE, full.names = FALSE)

dir.create("docs", showWarnings = FALSE)
for (app in apps) {
  unlink(file.path("docs", app), recursive = TRUE)
  shinylive::export(file.path("apps", app), "docs", subdir = app, quiet = FALSE)
}

# site/ 以下（アプリ一覧ページ、サンプルデータなど）をそのまま docs/ に重ねる
for (f in list.files("site", recursive = TRUE)) {
  dir.create(dirname(file.path("docs", f)), showWarnings = FALSE, recursive = TRUE)
  file.copy(file.path("site", f), file.path("docs", f), overwrite = TRUE)
}
# GitHub Pages の Jekyll 処理を止める（"_" で始まるファイルが配信されなくなるのを防ぐ）
file.create("docs/.nojekyll")

cat("shinylive", as.character(packageVersion("shinylive")),
    "/ assets", shinylive::assets_version(), "\n")
