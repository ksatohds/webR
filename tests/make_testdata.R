# webR 版アプリの動作確認用データを tests/data/ に作る
#   birthwt_jp.csv : 2値応答 (ROC) + 日本語の列名・水準 (UTF-8)
#   iris.csv       : 連続応答 (回帰) と 3 クラス分類の両方に使う
# 使い方: このファイルのあるフォルダの親で Rscript tests/make_testdata.R

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
