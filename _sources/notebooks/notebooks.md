(notebooks)=
# Notebooks

Notebooks describe step by step the basic process followed to generate some key figures of the AR6 WGI Atlas and some products underpinning the Interactive Atlas, such as reference regions, global warming levels, aggregated datasets. They include comments and hints to extend the analysis, thus promoting reusability of the results. These notebooks are provided as guidance for practitioners, more user friendly than the code provided as scripts in the [reproducibility](reproducibility) folder. In particular, the notebook regional-scatter-plots allows reproducing some of the figures of the AR6 WGI Atlas chapter (Figures Atlas.13, 16 ,17, 21, 22, 24, 26, 28 and 29) displaying regional climate change for precipiation vs. temperature for CMIP5, CMIP6 and CORDEX over different subcontinental regions.

[reproducibility](reproducibility)

Some of the notebooks require access to large data volumes out of this repository. To speed up the execution of the notebook, in addition to the full code to access the data, we provide a data loading shortcut, by storing intermediate results in the [auxiliary-material](auxiliary-material) folder in this repository. To test other parameter settings, the full data access instructions should be followed, which can take long waiting times.

Most of the notebooks are in R and some in Python:
c
Notebook | R | py
------------------------|------------------------------------------|---
bias-adjustment         | [X](./bias-adjustment_R.ipynb)           |
CORDEX-overlaps         |                                          | [X](./CORDEX-overlaps_Python.ipynb)
GeoTIFF-post-processing | [X](./GeoTIFF-post-processing_R.ipynb)   |
global-warming-levels   | [X](./global-warming-levels_R.ipynb)     |
hatching-uncertainty    | [X](./hatching-uncertainty_R.ipynb)      |
linear-trends           | [X](./linear-trends_R.ipynb)             |
reference-grids         | [X](./reference-grids_R.ipynb)           | 
reference-regions       | [X](./reference-regions_R.ipynb)         | [X](./reference-regions_Python.ipynb) 
regional-scatter-plots  | [X](./regional-scatter-plots_R.ipynb)    |
stripes-plots           | [X](./stripes-plots_R.ipynb)             |

<script src="https://utteranc.es/client.js"
        repo="PhantomAurelia/Atlas"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>