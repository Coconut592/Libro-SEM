# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 4 minutos). Lo que se revisó: la base `conjunto_de_datos_tenbiare_enbiare_2021.csv` y
su diccionario `diccionario_datos_tenbiare_enbiare_2021.csv` (ENBIARE 2021, INEGI). Cada cifra sale de la base
real, en R (`lavaan` 0.6-17, `psych`); cada ejercicio se corrió en los bloques de ítems candidatos.

## Resumen

1. **La base alcanza para 6 de los 7 ejercicios.** AFE, AFC, 2.º orden, confiabilidad y validez, puntajes e
   invarianza corren con datos reales y con un ajuste de aceptable a muy bueno. El **FIML no tiene dónde aplicarse** en las escalas de
   bienestar: no traen ningún faltante (hallazgo 5).
2. **La base está limpia:** 31,166 personas × 284 variables, las mismas que el diccionario; ningún valor fuera de
   rango; 214 variables sin faltantes. Los faltantes de las otras 70 son **saltos de pregunta**, no no-respuesta.
3. **No hay documento de referencia** (tesis, capítulo, `.inp`). No hay modelo publicado que reproducir: las
   estructuras salen de un AFE sobre la base y del contenido de los ítems. Los resultados de abajo son de este
   diagnóstico, no una réplica.
4. **La base no trae sexo, edad ni ninguna variable del encuestado**, y el diccionario **no trae etiquetas de
   valor**. La invarianza solo se pudo probar por tamaño de localidad (`tloc`), y la dirección de las escalas se
   infirió de las frecuencias (hallazgos 2 y 3).
5. **Los mejores candidatos** son la **confianza** (`pb1`: 5 factores y 2.º orden, CFI .968), la **satisfacción con
   17 aspectos** (`pa3`: 5 factores y 2.º orden, CFI .952), el **afecto** (`pa4`: 2 factores) y la **salud mental**
   (`pd2`/`pd3`: depresión y ansiedad, CFI .995). La satisfacción es el núcleo del cuestionario, pero tiene la
   validez convergente más débil (AVE .41–.45 con MLR; .49–.54 con WLSMV).
6. **El diseño muestral casi no afecta la estructura factorial:** el cluster por UPM mueve los errores estándar
   x1.01 y ponderar cambia las cargas en .014 como máximo. Importa para medias poblacionales, no para las cargas.
7. **Con 31 mil casos todo χ² rechaza.** Los ajustes se leen con CFI, TLI, RMSEA y SRMR. El RMSEA de confianza
   (.088) y afecto (.085) sale alto aunque el CFI es bueno: tienen pocos grados de libertad.

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| `conjunto_de_datos_tenbiare_enbiare_2021.csv` | **31,166 filas × 284 columnas**, una por **persona seleccionada** (no por hogar ni por integrante). Latin1, nombres en MAYÚSCULAS, sin etiquetas | Los 7 (ver sección 2) |
| `diccionario_datos_tenbiare_enbiare_2021.csv` | 284 filas: texto de la pregunta, longitud, tipo (todo "C"), nemónico, catálogo y `rango_claves`. UTF-8 con BOM | — |

Contenido de la base (los números son los de las preguntas del cuestionario):

| Bloque | Variables | Contenido |
|---|---|---|
| Identificación y diseño | `folio`, `viv_sel`, `hogar`, `n_ren`; `ent`, `tloc`; `fac_ele`, `est_dis`, `upm_dis` | Llave, entidad (32), tamaño de localidad (4), ponderador, estrato y UPM |
| PA. Bienestar | `pa1`, `pa2` | Satisfacción con la vida hoy y hace un año (0-10) |
| | `pa3_01`–`pa3_17` | Satisfacción con 17 aspectos: nivel de vida, salud, logros, relaciones, vida social, familia, afecto, futuro, tiempo, libertad, seguridad, actividad principal, vivienda, vecindario, ciudad, servicios públicos y país (0-10) |
| | `pa4_01`–`pa4_10` | Afecto del día de ayer: 5 positivos (`01`–`05`) y 5 negativos (`06`–`10`) (0-10) |
| | `pa5`, `pa6` | Escalón en que se ubica hoy y en 5 años (0-10) |
| PB. Confianza | `pb1_01`–`pb1_12` | Confianza en la gente, medios, policías, Guardia Nacional, Ejército, ministerio público, juzgados, cámaras, partidos y funcionarios (0-10) |
| | `pb2_1`, `pb2_2` | Contará con ayuda de familia / amistades (1-3) |
| PC. Vida social | `pc1_1`–`pc1_7` | Actividades de la semana pasada (Sí/No) |
| | `pc2_1`–`pc2_5` | Frecuencia en 5 redes sociales (1-5) |
| | `pc3_1`–`pc3_8` | Frecuencia de reuniones con 8 grupos (1-5) |
| | `pc4_1`, `pc4_2` | Grupo que más / menos disfruta (nominal) |
| PD. Salud | `pd1_1`–`pd1_6` | Dificultades funcionales (1-4) |
| | `pd2_1`–`pd2_7` | Depresión de la última semana (CESD-7; 0-3; `pd2_6`, "disfrutó de la vida", es positivo) |
| | `pd3_1`, `pd3_2` | Ansiedad de las últimas 2 semanas (GAD-2; 0-3) |
| PE. Trabajo | `pe1`–`pe18` | Situación laboral, prestaciones (`pe10_*`), ingresos; casi todo con saltos |
| PF. Finanzas, eventos y discriminación | `pf1`–`pf14` | Deudas, ingreso suficiente, eventos negativos y positivos (propios y de personas cercanas), agresiones, discriminación por 16 motivos (`pf7_*`, con `pf8_*` si contestó sí), texto libre |
| PG-PJ | `pg*`, `ph*`, `pi*`, `pj*` | Organizaciones y ayuda, religión, dificultades y alegrías por etapa de vida, pareja, oportunidades, escuelas, transporte, música |

## 2. Los 7 ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con la base? | Qué falta |
|---|---|---|---|
| AFE | ❌ No | ✅ Sí: satisfacción, confianza, afecto, salud mental, vida social | Decidir la(s) escala(s) |
| AFC | ❌ No (no hay modelo publicado) | ✅ Sí | Confirmar la estructura con el cuestionario |
| AFC 2.º orden | ❌ No | ✅ Sí en confianza, satisfacción, bienestar subjetivo y reuniones; ❌ en afecto, salud mental y redes (solo 2 factores) | — |
| Confiabilidad y validez | ❌ No | ✅ Sí, **con criterio externo en la propia base** (`pa1`, `pa5`, depresión, ansiedad) | Documento de validez, si lo hay |
| Puntajes factoriales | ❌ No | ✅ Sí: los 31,166 reciben puntaje | — (la llave para guardarlos es `folio` + `hogar`) |
| Invarianza factorial | ❌ No | ⚠️ **Por `tloc`** (4 grupos), no por sexo ni edad | La tabla sociodemográfica |
| FIML | ❌ No | ❌ **En las escalas de bienestar no hay faltantes**; solo `ph1_4`/`ph2_4` (14 %) | Una decisión (sección 6) |

## 3. Lo que se encontró

### Hallazgo 1. Base y diccionario coinciden

- Las **284 variables** del diccionario son exactamente las de la base; no hay valores fuera del rango de
  `rango_claves` (se comprobó variable por variable).
- Categorías declaradas que nadie contestó: la 4.ª de `pd1_1`, `pd1_2` y `pd1_6` (esos ítems quedan en 3
  categorías), la 3.ª de `pb2_2` y la 3.ª de `ph1_*`/`ph2_*` (solo salen 1, 2 y 9).
- El diccionario da el tipo "C" (carácter) en las 284 variables, aunque casi todas son numéricas. Los textos libres
  (`pf14_*_esp`) traen apóstrofos: hay que leer con `quote = "\""`, o R se detiene en el primer renglón.

### Hallazgo 2. El diccionario no trae etiquetas de valor

La columna `catálogo` solo repite el nombre de la variable (273) o está vacía (11). **No se sabe qué dice cada
código.** Lo que se infirió, por las frecuencias, y falta confirmar con el cuestionario:

| Ítems | Código | Evidencia |
|---|---|---|
| Sí/No (`pc1`, `pf1`, `pf4`, `pf7`, `ph1`, `ph2`, `pj6`...) | 1 = sí, 2 = no | `pf7_*` (discriminación) tiene 0.8 %-9.2 % de 1; `ph2_*` (alegrías) 89 %-94 %; `pc1_3` (quehaceres) 87 % |
| `pa*`, `pb1` | 0 = nada ... 10 = mucho | Rango declarado `00…10` |
| `pd2`, `pd3` | 0 = rara vez ... 3 = todo el tiempo | `pd2_6` (disfrutó) tiene 67 % en 3; los negativos, 46 %-64 % en 0 |
| `pc2`, `pc3` | 1 = nunca ... 5 = diario | WhatsApp (`pc2_4`) tiene 38 % en 5; Twitter (`pc2_2`), 90 % en 1 |
| `pd1` | 1 = sin dificultad ... 4 = no puede | 64 %-96 % en 1 |
| `ph1_*`, `ph2_*`, `pf3`, `pe16` | 9 = no sabe | Lo declara el diccionario (`rango_claves`) |

### Hallazgo 3. No hay sexo ni edad

Las 284 variables son cuestionario y diseño: ni sexo, ni edad, ni escolaridad. Los
únicos grupos que hay son `ent` (32 entidades, de 906 a 1,037 personas) y `tloc` (4 tamaños de localidad: 14,095,
4,793, 4,925 y 7,353; sin etiquetas, se supone 1 = 100 mil o más ... 4 = menos de 2,500). Las cuatro primeras
columnas (`folio`, `viv_sel`, `hogar`, `n_ren`) son la llave para unir otras tablas de la encuesta, pero esas tablas
no se subieron.

### Hallazgo 4. Diseño muestral y estructura de la base

- **Llave:** (`folio`, `hogar`) no se repite (31,166). `folio` identifica la **vivienda**: hay 30,822, y 300 tienen de
  2 a 5 personas (hogares distintos en la misma vivienda): dependencia mínima.
- **Diseño:** 472 estratos, 4,704 UPM (6.6 personas por UPM) y ponderador de **122 a 45,955** (suma 84.4 millones).
  Los pesos tan desiguales (efecto de Kish 2.23) importan para estimar niveles, no para la estructura.
- **Correlación intraclase por UPM:** mediana .025 (de .005 a .102) en los 39 ítems de `pa3`, `pa4` y `pb1`: efecto
  de diseño de ~1.14. Los más altos son los de entorno: `pb1_04` (policía municipal, .102), `pa3_15` (ciudad, .091)
  y `pa3_11` (seguridad, .084).
- **Efecto sobre el AFC** (satisfacción, 5 factores, MLR):

| | Sin diseño | Cluster por UPM | Con ponderador |
|---|---|---|---|
| Error estándar de las cargas | 1 | x1.01 | x1.45 |
| CFI | .952 | .952 | .950 |
| Diferencia máxima en las cargas estandarizadas | — | — | .014 |

  Se propone **trabajar sin ponderador** (como EMOVI) y usarlo solo si se quieren medias poblacionales.

### Hallazgo 5. Faltantes: son saltos de pregunta

- **214 variables no tienen ningún faltante**, entre ellas todas las de `pa`, `pb`, `pc1`-`pc3` y `pd`. Tampoco hay
  "Ns/Nc" que recodificar en las escalas 0-10.
- Las otras **70** faltan por diseño: `pe10_*` (8 prestaciones) faltan **juntas** para 17,589 (los que no trabajan);
  `pf8_*` solo se contestan si `pf7_*` = sí (exacto, en los 16); `pf11_*`/`pf12_*` faltan para 3,570 (11.5 %);
  `pj2_*` para 26,041. Un FIML ahí no agrega casos: los renglones sin ningún ítem del bloque no aportan.
- **Única excepción con faltantes parciales:** `ph1_4` y `ph2_4` (4,302 blancos idénticos, 13.8 %; muy probablemente
  porque la pregunta es "a partir de los 25 años" y no se hace a quien tiene menos; sin edad no se puede comprobar)
  más los códigos 9 de `ph1_*` y `ph2_*` (de 0.04 % a 0.2 %).

### Hallazgo 6. Forma de los ítems

- Escalas 0-10 con **asimetría negativa** (hasta −2.5, `pa3_06`, familia: 54 % contesta 10) y techo fuerte en
  satisfacción; el afecto negativo es asimétrico a la derecha (hasta 1.4, `pa4_10`: 55 % contesta 0). Se tratan
  como continuas con MLR (como PREP) y se comprueba con WLSMV (hallazgo en 5).
- Confianza es la escala mejor repartida (categoría modal de 20 %; medias de 3.6 a 7.6).
- `pd1` (dificultades funcionales): de **64 % a 96 %** en la categoría 1 (dos ítems, `pd1_5` y `pd1_6`, pasan de 90 %)
  y asimetría hasta 6.3. No es utilizable como escala reflectiva.
- `pf7` (discriminación): **los 16 ítems están por debajo de 10 %** (de 0.8 % a 9.2 %), el criterio 90-10 de la tesis
  de EMOVI los saca todos. `pg1` (organizaciones): de 0.3 % a 5.8 %.

### Hallazgo 7. Observaciones sobre los ítems

- `pb1_03` (confianza en los medios de comunicación) no pertenece a ningún factor: sus cargas son .19, .30 y .25 en
  tres factores. Se deja fuera del modelo de confianza.
- La **evaluación de la vida** (`pa1`, `pa2`, `pa5`, `pa6`) no es una escala por sí sola: KMO .68, ajuste de un
  factor RMSEA .159 y `pa6` (escalón en 5 años) carga .41. Funciona como componente del bienestar subjetivo (BS),
  no como bloque.
- En `pd2`, el ítem positivo (`pd2_6`) se invierte (`pd2_6r`); aun así carga bajo (.48 en el AFC y .43 en el AFE),
  igual que `pd2_5` (sueño, .55 en el AFC).
- `pa4_09` y `pa4_10` (aburrido, triste) comparten varianza: un residual correlacionado sube el CFI de .943 a .951.
  Es una modificación empírica, no se agrega.

## 4. Bloques candidatos

Se examinaron 16 bloques (cada uno con ítems de la misma pregunta). KMO, factores de Kaiser y del análisis paralelo
y el ajuste de **un** factor:

| Bloque | Ítems | Escala | N completos | % cat. modal | Ítems > 90 % | KMO | Kaiser | Paralelo | RMSEA 1 f. | Veredicto |
|---|---|---|---|---|---|---|---|---|---|---|
| `pa3` Satisfacción con aspectos | 17 | 0-10 | 31,166 | 32 | 0 | .92 | 2 | 6 | .097 | **Candidato principal** |
| `pa4` Afecto de ayer | 10 | 0-10 | 31,166 | 36 | 0 | .89 | 2 | 3 | .169 | **Candidato** |
| `pb1` Confianza | 12 | 0-10 | 31,166 | 20 | 0 | .90 | 2 | 5 | .192 | **Candidato** |
| `pd2` + `pd3` Depresión y ansiedad | 9 | 0-3 | 31,166 | 59 | 0 | .92 | 1 | 4 | .151 | **Candidato** (ordinal) |
| `pc3` Reuniones sociales | 8 | 1-5 | 31,166 | 57 | 0 | .86 | 2 | 4 | .115 | **Candidato** (ordinal) |
| `pc2` Redes sociales | 5 | 1-5 | 31,166 | 68 | 1 | .79 | 1 | 2 | .252 | Candidato chico (ordinal) |
| `pa1`, `pa2`, `pa5`, `pa6` | 4 | 0-10 | 31,166 | 35 | 0 | .68 | 1 | 2 | .159 | Débil sola; sirve en BS |
| `pd1` Dificultades funcionales | 6 | 1-4 | 31,166 | 83 | 2 | .74 | 1 | 3 | .210 | No: ítems casi constantes |
| `ph1` + `ph2` Etapas de vida | 8 | Sí/No | 26,784 | 83 | 3 | .65 | 2 | 3 | .506 | Solo para el FIML |
| `pc1` Actividades | 7 | Sí/No | 31,166 | 72 | 0 | .60 | 3 | 3 | .193 | No: sin estructura (KMO .60) |
| `pf7` Discriminación | 16 | Sí/No | 31,166 | 96 | 16 | .94 | 2 | 7 | .122 | No: los 16 ítems < 10 % |
| `pe10` Prestaciones laborales | 8 | Sí/No | 13,577 | 58 | 0 | .93 | 1 | 4 | .270 | No: un factor, 56 % faltante por diseño |
| `pf1` Pidió prestado | 6 | Sí/No | 31,166 | 84 | 2 | .87 | 1 | 3 | .235 | Débil |
| `pf4` Eventos negativos | 9 | Sí/No | 31,166 | 88 | 5 | .77 | 2 | 5 | .111 | No: lista de eventos, no reflectiva |
| `pj6` Gustos musicales | 13 | Sí/No | 31,166 | 71 | 1 | .78 | 3 | 5 | .231 | No: no es bienestar |
| `pg1` Organizaciones | 8 | Sí/No | 31,166 | 97 | 8 | .86 | 1 | 4 | .076 | No: prevalencias de 0.3 % a 5.8 % |

Además se probó **Bienestar subjetivo (BS)**: evaluación (`pa1`, `pa2`, `pa5`, `pa6`), afecto positivo y afecto
negativo, con 2.º orden (justo identificado).

## 5. Resultados de las pruebas

**AFE** (ML con oblimin para 0-10; mínimos residuales sobre policóricas para los ordinales). Cargas en
`output/afe_cargas_*.csv`:

| Bloque | KMO | Kaiser | Paralelo | Solución elegida | RMSEA | TLI |
|---|---|---|---|---|---|---|
| `pa3` (17) | .92 | 2 | 6 | **5 factores:** nivel de vida y logros (`01`-`03`, `08`), relaciones (`04`-`07`), autonomía y actividad (`09`, `10`, `12`), hogar y vecindario (`13`, `14`), ciudad y país (`11`, `15`-`17`) | .035 | .968 |
| `pa4` (10) | .89 | 2 | 3 | **2 factores:** positivo (`01`-`05`) y negativo (`06`-`10`); un 3.º no define nada (cargas de −.23 a .29) | .093 | .908 |
| `pb1` (12) | .90 | 2 | 5 | **5 factores:** interpersonal (`01`, `02`), policías (`04`, `05`), Guardia Nacional y Ejército (`06`, `07`), justicia (`08`, `09`), cámaras, partidos y funcionarios (`10`-`12`); `pb1_03` sin factor | .021 | .997 |
| `pd2` + `pd3` (9) | .92 | 1 | 4 | **2 factores:** depresión (`pd2_*`) y ansiedad (`pd3_*`) | .071 | .973 |
| `pc3` (8) | .86 | 2 | 4 | **3 factores:** comunidad (`pc3_1` vecinos, `pc3_2` iglesia), escuela / deporte / trabajo (`3`-`5`), familia y amistades (`6`-`8`) | .056 | .964 |
| `pc2` (5) | .79 | 1 | 2 | **2 factores:** mensajería y Facebook (`1`, `4`); Twitter, Instagram y TikTok (`2`, `3`, `5`) | .066 | .981 |

El análisis paralelo pide más factores que Kaiser (6 contra 2 en `pa3`); la elección salió del ajuste (RMSEA ≤ .06 y
TLI ≥ .95) y de que los factores se pudieran nombrar.

**AFC de primer y segundo orden** (`std.lv = TRUE`; MLR en los 0-10, WLSMV en los ordinales):

| Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR | Cargas |
|---|---|---|---|---|---|---|
| `pa3`, 5 factores | 4,419 (109) | .952 | .941 | .047 | .032 | .55–.76 |
| → 2.º orden (`SAT`) | 5,768 (114) | .938 | .925 | .053 | .041 | NIV .91 · REL .85 · AUT .88 · BAR .76 · CIU .60 |
| `pa4`, 2 factores | 5,332 (34) | .943 | .924 | .085 | .036 | .66–.78 |
| `pb1`, 5 factores | 5,468 (34) | .968 | .949 | .088 | .027 | .68–.96 |
| → 2.º orden (`CONF`) | 6,592 (39) | .962 | .946 | .090 | .034 | POL .86 · MIL .82 · JUS .93 · PLT .86 (INT queda aparte) |
| BS, 3 factores | 7,997 (74) | .934 | .919 | .069 | .037 | .44–.78 |
| → 2.º orden (`BS`) | 7,997 (74) | .934 | .919 | .069 | .037 | EVA .58 · AP .97 · AN −.63 |
| `pd2`+`pd3`, 2 factores (WLSMV) | 2,097 (26) | .995 | .992 | .051 | .021 | .48–.93 |
| `pc3`, 3 factores (WLSMV) | 1,167 (17) | .987 | .979 | .047 | .026 | .53–.83 |
| → 2.º orden (`SOC`) | 1,167 (17) | .987 | .979 | .047 | .026 | .68–.95 |
| `pc2`, 2 factores (WLSMV) | 143 (4) | .998 | .994 | .033 | .022 | .70–.90 |

- Todos convergen y son admisibles (sin varianzas negativas ni matrices no positivas definidas).
- **Correlaciones entre factores:** en `pa3`, de .44 (REL–CIU) a **.82** (NIV–REL); en `pb1`, de .35 (INT–MIL) a
  **.83** (JUS–PLT); `pa4`, −.61; `pd2`/`pd3`, .79; `pc3`, de .59 a **.83** (ESC–FAM).
- **2.º orden:** en `pb1` pierde .006 de CFI y en `pa3` .014 (el factor de ciudad y país, CIU, carga solo .60). En
  `BS` y `pc3`, con 3 factores, queda justo identificado: mismo ajuste que el de 1.er orden, sin prueba. `pa4`,
  `pd2` y `pc2` tienen 2 factores: sin restringir cargas, no hay 2.º orden.
- **Sensibilidad (`pa3`):** con los 11 puntos como ordinales (WLSMV) el ajuste mejora (CFI .966, RMSEA .062) y las
  cargas suben (media .71 contra .65). Mismos factores, otra escala de cargas.

**Confiabilidad y validez** (alfa con los datos; CR y AVE con las cargas estandarizadas; HTMT con valor absoluto):

| Bloque | Factor | k | α | CR | AVE | r² máx. | HTMT máx. | Fornell-Larcker |
|---|---|---|---|---|---|---|---|---|
| `pa3` | NIV | 4 | .755 | .757 | .439 | .674 | .82 | ❌ |
| | REL | 4 | .715 | .738 | .416 | .674 | .82 | ❌ |
| | AUT | 3 | .663 | .671 | .405 | .653 | .80 | ❌ |
| | BAR | 2 | .609 | .612 | .441 | .476 | .67 | ❌ |
| | CIU | 4 | .759 | .768 | .454 | .476 | .67 | ❌ |
| `pa4` | AP | 5 | .861 | .862 | .556 | .374 | .61 | ✅ |
| | AN | 5 | .828 | .829 | .493 | .374 | .61 | ✅ |
| `pb1` | INT | 2 | .721 | .733 | .581 | .216 | .48 | ✅ |
| | POL | 2 | .901 | .903 | .824 | .599 | .77 | ✅ |
| | MIL | 2 | .894 | .897 | .814 | .555 | .76 | ✅ |
| | JUS | 2 | .893 | .893 | .807 | .691 | .84 | ✅ |
| | PLT | 3 | .902 | .903 | .756 | .691 | .84 | ✅ |
| `pd2`+`pd3` | DEP | 7 | .902 | .912 | .607 | .628 | .81 | ❌ (rozando) |
| | ANS | 2 | .897 | .897 | .813 | .628 | .81 | ✅ |
| `pc3` | COM | 2 | .613 | .642 | .484 | .414 | .68 | ✅ |
| | ESC | 3 | .797 | .801 | .574 | .689 | .83 | ❌ |
| | FAM | 3 | .672 | .680 | .419 | .689 | .83 | ❌ |
| `pc2` | MSG | 2 | .818 | .819 | .693 | .506 | .72 | ✅ |
| | RED | 3 | .814 | .824 | .613 | .506 | .72 | ✅ |

- **Confianza y afecto cumplen todo** (CR > .70, AVE ≥ .50 salvo `AN` en .49, Fornell-Larcker, HTMT < .85). El caso
  más justo es Justicia–Partidos (r² = .69, HTMT .84).
- **Satisfacción (`pa3`) no llega a AVE .50 en ningún factor** (.41–.45), con CR de .61 a .77 y alfas de .61 a .76.
  Los HTMT sí quedan bajo .85: los factores se distinguen, pero cada uno explica menos de la mitad de la varianza
  de sus ítems. Con WLSMV la AVE sube a .49–.54 (sección de sensibilidad), así que parte del problema es el estimador.
- Los factores de **2 ítems** (BAR, COM, INT, POL, MIL, ANS, MSG) dan alfas poco informativas.
- **Validez de criterio:** sí hay criterio dentro de la base (correlaciones de Spearman entre medias de ítems):

| | `pa1` (vida) | `pa5` (escalón) | Afecto positivo | Afecto negativo | Depresión | Ansiedad |
|---|---|---|---|---|---|---|
| Satisfacción (`pa3`) | **.56** | **.54** | .49 | −.29 | −.33 | −.28 |
| Afecto positivo | .39 | .43 | — | −.55 | −.42 | −.35 |
| Afecto negativo | −.25 | −.28 | −.55 | — | **.48** | **.42** |
| Confianza (`pb1_04`–`pb1_12`) | .13 | .18 | .16 | −.03 | −.05 | −.07 |

  La satisfacción va con la satisfacción global y el escalón (≈ .55); el afecto negativo con la depresión y la
  ansiedad (≈ .45); y la confianza institucional **no** va con el bienestar (≤ .18): validez discriminante.

**Puntajes factoriales** (regresión en MLR; EBM por patrón de respuesta en WLSMV): los 31,166 reciben puntaje en
todos los modelos. **Determinación** de .86 a .97: las más bajas, BAR (.86), COM (.87) y EVA (.88); 15 de 22
factores llegan a .90. El puntaje correlaciona de .80 a .99 con la media simple de sus ítems (.80 en RED y .85 en COM,
factores de 2 a 3 ítems con categorías muy sesgadas). Hay **8,937** patrones distintos en depresión/ansiedad,
**12,231** en reuniones sociales y 1,014 en redes.

**Invarianza por tamaño de localidad** (`tloc`, 4 grupos; MLR en 0-10, WLSMV en ordinales; criterio de Chen, 2007:
ΔCFI ≥ −.010 y ΔRMSEA ≤ .015):

| Bloque | Configural (CFI) | Métrica (ΔCFI) | Escalar (ΔCFI) | Conclusión |
|---|---|---|---|---|
| `pa3` | .953 | .952 (−.001) | .942 (**−.010**) | Pasa, **justo en el límite** en la escalar |
| `pa4` | .942 | .942 (.000) | .941 (−.001) | Pasa |
| `pb1` | .967 | .967 (.000) | .967 (−.001) | Pasa |
| BS | .934 | .933 (.000) | .931 (−.002) | Pasa |
| `pd2`+`pd3` | .994 | umbrales + cargas: .995 (+.001, ΔRMSEA −.015) | | Pasa |
| `pc3` | .987 | umbrales + cargas: .985 (−.002) | | Pasa |
| `pc2` | .998 | umbrales + cargas: .991 (−.006) | | Pasa |

Los 4 grupos son grandes (de 4,793 a 14,095). Es una invarianza real, pero no la que se hace normalmente (sexo y
edad). Con las 32 entidades (de 906 a 1,037 personas) o regiones armadas con `ent` también se puede.

**FIML** (`ph1_*` + `ph2_*`, 2 factores: dificultades y alegrías por etapa de vida):

| Método | N | CFI | RMSEA | Error estándar |
|---|---|---|---|---|
| Listwise (MLR) | 26,784 | .904 | .128 | 1 |
| FIML (MLR, ítems como continuos) | 31,164 | .902 | .127 | x0.93 |
| Pairwise (WLSMV, ordinales) | 31,164 | .939 | .055 | — |

FIML recupera 4,380 personas y baja 7 % los errores estándar, pero el modelo no ajusta bien con Sí/No tratados como
continuos, y los dos factores casi no se relacionan (−.07). En `lavaan` **no existe FIML con ítems ordinales**
(`missing = "fiml"` con `ordered` da error), por lo que o se tratan como continuos con MLR o se usa `pairwise` con
WLSMV.

## 6. Qué necesito

**Documentos:**

1. **La tabla sociodemográfica** de la ENBIARE 2021 (sexo, edad, escolaridad, ocupación), que se une por `folio`,
   `viv_sel`, `hogar` y `n_ren`. Sin ella no hay invarianza por sexo ni edad, ni criterio sociodemográfico.
2. **El cuestionario o los catálogos** de INEGI, para confirmar las etiquetas de valor (hallazgo 2), el significado de
   `tloc` y qué 1, 2 y 3 son en `pb2`, `pf5`, `pi*` y `pj3`.
3. Un **documento de validez**, si se quiere replicar el criterio de otros proyectos (en el Tren, SEM06). Aquí no
   hace falta para el criterio: la base trae `pa1`, `pa5`, depresión y ansiedad.

**Decisiones (con propuesta):**

| Tema | Propuesta |
|---|---|
| Escala(s) de los ejercicios | **Satisfacción con 17 aspectos (`pa3`)** como escala principal: es el núcleo del cuestionario, con 5 factores y 2.º orden. **Confianza (`pb1`)** como segunda, que es la que más limpio pasa la validez. Afecto y salud mental como complemento. A elegir |
| Estimador | MLR para los 0-10 (11 categorías) y WLSMV para los de 3 a 5 categorías. Para `pa3`, mostrar también WLSMV |
| Ponderador | Sin ponderador (cluster por UPM no cambia nada; los pesos solo mueven los errores estándar x1.45) |
| Grupo de la invarianza | `tloc` (4 tamaños de localidad) mientras no llegue la tabla sociodemográfica; después, sexo y edad |
| AFE y AFC en la misma muestra | Con 31 mil casos se puede partir la muestra (AFE en una mitad y AFC en la otra, como en Violencia Guerrero) |
| FIML | Tres opciones: **(a)** omitirlo, como en Habilidades Políticas, porque las escalas no tienen faltantes; **(b)** usar `ph1_*`/`ph2_*` (único con faltantes parciales, ítems como continuos); **(c)** simular faltantes MCAR/MAR en `pa3` |

Salidas (en `output/`, que no se versiona): `efecto_diseno.csv`, `faltantes_por_variable.csv`,
`bloques_candidatos.csv`, `afe_ajuste.csv`, `afe_cargas_*.csv`, `afc_ajuste.csv`, `afc_cargas.csv`,
`confiabilidad_validez.csv`, `validez_criterio.csv`, `puntajes_resumen.csv`, `invarianza_tloc.csv`, `fiml_ph.csv` y
`resumen_ejercicios.csv`.
