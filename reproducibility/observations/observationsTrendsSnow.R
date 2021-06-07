### Loading Libraries ------------------------------------------------------------------------------
options(java.parameters = "-Xmx8g")
library(loadeR) # C4R
library(transformeR) # C4R
library(visualizeR) # C4R
library(climate4R.indices) # C4R
library(magrittr) # The package magrittr is used to pipe (%>%) sequences of data operations improving readability
library(gridExtra) # plotting functionalities
library(sp) # plotting functionalities
library(RColorBrewer)  # plotting functionalities e.g., color palettes
library(rgdal)
setwd("/Users/jorgebanomedina//Desktop/IPCC/")


### Loading the IPCC regions ------------------------------------------------------------------------------
regs <- get(load(url("https://raw.githubusercontent.com/SantanderMetGroup/ATLAS/master/reference-regions/IPCC-WGI-reference-regions-v4_R.rda")))
regs <- as(regs, "SpatialPolygons")
regs.area <- c("RAR","EEU","WSB","ESB","RFE","WCA","NEU","WCE","ECA","EAS")

### Loading data ------------------------------------------------------------------------------
snowH <- loadStationData(dataset = "NorthAsia/datasets/", var = "snowheight", years = 1980:2015) 
mask <-  binaryGrid(snowH, condition = "GE", threshold = 9999, values = c(1,NA))
snowH %<>% gridArithmetics(mask) %>% gridArithmetics(10)
snowC <- loadStationData(dataset = "NorthAsia/datasets/", var = "snowcover", years = 1980:2015) 
mask <- binaryGrid(snowC, condition = "GE", threshold = 990, values = c(1,NA))
snowC %<>% gridArithmetics(mask) %>% binaryGrid(condition = "GT", threshold = 0)

### Compute Maximum yearly snow height (and trends) ------------------------------------------------------------------------------
# Maximum snow height ------------------------------------------------------------------------------
snowH %<>% aggregateGrid(aggr.y = list(FUN = "max", na.rm = TRUE))
snowH$Data[which(snowH$Data == -Inf, arr.ind = TRUE)] <- NA

# Compute the linear trends ------------------------------------------------------------------------------
objGrid <- linearTrend(snowH, p = 0.9)
lt <- subsetGrid(objGrid, var = "b") %>% gridArithmetics(10)
pval <- subsetGrid(objGrid, var = "pval") %>% binaryGrid(condition = "GT", threshold = 0.1)
ind <- which(pval$Data == 1)
x <- pval$xyCoords$x[ind]
y <- pval$xyCoords$y[ind]
mat <- cbind(x,y)

### We depict the spatial maps ------------------------------------------------------------------------------
pdf("snowHeight.pdf")
spatialPlot(lt, backdrop.theme = "coastline", main = "Linear trend of the maximum yearly snow height (mm/decade)", ylab = "1980-2015",
                      color.theme = "RdBu",
                      at = seq(-120,120,length.out = 11), 
                      set.min = -120, set.max = 120,
                      pch = 21,
                      cex = 0.5,
                      xlim = c(8,180),
                      colorkey = TRUE,
                      sp.layout = list(
                        list(regs[regs.area], first = FALSE, lwd = 0.6),
                        list("sp.text", coordinates(regs[regs.area]), names(regs[regs.area]), first = FALSE, cex = 0.6),
                        list("sp.points", SpatialPoints(mat), pch = 4, first = FALSE, cex = 0.4, col = "black", lwd = 0.4)
                      ))
dev.off()

### Snow duration (Jan-Jun) ------------------------------------------------------------------------------
snowH <- loadStationData(dataset = "NorthAsia/datasets/", var = "snowheight", years = 1980:2015) %>% subsetGrid(season = 1:6)
mask <-  binaryGrid(snowH, condition = "GE", threshold = 9999, values = c(1,NA))
snowH %<>% gridArithmetics(mask) %>% binaryGrid(condition = "GT", threshold = 0) %>% aggregateGrid(aggr.y = list(FUN = "sum", na.rm = TRUE))

objGrid <- linearTrend(snowH, p = 0.9)
lt <- subsetGrid(objGrid,var = "b") %>% gridArithmetics(10)
pval <- subsetGrid(objGrid, var = "pval") %>% binaryGrid(condition = "GT", threshold = 0.1)
ind <- which(pval$Data == 1)
x <- pval$xyCoords$x[ind]
y <- pval$xyCoords$y[ind]
mat <- cbind(x,y)

pdf("coverDurationJanJun.pdf")
spatialPlot(lt, backdrop.theme = "coastline", main = "Linear trend of Jan-Jun snow duration (days/decade)", ylab = "1980-2015",
            color.theme = "RdBu",
            at = seq(-10,10,length.out = 11), 
            set.min = -10, set.max = 10,
            pch = 21,
            cex = 0.5,
            xlim = c(8,180),
            colorkey = TRUE,
            sp.layout = list(
              list(regs[regs.area], first = FALSE, lwd = 0.6),
              list("sp.text", coordinates(regs[regs.area]), names(regs[regs.area]), first = FALSE, cex = 0.6),
              list("sp.points", SpatialPoints(mat), pch = 4, first = FALSE, cex = 0.4, col = "black", lwd = 0.4)
            ))
dev.off()

### Snow duration (Jul-Dec) ------------------------------------------------------------------------------
snowH <- loadStationData(dataset = "NorthAsia/datasets/", var = "snowheight", years = 1980:2015) %>% subsetGrid(season = 7:12)
mask <-  binaryGrid(snowH, condition = "GE", threshold = 9999, values = c(1,NA))
snowH %<>% gridArithmetics(mask) %>% binaryGrid(condition = "GT", threshold = 0) %>% aggregateGrid(aggr.y = list(FUN = "sum", na.rm = TRUE))

objGrid <- linearTrend(snowH, p = 0.9)
lt <- subsetGrid(objGrid,var = "b") %>% gridArithmetics(10)
pval <- subsetGrid(objGrid, var = "pval") %>% binaryGrid(condition = "GT", threshold = 0.1)
ind <- which(pval$Data == 1)
x <- pval$xyCoords$x[ind]
y <- pval$xyCoords$y[ind]
mat <- cbind(x,y)

pdf("coverDurationJulDec.pdf")
spatialPlot(lt, backdrop.theme = "coastline", main = "Linear trend of Jul-Dec snow duration (days/decade)", ylab = "1980-2015",
            color.theme = "RdBu",
            at = seq(-10,10,length.out = 11), 
            set.min = -10, set.max = 10,
            pch = 21,
            cex = 0.5,
            xlim = c(8,180),
            colorkey = TRUE,
            sp.layout = list(
              list(regs[regs.area], first = FALSE, lwd = 0.6),
              list("sp.text", coordinates(regs[regs.area]), names(regs[regs.area]), first = FALSE, cex = 0.6),
              list("sp.points", SpatialPoints(mat), pch = 4, first = FALSE, cex = 0.4, col = "black", lwd = 0.4)
            ))
dev.off()

