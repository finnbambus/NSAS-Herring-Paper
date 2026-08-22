The folder R contains all the R code used in this project. The main
ideas for the functionality and approach were taken from the paper
[“Regime shift dynamics, tipping points and the success of fisheries
management” by Blöcker et al. 2023](https://doi.org/10.1038/s41598-022-27104-y),
whose code is available under
<https://github.com/HeleneGutte/tipping_northsea_fish/tree/main>.

-   **data\_cleanup.Rmd** imports and cleans the raw data from the
    “data raw” folder (LAI, SSB and ICES assessment data), saves the
    processed data to the “data” folder in the .Rdata format and
    generates first descriptive plots in the “plots” folder.

-   **data\_analysis.Rmd** analyses the full stock for regime shifts:
    change-point analysis (CPT + BCP consensus), SSB-F hysteresis
    break-point analysis and non-stationary stock-recruitment
    relationships (model comparison, LOOCV and strucchange
    break-points). It imports its data from “data” and uses functions
    from “functions.R” and “model\_comp\_functions.R”.

-   **data\_analysis\_component.Rmd** runs the same analyses on the
    spawning-component level (Shetland / Orkney, Buchan, Banks, Downs),
    driven by a per-component configuration list, and assembles the
    combined component figures.

-   **functions.R** defines the analysis and plotting functions used by
    the two analysis scripts (change-point analysis, break-point
    analysis, hysteresis / SRR / summary plots).

-   **model\_comp\_functions.R** defines the functions used to fit and
    compare the candidate stock-recruitment models (linear,
    Beverton-Holt, Ricker, segmented variants, strucchange, Negative
    Binomial GLM) and the leave-one-out cross-validation. Note: it
    requires functions.R to be sourced first (opt\_bpts).

-   **map\_components.Rmd** compiles a bathymetric map of the North Sea
    including the areas of each spawning component.
