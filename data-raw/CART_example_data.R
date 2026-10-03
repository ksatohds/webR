# Create the CART example data (site/CART/data/) from R's datasets package
# Usage (in the repository root): Rscript data-raw/CART_example_data.R

out <- "site/CART/data"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# iris: as it is
write.csv(iris, file.path(out, "iris.csv"), row.names = FALSE)

# Titanic: expand the 4-way table to one row per person (2201 rows)
# and replace Survived by Died (1 = did not survive)
d <- as.data.frame(Titanic)
d <- d[rep(seq_len(nrow(d)), d$Freq), c("Class", "Sex", "Age", "Survived")]
d$Died <- as.integer(d$Survived == "No")
d$Survived <- NULL
write.csv(d, file.path(out, "titanic.csv"), row.names = FALSE)
