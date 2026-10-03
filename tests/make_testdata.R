# Create test data for checking the webR apps in tests/data/ (not committed)
#   birthwt_jp.csv : binary response (ROC curve) with Japanese column names and factor
#                    levels (UTF-8), to check Japanese text in plots, PDFs and CSV downloads
#   iris.csv       : continuous response (regression) and a 3-class response
# Usage (in the repository root): Rscript tests/make_testdata.R

library(MASS)

dir.create("tests/data", showWarnings = FALSE, recursive = TRUE)

b <- birthwt
d <- data.frame(
  低体重   = b$low,
  年齢     = b$age,
  母体重   = b$lwt,
  人種     = factor(b$race, levels = 1:3, labels = c("白人", "黒人", "その他")),
  喫煙     = factor(b$smoke, levels = 0:1, labels = c("なし", "あり")),
  早産歴   = b$ptl,
  高血圧   = factor(b$ht, levels = 0:1, labels = c("なし", "あり")),
  子宮過敏 = factor(b$ui, levels = 0:1, labels = c("なし", "あり")),
  受診回数 = b$ftv
)
write.csv(d, "tests/data/birthwt_jp.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(iris, "tests/data/iris.csv", row.names = FALSE)

str(d)
