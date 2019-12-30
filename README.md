# The Climate Change ATLAS 

The Climate Change ATLAS is an initiative to develop ready-to-use code and datasets for regional analysis of observed and model projected (e.g. CMIP6 and CORDEX) climate change information. An updated set of sub-continental reference regions is provided as the basis for regional synthesis (building on AR5 reference regions) and monthly spatially aggregated datasets are produced to facilitate the development of regional climate change proudcts. This initiative aims to contribute to the IPCC AR6. 

The **accessibility and reproducibility of scientific results** has been a major concern during the development of the Climate Change ATLAS, in order to ensure the transparency of the products (which will be all publicly available). The Atlas products are generated using **free software community tools**, in particular [R](https://www.r-project.org) building on the [**climate4R** framework](https://github.com/SantanderMetGroup/climate4R) for data post-processing (regridding, aggregation, bias adjustment, etc.) and evaluation and quality control (when applicable). **Provenance metadata** is generated using the [**METACLIP**](http://www.metaclip.org) RDF-based framework (building on the [metaclipR](https://github.com/metaclip/metaclipR) package for the climate4R framework).

### Reference Regions 
Different reference regions have been proposed for the regional synthesis of observed and model projected (CMIP) climate change information. A popular example is the [AR5 IPCC reference regions](http://www.ipcc-data.org/guidelines/pages/ar5_regions.html) developed for reporting sub-continental CMIP5 projections over a reduced number of regions encompassing a representative number of model gridboxes (the typical resolution of CMIP5 was around 2º). 

### Aggregated CMIP datasets

The IPCC reference regions have been used as the basis to generate popular spatially aggregated datasets, such as the seasonal mean temperature and precipitation in IPCC regions for CMIP5. 




### The Atlas Hub

, including **a first illustrative (Jupyter) notebook** with commented code for reproducing some of the figures of the Atlas regional synthesis. Editing and executing notebooks locally requires software installation and configuration (see the installation options with  [docker](https://github.com/SantanderMetGroup/climate4R/tree/master/docker) or [conda](https://github.com/SantanderMetGroup/climate4R/tree/master/conda)), therefore, the computing facility [**climate4R Hub (C4R hub)**](https://hub.ipcc.ifca.es) is provided as an additional alternative, allowing IPCC users to edit/run provided notebooks in a remote machine where all the software is pre-installed. C4R Hub builds on the R framework for statistical computing with a pre-installed version of the climate4R packages, allowing for transparent climate data access, collocation, post-processing (including bias correction) and visualization. Find instructions to start working with the C4R Hub in [IPCC-Atlas_hub_instructions.pdf](https://github.com/SantanderMetGroup/IPCC-Atlas/blob/master/IPCC-Atlas_hub_instructions.pdf) of this repository.

### **Important**: Please note this is not an official IPCC product. This repository is fully managed by the [Santander Met Group](https://github.com/SantanderMetGroup) and it is only intended to keep track of internal research activities.
