$ontext
This code contains the main LP model of Profile Expansion Model
a. Loading and preprocessing sets and data
b. Run simulation year by year
c. Post processing data for reporting
d. Unload data to gdx file for reporting purpose

Last modified by Tuong Nguyen, 17/02/2014.
$offtext

$oneolcom
$eolcom !

$oninline
$inlinecom { }

SETS
* Time sets
  t            'time series'
  p            'Trading period of the day'
  d            'dates of the month'
  w            'day of the week'
  m            'month numbers'
  t2m(t,m)     'Time series to month'

* Network sets
  r                        'Islands/regions'
  tx                       'transmission link'
  txdef(tx,r,r)            'transmission link definition'

* Technology sets
  g                        'Generation projects'
  k                        'Generation technologies'
  gp                       'Generation projects properties'
  fk(g)                    'Generation technologies can be used for FK/reserve service'
  g2k(g,k)                 'mapping generation project to technology'
  g2r(g,r)                 'mapping generation project to region'

* Different types of load
  lpf                      'Load profile type'

* Violation type
  v            'list of violation type'
               / OverBuiltCapacity
                 GenerationDeficit
                 GenerationSurplus
                 ReserveShortage
                 OverGenerationMax
                 UnderGenerationMin
                 MonthlyGenOutputVio
                 OverTxCapacity
                 YearlyGenOutputVio /
;

ALIAS (r,r1,r2), (tx,tx1,tx2), (k,k1,k2), (g,g1,g2,g3,g4,g5,g6)
;

PARAMETERS
* Scalar
  WACC                     'Weighted average cost of capital'
  TaxRate                  'Corporate tax rate'
  Inflation                'Inflation rates'
  Co2tax                   'CO2 tax, $/tonne CO2-equivalent'
  HrsPerPeriod             'Lenght of a period'
  ReserveRatio             'Reserve requirement: ratio of Demand'
  SystemLossRate           'System loss rate'

* Generation data
  CapitalCost(g)           'Capital cost by technology, $/kW'
  CapexLife(g)             'Plant life by technology, years'
  DepRate(g)               'Depreciation rate by technology'
  FixedCost(g)             'Annual fixed operating cost, $/MW/Yr'

  NamePlate(g)             'Maximum capacity can be installed/built, MW'
  ExistCapacity(g)         'Existing capacity, MW'
  YearlyFactor(g)          'Yearly capacity factor, %'

  VarOM(g)                 'Variable O&M costs by technology, $/MWh'
  FuelPrices(g)            'Fuel prices by technology, $/GJ'
  Heatrate(g)              'Heat rate of generating plant by technology, GJ/GWh'
  EmissionFactors(g)       'CO2-equivalent emissions by technology, tonnes CO2/PJ'

  FuelCost(g)              'Fuel cost of technology g, $/MWh'
  Co2Cost(g)               'Carbon emission cost of technology g, $/MWh'
  Srmc(g)                  'Short run marginal cost for the year to be modelled, $/MWh'
  AnnuityFacR(g)           'Real annuity factor by technology'
  CapRecFac(g)             'Capital recovery factor by technology (includes a nominal accounting treatment of depreciation tax credit)'
  AnnualCapCharge(g)       'Annualised capital charge by technology for modelled year, $/MW/Yr'

  MonthExpectRatio(m,g)    'Expecting average monthly generation output'
  MaxCapFactor(t,g)        'Plant operating capacity factors depending in technology and time of the year, fraction of installed capacity'
  MustRunFactor(t,g)       'Must run factors depending on technology and time of the year, fraction of installed capacity'
  WindGenFactor(t,g)       'Wind generation output factor in each period, MW '

*Network
  TxCapacity(tx)           'transmission capacity'
  TxLossRate(tx)           'transmission loss rate'

* Demand data
  AvgDemand(r,lpf)         'Yearly average demand by region and load type, MW'
  LoadRatio(t,r,lpf)       'Load distribution factor'

* Violation penalty values
  Penalty(v)               'Violation Penalty - Big number'
                           / OverBuiltCapacity     1e6
                             GenerationDeficit     1e6
                             GenerationSurplus     1e6
                             ReserveShortage       1e6
                             OverGenerationMax     1e6
                             UnderGenerationMin    1e6
                             MonthlyGenOutputVio   1e6
                             OverTxCapacity        1e6
                             YearlyGenOutputVio    1e9 /

;

*====== MODEL FORMULATION ================================================================================================================================================================

* Declare and initialise model.
Variables
  COST                     'Cost - objective function value in fixed demand LP, $m'
;

Positive Variables
  REMOVEDCAPACITY(g)       'Level of capacity to be removed for each generation technology type, MW'
  ADDEDCAPACITY(g)         'Level of capacity installed of each generation technology type, MW'
  DEMAND(t,r)              'Regional Demand in period t'
  DEMANDPROFILE(t,r,lpf)   'Regional demand of load type lpf in period t'
  GENERATION(t,g)          'Output or quantity produced in each time period by each technology, MW'
  POWERFLOW(t,tx)          'Power flow on tranmission line tx'
  SPILLAGE(t,g)            'Spilled quantity in each time period by hydro technology, MW'

*Slack variables
  OVERBUILT(g)             'Amount of capacity built over the NamePlate limit, MW'
  DEFICITGEN(t,r)          'Deficit generationin each time period t, MW'
  SURPLUSGEN(t,r)          'Surplus generationin each time period t, MW'
  DEFICITRES(t,r)          'Deficit of reserve to meet reserve requirement, MW'
  OVERGENERATION(t,g)      'Violation of operating capacity limit, MW'
  UNDERGENERATION(t,g)     'Violation of must-run limit, MW'
  MONTHLYGENVIO(m,g)       'Violation of expected monthly generation, MW'
  TXOVERFLOW(t,tx)         'Violation of transmission capacity, MW'
  YEARLYGENVIO(g)          'Violation of expected monthly generation, MW'
;

Equations
  Objfn                    'Objective function for the fixed demand LP problem'

  ProfileDemand(t,r,lpf)   'Calculate regional demand of load type lpf in period t'
  AggregateDemand(t,r)     'Calculate regional total demand in period t'
  BuildCapacity(g)         'Impose an upper bound on built capacity'
  MaxGeneration(t,g)       'Maximum generation limit'
  MinGeneration(t,g)       'Must-run requirment'
  MonthlyGeneration(m,g)   'Expected monthly output for weather dependant technologies'
  YearlyGenerationMax(g)   'Max yearly output based on outage rate'
  MktClearing(t,r)         'Market clearing condition - demand = generation'
  ReserveReq(t,r)          'Market reserve requirement'
  PowerFlowMax(t,tx)       'Power flow limit'
;

Objfn..
   Cost =e= Sum[ g      , AnnualCapCharge(g)                      * ADDEDCAPACITY(g)                       ]      !  'Anual capcital charge applied to added capacity = $/MW/yr * MW * yr = $'

         +  Sum[ g      , FixedCost(g) * (1 - taxRate)            * (ADDEDCAPACITY(g) - REMOVEDCAPACITY(g))]      !  'Fixed cost applied to installed capacity = $/MW * MW = $'

         +  Sum[(t,g)   , Srmc(g)  * (1 - taxRate) * HrsPerPeriod * GENERATION(t,g)                        ]      !  'Short-run marginal cost = $/MWh * GWh * hr = $'

*The slack variables below are used to relax the constraint and to raise the cause of infeasibility.
         +  Sum[  g     , Penalty('OverBuiltCapacity')   *   OVERBUILT(g)         ]
         +  Sum[ (t,r)  , Penalty('GenerationDeficit')   *   DEFICITGEN(t,r)      ]
         +  Sum[ (t,r)  , Penalty('GenerationSurplus')   *   SURPLUSGEN(t,r)      ]
         +  Sum[ (t,r)  , Penalty('ReserveShortage')     *   DEFICITRES(t,r)      ]
         +  Sum[ (t,g)  , Penalty('OverGenerationMax')   *   OVERGENERATION(t,g)  ]
         +  Sum[ (t,g)  , Penalty('UnderGenerationMin')  *   UNDERGENERATION(t,g) ]
         +  Sum[ (m,g)  , Penalty('MonthlyGenOutputVio') *   MONTHLYGENVIO(m,g)   ]
         +  Sum[ (t,tx) , Penalty('OverTxCapacity')      *   TXOVERFLOW(t,tx)     ]
         +  Sum[  g     , Penalty('YearlyGenOutputVio')  *   YEARLYGENVIO(g)      ]
;


* Calculate regional demand of load type lpf in period t
ProfileDemand(t,r,lpf) $ [ LoadRatio(t,r,lpf) and AvgDemand(r,lpf) ]..
   DEMANDPROFILE(t,r,lpf) * 1/LoadRatio(t,r,lpf)
=e=
   AvgDemand(r,lpf)
;


* Calculate regional total demand in period t
AggregateDemand(t,r)..
   DEMAND(t,r)
=e=
   (1 + SystemLossRate) * Sum[lpf, DEMANDPROFILE(t,r,lpf)]
;


* Impose an upper bound on built capacity
BuildCapacity(g)..
   ADDEDCAPACITY(g)
 + ExistCapacity(g)
 - REMOVEDCAPACITY(g)
 - OVERBUILT(g)
=l=
   NamePlate(g) ;
;


* Market clearing condition - total demand = sum of output from all technologies
MktClearing(t,r)..
   Sum[ g $ g2r(g,r), GENERATION(t,g) ]
 + Sum[ (tx1,r1) $ txdef(tx1,r1,r), POWERFLOW(t,tx1) * (1 - TxLossRate(tx1)) ]
 - Sum[ (tx2,r2) $ txdef(tx2,r,r2), POWERFLOW(t,tx2) ]
 + DEFICITGEN(t,r)
=e=
   DEMAND(t,r)
 + SURPLUSGEN(t,r)
;


* System reserve requirement
ReserveReq(t,r)..
   Sum[ g $ ( fk(g) and g2r(g,r) )
      , MaxCapFactor(t,g) * [ ADDEDCAPACITY(g) + ExistCapacity(g) - REMOVEDCAPACITY(g) ]
      - GENERATION(t,g)
      ]
 + DEFICITRES(t,r)
=g=
   ReserveRatio * DEMAND(t,r)
;


* Maximum generation limit (MW)
MaxGeneration(t,g)..
   GENERATION(t,g)
=l=
   MaxCapFactor(t,g) * [ ADDEDCAPACITY(g) + ExistCapacity(g) - REMOVEDCAPACITY(g) ]
 + OVERGENERATION(t,g)
;


* Must-run generation output (MW)
MinGeneration(t,g)..
   GENERATION(t,g) + SPILLAGE(t,g)
 + UNDERGENERATION(t,g)
=g=
   MustRunFactor(t,g) * [ ADDEDCAPACITY(g) + ExistCapacity(g) - REMOVEDCAPACITY(g) ]

;


* Total generation should not greater than expected output per month'
MonthlyGeneration(m,g) $ MonthExpectRatio(m,g)..
   Sum[ t $ t2m(t,m), GENERATION(t,g) + SPILLAGE(t,g) ]
=l=
   Sum[ t $ t2m(t,m), MonthExpectRatio(m,g) * [ ADDEDCAPACITY(g)
                                              + ExistCapacity(g)
                                              - REMOVEDCAPACITY(g) ]
      ]
 + MONTHLYGENVIO(m,g)
;


* Max yearly output based on outage rate
YearlyGenerationMax(g) $ ( YearlyFactor(g) < 1 )..
   Sum[ t, GENERATION(t,g) + SPILLAGE(t,g)] / card(t)
=l=
   YearlyFactor(g) * [ ADDEDCAPACITY(g)
                    +  ExistCapacity(g)
                     - REMOVEDCAPACITY(g)]
 + YEARLYGENVIO(g)
;

PowerFlowMax(t,tx)..
   POWERFLOW(t,tx)
=l=
   TxCapacity(tx)
 + TXOVERFLOW(t,tx)
;

Models
  FixedQtyLP 'Fixed demand quantity'
    / Objfn
      ProfileDemand
      AggregateDemand
      BuildCapacity
      MktClearing
      ReserveReq
      Maxgeneration
      Mingeneration
      MonthlyGeneration
      YearlyGenerationMax
      PowerFlowMax
    /

  UnlimitedCapacityLP 'Capacity built is unlimited'
    / Objfn
      ProfileDemand
      AggregateDemand
*      BuildCapacity
      MktClearing
      ReserveReq
      Maxgeneration
      Mingeneration
      MonthlyGeneration
      YearlyGenerationMax
      PowerFlowMax
    /

;

*====== MODEL FORMULATION END ============================================================================================================================================================

