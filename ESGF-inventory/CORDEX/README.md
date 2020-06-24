# CORDEX ATLAS dataset

The management of the dataset involves the following processes:

- Discovering available datasets in ESGF and generation of inventories in csv format.
- Downloading available datasets from ESGF and reporting status of the download.
- Generation on NcMLs.

This is a long process so, when a new update is required, I suggest to work in a specific branch and commit changes after every step of the process. I also suggest to merge with a commit message including the date of the merge and tag the merge commit (ex. `cordex-2020-06-23`).

## Generation of inventories of datasets available in ESGF

```bash
scripts/CORDEX.sh
```

This creates the inventories `CORDEX_day.json` and `CORDEX_fx.json` and the metalink files in the `metalink` directory.

## Downloading available datasets from ESGF

Download the selected files from ESGF using aria2c and metalink files. You can check the status of the download in `download-report`, generated using `../esgf-check -m -r /oceano/gmeteo/WORK/PROYECTOS/2020_C3S_34d/synda/data/ metalinks/* > download-report`.

## Generation of NcMLs

See `scripts/publisher.sh`.

## Unique inventory

jq can be used to create an unique inventory combining daily and fixed `time_frequency` values. Here we show how (just for reference).

```
jq -r --slurp --arg variables "${variables}" '
	map(. + map_values(arrays|first)) | 
	map(select(.replica == false)) |

	map(. + { dataset_all_runs: (.master_id|split(".")|del(.[6,9,10])|join(".")) }) |
	group_by(.dataset_all_runs) |
	map( {	dataset_all_runs: .[0].dataset_all_runs,
			time: map(select(.time_frequency != "fx")),
			fixed: map(select(.time_frequency == "fx")) }) |

	map(.time |= group_by(.ensemble)) |
	map(.time |= map({ensemble: .[0].ensemble, size: map(.size)|add, variables: map(.variable)})) |
	map(.fixed |= {ensemble: .[0].ensemble, size: map(.size)|add, variables: map(.variable)}) |

	map({dataset_all_runs, variables: [.time, [.fixed]]|combinations}) |
	map({dataset_id:
			((.dataset_all_runs|split(".")[:6]) +
			[(.variables|map(select(.ensemble != "r0i0p0"))|map(.ensemble)|first)] +
			(.dataset_all_runs|split(".")[6:])) | join("."),
		size: .variables|map(.size)|add,
		variables: .variables|map(.variables)|add}) |

	(reduce ($variables|split(","))[] as $v ({}; . + {($v): false})) as $false_variables |
	map(reduce .variables[] as $v ({dataset_id, size} + $false_variables; . + {($v): true})) |

	(["dataset_id", "size"] + ($variables|split(",")|sort)) as $keys | $keys, map([.[ $keys[] ]])[] | @csv'
```
