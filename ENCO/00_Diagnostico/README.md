# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 2 minutos). Lo que se revisó: el documento de INEGI `fd_enco_v7.pdf` («Estructura de
la base de datos» de la ENCO, 06/10/2025, 17 págs.) y las tres tablas de **agosto de 2026** (periodo `0826`):
`encoviv_0826.DBF`, `encocs_0826.DBF` y `encocb_0826.DBF`. Cada ejercicio se probó con la base real en R (`lavaan`,
`psych`), con los mismos estimadores y criterios de los proyectos anteriores (ítems ordinales con WLSMV, `efa()` con
oblimin, criterio de Chen para invarianza, EBM para puntajes).

## Resumen

1. **La base alcanza para los 7 ejercicios.** El cuestionario básico (`ENCOCB`) trae **2,050 personas de 18 a 97
   años** y **15 ítems de opinión** (`P1`–`P15`) sobre la situación económica. Salen **4 factores limpios** (AFE: CFI
   .992, RMSEA .053; AFC: CFI .975, TLI .969, RMSEA .071, SRMR .048) y un factor general de **Confianza del
   consumidor** de segundo orden (cargas de .68 a .92, sin casos Heywood).
2. **No hay archivos de referencia**: solo el diccionario (el PDF) y las bases. No hay tesis, script, `.inp` ni
   documento de validez ni de invarianza. El modelo no se replica de nada: sale del AFE y del contenido de las
   preguntas (las cinco del Índice de Confianza del Consumidor, ICC, caen en los cuatro factores, dos de ellas en
   el del país).
3. **Los 15 ítems no son una escala homogénea**: mezclan 2, 3, 5 y 6 categorías, con el «No sabe» en códigos
   distintos (6, 4, 3 o 7) y **P10** y **P12** con códigos especiales. Hay que limpiar antes de analizar (sección 3).
4. **`P1`–`P3` y `P2`–`P4` son casi la misma pregunta** (r = .72 y .74): una la hace sobre «su situación» y otra
   sobre la del hogar. De ahí los dos factores de **dos ítems** (hogar hoy y hogar esperado).
5. **Ítems débiles:** `P12` (precios) carga .48 y `P11` (condiciones para ahorrar) cruza varios factores. El factor
   **país** es el flojo: α .73, AVE .43.
6. **Faltantes: pocos pero reales.** Son «No sabe» en 115 personas (5.6 %), más frecuentes con la edad y en mujeres.
   El FIML corre (con ítems continuos), pero **casi no cambia nada** frente a quitar esos 115 casos.
7. **Un solo mes.** Hay invarianza por sexo, edad, escolaridad y ciudad, pero no en el tiempo (se necesitarían
   otros meses). No hay variable de región.
8. **El ICC oficial no se reproduce con estos archivos:** falta la nota metodológica de INEGI con su fórmula
   (sección 6).

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| `fd_enco_v7.pdf` | Diccionario de INEGI: las tres tablas, campo por campo, con tipos, longitudes y códigos válidos | — |
| `encoviv_0826.DBF` | **2,336 viviendas** × 33 variables: ciudad (`CD`), resultado de la entrevista (`R_PRE`, `R_DEF`), tamaño del hogar (`P1`–`P4`), fechas y observaciones. 2,050 con entrevista completa (`R_DEF` = 00) | Ninguno (no hay ítems ni estructura factorial); da el resultado de la entrevista |
| `encocs_0826.DBF` | **6,670 integrantes** de 2,070 hogares × 32 variables: sexo, edad, parentesco, escolaridad, condición de actividad, ocupación, ingreso y los dos ponderadores (`FACTOR`, `FAC_P18`). `ELEGIDO` = 1 marca a la persona que contestó el básico (2,050) | Grupos de invarianza y criterios externos |
| `encocb_0826.DBF` | **2,050 personas de 18+** × 28 variables: los 15 ítems `P1`–`P15`, `FACTOR`, ciudad y llaves | AFE, AFC, 2.º orden, confiabilidad, puntajes, FIML |

Las tres se unen con campos de identificación (`FOL`, `CVE_ENT`, `CON`, `V_SEL`, `N_HOG`, `H_MUD` y, por persona,
`N_REN`): son llaves sin duplicados y **las 2,050 personas encuentran su registro en las otras dos tablas**. El
nombre del integrante (`NOM`) viene enmascarado con «-»: no hay datos personales. Las 20 viviendas que tienen hogar
en `ENCOCS` pero no cuestionario básico (2,070 − 2,050) son las de `R_DEF` 14, 15 y 16: la persona elegida no se
encontró (13), se negó (6) o estaba incapacitada (1).

## 2. Los 7 ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con lo subido? | Qué falta |
|---|---|---|---|
| AFE | ❌ No hay referencia | ✅ Sí: KMO .91, 4 factores (el análisis paralelo pide 5) | Confirmar el número de factores |
| AFC | ❌ No hay modelo | ✅ Sí: CFI .975, RMSEA .071 | Decidir `P11` y si `PLAN` va aparte |
| AFC 2.º orden | ❌ No | ✅ Sí, y **se puede contrastar** (con 4 factores no queda justo identificado) | — |
| Confiabilidad y validez | ❌ No | ✅ Confiabilidad y discriminante (HTMT). ⚠️ Criterio solo con sociodemográficos (|r| de .16 a .33) | Documento de validez y confirmar el criterio |
| Puntajes factoriales | ❌ No | ✅ Sí: 2,050 puntajes, aun con algún «No sabe» | — (la llave de la persona son las 7 variables de identificación) |
| Invarianza factorial | ❌ No | ✅ Sexo, edad, escolaridad y gran ciudad contra resto | Definir los grupos; sin región ni meses |
| FIML | ❌ No | ✅ Con ítems continuos (MLR). ❌ Con ítems ordinales: `lavaan` no lo permite | Decidir el tratamiento |

## 3. Lo que se encontró

### Hallazgo 1. El «No sabe» tiene un código distinto en cada pregunta

Según el PDF: `P1`–`P6`, `P11` y `P13` usan 6; `P7`, `P8`, `P14` y `P15`, 4; `P9` y `P10`, 3; `P12`, 7. En `P10`
existe además el 4, «No tiene ingresos». Todos pasan a faltante (`NA`). Sin recodificar, un 6 en `P1` pasaría por
«mucho peor» y un 7 en `P12` por una categoría más. El script lo hace.

### Hallazgo 2. Todas las escalas van en la misma dirección

En el cuestionario el código 1 es **siempre la respuesta más optimista** (mucho mejor, sí, mayores, aumentará mucho
el empleo, disminuirán mucho los precios), así que las correlaciones son positivas (de .12 a .74). Se **invierten
todas** para que **mayor = más confianza**.

### Hallazgo 3. Colas muy raras y un código ambiguo en `P12`

`P12` (precios en los próximos 12 meses) tiene «Disminuirán mucho» en **5** personas y «poco» en 26. Con subgrupos
(escolaridad) una categoría queda vacía y `lavaan` se detiene; el script **funde las dos**. Además el código 5 es
«**Aumentarán igual**» (así dice el PDF): queda entre «poco» y «mucho» por el orden del código, pero su sentido no es
claro. En los subgrupos hay categorías con 1 a 3 casos (`P11`, `P2`, `P3`, `P1`); en el ejercicio de invarianza conviene
fundir las colas de las escalas de 5 puntos.

### Hallazgo 4. Faltan pocos datos y no son del todo al azar

115 de 2,050 (**5.6 %**) tienen algún «No sabe»; por ítem, de 1 caso (`P1`, `P3`, `P7`, `P14`, `P15`) a 34 (`P13`,
1.7 %); 1,935 completos. Quien no sabe es mayor (+.022 en logit por año, p < .001) y, algo más, mujer (+.41,
p = .046): es un patrón **MAR** (depende de variables que sí se observan), no completamente al azar. Con
`missing = "pairwise"` los 115 conservan su puntaje.

### Hallazgo 5. `P1`–`P3` y `P2`–`P4` son casi la misma pregunta

`P1`/`P2` preguntan por «su situación» y `P3`/`P4` por la «de los miembros de este hogar» (hoy contra hace 12 meses y
dentro de 12 meses). Correlacionan .72 y .74 y producen factores de dos ítems con cargas de .89 a .91 (AVE de .81).
El ICC oficial usa solo `P3` y `P4`.

### Hallazgo 6. Los cinco ítems del ICC no bastan para una estructura factorial

El ICC se calcula con cinco de las 15 preguntas (situación actual y esperada del hogar y del país, y posibilidades
de compra de bienes durables): `P3`, `P4`, `P5`, `P6` y `P8`. Según fuentes secundarias, es el promedio de cinco
subíndices de 0 a 100 (confirmar con la nota técnica de INEGI). Esas cinco caen en los **cuatro factores** del modelo
y, como un solo factor, **no ajustan** (CFI .883, RMSEA .228). El modelo necesita los 15 ítems.

### Hallazgo 7. Diseño muestral

El ponderador `FACTOR` va de 4,812 a 88,119 (18 a 1) y su efecto de diseño por pesos es 1.26. Hay **583 UPM** con a lo
más 4 entrevistados cada una. Con MLR y FIML (la comparación de la sección 5), ponderar mueve las cargas hasta .028 y
agrupar por UPM multiplica los errores estándar por 1.04. Propuesta: **sin ponderador y sin conglomerado** en los
modelos, como en EMOVI.

### Hallazgo 8. `ENCOVIV` no aporta variables al modelo

Trae el tamaño del hogar (`P1`–`P4`), la ciudad y el resultado de la entrevista, pero ningún ítem de opinión. Solo se
usó para comprobar que las 2,050 entrevistas completas son las de `ENCOCB`.

## 4. Los ítems y el modelo propuesto

| Ítem | Contenido | Categorías | Factor propuesto |
|---|---|---|---|
| `P1` | Su situación económica hoy, frente a hace 12 meses | 5 | `HOGA` Hogar hoy |
| `P3` | Situación del hogar hoy, frente a hace 12 meses (**ICC**) | 5 | `HOGA` |
| `P2` | Su situación económica dentro de 12 meses | 5 | `HOGE` Hogar esperado |
| `P4` | Situación del hogar dentro de 12 meses (**ICC**) | 5 | `HOGE` |
| `P5` | Situación económica del país hoy (**ICC**) | 5 | `PAIS` Economía del país |
| `P6` | Situación económica del país dentro de 12 meses (**ICC**) | 5 | `PAIS` |
| `P12` | Precios en el país en los próximos 12 meses | 6 → 5 | `PAIS` (carga .48) |
| `P13` | Empleo en el país en los próximos 12 meses | 5 | `PAIS` |
| `P7` | Mayores posibilidades hoy de comprar ropa, calzado, alimentos | 3 | `CONS` Consumo, ahorro y planes |
| `P8` | Posibilidades hoy de comprar bienes durables (**ICC**) | 3 | `CONS` |
| `P9` | Posibilidades de salir de vacaciones en 12 meses | 2 | `CONS` |
| `P10` | Posibilidades hoy de ahorrar | 2 | `CONS` |
| `P11` | Condiciones para ahorrar dentro de 12 meses | 5 | `CONS` (el menos limpio) |
| `P14` | Planes de comprar un automóvil en 2 años | 3 | `CONS` |
| `P15` | Planes de comprar, construir o remodelar casa en 2 años | 3 | `CONS` |

## 5. Resultados de las pruebas

**AFE** (casos completos, 1,935; policóricas y `efa()` ordinal con oblimin):

| Factores | χ² (gl) | CFI | TLI | RMSEA | SRMR | Varianza residual mínima |
|---|---|---|---|---|---|---|
| 1 | 3,827 (90) | .888 | .869 | .147 | .093 | .311 |
| 2 | 2,385 (76) | .931 | .904 | .125 | .071 | .227 |
| 3 | 1,325 (63) | .962 | .937 | .102 | .053 | .158 |
| **4** | **325 (51)** | **.992** | **.983** | **.053** | **.024** | **.166** |
| 5 | 188 (40) | .996 | .988 | .044 | .016 | .157 |

KMO .91, Bartlett p ≈ 0, matriz policórica definida positiva (eigenvalor mínimo .18). **Kaiser pide 2, el análisis
paralelo 5**: se escoge **4** por el ajuste (con 5 solo se separan `P14` y `P15`, auto y casa, en un factor propio) y
porque cada factor tiene sentido. Cargas de patrón con 4 factores (los factores correlacionan de .41 a .60):

| Factor | Ítems (carga) |
|---|---|
| F1 Hogar hoy | `P1` .82, `P3` .78 |
| F2 Hogar esperado | `P2` .81, `P4` .78 |
| F3 País | `P6` .79, `P5` .76, `P13` .44, `P12` .41 |
| F4 Consumo y planes | `P9` .78, `P10` .78, `P14` .78, `P15` .71, `P8` .66, `P7` .57, `P11` .41 |

`P7` y `P8` cargan algo en F1 (.37 y .27) y `P11`, en tres factores (.41, .24 y .21).

**AFC de primer orden** (WLSMV, 2,050 casos, `pairwise`):

| Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR |
|---|---|---|---|---|---|
| **4 factores** (HOGA, HOGE, PAIS, CONS) | 960 (84) | **.975** | **.969** | **.071** | **.048** |
| 4 factores sin `P11` | 679 (71) | .981 | .976 | .065 | .045 |
| 5 factores (`PLAN` aparte) | 806 (80) | .979 | .973 | .067 | .042 |
| 1 factor con los 15 ítems | 4,007 (90) | .889 | .870 | .146 | .093 |

Cargas estandarizadas de .48 (`P12`) a .91 (`P1`, `P4`, `P2`); sin varianzas negativas. Correlaciones entre factores:
HOGA–HOGE .66, HOGA–PAIS .54, HOGA–CONS .79, HOGE–PAIS .58, HOGE–CONS .71, PAIS–CONS .62. Los mayores índices de
modificación son `P11` con `HOGE` (123) y con `PAIS` (99), y los residuales `P14`–`P15` (103), `P5`–`P6` (69) y
`P9`–`P10` (68): parejas de preguntas casi iguales. El RMSEA es el punto flojo; con un solo factor el ajuste cae
(CFI .889).

**Segundo orden** (`CONF =~ HOGA + HOGE + PAIS + CONS`):

| Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR |
|---|---|---|---|---|---|
| 1.er orden (4 factores) | 960 (84) | .975 | .969 | .071 | .048 |
| 2.º orden (`CONF`) | 951 (86) | .975 | .970 | .070 | .049 |

Con 4 factores el segundo orden queda con 2 gl más y se contrasta contra el primero: la χ² rechaza (p < .001, con
2,050 casos), pero CFI, RMSEA y SRMR no cambian. Cargas en `CONF`: HOGA .85 (R² .72), HOGE .79 (.62), PAIS .68 (.47) y
CONS .92 (.84). Varianzas residuales de los factores todas positivas (.12 a .31). `CONS` es el que más se parece al
factor general; `PAIS`, el que menos.

**Confiabilidad y validez** (alfa ordinal sobre policóricas; CR y AVE con las cargas estandarizadas):

| Factor | k | α ordinal | CR | AVE | r² máx. con otro factor | ¿AVE > r²? |
|---|---|---|---|---|---|---|
| HOGA | 2 | .896 | .896 | .812 | .620 | Sí |
| HOGE | 2 | .900 | .900 | .818 | .503 | Sí |
| PAIS | 4 | .726 | .742 | **.425** | .382 | Sí (pero AVE < .50) |
| CONS | 7 | .910 | .912 | .597 | .620 | **No** (por poco) |

HTMT de .55 (HOGA–PAIS) a .77 (HOGA–CONS): todos bajo .85. ω jerárquico .76 y ω total .95 (policóricas, 4 grupos).
`CONS` no pasa Fornell-Larcker frente a `HOGA` (r² de .62 contra una AVE de .597) y `PAIS` no llega a AVE de .50: por
eso el segundo orden tiene sentido.

**Puntajes factoriales** (EBM, 40 s para los 2,050): sin ningún faltante; media 0 y desviación de .63 (`PAIS`) a .83
(`HOGA`). `CONF` correlaciona **.970** con el promedio simple de los 15 ítems y **.904** con el de los cinco del ICC
(el promedio simple, no la fórmula oficial). **Validez de criterio** (Spearman con variables que no entraron al
modelo): edad **−.33**, estudios **.16**, ingreso mensual (log) **.20** (solo 810 con ingreso válido; el 999999 es
«no especificado»), estar ocupado **.17**. Por grupos de edad, `CONF` promedia .35, .13, −.13 y −.25 de 18-29 a 60+:
los jóvenes confían más.

**Invarianza** (umbrales y cargas juntos, por Millsap y Tein, porque `P9` y `P10` son binarios; criterio de Chen):

| Grupo (n) | Modelo | CFI | RMSEA | ΔCFI | ΔRMSEA | p (χ²) |
|---|---|---|---|---|---|---|
| Sexo (862 / 1,188) | Configural | .975 | .071 | | | |
| | Umbrales + cargas | .977 | .061 | +.002 | −.010 | .00 |
| Edad: 18-39 / 40-59 / 60+ (773 / 747 / 530) | Configural | .971 | .072 | | | |
| | Umbrales + cargas | .975 | .059 | +.004 | −.013 | .02 |
| Estudios: 4 niveles (316 / 453 / 559 / 720) | Configural | .974 | .071 | | | |
| | Umbrales + cargas | .977 | .059 | +.003 | −.012 | .00 |
| Ciudad: CDMX, Guadalajara y Monterrey (766) contra las otras 29 (1,284) | Configural | .976 | .071 | | | |
| | Umbrales + cargas | .979 | .060 | +.003 | −.011 | .01 |

Los cuatro convergen y **cumplen el criterio de Chen** (ΔCFI no empeora, ΔRMSEA ≤ .015), pero la χ² rechaza con tantos
casos. El modelo ajusta en cada grupo por separado (CFI de .962 a .984, RMSEA de .052 a .082). Cuidado con las colas
(categorías con 1 a 14 casos).

**FIML frente a listwise** (ítems continuos, MLR; `lavaan` rechaza `missing = "fiml"` con ítems ordinales):

| Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
|---|---|---|---|---|---|---|
| Listwise | 1,935 | 764 (84) | .935 | .919 | .068 | .046 |
| FIML | 2,050 | 777 (84) | .936 | .920 | .067 | .043 |

Las cargas difieren hasta .007 y los errores estándar de FIML son 97.5 % de los de listwise: con 5.6 % de casos
incompletos **el FIML casi no aporta**. (Con ítems continuos el ajuste es peor que con ordinales: CFI .936 contra
.975.)

## 6. Qué necesito

**Documentos:**

1. **La nota metodológica de INEGI del ICC** (fórmula de los cinco subíndices), si se quiere reproducir el indicador
   oficial y compararlo con los puntajes factoriales. Hoy solo se compara con un promedio simple.
2. Un **documento de validez** (en el Tren se usó SEM06) y, si se quiere validez de criterio, confirmar cuál es el
   criterio. Hoy solo hay sociodemográficos (edad, estudios, ingreso, ocupación).
3. Si se quiere **invarianza en el tiempo** o comparar meses, **otros meses de la ENCO** (`encocb_<mes>.DBF`).

**Decisiones (por confirmar):**

1. ¿**4 factores** (`HOGA`, `HOGE`, `PAIS`, `CONS`) o **5** (`PLAN` con `P14` y `P15` aparte)? Se propone 4: el paralelo
   sugiere 5, pero el ajuste ya es bueno (CFI .975) y `PLAN` tendría dos ítems.
2. ¿`P11` se queda en `CONS` (carga .41 en el AFE, .77 en el AFC) o se quita? Sin él, el RMSEA baja de .071 a .065.
   Se propone dejarlo.
3. `P12`: se fundieron «Disminuirán mucho» y «poco» (5 y 26 casos). ¿Se acepta, aun con el código 5 ambiguo
   («Aumentarán igual»)?
4. ¿**Sin ponderador** y sin conglomerado (como EMOVI)? Se propone sí, con la sensibilidad del Paso 12.
5. ¿Qué **grupos** se usan en la invarianza? Sexo, edad (18-39 / 40-59 / 60+), escolaridad y gran ciudad contra resto
   están listos. Para región habría que construirla a mano desde `CVE_ENT`.
6. ¿**FIML** con ítems continuos (MLR), como en EMOVI, o también con **faltantes simulados** (MCAR y MAR)? Con 5.6 %
   de incompletos el FIML real casi no cambia el resultado.

Salidas (en `output/`, que no se versiona): `inventario_archivos.csv`, `items_enco.csv`, `faltantes_por_item.csv`,
`ajuste_AFE.csv`, `cargas_AFE_4_factores.csv`, `ajuste_AFC.csv`, `cargas_AFC.csv`, `ajuste_2do_orden.csv`,
`confiabilidad_validez.csv`, `htmt.csv`, `validez_criterio.csv`, `invarianza.csv`, `ajuste_por_grupo.csv` y
`fiml_vs_listwise.csv`.
