# The Multi-MIP Climate Change ATLAS

The **WGI Atlas** is part of the AR6 report and provides a region-by-region assessment of climate change including also an innovative online tool (the **Interactive Atlas**, http://interactive-atlas.ipcc.ch) that complements the report by providing flexible spatial and temporal analyses of regional climate change by means of two components (see AR6 Atlas chapter, Sections 1 and 2). The **regional information** component allows for flexible analysis of past and projected changes for over 25 variables and derived indices calculated from key climate datasets supporting the assessment done in the Chapters. The **regional synthesis** component provides flexible anlysis of synthesis assessments over a new set of sub-continental reference regions supporting the Technical Summary and Summary for Policymakers. A description of the datasets 

The IPCC AR6 WGI report promotes best practices in traceability and reproducibility, including through adoption of the Findable, Accessible, Interoperable, and Reusable (FAIR) principles for scientific data. In particular, reproducibility and reusability are central in order to ensure the transparency of the products, which are all publicly available. The Atlas products are generated using **free software community tools**, in particular [R](https://www.r-project.org) building on the [**climate4R** framework](https://github.com/SantanderMetGroup/climate4R) for data post-processing (data access, regridding, aggregation, bias adjustment, etc.) and evaluation and quality control (when applicable). **Provenance metadata** is generated for the Interactive Atlas using the [**METACLIP**](http://www.metaclip.org) RDF-based framework, extended to cover the products delivered by the IPCC-AR6 Interactive Atlas ([metaclipcc](https://rdrr.io/github/metaclip/metaclipcc)). 


## Contents

This repository provides the scripts and notebooks, as well as the required auxiliary products and datasets, supporting the reproducilibility and reusability of some of the Atlas products (mainly key figures in the Chapter and data-driven products of the Interactive Atlas – regional information component), as described in the following schema and table of contents.

![Atlas repository scheme](Atlas-repo-scheme.svg)

| Directory | Contents |
| :-------- | :------- |
| [data-sources](data-sources) | Full list of model simulations used for the different experiments and scenarios, indicating the availability of the different variables
| [reference-grids](reference-grids) | Reference commensurable grids at regular 0.5&deg;, 1&deg; and 2&deg; resolutions. These are used to interpolate all variables and indices as a final processing step before analysis.
| [datasets-interactive-atlas](datasets-interactive-atlas) |  End-to-end scripts used for the preparation of the intermediate data (Interactive Atlas Dataset) underpinning the Interactive Atlas. The Interactive Atlas Dataset is formed by monthly values of CMIP5/6 and CORDEX data for different variables and indices interpolated to common reference grids. The scripts document the whole process, from data access to index calculation (and postprocessing –e.g. bias adjustment– if needed).
| [reference-regions](reference-regions) | New set of reference analysis regions in AR6
| [datasets-aggregated-regionally](datasets-aggregated-regionally) | The Interactive Atlas Dataset is averaged over the reference regions to produce many of the figures. These key aggregated data are provided directly for further analysis within this Github repository folder.
| [warming-levels](warming-levels) | Global Warming Levels (+1.5&deg;, +2&deg;, +3&deg;, +4&deg;) are computed and provided in this folder.
| [notebooks](notebooks) | Cross-cutting Jupyter notebooks, combining the information from several of the previous directories to perform specific analyses.
| [reproducibility](reproducibility) | End-to-end scripts used for the preparation of the key figures of the IPCC AR6 WGI Atlas chapter.
| [binder](binder) | Files providing reproducible execution environment specifications

## New Reference Regions

<img src="reference-regions/reference_regions.png" align="left" alt="" width="500" />

A new set of reference regions was produced building on the popular [IPCC AR5 reference regions](http://www.ipcc-data.org/guidelines/pages/ar5_regions.html) developed for reporting sub-continental CMIP5 projections (with typical resolution of 2&deg;) over a reduced number of regions. The increased resolution of CMIP6 and CORDEX projections (typically 1&deg; and 0.5&deg;) allowed to increase the number of regions for a better representation of different climates, resulting in new set of **46 land and 14 ocean reference regions** ([Iturbide et al. 2020](https://doi.org/10.5194/essd-12-2959-2020)). The coordinates delimiting the regions (CSV and shapefiles) and other related datasets are available at the [reference-regions](./reference-regions) repository folder.

## Regionally-aggregated datasets (CMIP and CORDEX)
The IPCC reference regions have been used as the basis to generate popular spatially-aggregated datasets, such as the [IPCC AR5 seasonal mean temperature and precipitation in IPCC regions for CMIP5](https://catalogue.ceda.ac.uk/uuid/9d0f61dc7a1b4017b22d88f9d38ab398). Here, we provide a new aggregated dataset using CMIP5, CMIP6 and CORDEX projections (interpolated to common 2&deg;, 1&deg;, and 0.5&deg; resolution, respectively, see [reference-grids](./reference-grids)) for the new regions. Monthly mean values are stored for CMIP5/6 and CORDEX for the historical (1850-2005/1850-2014, only 1970-2014 for CORDEX) and future RCP2.6/SSP1-2.6, RCP4.5/SSP2-4.5, SSP3-7.0 and RCP8.5/SSP5-8.5 scenarios. An inventory of the currently available models and runs is available at the [data-sources](./data-sources) folder.

Besides the analysis of time-slices (e.g. near-, mid- and long-term, 2021-2040, 2041-2060, 2081-2100, respectively), we also provide information to work with Global Warming Levels (1.5&deg;, 2&deg;, 3&deg;, 4&deg;) under [warming-levels](./warming-levels).

## Requirements

Scripts and (jupyter) notebooks are provided in the different sections to ensure reproducibility and reusability of the results.
Most of this code builds on the climate4R R package, allowing for transparent climate data access, collocation, post-processing (including bias adjustment) and visualization. The code runs on climate4R release v2.5.3. Check https://github.com/SantanderMetGroup/climate4R/releases/tag/v2.5.3 for specific library versions in this release. These depend on a wealth of other R packages. Additionally, [Jupyter](https://jupyter.org) should also be available with the [R kernel](https://irkernel.github.io/installation) enabled. The simplest way to match all these requirements is by using a dedicated [conda](https://docs.conda.io) environment, which can be easily installed by issuing:
```sh
conda env create -n ipcc-wgi-ar6-atlas --file binder/conda/environment.yml
conda activate ipcc-wgi-ar6-atlas
```
See [binder/README.md](./binder) for other options to deploy locally a reproducible execution environment.

### Virtual workspace through binder

A much straigtforward way to explore and interact with this repository is through [binder](https://mybinder.org/). Binder provides an executable environment, making the code immediately reproducible. The required software is pre-installed in a cloud environment where the user can create and execute notebooks (directly) and scripts (via the available Terminal). Moreover, the environment is accesible without any further authentication by the user.

To start exploring the binder interface, just click the *Launch in MyBinder* badge above. You will arrive at a [JupyterLab interface](https://jupyterlab.readthedocs.io/en/stable/user/interface.html) with access to the contents of this repository.
