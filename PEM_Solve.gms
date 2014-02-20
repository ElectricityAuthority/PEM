$ontext
This code is used for
a. Loading and preprocessing sets and data
b. Run simulation year by year
c. Post processing data for reporting
d. Unload data to gdx file for reporting purpose

Last modified by Tuong Nguyen, 17/02/2014.
$offtext

$include Settings.inc

* Set the solver for the LP and MIP
option lp = %Solver% ;
option mip = %Solver% ;

* Set the solution print status in the lst file
option solprint = off ;

* Set the column (variable) and row (equation) listing in the lst file
option limcol = 0, limrow = 0 ;


*===== SETS AND PARAMETERS DECLARATION =========================================
* The elements of following sets are hardcoded
SETS
* The elements of set y control the data imported from GDX input file ----------
  y            'studied years'                  /1990 * 2012/

* Time sets
  t            'time series'                    / 1 * 17568 /
*  t            'time series'                    / 1 * 100 /
  p            'Trading period of the day'      / 1 * 50 /
  d            'dates of the month'             / 1 * 31 /
  w            'day of the week'                / 1 * 7 /
  m            'month numbers'                  / 1 * 12 /


* Sets for reporting purpose
  Month        'Months'                         / Jan   'January'
                                                  Feb   'February'
                                                  Mar   'March'
                                                  Apr   'April'
                                                  May   'May'
                                                  Jun   'June'
                                                  Jul   'July'
                                                  Aug   'August'
                                                  Sep   'September'
                                                  Oct   'October'
                                                  Nov   'November'
                                                  Dec   'December' /

  m2M(m,Month) 'Map month numbers to months'    / #m:#Month /

;
*-------------------------------------------------------------------------------


* The elements of following sets are imported from GDX input file --------------
SETS

* Network sets
  r                        'Islands/regions'
  tx                       'transmission link'
  txpar                    'parameter components (properties) of transmission'
  txdef(tx,r,r)            'transmission link definition'

* Technology sets
  g                        'Generation projects'
  k                        'Generation technologies'
  gp                       'Generation projects properties'

* Different types of load
  lpf                      'Load profile type'

* Mapping sets
  g2k2r(g,k,r)             'mapping gen project to technology and to region'
  TSMapping(t,m,d,w,p)     'Time series mapping'
;

$GDXIN Inputs.gdx
$LOAD g = GenProjects
$LOAD k = GenTechnologies
$LOAD r = Regions
$LOAD gp = GenProjectProperties
$LOAD tx = TxNames
$LOAD txpar = TxProperties
$LOAD txdef = TxDefinition
$LOAD lpf =ProfileType
$LOAD g2k2r = GenProjectTechnologyMapping
$LOAD TSMapping = TimeSeriesMapping
$GDXIN
*-------------------------------------------------------------------------------


* The following data are imported from GDX input file --------------------------
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
  GenProjectData(g,y,gp)    'Generation technology data table'
  Reserve(k)                'Technology can be used for reserve'
  MonthExpectRatio(m,g)     'Expecting average monthly generation output'
  MonthMaxFactor(m,g)       'Maximum capacity factor calculated by month using historical generation output and installed capacity'
  MonthMinFactor(m,g)       'Minimum capacity factor calculated by month using historical generation output and installed capacity'

*Network
  TxParameters(tx,y,txpar)  'transmission data by year'

* Demand data
  YearlyAvgDemand(y,r)      'Yearly average demand by region and load type, MW'
  LDFactor(t,m,d,w,p,r,lpf) 'Load distribution factor table'

* Wind generation data
  WindGenFactor(t,g)        'Wind generation output factor in each period, MW --> imported from GDX input file'
;

$GDXIN Inputs.gdx
$LOAD WACC TaxRate Co2tax ReserveRatio SystemLossRate
$LOAD Inflation = InflationRate
$LOAD HrsPerPeriod = PeriodLength
$LOAD GenProjectData
$LOAD MonthExpectRatio
$LOAD MonthMaxFactor
$LOAD MonthMinFactor
$LOAD WindGenFactor
$LOAD Reserve = ReserveTechnology
$LOAD TxParameters
$LOAD YearlyAvgDemand = AvgDemand
$LOAD LDFactor = ProfileFactor
$GDXIN
*-------------------------------------------------------------------------------


* The following data are calculated during preprocessing phase -----------------
PARAMETERS
* Transmission data
  txCapacity(tx)           'transmission capacity'
  txLossRate(tx)           'transmission loss rate'

* Demand data
  avgDemand(r,lpf)         'Yearly average demand by region and load type, MW'
  loadRatio(t,r,lpf)       'Load distribution factor'

* Investment and operational information for each technology
  capitalCost(g)           'Capital cost by technology, $/kW'
  capexLife(g)             'Plant life by technology, years'
  depRate(g)               'Depreciation rate by technology'
  fixedCost(g)             'Annual fixed operating cost, $/MW/Yr'

  namePlate(g)             'Maximum capacity can be installed/built, MW'
  existCapacity(g)         'Existing capacity, MW'
  retiredCapacity(g)       'Retired capacity or force built if negative'
  yearlyFactor(g)          'Yearly capacity factor, %'

  varOM(g)                 'Variable O&M costs by technology, $/MWh'
  fuelPrices(g)            'Fuel prices by technology, $/GJ'
  heatrate(g)              'Heat rate of generating plant by technology, GJ/GWh'
  emissionFactors(g)       'CO2-equivalent emissions by technology, tonnes CO2/PJ'

* Other calculated data
  fuelCost(g)              'Fuel cost of technology g, $/MWh'
  Co2Cost(g)               'Carbon emission cost of technology g, $/MWh'
  Srmc(g)                  'Short run marginal cost for the year to be modelled, $/MWh'
  annuityFacR(g)           'Real annuity factor by technology'
  capRecFac(g)             'Capital recovery factor by technology (includes a nominal accounting treatment of depreciation tax credit)'
  annualCapCharge(g)       'Annualised capital charge by technology for modelled year, $/MW/Yr'

  maxCapFactor(t,g)        'Plant operating capacity factors depending in technology and time of the year, fraction of installed capacity'
  mustRunFactor(t,g)       'Must run factors depending on technology and time of the year, fraction of installed capacity'
;
*-------------------------------------------------------------------------------


* The following parameters are for reporting and post processing----------------
Parameters
  PeriodDemand(y,t,r)               'Calulated period demand'
  Power_Flow(y,t,tx)                'Flow in TX line, MW'
  Price(y,t,r)                      'Market clearing price by region, $/MWh'
  ProPr(y,r,lpf)                    'LRMC by load profile and region, $/MW'
  InstalledCap(y,g)                 'Total capacity = existing + added - removed'
  GenOutput(y,t,g)                  'Generation cleared, MW'
  TotalGen(y,t,r)                   'Total generation cleared by period, MW'
  MonthExpOutput(y,m,g)             'Total expected generation per month, GWh'
  MonthGenOutput(y,m,g)             'Total generation cleared per month, GWh'
  MonthSpillage(y,m,g)              'Total hydro splilled per month, GWh'
  YearGenOutput(y,g)               'Total generation cleared per year, GWh'
  YearSpillage(y,g)                 'Total spilled hydro per year, GWh'
  YearBuiltGWh(y,g)                 'Total new-built capacity per year, GWh'
  YearOpGWh(y,g)                    'Total avaiable capacity per year, GWh'
  LoadFactor(y,g)                   'Load factor of generation g, %'
  UtilFactor(y,g)                   'Utility factor of generation g, %'
  ObjValue(y)                       'Objective value, $'
  TotalCost(y)                      'Total cost of supply ignore sunk cost, $'
  GenRevenue(y)                     'Annual revenue, $'

  PlantResult(y,*,g)               'Plant result summary'

  Vio_NamePlate(y,g)               'Violation'
  Vio_GenDeficit(y,t,r)            'Violation'
  Vio_GenSurplus(y,t,r)            'Violation'
  Vio_ResDeficit(y,t,r)            'Violation'
  Vio_GenMaxMW(y,t,g)              'Violation'
  Vio_GenMinMW(y,t,g)              'Violation'
  Vio_GenMonth(y,m,g)              'Violation'
  Vio_TxLimit(y,t,tx)              'Violation'
  Vio_GenYear(y,g)                 'Violation'
  Vio_Test(y)                      'Violation'
;
*-------------------------------------------------------------------------------


*===== SETS AND PARAMETERS DECLARATION END =====================================




*===== GENERAL SET AND DATA PROCESSING =========================================

* Calculating set elements

* Set mapping generation project to technology
  g2k(g,k) $ Sum[ r $ g2k2r(g,k,r), 1] = yes;

* Set mapping generation project to region
  g2r(g,r) $ Sum[ k $ g2k2r(g,k,r), 1] = yes;

* Set mapping time series to month
  t2m(t,m) $ Sum[ (d,w,p) $ TSMapping(t,m,d,w,p), 1 ] = yes;

* Set define generation project can provide reserve
  fk(g) $ Sum[ k $ g2k(g,k), Reserve(k)] = yes   ;

* Max operating capacity factor
  MaxCapFactor(t,g) = 0.9;  ! 'Default value'
  MaxCapFactor(t,g) $ ( Sum[ m $ t2m(t,m), MonthMaxFactor(m,g) ] > 0 )
                    = Sum[ m $ t2m(t,m), MonthMaxFactor(m,g) ] ;
  MaxCapFactor(t,g) $ g2k(g,'Wind')= WindGenFactor(t,g) ;

* Must-run factor
  MustRunFactor(t,g) = Sum[ m $ t2m(t,m), MonthMinFactor(m,g) ];

* Load Ratio Data
  LoadRatio(t,r,lpf) = Sum[ (m,d,w,p), LDFactor(t,m,d,w,p,r,lpf)];

*====== GENERAL SET AND DATA PROCESSING END ====================================


*===== RUN SIMULATION ONE YEAR AT A TIME =======================================
InstalledCap(y,g)= 0;

Loop[ y,

*+++++ DATA RESET AND PREPROCESSING ++++++++++++++++++++++++++++++++++++++++++++
*   CO2 Tax
    Co2tax = 12.5 $ (ord(y) > 21);

*   Demand
    AvgDemand(r,lpf) $ Sameas(lpf,'All') = YearlyAvgDemand(y,r);
    AvgDemand(r,lpf) $ (not Sameas(lpf,'All')) = 0.001;

*   Transmission capacity
    option clear = txCapacity;
    txCapacity(tx) = Sum[ txpar $ (ord(txpar) = 1), txParameters(tx,y,txpar) ];

*   Transmission loss factor
    option clear = txLossRate;
    txLossRate(tx) = Sum[ txpar $ (ord(txpar) = 2), txParameters(tx,y,txpar) ];

*   Maximum capacity can be installed, MW'
    option clear = namePlate;
    namePlate(g) = GenProjectData(g,y,'Maximum Capacity');

*   Retired capacity, MW --> forced built if negative
    option clear = retiredCapacity;
    retiredCapacity(g) = GenProjectData(g,y,'Retired');

*   Existing capacity, MW
    option clear = existCapacity;
    existCapacity(g) $ (ord(y) = 1) = GenProjectData(g,y,'Existing Capacity');
    existCapacity(g) $ (ord(y) > 1) = InstalledCap(y-1,g) - RetiredCapacity(g);

*   Yearly capacity factor in each region, %
    option clear = yearlyFactor;
    yearlyFactor(g) = GenProjectData(g,y,'Availability Factor');

*   Capital cost by technology, $/kW
    option clear = capitalCost;
    capitalCost(g) = GenProjectData(g,y,'Capital Cost');

*   Plant life by technology, years
    option clear = capexLife;
    capexLife(g) = GenProjectData(g,y,'Capex Life');

*   Depreciation rate by technology
    option clear = depRate;
    depRate(g) = GenProjectData(g,y,'Depreciation');

*   Annual fixed operating cost, $/MW/Yr
    option clear = fixedCost;
    fixedCost(g) = GenProjectData(g,y,'Fixed Cost');

*   Variable O&M costs by technology, $/MWh'
    option clear = varOM;
    varOM(g) = GenProjectData(g,y,'Var O&M Cost');

*   Fuel prices by technology, $/GJ
    option clear = fuelPrices;
    fuelPrices(g) = GenProjectData(g,y,'Fuel Cost');

*   Heat rate of generating plant by technology, GJ/GWh
    option clear = heatRate;
    heatrate(g) = GenProjectData(g,y,'Heat rate');

*   CO2-equivalent emissions by technology, tonnes CO2/PJ
    option clear = emissionFactors;
    emissionFactors(g) = GenProjectData(g,y,'Emission');

*   Calculate annualised capital cost ------------------------------------------
    option clear = annuityFacR;
    option clear = capRecFac;
    option clear = annualCapCharge;
*   Compute capital recovery factor using declining balance depreciation method.
    annuityFacR(g) $ WACC = [ 1 - ( 1 + WACC ) ** (-CapexLife(g)) ] / WACC ;

    capRecFac(g) $ annuityFacR(g) = [ 1 - ( depRate(g) * taxRate )
                                        / ( depRate(g) + inflation + WACC )
                                    ]
                                  / annuityFacR(g) ;

    annualCapCharge(g) = 1e3 * capitalCost(g) * capRecFac(g) ;
*   Calculate annualised capital cost end --------------------------------------

*   Calculate SRMC -------------------------------------------------------------
    option clear = fuelCost;
    option clear = Co2Cost;
    option clear = Srmc;
*   Compute the SRMC (and its components) for each generation plant, $/MWh.
    fuelCost(g) = 1e-3 * fuelPrices(g) * heatRate(g);
    Co2Cost(g) = 1e-9 * heatRate(g) * emissionFactors(g) * Co2tax ;
    Srmc(g) = VarOM(g) + FuelCost(g) + Co2Cost(g) ;
    Srmc(g) $ (Srmc(g) < .01 ) = 1e-3 * ord(g) / card(g) ;
*   Calculate SRMC end ---------------------------------------------------------

*+++++ DATA RESET AND PREPROCESSING END ++++++++++++++++++++++++++++++++++++++++


*+++++ SOLVING +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

*   Reset variables
    option clear = COST;

    option clear = REMOVEDCAPACITY;
    option clear = ADDEDCAPACITY;
    option clear = DEMAND;
    option clear = DEMANDPROFILE;
    option clear = GENERATION;
    option clear = POWERFLOW;
    option clear = SPILLAGE;

    option clear = OVERBUILT;
    option clear = DEFICITGEN;
    option clear = SURPLUSGEN;
    option clear = DEFICITRES;
    option clear = OVERGENERATION;
    option clear = UNDERGENERATION;
    option clear = MONTHLYGENVIO;
    option clear = TXOVERFLOW;
    option clear = YEARLYGENVIO;
*   Reset variables end

*   Set bounds for variables
    ADDEDCAPACITY.fx(g) $ [NamePlate(g) <= ExistCapacity(g)] = 0;
    GENERATION.fx(t,g) $ [NamePlate(g) + ExistCapacity(g) = 0] = 0;
    REMOVEDCAPACITY.up(g) =  ExistCapacity(g);
    REMOVEDCAPACITY.fx(g) =  0; ! 'at the moment, no cacacity removal is allowed'
    DEMANDPROFILE.fx(t,r,lpf) $ [LoadRatio(t,r,lpf) * AvgDemand(r,lpf) = 0] = 0;
    SPILLAGE.fx(t,g) $ [not g2k(g,'Hydro')] = 0; ! 'only hydro is spillabe'
    POWERFLOW.up(t,tx) = Sum[(r,lpf) $ Sum[r1 $ txdef(tx,r1,r), 1], AvgDemand(r,lpf)];
*   Set bounds for variables end

*   Solve LP problem
*    FixedQtyLP.reslim = LPTimeLimit ;
*    FixedQtyLP.iterlim = LPIterationLimit ;
*    Solve FixedQtyLP minimising Cost using lp ;

    UnlimitedCapacityLP.reslim = LPTimeLimit ;
    UnlimitedCapacityLP.iterlim = LPIterationLimit ;
    Solve UnlimitedCapacityLP minimising Cost using lp ;

*+++++ SOLVING END +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


*+++++ OUTPUT PROCESSING ================================================================================================================================================================

    PeriodDemand(y,t,r) = DEMAND.l(t,r);

    Power_Flow(y,t,tx) = POWERFLOW.l(t,tx);

    Price(y,t,r) = mktClearing.m(t,r);

    ProPr(y,r,lpf) = Sum[ t, ProfileDemand.m(t,r,lpf)]
                   / [HrsPerPeriod * card(t)];

    InstalledCap(y,g) = ADDEDCAPACITY.l(g)
                      + ExistCapacity(g)
                      - REMOVEDCAPACITY.l(g);

    GenOutput(y,t,g) = GENERATION.l(t,g);

    TotalGen(y,t,r)  = Sum[ g $ g2r(g,r), GENERATION.l(t,g) ];

    MonthExpOutput(y,m,g) = Sum[ t $ t2m(t,m), MonthExpectRatio(m,g)
                                             * [ ADDEDCAPACITY.l(g)
                                               + ExistCapacity(g)
                                               - REMOVEDCAPACITY.l(g)
                                               ]
                               ] * HrsPerPeriod * 1e-3;

    MonthGenOutput(y,m,g) = Sum[ t $ t2m(t,m), GENERATION.l(t,g) ]
                          * HrsPerPeriod * 1e-3;

    MonthSpillage(y,m,g)  = Sum[ t $ t2m(t,m), SPILLAGE.l(t,g) ]
                          * HrsPerPeriod * 1e-3;

    YearGenOutput(y,g)    = Sum[ m, MonthGenOutput(y,m,g) ];

    YearSpillage(y,g)     = Sum[ t, SPILLAGE.l(t,g) ]
                          * HrsPerPeriod * 1e-3;

    YearBuiltGWh(y,g)     = HrsPerPeriod * 1e-3 * card(t)
                          * [ ADDEDCAPACITY.l(g)
                            + ExistCapacity(g)
                            - REMOVEDCAPACITY.l(g)
                            ];

    YearOpGWh(y,g)      = Sum[ t, Max[ MaxCapFactor(t,g), yearlyfactor(g) ]
                                  * [ ADDEDCAPACITY.l(g)
                                    + ExistCapacity(g)
                                    - REMOVEDCAPACITY.l(g)
                                    ]
                               ] * HrsPerPeriod * 1e-3;

    LoadFactor(y,g) $ YearBuiltGWh(y,g) = YearGenOutput(y,g) / YearBuiltGWh(y,g);

    UtilFactor(y,g) $ YearOpGWh(y,g) = YearGenOutput(y,g) / YearOpGWh(y,g);

    ObjValue(y) = Cost.l;

    TotalCost(y) = Sum[ g, AnnualCapCharge(g) * ADDEDCAPACITY.l(g) ]
                 + Sum[ g, FixedCost(g) * (1 - taxRate)
                        * [ ADDEDCAPACITY.l(g)
                          + ExistCapacity(g)
                          - REMOVEDCAPACITY.l(g)
                          ]
                      ]
                 + Sum[ (t,g), Srmc(g) * (1 - taxRate)
                             * HrsPerPeriod * GENERATION.l(t,g)
                      ];

    GenRevenue(y) = Sum[ (t,g,r) $ g2r(g,r), Price(y,t,r)
                                           * GenOutput(y,t,g)
                                           * HrsPerPeriod
                       ];

    PlantResult(y,'NamePlate, MW',g) = NamePlate(g);
    PlantResult(y,'CapCost, $/MW/Yr',g) = AnnualCapCharge(g);
    PlantResult(y,'FixedCost, $/MW/Yr',g) = FixedCost(g);
    PlantResult(y,'SRMC, $/MWh',g) = SRMC(g);
    PlantResult(y,'Exist, MW',g) = ExistCapacity(g);
    PlantResult(y,'Removed, MW',g) = REMOVEDCAPACITY.l(g);
    PlantResult(y,'Forced Closed, MW',g) = RetiredCapacity(g) $ (RetiredCapacity(g) > 0);
    PlantResult(y,'Forced Built, MW',g) = - RetiredCapacity(g) $ (RetiredCapacity(g) < 0);
    PlantResult(y,'Built, MW',g) = ADDEDCAPACITY.l(g);
    PlantResult(y,'Installed Capacity, GWh',g) = YearBuiltGWh(y,g);
    PlantResult(y,'Operating Capacity, GWh',g) = YearOpGWh(y,g);
    PlantResult(y,'Generation, GWh',g) = YearGenOutput(y,g);
    PlantResult(y,'Spillage, GWh',g) = YearSpillage(y,g);
    PlantResult(y,'Load Factor',g) = LoadFactor(y,g);
    PlantResult(y,'Utilization Factor',g) = UtilFactor(y,g);
    PlantResult(y,'Average Cost, $/MWh',g) $ LoadFactor(y,g)
        = SRMC(g) * (1 - taxRate)
        + [ AnnualCapCharge(g) + FixedCost(g) * (1 - taxRate) ]
        / [ YearGenOutput(y,g) * 1e3 ];

    Vio_NamePlate(y,g) = OVERBUILT.l(g);
    Vio_GenDeficit(y,t,r) = DEFICITGEN.l(t,r);
    Vio_GenSurplus(y,t,r) = SURPLUSGEN.l(t,r);
    Vio_ResDeficit(y,t,r) = DEFICITRES.l(t,r);
    Vio_GenMaxMW(y,t,g) = OVERGENERATION.l(t,g);
    Vio_GenMinMW(y,t,g) = UNDERGENERATION.l(t,g);
    Vio_GenMonth(y,m,g) = MONTHLYGENVIO.l(m,g);
    Vio_TxLimit(y,t,tx) = TXOVERFLOW.l(t,tx);
    Vio_GenYear(y,g) = YEARLYGENVIO.l(g);
    Vio_Test(y) = Sum[ g, Vio_NamePlate(y,g) ]
                + Sum[ (t,r), Vio_GenDeficit(y,t,r)
                            + Vio_GenSurplus(y,t,r)
                            + Vio_ResDeficit(y,t,r) ]
                + Sum[ (t,g), Vio_GenMaxMW(y,t,g)
                            + Vio_GenMinMW(y,t,g) ]
                + Sum[ (m,g), Vio_GenMonth(y,m,g) ]
                + Sum[ (t,tx), Vio_TxLimit(y,t,tx) ]
                + Sum[ g, Vio_GenYear(y,g) ]

] ;


*===== RUN SIMULATION ONE YEAR AT A TIME END ===================================

execute_Unload "PEMResults.gdx",
*Input
   y = year
   t = Period
   k = Technology,
   g = GenerationProject,

   Penalty = ViolationPenalty
   WACC
   TaxRate
   Inflation
   HrsPerPeriod
   ReserveRatio

   MaxCapFactor
   MustRunFactor
   MonthExpectRatio
   YearlyAvgDemand = AvgDemand
   LDFactor

   tx = Transmisson
   txDef = TxDefinition
   txCapacity
   txLossRate

*Output
   PeriodDemand
   Power_Flow
   Price
   ProPr = MarginalCostofSupply
   GenOutput = PeriodGeneration
   TotalGen = PeriodTotalGen
   MonthExpOutput
   MonthGenOutput
   GenRevenue

   ObjValue
   TotalCost
   PlantResult

   Vio_Test
   Vio_NamePlate
   Vio_GenDeficit
   Vio_GenSurplus
   Vio_ResDeficit
   Vio_GenMaxMW
   Vio_GenMinMW
   Vio_GenMonth
   Vio_TxLimit
   Vio_GenYear

;


execute "Gdxxrw PEMResults.gdx o=PEMResults.xls par=PlantResult Rng=Results!A1"
execute "Gdxxrw PEMResults.gdx o=PEMResults.xls par=MarginalCostofSupply Rng=Prices!A1"
execute "Gdxxrw PEMResults.gdx o=PEMResults.xls par=ObjValue Rng=ObjValue!A1"
execute "Gdxxrw PEMResults.gdx o=PEMResults.xls par=Vio_Test Rng=Violation!A1"

