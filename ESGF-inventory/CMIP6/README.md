# CMIP6 inventories

Usage:

```bash
./CMIP6.sh
```

This creates the inventories CMIP6\_day.json, CMIP6\_mon.json and CMIP6\_fx.json.
Manual revision of these inventories is required and the results should be saved in the file `CMIP6_day_1run.csv`.

The script `inventory-to-metalink` inspects `CMIP6_day_1run.csv` and generates the corresponding metalink file, used for data download.

```bash
./inventory-to-metalink
```
