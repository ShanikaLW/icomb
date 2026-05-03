old_wd <- getwd()

setwd("vignettes-raw/")
knitr::knit("icomb.Rmd", output = "../vignettes/icomb.Rmd")

imgs <- list.files(pattern = "\\.png$")
imgs_new <- file.path("..", "vignettes", imgs)
file.rename(imgs, imgs_new)
setwd(old_wd)


