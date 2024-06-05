# Log for May 20-21

> Date: May 16-17, 2024
>
> Author: Haolin Li



## Meeting

- making a summery of the related columns
- the cob + vegetative parts as input C
- plus + weed input
- estimate the root carbon using the above ground carbon
- repeat for soybean and wheat
- try to integrate N input as well

## Tasks

- adjust the CAP calc to include the fertilizer input
- adjust other parts of the code to be compatible



## Work Log

Carbon input calculation for crops (which are corn, wheat, soybean)

*neglect the calculation for Standard Variation for the dataset*
$$
C_p = C_{grain} = Y_p * conc\_rate\\
C_s = Y_p(1-HI)/HI*conc\_rate = C_p * (1-HI)/HI\\
C_r = Y_p(S:R*HI)*conc\_rate = C_p / (S:R*HI)\\
C_e = C_r * Y_e = C_r * ERtoR\\
C_{input} = C_s + C_r + C_e
$$
For corn:

- C_p = AGR23 (if AGR23 is available)
- if not, use Y_p = AGR33
- C_s can be calculated with above method
- or we assume C_s = C_cob + C_vegetative
- HI_corn = 0.5
- Use different S:R ratio for fertilized/unfertilized ones

For soybean

- C_p = AGR27
- C_s can be calculated with above method
- or we assume C_s = C_vegetative
- HI_soy = 0.4
- Use uniform S:R ratio = 5.2

For wheat

- C_p is not available, we use Y_p to calculate C_p instead
  - conc_rate = 0.65
  - given raw yield Y_r, kg/ha
  - given moisture ratio M, g/kg
  - thus dry yield Y_p = Y_r - (Y_r * M / 1000)
- HI_wheat = 0.4
- S:R ratio = 6

For cover crop

- C input for cover crop = AGR43 + AGR46

For weedy

- C input for weedy = AGR40 * 0.45

## Questions

- For the corn part, how
- what is the conversion from biomass to carbon for cover crop?
- how to calculate output C (for each plot)
- here I used the infer method, maybe should use original data instead