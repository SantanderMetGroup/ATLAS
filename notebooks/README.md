# Notebooks

Notebooks describe step by step the basic process followed to generate some key figures. They include comments and hints to extend the analysis, thus promoting reusability of the results. These notebooks are provided as guidance for practitioners, more user friendly than the code provided as scripts in the [reproducibility](../reproducibility) folder. 

Some of the notebooks require access to large data volumes out of this repository. To speed up the execution of the notebook, in addition to the full code to access the data, we provide a data loading shortcut, by storing intermediate results in the [auxiliary-material](auxiliary-material) folder in this repository. To test other parameter settings, the full data access instructions should be followed, which can take long waiting times.

Most of the notebooks are in R and some in Python:

Notebook | R | py
---------|---|-------
bias-adjustment         | [X](./bias-adjustment_R.ipynb) |
climate-stripes         | [X](./climate-stripes_R.ipynb) |
GeoTIFF-post-processing | [X](./GeoTIFF-post-processing_R.ipynb) |
global-warming-levels   | [X](./global-warming-levels_R.ipynb) |
linear-trends           | [X](./linear-trends_R.ipynb) |
reference-regions-CORDEX-overlap |  | [X](./reference-regions-CORDEX-overlap_Python.ipynb)
reference-regions       | [X](./reference-regions_R.ipynb) | [X](./reference-regions_Python.ipynb) 
regional-delta-changes  | [X](./regional-delta-changes_R.ipynb) |

