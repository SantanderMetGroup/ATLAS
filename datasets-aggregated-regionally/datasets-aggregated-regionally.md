(datasets-aggregated-regionally)=
# Aggregated datasets

These files contain monthly precipitation and near surface temperature spatially averaged over the reference regions for CMIP5, CMIP6 and CORDEX model output datasets (a single run per model) separately for land, sea, and land-sea gridboxes. Regional averages are weighted by the cosine of latitude in all cases. Also, an observation-based product is provided in the same format for reference: W5E5 ({cite:authorpar}`WFDE5`)

For the different CORDEX domains, aggregated results are calculated only in those regions with overlap larger than 80% (see {download}`Overlaps-CORDEX-ReferenceRegions.csv<./data/CORDEX/Overlaps-CORDEX-ReferenceRegions.csv>` for details on the overlap areas, as percentages over the total area of the reference region; regular geographic grids for every CORDEX domain are obtained from Table 2{cite:authorpar}`christensenCORDEXArchiveDesign` in the CORDEX specification archive; an annotated notebook for reproducibility is available at: [notebooks/CORDEX-overlaps_Python.ipynb](../notebooks/CORDEX-overlaps_Python.ipynb). The regions resulting for each domain are:

Domain | Reference regions above 80% overlap
-------|------------------------------------
NAM    | NWN, NEN, WNA, CNA, ENA, NCA, CAR
CAM    | NCA, SCA, CAR, NWS, NSA, NES, SAM
SAM    | SCA, NWS, NSA, NES, SAM, SWS, SES, SSA
ARC    | GIC, NWN, NEN, NEU, RAR, RFE, ARO
AFR    | MED, SAH, WAF, CAF, NEAF, SEAF, WSAF, ESAF, MDG, ARP
EUR    | NEU, WCE, EEU, MED
MED    | WCE, MED
MNA    | MED, SAH, WAF, CAF, NEAF, SEAF, WCA, ARP, ARS
SEA    | SEA
EAS    | ECA, TIB, EAS, SAS, SEA, NAU, BOB
WAS    | NEAF, SEAF, WCA, ECA, TIB, ARP, SAS, ARS, BOB, EIO
CAS    | EEU, WSB, ESB, WCA, ECA, TIB, EAS, ARP
ANT    | EAN, WAN
AUS    | SEA, NAU, CAU, EAU, SAU, NZ


## References
```{bibliography}
:filter: docname in docnames
```

<script src="https://utteranc.es/client.js"
        repo="PhantomAurelia/Atlas"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>