********************************************************************************
*																			   *
*								Módulo 400		y 200							   *
*																			   *
*******************************************************************************

********************************************************************************
*ESTADSISTICAS DE SALUD*
use "enaho01a-2024-400trim", clear
merge 1:1 conglome vivienda hogar codperso using "enaho01-2024-200trim", keep(3) nogen
* Filtro miembro del hogar
gen byte miembro_hogar = (p204==1)
keep if miembro_hogar==1

drop if codinfor=="00"
*-----------------------------*
* 2) DISEÑO MUESTRAL (svyset) *
*-----------------------------*
svyset conglome [pweight=factor], strata(estrato)

*-----------------------------------------------------*
* 3) MAPEO de variables     *
*-----------------------------------------------------*

*   Seguro de salud (Sí/No)               -> var_seguro
*   Sexo? (1=Hombre, 2=Mujer)             -> var_sexo
*   Edad en años cumplidos                -> var_edad
*   Tuvo problema de salud (últ. 4 sem)   -> var_morbilidad
*   Poblacion con enferemdad cronicas     -> Var_ cronicas
*   Buscó atención por ese problema       -> var_busco
*    

* ) Indicador: Cobertura de seguro de salud   *
*----------------------------------------------*

gen tiene_seguro = 0
replace tiene_seguro = 1 if p4191 == 1 | p4192 == 1 | p4193 == 1 | p4194 == 1 | ///
                          p4195 == 1 | p4196 == 1 | p4197 == 1 | p4198 == 1 | ///
                          p419a1 == 1 | p419a2 == 1 | p419a3 == 1 | p419a4 == 1 | ///
                          p419a5 == 1 | p419a6 == 1 | p419a7 == 1 | p419a8 == 1

label define lb_seg 1 "Afiliado a algún seguro" 0 "No afiliado"
label values tiene_seguro lb_seg
label var tiene_seguro "Afiliado a cualquier tipo de seguro de salud"
svy: proportion tiene_seguro
tab tiene_seguro [iw=factor]
* 1) Crear seguro por sexo
svyset conglome [pweight=factor], strata(estrato)
label define lb_sexo 1 "Hombre" 2 "Mujer"
label values p207 lb_sexo
keep if !missing(tiene_seguro, p207)
svy: proportion tiene_seguro, over(p207)
svy: tab p207 tiene_seguro, row ci format(%6.2f)

* 2) Crear grupo estario con seguro de salud 
egen grp_edad = cut(p208a), at(0,18,30,60,120) icodes
label define lb_grp_edad 1 "0–17" 2 "18–29" 3 "30–59" 4 "60+"
label values grp_edad lb_grp_edad
label var grp_edad "Grupo etario"
keep if !missing(tiene_seguro, p208a, grp_edad)
svy: proportion tiene_seguro, over(grp_edad)
svy: tab grp_edad tiene_seguro, row ci format(%6.2f)

* 3) * Crear grupo personas que tuvieron problemas de salud las ultimas 4 semanas 
gen byte morbilidades = .
replace morbilidades = 1 if p401 == 1               // Sí tuvo problema
replace morbilidades = 0 if p401 == 2               // No tuvo problema
label define lb_morb 1 "Sí tuvo problema" 0 "No tuvo problema"
label values morbilidades lb_morb
label var morbilidades "Tuvo problema de salud (últ. 4 semanas)"
replace morbilidades = . if inlist(p401,8,9,.)
* 4) * personas con probelams de salud entre hombres y mjeres 
svy: proportion morbilidades
label define lb_sexo2 1 "Hombre" 2 "Mujer"
label values p207 lb_sexo

svy: proportion morbilidades, over(p207)
svy: tab p207 morbilidades, row ci format(%6.2f)   // tabla por filas

* 5) *  Población con algún problema de salud duramte las ultimas 4 semanas
svy: total morbilidades, over(p207)
 
*6)* poblacion con proeblams de salud cronico

capture drop cronico
gen byte cronico = .
replace cronico = 1 if p401 == 1          // Sí tiene crónico
replace cronico = 0 if p401 == 2          // No tiene
replace cronico = . if inlist(p401,8,9,.)  // Ns/Nr a missing (ajusta si difiere)

label define lb_cronico 1 "Sí crónico" 0 "No crónico", replace
label values cronico lb_cronico
label var cronico "Tiene enfermedad/problema crónico"
tab p401, m
tab cronico, m

*7)* poblacion que busco atencion en centro de salud 
capture drop any_lugar busco_atencion
gen byte any_lugar = 0
foreach v in p4031 p4032 p4033 p4034 p4035 p4036 p4037 p4038 p4039 p40310 p40311 p40313 {
    replace any_lugar = 1 if `v'==1
}
***busco un centro de salud*
gen byte busco_atencion = .
replace busco_atencion = 1 if cronico==1 & any_lugar==1
replace busco_atencion = 0 if cronico==1 & p40314==1     // 14 = no buscó
replace busco_atencion = 0 if cronico==1 & missing(busco_atencion)
drop any_lugar
label define lb_busco 1 "Sí buscó atención" 0 "No buscó atención", replace
label values busco_atencion lb_busco
***assitio a un centro de salud 
capture drop asistio_centro
gen byte asistio_centro = .
replace asistio_centro = 1 if cronico==1 & p4032==1
replace asistio_centro = 0 if cronico==1 & p4032!=1 & p4032!=.
label define lb_centro 1 "Sí asistió centro" 0 "No asistió centro", replace
label values asistio_centro lb_centro
label var asistio_centro "Crónicos que asistieron a Centro de salud (P4032)"
**estimacines**
* % y total de crónicos que asistieron a centro
svyset conglome [pweight=factor], strata(estrato)
svy, subpop(if cronico==1): proportion asistio_centro
svy, subpop(if cronico==1): total      asistio_centro
 * % entre quienes buscaron atención (base = crónicos que buscaron)
svy, subpop(if cronico==1 & busco_atencion==1): proportion asistio_centro
* Desagregados útiles
label define lb_sexo 1 "Hombre" 2 "Mujer", replace
label values p207 lb_sexo
svy, subpop(if cronico==1): proportion asistio_centro, over(p207)

capture label define lb_area 1 "Urbana" 2 "Rural", replace
capture label values area lb_area
capture noisily svy, subpop(if cronico==1): proportion asistio_centro, over(area)
* Crear área (Urbana/Rural) desde 'dominio'
capture confirm variable area
if _rc {
    capture confirm variable dominio
    if !_rc {
        capture drop area
        gen byte area = .
        replace area = 1 if inlist(dominio,1,2,3,4)   // Urbano
        replace area = 2 if inlist(dominio,5,6,7)     // Rural
        label define lb_area 1 "Urbana" 2 "Rural", replace
        label values area lb_area
        label var area "Área de residencia"
    }
    else {
        di as error "No encuentro 'area' ni 'dominio'. Ejecuta: ds area area* dominio* ambito*"
    }
}
svy, subpop(if cronico==1): proportion asistio_centro, over(area)

* 8) Lugar de consulta en salud
tab p401, m
tab busco_atencion if cronico==1, m
tab p4032 if cronico==1, m



























