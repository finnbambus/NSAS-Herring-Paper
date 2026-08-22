The “data” folder contains the .Rdata files used for analysis. The files
are processed data from the “data raw” folder by the code in the
“data\_cleanup.Rmd” file of the “R” folder.

-   **LAI\_full** contains the LAI data for each component and fortnight
    -   Type: Data frame
    -   Variables: year, LAI\_unit, component, fortnight, LAI\_9mm
-   **LAI\_aggregated** contains the LAI data summed per year per
    component.
    -   Type: Data frame
    -   Variables: year, component, LAI\_9mm
-   **Herring\_LAI** contains the Spawning-Stock-Biomass (SSB) for each
    component as well as F & R for the entire stock over time, as well
    as the percent each component contributed to the LAI for each year.
    -   Type: tibble
    -   Variables: year, component, LAI\_perc. \[%\], SSB\_component
        \[t\], l\_bnd (lower bound) \[t\], u\_bnd (upper bound) \[t\],
        F, R \[thousands\]
-   **Herring\_full** contains the SSB, F and R time-series for the full
    stock as well as a coefficient variance and lower and upper bounds
    for SSB. The F and R values are taken from the recent ICES Advice
    and joined to the SSB series by year.
    -   Type: tibble
    -   Variables: year, SSB \[t\], cv, l\_bnd \[t\], u\_bnd \[t\], F, R
        \[thousands\]

Note: the environmental (env\_\*) and plankton (cpr\_\*) files from the
thesis version were removed together with the environmental-driver
analysis; the corresponding raw data remains in “data raw” for
reference.
