## The Climate Change ATLAS: Datasets, code and virtual workspace

The Climate Change ATLAS is an initiative to develop **ready-to-use code and datasets** for regional analysis of observed and model projected (e.g. CMIP6 and CORDEX) climate change information using both time-slices (e.g. 2081-2100) and warming levels (e.g. +1.5º). A **new set of sub-continental reference regions** is provided as the basis for regional synthesis (building on IPCC AR5 reference regions) and monthly spatially aggregated datasets are produced to facilitate the development of regional climate change proudcts. 

The **accessibility and reproducibility** of results has been a major concern during the development of the Climate Change ATLAS, in order to ensure the transparency of the products (which are all publicly available). The Atlas products are generated using **free software community tools**, in particular [R](https://www.r-project.org) building on the [**climate4R** framework](https://github.com/SantanderMetGroup/climate4R) for data post-processing (data access, regridding, aggregation, bias adjustment, etc.) and evaluation and quality control (when applicable). **Provenance/ metadata** is generated using the [**METACLIP**](http://www.metaclip.org) RDF-based framework (building on the [metaclipR](https://github.com/metaclip/metaclipR) package for the climate4R framework).

<img src="/man/new_eference_regions.png" align="left" alt="" width="400" />

### New Reference Regions 
A new set of reference regions is produced building on the popular [AR5 IPCC reference regions](http://www.ipcc-data.org/guidelines/pages/ar5_regions.html) developed for reporting sub-continental CMIP5 (with typical resolution of 2º) projections over a reduced number of regions. The increased reasolution (typically 1º in CMIP6) allows to increase the number of regions for a better climatic representatio (this results in **43 land and 12 open ocean reference regions**). The coordinates (csv and shapefiles) of the regions and related datasets are available at the *reference_regions* directory.

### Aggregated CMIP6 datasets
The IPCC reference regions have been used as the basis to generate popular spatially aggregated datasets, such as the [IPCC AR5 seasonal mean temperature and precipitation in IPCC regions for CMIP5](https://catalogue.ceda.ac.uk/uuid/9d0f61dc7a1b4017b22d88f9d38ab398). Here we produce a updated version of this dataset using CMIP6 projections (interpolated to a common 1º resolution, see *referece_masks*) for the new regions (this will later extended to CMIP5 and CORDEX datasets).  The inventory of availabe models and runs for the different CMIP and CORDEX datasets are available at the *AtlasHub-inventory* (building on ESGF information; an inventory of ESGF is available at *ESGF-inventory*). 

### Global warming levels
The periods where different global warming levels (+1.5º, +2º, +3º, +4º) are reached by the different CMIP6 runs are available at the *GWL* directory. 

### The Atlas Hub
The Atlas Hub is a cloud facility providing virtual workspace for the Climate Change Atlas code and data (with preinstalled software and accesible data). The Atlas Hub is based on **Jupyter** to create and run notebooks on a remote machine where all the software is pre-installed (instructions available in the *IPCC-Atlas_hub_instructions.pdf* document). The Atlas Hub builds on the R **climate4R** package, allowing for transparent climate data access, collocation, post-processing (including bias correction) and visualization. Instructions to start working with the Hub are available at the document [IPCC-Atlas_hub_instructions.pdf](https://github.com/SantanderMetGroup/IPCC-Atlas/IPCC-Atlas_hub_instructions.pdf) on this repository.

### **Important**: This initiative contributes to the development of the IPCC AR6 Atlas, but this is not an official IPCC site. This repository is fully managed by the [Santander Met Group](https://github.com/SantanderMetGroup) and it is only intended to keep track of internal research activities.
