# CMIP6 inventories

Usage:

```bash
./CMIP6.sh
```

This creates the directories `all_runs` and `one_run` (lowest run with greatest number of variables).  
Manual revision of these inventories is required and the results should be saved in the file `CMIP6_day_1run.csv`.

The script `inventory-to-metalink` inspects `CMIP6_day_1run.csv` and generates the corresponding metalink file, used for data download.

```bash
./inventory-to-metalink
```
