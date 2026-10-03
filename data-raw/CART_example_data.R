# CART のサンプルデータ (site/CART/data/) を R の datasets パッケージから作る
# 使い方: webR フォルダで Rscript data-raw/CART_example_data.R

out <- "site/CART/data"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# iris: そのまま
write.csv(iris, file.path(out, "iris.csv"), row.names = FALSE)

# Titanic: 4元分割表を1人1行 (2201行) に展開し、Survived を Died (1 = 死亡) に置き換える
d <- as.data.frame(Titanic)
d <- d[rep(seq_len(nrow(d)), d$Freq), c("Class", "Sex", "Age", "Survived")]
d$Died <- as.integer(d$Survived == "No")
d$Survived <- NULL
write.csv(d, file.path(out, "titanic.csv"), row.names = FALSE)
