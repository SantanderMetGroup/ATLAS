# Just personal notes

Easier way to generate csv inventories.

```bash
jq -r '
  . += {"instance_id": (if .instance_id|endswith(".nc") then .instance_id else (.instance_id + "." + .title) end)} | 
  [(.instance_id|split(".")[:9]|del(.[7])|join(".")), (.instance_id|split(".")[7]), .size, .title] | @csv' CMIP6_atmos_day.json | sort -u -t, -k1,4 | \
awk -F, '
BEGIN{ nvariables=split("pr,psl,tas,tasmax,tasmin", variables, ",") }
{
  gsub("\"", "")
  datasets[$1]=1
  sizes[$1]=sizes[$1]+$3
  datasets_variables[$1 " " $2]=1
}
END{
  for(d in datasets) {
    line="\""d"\""","sizes[d]
    for(i=1;i<=nvariables;i++) {
      if(datasets_variables[d " " variables[i]]) {
        line = line",true"
      } else {
        line = line",false"
      }
    }
    print line
  }
}' | (echo "dataset_id,size,pr,psl,tas,tasmax,tasmin"; sort -V)
```
