## The Climate Change ATLAS: Datasets, code and virtual workspace

The Climate Change ATLAS is an initiative to develop ready-to-use code and datasets for regional analysis of observed and model projected (e.g. CMIP6 and CORDEX) climate change information using both time-slices (e.g. 2081-2100) and warming levels (e.g. +1.5º). An updated set of sub-continental reference regions is provided as the basis for regional synthesis (building on AR5 reference regions) and monthly spatially aggregated datasets are produced to facilitate the development of regional climate change proudcts. 

The **accessibility and reproducibility of scientific results** has been a major concern during the development of the Climate Change ATLAS, in order to ensure the transparency of the products (which will be all publicly available). The Atlas products are generated using **free software community tools**, in particular [R](https://www.r-project.org) building on the [**climate4R** framework](https://github.com/SantanderMetGroup/climate4R) for data post-processing (regridding, aggregation, bias adjustment, etc.) and evaluation and quality control (when applicable). **Provenance metadata** is generated using the [**METACLIP**](http://www.metaclip.org) RDF-based framework (building on the [metaclipR](https://github.com/metaclip/metaclipR) package for the climate4R framework).

### Reference Regions 
A new set of reference regions have been proposed for the regional synthesis of observed and model projected (CMIP6) climate change information. The new regions build on the popular [AR5 IPCC reference regions](http://www.ipcc-data.org/guidelines/pages/ar5_regions.html) developed for reporting sub-continental CMIP5 projections over a reduced number of regions with a representative number of model gridboxes. The increased reasolution (typically 1º in CMIP6 vs 2º in CMIP5) allows to increase the number of regions to 43 land (plus 12 open ocean) reference regions. 

### Aggregated CMIP datasets

The IPCC reference regions have been used as the basis to generate popular spatially aggregated datasets, such as the seasonal mean temperature and precipitation in IPCC regions for CMIP5. Here we produce a similar product using CMIP6 for the new regions (this will later extended to CMIP5 and CORDEX datasets).   

### The Atlas Hub

The Atlas Hub is a cloud facility providing virtual workspace for the Climate Change Atlas code and data (with preinstalled software and accesible data). The Atlas Hub is based on **Jupyter** to create and run notebooks on a remote machine where all the software is pre-installed (instructions available in the *IPCC-Atlas_hub_instructions.pdf* document). The Atlas Hub builds on the R **climate4R** package, allowing for transparent climate data access, collocation, post-processing (including bias correction) and visualization. Instructions to start working with the Hub are available at the document [IPCC-Atlas_hub_instructions.pdf](https://github.com/SantanderMetGroup/IPCC-Atlas/IPCC-Atlas_hub_instructions.pdf) on this repository.

### **Important**: This initiative contributes to the development of the IPCC AR6 Atlas, but this is not an official IPCC site. This repository is fully managed by the [Santander Met Group](https://github.com/SantanderMetGroup) and it is only intended to keep track of internal research activities.
