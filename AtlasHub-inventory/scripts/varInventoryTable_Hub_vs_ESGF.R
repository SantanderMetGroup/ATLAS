library(magrittr)
library(httr)
library(lattice)

# USER PARAMETER SETTING -----------------------------------------------------------------------

# datasets
datasets <- "CORDEX_day" #"CMIP6_mon"# "CMIP6_day" #"CORDEX_mon" 
datasets.label <- "CORDEX-"
# output directory, e.g.:
out.dir <- "AtlasHub-inventory/Hub/Hub_vs_ESGF"
extension <-  ""#"_1run"

# LIST FILES IN URL -----------------------------------------------------------------------------
# https://stackoverflow.com/questions/25485216/how-to-get-list-files-from-a-github-repository-folder-using-r
myurl <- "https://api.github.com/repos/SantanderMetGroup/ATLAS/git/trees/devel?recursive=1"
req <- GET(myurl) %>% stop_for_status(req)
filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = FALSE)
root <- "https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/devel/"

# list the subset of target files
ls <- grep(paste0("ESGF-inventory/", gsub("_.*", "", datasets),"/", datasets, extension,".csv"), filelist, value = TRUE, fixed = TRUE) %>% grep("\\.csv$", ., value = TRUE)
esgffile <- paste0(root, ls)
ls <- grep(paste0("AtlasHub-inventory/Hub/", datasets, ".*_Hub.csv"), filelist, value = TRUE, fixed = FALSE) %>% grep("\\.csv$", ., value = TRUE)
hubfile <- paste0(root, ls)
hubfile <- hubfile[5]
# FIND MATCHES AND EXPORT PDF AND CSV -------------------------------------------------------------


lapply(hubfile, function(hub){
hubdf <- read.csv(hub)
hubdf.label <- gsub(datasets.label, "", as.character(hubdf[,1]))
esgf <- read.csv(esgffile)

x.hub <- strsplit(as.character(hubdf.label), "_")
ind <- c(2,4,3)
if (gsub("_.*", "", datasets) == "CORDEX") {
  ind <- (1:6)[-5]
  # x.hub.domain <- unique(lapply(x.hub, function(l) {sub('(?<=.{3})', '-', gsub("CORDEX-", "", l[[1]]), perl = TRUE)}))
  # esgf <- esgf[grep(paste0(x.hub.domain, "."), as.character(esgf[,1]), fixed = TRUE),]
}
x.hub <- lapply(x.hub, "[", ind)
x.hub <- lapply(x.hub, function(i) paste0(paste(i, collapse = ".*"), ".*"))
x.esgf <- as.character(esgf[,1])


esgf[,-(1:2)] <- data.frame(lapply(esgf[,-(1:2)], as.logical))
diff <- esgf
nam <- colnames(esgf[,-(1:2)])
for (i in 1:nrow(hubdf)) {
  message(i)
  k <- grep(x.hub[i], esgf[,1])
  if (length(k) < 1) k <- NA
  if (length(k) > 1) {
    choices <- sapply(strsplit(as.character(esgf[k, 1]), "\\."), "[", 4)
    ch <- sapply(choices, grep, x.hub[i])  
    k <- k[which(ch == 1)]
  }
  if (!is.na(k)) {
    for (j in nam) {
      exists <- esgf[k, j]
      if (exists) {
        if (is.null(hubdf[i, j])){
          diff[k, j] <- 0L
        } else if (hubdf[i, j]) {
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
filename <- paste0(out.dir, "/", gsub(".csv", paste0("_vs_ESGF", extension, "_", gsub("-", "", Sys.Date()), ".csv"), gsub(".*/", "", hub)))
write.csv(diff, filename)

# figure
diff.p <- as.matrix(diff[nrow(diff):1,-(1:2)])
rownames(diff.p) <- as.character(diff[nrow(diff):1,1])
pdf(gsub(".csv", ".pdf", filename), width = 5, height = 120)
levelplot(t(diff.p), scales=list(x=list(alternating=2, rot=90, cex = 0.5),
                                 y=list(cex = 0.5)),
          border = "black", bw = 10, ylab = NULL, colorkey = FALSE,
          xlab = "",
          col.regions = c("red", "green"),
          main = list("green = available    red = not available   white = not available in ESGF", cex = 0.8))
dev.off()
})
