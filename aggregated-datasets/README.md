## CMIP5, CMIP6 AND CORDEX spatial averages over the reference regions

Spatially aggregated monthly results over the reference regions for CMIP5, CMIP6 and CORDEX ATLAS datasets (a single run per model) separately for land, sea, and land-sea gridboxes.

Note that the aggregated results for the different CORDEX domains are calculated only in those regions with overlap larger than 80% (see file *data/CORDEX/CORDEXDomainsVSreferenceRegions.csv* for details on the overalp areas, as percentages over the total area of the reference region). Regular geographic grids for every CORDEX domain are obtained from Table 2 available in the CORDEX specification archive (https://is-enes-data.github.io/cordex_archive_specifications.pdf); an annotated notebook for reproducibility is available at: ***

reference_regions["NAM"] = ['NWN', 'NEN', 'WNA', 'CNA', 'ENA', 'NCA', 'CAR']<br>
reference_regions["CAM"] = ['NCA', 'SCA', 'CAR', 'NWS', 'NSA', 'NES', 'SAM']<br>
reference_regions["SAM"] = ['SCA', 'NWS', 'NSA', 'NES', 'SAM', 'SWS', 'SES', 'SSA']<br>
reference_regions["ARC"] = ['GIC', 'NWN', 'NEN', 'NEU', 'EEU', 'RAR', 'WSB', 'ESB', 'RFE', 'ARO']<br>
reference_regions["AFR"] = ['MED', 'SAH', 'WAF', 'CAF', 'NEAF', 'SEAF', 'WSAF', 'ESAF', 'MDG', 'ARP']<br>
reference_regions["EUR"] = ['NEU', 'WCE', 'EEU', 'MED']<br>
reference_regions["MED"] = ['WCE', 'MED']<br>
reference_regions["MNA"] = ['MED', 'SAH', 'WAF', 'CAF', 'NEAF', 'WCA', 'ARP', 'ARS']<br>
reference_regions["SEA"] = ['SEA']<br>
reference_regions["EAS"] = ['ECA', 'TIB', 'EAS', 'SAS', 'SEA', 'NAU', 'BOB']<br>
reference_regions["WAS"] = ['NEAF', 'SEAF', 'WCA', 'ECA', 'TIB', 'ARP', 'SAS', 'ARS', 'BOB', 'EIO']<br>
reference_regions["CAS"] = ['EEU', 'WSB', 'ESB', 'WCA', 'ECA', 'TIB', 'EAS', 'ARP']<br>
reference_regions["ANT"] = ['EAN', 'WAN']<br>
reference_regions["AUS"] = ['SEA', 'NAU', 'CAU', 'EAU', 'SAU', 'NZ']

Additionally, results for all CMIP6 model runs (*CMIP6Amon_Hub* version 20191028 in 'ATLAS-inventory/Hub') are also available at the following links:

[CMIP6Amon_pr_land.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_pr_land.zip)\
[CMIP6Amon_pr_landsea.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_pr_landsea.zip)\
[CMIP6Amon_pr_sea.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_pr_sea.zip)\
[CMIP6Amon_tas_land.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_tas_land.zip)\
[CMIP6Amon_tas_landsea.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_tas_landsea.zip)\
[CMIP6Amon_tas_sea.zip](http://meteo.unican.es/work/IPCC_Atlas/regional_means/CMIP6Amon_tas_sea.zip)


***
NOTE!: Regional averages are weighted by the cosine of latitude.
