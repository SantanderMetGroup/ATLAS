library(magrittr)
library(httr)
library(lattice)

# USER PARAMETER SETTING -----------------------------------------------------------------------

# datasets
datasets <- "CMIP6"# "CMIP6Amon"

# output directory, e.g.:
out.dir <- "AtlasHub-inventory/Hub/Hub_vs_ESGF"


# LIST FILES IN URL -----------------------------------------------------------------------------
# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"

# list the subset of target files
ls <- grep(paste0("ESGF-inventory/", gsub("Amon", "", datasets), "/", datasets, ".csv"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
esgffile <- paste0(root, ls)
ls <- grep(paste0("AtlasHub-inventory/Hub/", datasets, "_"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
hubfile <- paste0(root, ls)

# FIND MATCHES AND EXPORT PDF AND CSV -------------------------------------------------------------
hub <- read.csv(hubfile)
esgf <- read.csv(esgffile)
x.hub <- strsplit(as.character(hub[,1]), "_")
x.hub <- lapply(x.hub, "[", c(2,4,3))
x.hub <- lapply(x.hub, function(i) paste0(paste(i, collapse = ".*"), ".*"))
x.esgf <- as.character(esgf[,1])

esgf[,-1] <- data.frame(lapply(esgf[,-1], as.logical))
diff <- esgf
nam <- colnames(esgf[,-1])
ind <- numeric()
for (i in 1:nrow(hub)) {
  k <- grep(x.hub[i], esgf[,1])
  if (length(k) < 1) k <- NA
  if (!is.na(k)) {
    for (j in nam) {
      exists <- esgf[k, j]
      if (exists) {
        if (hub[i, j]) {
          diff[k, j] <- 1L
        } else {
          diff[k, j] <- 0L
        }
      } else {
        diff[k, j] <- NA
      }
    }
  }
}

# csv
write.csv(diff, paste0(out.dir, "/", gsub(paste0(".*", datasets), datasets, ls)))

# figure
diff.p <- as.matrix(diff[,-1])
rownames(diff.p) <- as.character(diff[,1])
pdf(paste0(out.dir, "/", gsub(".csv", ".pdf", gsub(paste0(".*", datasets), datasets, ls))), width = 5, height = 60)
levelplot(t(diff.p), scales=list(x=list(alternating=2, rot=90, cex = 0.5),
                                     y=list(cex = 0.5)),
                  border = "black", bw = 10, ylab = NULL, colorkey = FALSE,
                  xlab = "",
                  col.regions = c("red", "green"),
                  main = list("green = available    red = not available   white = not available in ESGF", cex = 0.8))
dev.off()

