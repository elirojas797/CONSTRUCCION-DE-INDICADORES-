
clear all
global path "D:\UNTRM -2025\TESIS DE MAESTRIA\CURSOS STATA\ENCUESTA ENAHO"
global an "D:\UNTRM -2025\TESIS DE MAESTRIA\CURSOS STATA\ENCUESTA ENAHO\dta"
cd "D:\UNTRM -2025\TESIS DE MAESTRIA\CURSOS STATA\ENCUESTA ENAHO\dta"
 /*Trasladamos nuestra base de datos a código ASCII ISO-8859-1*/

unicode analyze "enaho01-2024-100anual.dta"
unicode encoding set ISO-8859-1
unicode translate "enaho01-2024-100anual.dta"

****************************************************************************
* 									Módulo 100-2024
****************************************************************************
clear all

use "$an\enaho01-2024-100anual", clear 
sort aÑo mes conglome vivienda hogar /*ordenamiento de menor a mayor*/

tab hogar /*tabulado del numero secuencial del hogar*/
browse
fre result /*revisar el resultado de la encuesta*/
*nos quedamos solamente con las encuestas cuyo resultado es completa e incompleta
keep if result<=2
*revisamos losfactores de expansión del resultado de la encuesta*/
br result factor
/*región natural*/
codebook dominio
fre dominio
tab dominio

generate reg_nat=1 if dominio<=3 | dominio==8
replace reg_nat=2 if dominio>3 & dominio<7
replace reg_nat=3 if dominio==7

label var reg_nat "región natural"
label def reg_nat 1 "Costa" 2 "Sierra" 3 "Selva"
label values reg_nat reg_nat

fre reg_nat

/*departamento*/
gen dpto=real(substr(ubigeo,1,2))

label var dpto "departamento"
label def dpto 1 "Amazonas" 2 "Áncash" 3 "Apurímac" 4 "Arequipa" 5 "Ayacucho"  6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huánuco" 11 "Ica" 12 "Junín" 13 "La Libertad" 14 "Lambayeque"  15 "Lima" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martín" 23 "Tacna"  24 "Tumbes" 25 "Ucayali"
label values dpto dpto 

/*Ámbito geográfico*/
gen amb_geo=1 if dominio==8
replace amb_geo=1 if estrato>=1 & estrato<=5
replace amb_geo=2 if estrato>5

label var amb_geo "ámbito geográfico"
label def amb_geo 1 "urbano" 2 "rural"
label values amb_geo amb_geo
fre amb_geo 

*******************************************************************************
*seteamos la bases
svyset conglome [pweight=factor], strata(estrato)
*******************************************************************************

* 1. Acceso a agua por red pública
gen acceso_agua = 0
replace acceso_agua = 1 if p110 <= 3
label var acceso_agua "acceso agua"
capture label drop acceso_agua
label define acceso_agua 1 "sí" 0 "no"
label values acceso_agua acceso_agua


svy: proportion acceso_agua
svy: proportion p110

* 2. Acceso a agua potable
gen agua_pot=0 if p110a1==2
replace agua_pot=1 if p110a1==1
lab var agua_pot "agua potable"
lab def agua_pot 1 "sí" 0 "no"
lab values agua_pot agua_pot

svy: proportion agua_pot
tab agua_pot [iw=factor07]

* 3. Acceso a alcantarillado (desague)
svy: proportion p111a
tab p111a
tab p111a [iw=factor07] 

* 4. Alumbrado de hogar
svy: proportion p1121
tab p1121 [iw=factor07]

* 6. Hogares con al menos 2 NBI
br nbi*

egen suma_2nbi=rsum(nbi1 nbi2 nbi3 nbi4 nbi5)

gen almenos_2nbi=0 if suma_2nbi<2
replace almenos_2nbi=1 if suma_2nbi>=2

svy: proportion almenos_2nbi
