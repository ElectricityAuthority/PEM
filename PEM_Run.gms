$call gams PEM_Model.gms s=PEM_Model

$call gams PEM_Solve.gms r=PEM_Model lo=3 ide=1 Errmsg=1
