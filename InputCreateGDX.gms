$ontext
This gams code read data from xlsx excel file and write the data to GDX file
The excel file is define in Setting.inc text file under the global set
Created by        Tuong Nguyen   14/02/2014.
Last modified by  Tuong Nguyen   14/02/2014.
$offtext

$include '%System.Fp%\Settings.inc'

$Call 'Gdxxrw "%System.Fp%\%ExcelFile%" Output="%System.Fp%\Inputs.gdx" skipempty=0 trace=2 index=Index!A1'





