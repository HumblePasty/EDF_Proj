# Log for May 22-25

> Date: May 22-25, 2024
>
> Author: Haolin Li



## Tasks from last meeting

- [ ] making a summery of the related columns
- [ ] the cob + vegetative parts as input C
- [ ] plus + weed input
- [ ] estimate the root carbon using the above ground carbon
- [ ] repeat for soybean and wheat
- [ ] adjust the CAP calc to include the fertilizer input
- [ ] adjust other parts of the code to be compatible



## How I Calculated C Input for CAP Experiment

$$
C\_input\_total = C_{corn} + C_{soy} + C_{wheat} + C_{cover} + C_{weedy}
$$

According to Bolinder et. al, for $C_{corn}, C_{wheat}, C_{soy}:$
$$
\begin{align}
C_p &= C_{grain} = Y_p * conc\_rate\\
C_s &= Y_p(1-HI)/HI*conc\_rate = C_p * (1-HI)/HI\\
C_r &= Y_p(S:R*HI)*conc\_rate = C_p / (S:R*HI)\\
C_e &= C_r * Y_e = C_r * ERtoR\\
C_{input} &= C_s + C_r + C_e
\end{align}
$$

- $C_p$: Carbon in grain part (production)
- $C_s$: Carbon in non-harvested parts (vegetative parts or cob)
- $C_r$: Carbon in roots
- $C_e$: extra root

We assume
$$
conc\_rate = 0.45\\
ERtoR = 0.65
$$

|         |                            $C_p$                             |                            $C_s$                             |                          $C_r$                          |        $C_e$        |
| :-----: | :----------------------------------------------------------: | :----------------------------------------------------------: | :-----------------------------------------------------: | :-----------------: |
|  Corn   | $C_p = AGR23$ or<br />$C_p = Y_p * conc\_rate = AGR33 * conc\_rate$ or<br />$Y_p = AGR17 * (1 - AGR18 / 1000)$<br />$C_p = Y_p * conc\_rate$ | $C_s = C_{cob} + C_{vegetative} = AGR24 + AGR09$ or<br />$C_s = C_p * (1-HI)/HI$ | $C_p / (S:R*HI)$<br />use different S:R for fert/unfert | $C_e = C_r * ERtoR$ |
| Soybean | $C_p = AGR27$ or<br />$C_p = Y_p * conc\_rate = AGR34 * conc\_rate$ or<br />$Y_p = AGR19 * (1 - AGR20 / 1000)$<br />$C_p = Y_p * conc\_rate$ | $C_s = C_{vegetative} = AGR11$ or<br />$C_s = C_p * (1-HI)/HI$ |                    $C_p / (S:R*HI)$                     | $C_e = C_r * ERtoR$ |
|  Wheat  | $Y_p = AGR21 * (1 - AGR22 / 1000)$<br />$C_p = Y_p * conc\_rate$ |                   $C_s = C_p * (1-HI)/HI$                    |                    $C_p / (S:R*HI)$                     | $C_e = C_r * ERtoR$ |



### Corn

- $C_p$

  - if AGR23 (corn grain carbon) is available

    $C_p = AGR23$

  - if not, use AGR33 (corn dry yield)

    $C_p = Y_p * conc\_rate = AGR33 * conc\_rate$​

  - if AGR33 is not available, use raw yield (AGR17) and subtract moisture (AGR18)

    $Y_p = AGR17 * (1 - AGR18 / 1000)$

    $C_p = Y_p * conc\_rate$

- $C_s$

  - If carbon is measured for vegetative and cob parts:

    $C_s = C_{cob} + C_{vegetative} = AGR24 + AGR09$

  - else use the formula

    $C_s = C_p * (1-HI)/HI$​

    Here $HI_{corn} = 0.5$

- $C_r$​

  $C_p / (S:R*HI)$

  - Use different S:R ratio for fertilized/unfertilized ones
    - `NIT1` for unfertilized, all others fertilized
    - fertilized: 4.7
    - unfertilized: 3.6
  - HI_corn = 0.5

- $C_e$

  $C_e = C_r * ERtoR$​

- Thus

  $C_{input} = C_s + C_r + C_e$​



### Soybean

- $C_p$

  - if AGR27 (soybean grain carbon) is available

    $C_p = AGR27$

  - if not, use AGR34 (corn dry yield)

    $C_p = Y_p * conc\_rate = AGR34 * conc\_rate$​

  - if AGR34 is not available, use raw yield (AGR19) and subtract moisture (AGR20)

    $Y_p = AGR19 * (1 - AGR20 / 1000)$

    $C_p = Y_p * conc\_rate$

- $C_s$

  - If carbon is measured for vegetative parts:

    $C_s = C_{vegetative} = AGR11$

  - else use the formula

    $C_s = C_p * (1-HI)/HI$​

    Here $HI_{soy} = 0.4$

- $C_r$​

  $C_p / (S:R*HI)$

  - HI_soy = 0.5
  - Use uniform S:R ratio = 5.2

- $C_e$

  $C_r * ERtoR$​

- Thus

  $C_{input} = C_s + C_r + C_e$​



### Wheat

- $C_p$

  - Use raw yield (AGR21) and subtract moisture (AGR22)

    $Y_p = AGR21 * (1 - AGR22 / 1000)$

    $C_p = Y_p * conc\_rate$

- $C_s$

  $C_s = C_p * (1-HI)/HI$​

  Here $HI_{wheat} = 0.4$

- $C_r$​

  $C_p / (S:R*HI)$

  - HI_wheat = 0.5
  - Use uniform S:R ratio = 6

- $C_e$

  $C_r * ERtoR$​

- Thus

  $C_{input} = C_s + C_r + C_e$



### Cover crop

- Two kind of cover crops

  - rye
  - red clover/mixed cover crops

- I assume

  $cover\_biomass\_to\_C = 0.45$

- For rye

  - fall biomass - `AGR06`
  - spring biomass - `AGR07`

  I assume:

  $C_{cover\_rye} = (AGR06 + AGR07) * cover\_biomass\_to\_C$

- For red clover/mixed

  - fall biomass - `AGR41`
  - fall carbon - `AGR43`
  - spring carbon - `AGR46`

  I assume:

  $C_{cover\_red} = AGR43 + AGR46$

- In total:

  $C_{cover} = C_{cover\_rye} + C_{cover\_red}$​



### Weedy

- $C_{weedy} = AGR40 * 0.45$



**Total Carbon Input**
$$
C\_input\_total = C_{corn} + C_{soy} + C_{wheat} + C_{cover} + C_{weedy}
$$


## Problems

- Additional information needed for

  - conversion from biomass to carbon for weed
  - conversion from biomass to carbon for rye cover crop

- How to calculate output C (for each plot)?

  Assumption: $C_{output} = C_p$​



## Next Steps

- [ ] try to repeat for other experiments

- [ ] try to integrate N input as well

- [ ] site selection for Gracenet

  - [ ] not all the sites are interested

- [ ] The tillage

  - [ ] A list for all the tillage columns 
  - [ ] factor should be include: tillage, 
  - [ ] hear from Dr. O'Neil

- [ ] Gas loss N2O and NH3

  - [ ] GHG flux

- [ ] Biomass in the field

  Grain carbon

  Grain removed from the field

  Estimate of CO2 emission

  CH4 output (positive and negative)

  divide by year

  differentiate by rotation

- [ ] For Gas emission

  N2O, CO2 and CH4

  unique value for a year

  should include standard variation

  field 

- [ ] Figure out the NO2, NH4, MeasGasNutrientLoss, difference, whether it is aggregated