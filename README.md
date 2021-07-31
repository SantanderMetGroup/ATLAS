[![DOI](https://zenodo.org/badge/190203356.svg)](https://zenodo.org/badge/latestdoi/190203356) [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/SantanderMetGroup/binder-atlas/master?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FIPCC-WG1%252FAtlas%26urlpath%3Dlab%252Ftree%252FAtlas%252F%26branch%3Ddevel)

# Repository supporting the implementation of FAIR principles in the IPCC-WGI Atlas

The IPCC AR6 WGI report promotes best practices in traceability and reproducibility, including through adoption of the Findable, Accessible, Interoperable, and Reusable (FAIR) principles for scientific data. The **WGI Atlas** is part of the AR6 report and provides a region-by-region assessment of climate change including also an innovative online tool (the **Interactive Atlas**, http://interactive-atlas.ipcc.ch) that complements the report by providing flexible spatial and temporal analyses of regional climate change. It comprises a **regional information** component for flexible analysis of past and projected climate datasets supporting the assessment done in the Chapters, and a **regional synthesis** component for flexible anlysis of synthesis assessments supporting the Technical Summary and Summary for Policymakers. The data-driven regional information component builds on global and regional observations (e.g. CRU-TS and E-OBS) and projections (CMIP5/6 and CORDEX) to produce relevant indices for regional analysis of climate change information using both time-slices and global warming levels across scenarios. 

A **new set of sub-continental reference regions** is used as the basis for regional information and monthly spatially aggregated datasets are produced to facilitate the development of regional climate change information. 

Reproducibility and reusability are central in order to ensure the transparency of the products, which are all publicly available. The Atlas products are generated using **free software community tools**, in particular [R](https://www.r-project.org) building on the [**climate4R** framework](https://github.com/SantanderMetGroup/climate4R) for data post-processing (data access, regridding, aggregation, bias adjustment, etc.) and evaluation and quality control (when applicable). **Provenance metadata** is generated for the Interactive Atlas using the [**METACLIP**](http://www.metaclip.org) RDF-based framework, building on the [metaclipR](https://github.com/metaclip/metaclipR) package of the climate4R framework, extended to cover the products to be delivered by the IPCC-AR6 Interactive Atlas ([metaclipcc](https://rdrr.io/github/metaclip/metaclipcc)).

This repository provides the scripts and notebooks, as well as the required auxiliary products and datasets, supporting the reproducilibility and reusability of some of the Atlas products, as described in the following schema and table of contents.

## Contents

![Atlas repository scheme](Atlas-repo-scheme.svg)

| Directory | Contents |
| :-------- | :------- |
| [data-sources](data-sources) | Full list of model simulations used for the different experiments and scenarios, indicating the availability of the different variables
| [reference-grids](reference-grids) | Reference commensurable grids at regular 0.5&deg;, 1&deg; and 2&deg; resolutions. These are used to interpolate all variables and indices as a final processing step before analysis.
| [reference-regions](reference-regions) | New set of reference analysis regions
| [datasets-interactive-atlas](datasets-interactive-atlas) |  End-to-end scripts used for the preparation of the intermediate data (Interactive Atlas Dataset) underpinning the Interactive Atlas. The Interactive Atlas Dataset is formed by monthly values of CMIP5/6 and CORDEX data for different variables and indices interpolated to common reference grids. The scripts document the whole process, from data access to index calculation (and postprocessing –e.g. bias adjustment– if needed).
| [datasets-aggregated-regionally](datasets-aggregated-regionally) | The Interactive Atlas Dataset is averaged over the reference regions to produce many of the figures. These key aggregated data are provided directly for further analysis within this Github repository folder.
| [warming-levels](warming-levels) | Global Warming Levels (+1.5&deg;, +2&deg;, +3&deg;, +4&deg;) are computed and provided in this folder.
| [notebooks](notebooks) | Cross-cutting Jupyter notebooks, combining the information from several of the previous directories to perform specific analyses. Some of the previous top-level directories also contain their own notebooks directory with specific examples to work with the particular data in those directories.
| [reproducibility](reproducibility) | End-to-end scripts used for the preparation of the key figures of the IPCC AR6 WGI Atlas chapter.

## New Reference Regions

<img src="reference-regions/reference_regions.png" align="left" alt="" width="500" />

A new set of reference regions is produced building on the popular [IPCC AR5 reference regions](http://www.ipcc-data.org/guidelines/pages/ar5_regions.html) developed for reporting sub-continental CMIP5 projections (with typical resolution of 2&deg;) over a reduced number of regions. The increased resolution of CMIP6 and CORDEX projections (typically 1&deg; and 0.5&deg;) allows to increase the number of regions for a better representation of different climates. This results in new set of **46 land and 14 ocean reference regions**). The coordinates delimiting the regions (CSV and shapefiles) and other related datasets are available at the [reference-regions](./reference-regions) repository folder.

## Regionally-aggregated datasets (CMIP and CORDEX)
The IPCC reference regions have been used as the basis to generate popular spatially-aggregated datasets, such as the [IPCC AR5 seasonal mean temperature and precipitation in IPCC regions for CMIP5](https://catalogue.ceda.ac.uk/uuid/9d0f61dc7a1b4017b22d88f9d38ab398). Here, we provide an updated version of this dataset using CMIP6 projections (interpolated to a common 1º resolution, see **'referece_masks'**) for the new regions. Monthly mean values are stored for CMIP5/6 and CORDEX for the historical (1850-2005/1850-2014, only 1970-2014 for CORDEX) and future RCP2.6/SSP1-2.6, RCP4.5/SSP2-4.5 and RCP8.5/SSP5-8.5 scenarios. An inventory of the currently available models and runs is available at the [data-sources](./data-sources) folder.

Besides the analysis of time-slices (e.g. near-, mid- and long-term, 2021-2040, 2041-2060, 2081-2100, respectively), we also provide information to work with Global Warming Levels (+1.5&deg;, +2&deg;, +3&deg;, +4&deg;) under [warming-levels](./warming-levels).

## Requirements

Scripts and (jupyter) notebooks are provided in the different sections to ensure reproducibility and reusability of the results.
Most of this code builds on the climate4R R package, allowing for transparent climate data access, collocation, post-processing (including bias adjustment) and visualization. The code runs on climate4R release v1.5.1. Check https://github.com/SantanderMetGroup/climate4R/releases/tag/v1.5.1 for specific library versions in this release. These depend on a wealth of [other R packages](https://github.com/SantanderMetGroup/climate4R/blob/devel/conda-full/meta.yaml). Additionally, [Jupyter](https://jupyter.org) should also be available with the [R kernel](https://irkernel.github.io/installation) enabled. The simplest way to match all these requirements is by using a dedicated [conda](https://docs.conda.io) environment, which can be easily installed by issuing:
```sh
conda create -n climate4R
conda activate climate4R
conda install -n climate4R -c conda-forge -c r -c defaults -c santandermetgroup climate4r=1.5.1
```

### Virtual workspace through binder

A much straigtforward way to explore and interact with this repository is through [binder](https://mybinder.org/). Binder provides an executable environment, making the code immediately reproducible. The required software is pre-installed in a cloud environment where the user can create and execute notebooks (directly) and scripts (via the available Terminal). Moreover, the environment is accesible without any further authentication by the user.

To start exploring the binder interface, just click [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/SantanderMetGroup/binder-atlas/master?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FIPCC-WG1%252FAtlas%26urlpath%3Dlab%252Ftree%252FAtlas%252F%26branch%3Ddevel). You will arrive at a [JupyterLab interface](https://jupyterlab.readthedocs.io/en/stable/user/interface.html) with access to the contents of this repository.

## Errata and problem reporting

The [errata](./ERRATA.md) of the Atlas covers both the content (products, such as plots and data) and the application/platform of the Interactive Atlas, as well as this GitHub repository supporting reproducibility and reusability. The existing products are frozen and the issues reported are documented in the errata list. Technical problems are listed separately and those not affecting the products could be fixed and documented.
