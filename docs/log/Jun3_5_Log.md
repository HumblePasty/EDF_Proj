# Log Jun 3 - 5

> Author: Haolin Li



## Summary

- Carbon Input for KBS
- Carbon Input for CAP
- Carbon Input for GraceNET
- keep the biomass column
- Carbon Output for CAP and gracenet



## Log

### Carbon Input and Outputs

keep the biomass column

**CAP Carbon Input**

- cap_carbon_input.csv

**KBS Carbon Input**

- kbs_carbon_input.csv

**GraceNet Carbon Input and Output**

- I need a list of the interested sites

  IAAMBRUN, INWLACRE, MNMOBRR, MNMOFS, NELITCSE, NEMEIRR, NEMERREM, NEMLTCRS,

  - now using the listed on other outputs

- gracenet_carbon_input.csv

  ```
   [1] "Aboveground biomass"            "Ear Leaf"                       "Above earshank"               
   [4] "Below earshank"                 "Cobs"                           "Grain"                         
   [7] "Stover (all non-grain biomass)" "Stems and leaves"               "Husk"                         
  [10] "Stems"                          "Leaves"                         "Tassel"                       
  [13] "Sheath"                         "Cobs and grain"                 "Roots"                         
  [16] "Below earshank leaves"          "Below earshank stems"           "Above earshank leaves"         
  [19] "Above earshank stems"
  ```

  just aboveground ground biomass

  grain

  cob

  just roots

  just grain

- Carbon output: gracenet_carbon_output.csv

  - C_p output
  - Gas estimation
    - CO2 output
    - CH4 output

  - differentiate between rotations
    - a script on the analysis

- GHGFlux and Nutrient loss

  - GHGFlux - chamber placement
  - less sites for nutrient loss
  - should use GHGFlux tab


### Nitrogen Input and Outputs

- Need references
- the gas emission part 
- TBD

### Database Framework

- MySQL
- ER Graph of tables and columns
- Deployment and APIs



## Questions

- Legacy question for CAP Carbon

  - The fertilization differences (NIT1-4, should we use the same SR ratio?)

- Meta question: How should the C input/output table be aggregated?

  What columns should be included?

  - Include many columns and aggregate afterwards

  - by each plot by year
  - by rotation/treatment



## Next Steps

- Transfer data to SQL/Database
- Repeat for other experiments



- a scale from 0-200
- estimate the missing information
- https://www.nrcs.usda.gov/sites/default/files/2022-11/CEAP-Croplands-2008-Methodology-SoilTillageIntensityRating.pdf
- https://fargo.nserl.purdue.edu/rusle2_dataweb/RUSLE2_Index.htm
- Year is included
- Site, Treatment, Plot, Year