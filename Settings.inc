*+++ Settings +++

$setglobal Solver                       CPLEX
$setglobal ExcelFile                   'Inputs.xlsx'
Scalar LPtimeLimit                    / 3600 / ;
Scalar LPiterationLimit               / 1000000 / ;
Scalar MIPtimeLimit                   / 3600 / ;
Scalar MIPoptimality                  / 0 / ;
Scalar MIPiterationLimit              / 1000000 / ;
