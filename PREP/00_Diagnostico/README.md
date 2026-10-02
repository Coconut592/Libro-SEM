# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 7 minutos). Lo que se revisó: los nueve archivos de referencia
(`EFA_Hogares.inp`, `CFA_Hogares.inp`, `CFA_Espacio_Publico.inp`, `AFE.do`, `cfa_espacio_publico.pdf` y los
Laboratorios 2 a 5) y la base `PREP.dta`. Cada ejercicio se corrió con la base real en R (`lavaan`, MLR
y FIML, como Mplus).

## Resumen

1. **La base alcanza para los 7 ejercicios.** Lo que falta son documentos y decisiones, no datos.
2. **Todo lo que se adjuntó es del piloto**: `Datos_Piloto_MPLus*.dat` y `datos Piloto PREP_Final.dta`,
   con variables `B13`–`G3` y entre 75 y 100 casos (el PDF dice 75 analizados y 25 vacíos). `PREP.dta` es
   el estudio final: 8,242 respondientes y otra numeración. Los `.inp`, el `.do` y los laboratorios no
   corren tal cual; hace falta una **tabla de equivalencias** (sección 4).
3. **No vienen en los archivos:** invarianza factorial (nada) y validez (nada, solo confiabilidad). El
   segundo orden viene como técnica (Lab 3) pero no hay un modelo de segundo orden del PREP.
4. **Hay que limpiar la base antes de analizar:** el "99 = Ns/Nc" de los bloques C a F es un valor y no un
   faltante.

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| `AFE.do` | Stata: AFE ML del espacio público (3 factores) y de la colonia (22 ítems, 4 factores, varimax con Kaiser, KMO) | AFE |
| `EFA_Hogares.inp` | Mplus: `TYPE EFA 1 3`, MLR, varimax, faltantes. **Usa los ítems del espacio público** aunque se llama *Hogares* | AFE, FIML |
| `CFA_Espacio_Publico.inp` | Mplus: 3 factores (`EVEP`, `SEGEP`, `ACTEP`), MLR, interceptos en 0, `SAVE = FS` | AFC, puntajes |
| `CFA_Hogares.inp` | Mplus: 5 factores (`IP`, `SG`, `CS`, `IN`, `SR`), ML, `SAVE = FS` | AFC, puntajes |
| `cfa_espacio_publico.pdf` | Salida de Mplus del piloto (24/04/2013): 75 casos, MLR, `TYPE = H1 missing`, 12 patrones de faltantes. χ²(41) = 77.2, CFI = .890, TLI = .853, RMSEA = .108, SRMR = .062 | AFC, FIML |
| Lab 2 `Afe_Conf1.R` | Alfa, KR-20, componentes principales, análisis paralelo, `fa`, AFC con `sem` y `lavaan`, alfa y confiabilidad compuesta con el piloto, puntajes (Bartlett) y gráficas por `parque` | AFE, AFC, confiabilidad, puntajes |
| Lab 3 `CFA_2o_Orden.R` | AFC de primer y segundo orden y modelo con indicadores formativos, con bases de ejemplo (que no están) | AFC 2.º orden |
| Lab 4 `efectos_dir_indir.R` | SEM de la colonia con efectos directo, indirecto y total (`:=`) y `missing = "fiml"` | FIML (y SEM, que no es de los 7) |
| Lab 5 `SEM.R` | Democracia e industrialización (otra base) y el SEM del PREP; puntajes, medias ponderadas y `t.test` por `parque` | FIML, puntajes (y SEM) |

## 2. Los 7 ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con `PREP.dta`? | Qué falta |
|---|---|---|---|
| AFE | ✅ Sí | ✅ Sí | Confirmar equivalencias |
| AFC | ✅ Sí | ✅ Sí | Confirmar equivalencias |
| AFC 2.º orden | ⚠️ Solo la técnica (Lab 3, otras bases) | ✅ En lo técnico | El modelo de 2.º orden del PREP |
| Confiabilidad y validez | ⚠️ Confiabilidad (Lab 2). **Validez no** | ✅ Sí | Documento de validez y variable criterio |
| Puntajes factoriales | ✅ Sí | ✅ Sí | `id` del respondiente y `parque` |
| Invarianza factorial | ❌ **No** | ✅ En lo técnico | Documento y definir el grupo |
| FIML | ✅ Sí | ✅ Sí | Saber por qué faltan los datos |

## 3. Lo que se encontró en la base

1. **"99 = Ns/Nc" sin recodificar en C, D, E y F.** En B y G ya es `NA`. En C a F hay entre 16 y 1,052
   respuestas 99 por ítem (`c05` tiene 1,052). Se recodifican a `NA`; el script lo hace.
2. **Faltantes altos en el espacio público.** `b22` 33%, `b21` 33%, `b18` 22%, `b17` 16%; los demás ítems,
   entre 0.2% y 14%. Solo **4,019** de 8,242 tienen completos los 11 ítems del espacio público
   (5,880 en la colonia y 6,627 en G; 3,194 en todos).
3. **428 respondientes (5%) no tienen ningún ítem del bloque B**; 426 sí contestaron la colonia. Ocurre en
   31 espacios y en **10 de ellos nadie tiene el bloque B**. Parece un bloque no aplicado o no capturado en
   esos espacios, no no-respuesta individual.
4. **`b21` y `b22` faltan por "no sé", no por salto de pregunta, al menos en parte:** el 80% de quienes no
   contestan `b21` sí contestan `b26` (la satisfacción con las mismas actividades).
5. **Datos anidados.** 276 espacios: 273 con 30 respondientes y 3 con 9, 15 y 28. Las correlaciones
   intraclase por espacio van de .12 a .39 (mediana .21). Con `cluster = "espacio"` los errores estándar
   de las cargas son **37% mayores** y el ajuste casi no cambia (CFI = .980).
6. **Dirección de las escalas.** `b14`–`b18` originales: 1 = "Totalmente cierto", 10 = "Totalmente falso",
   es decir, **mayor = más seguro**; correlacionan **+.35** con las calificaciones `b11`–`b13`. Las
   `*Recod` están invertidas (−.35). En el piloto, `B18`–`B21` sin recodificar correlacionaban en
   negativo con las calificaciones (PDF), así que por el signo las originales de la base se comportan
   como `B18r`–`B21r` (los `.inp` nuevos y el `.do`) y las `Recod` como `B18`–`B21` (el PDF). Por confirmar.
7. **Forma de los ítems.** Escalas de 1 a 10 con asimetría casi siempre negativa (−0.9 a 0.4) y curtosis de
   −1.4 a 0.3, salvo `g06`–`g08`: el 50% responde 1 (asimetría de 1.3 a 1.6). MLR corrige la no normalidad.
8. **No hay `id`, `parque` ni variables del respondiente** (sexo, edad, escolaridad). Solo `espacio` e
   `ID_MPIO`.

## 4. Equivalencias piloto → `PREP.dta` (propuesta por contenido; falta confirmar)

La numeración de las secciones se recorrió una letra (piloto `D` → base `C`, `E` → `D`, `F` → `E`,
`G` → `F`), pero el número de ítems por escala cambió, así que **no es uno a uno** salvo en `D`/`C`.

| Factor | Piloto (`.inp` y labs) | `PREP.dta` | Comentario |
|---|---|---|---|
| Evaluación del espacio (`EVEP`) | `B13`–`B16` (4) | `b11`–`b13` (3) | Falta un ítem |
| Seguridad del espacio (`SEGEP`, antes `INEP`) | `B18r`–`B21r` (4; `B17` se excluye) | `b14`–`b18` (5) | Originales, no `Recod` |
| Actividades (`ACTEP`) | `B23`–`B25` (3) | `b21`, `b22`, `b26` (3) | `b26` es satisfacción con las actividades |
| Inseguridad percibida (`IP`) | `D1`–`D4`, `D6` (5) | `c01`–`c06` (6) | El piloto excluyó `D5` |
| Seguridad en la colonia (`SG`) | `D7`–`D9` (3) | `c07`–`c09` (3) | |
| Cohesión social (`CS`) | `E1`–`E6`, `E9`, `E10` (8 de 10) | `d01`–`d09` (9) | Cambia el número de ítems |
| Infraestructura (`IN`) | `F1`, `F4`–`F8` (6 de 8) | `e01`–`e05` (5) | |
| Satisfacción residencial (`SR`) | `G1`–`G3` (3) | `f01`, `f02` (2) | Solo 2 indicadores |
| Participación y civismo | — | `g01`–`g12` | Sin antecedente en el piloto |

## 5. Resultados de las pruebas

**AFE** (casos completos, ML, varimax): los factores salen limpios.

| Bloque | N | KMO | Kaiser | Paralelo (componentes / ML) | Solución | RMSEA | TLI |
|---|---|---|---|---|---|---|---|
| Espacio público (11) | 4,019 | .89 | 3 | 3 / 3 | Calificación (`b11`–`b13`), seguridad (`b14`–`b18`) y actividades (`b21`, `b22`; `b26` carga .37 y .54) | .050 | .979 |
| Colonia (25) | 5,880 | .93 | 4 | 4 / 5 | Inseguridad (`c01`–`c06`), seguridad (`c07`–`c09`), cohesión (`d01`–`d09`) y **`e01`–`e05` con `f01`–`f02` en un solo factor** | .068 | .912 |
| G (12) | 6,627 | .78 | 3 | 3 / 4 | Participación (`g01`–`g04`), rechazo a conductas (`g06`–`g08`) e intervención (`g09`–`g12`); `g05` no carga (comunalidad .03) | .050 | .970 |

**AFC** (MLR + FIML):

| Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
|---|---|---|---|---|---|---|
| Espacio público: EVEP, SEGEP, ACTEP | 7,814 | 622 (41) | .979 | .972 | .058 | .031 |
| Colonia: IP, SG, CS, INF, SR | 8,239 | 5,484 (265) | .938 | .930 | .059 | .034 |
| G: PART, RECH, INTV | 7,805 | 501 (41) | .985 | .979 | .045 | .025 |

- Cargas estandarizadas de .71 a .92 (espacio público), de .46 a .91 (colonia; la menor es `d09`, "pediría
  prestado dinero a un vecino") y de .52 a .92 (G). No hay varianzas negativas.
- Correlaciones: EVEP–SEGEP .50, EVEP–ACTEP .64, SEGEP–ACTEP .43. En la colonia, **INF–SR = .77**, la
  única alta (y SR tiene solo 2 ítems).
- **Frente al piloto** (PDF): CFI .890 → .979 y RMSEA .108 → .058. El signo EVEP–seguridad se invierte
  (−.51 allá porque usaba inseguridad; +.50 aquí). Actividades–seguridad era casi nula (−.15, no
  significativa) y aquí es .43.

**Segundo orden:**

| Modelo | gl | CFI | RMSEA | Cargas de 2.º orden |
|---|---|---|---|---|
| Espacio público (3 factores) | 41 | .979 | .058 | Calificación .86, seguridad .58, actividades .75 (justo identificado: ajuste idéntico al de 1.er orden) |
| Colonia (5 factores) | 270 | .936 | .060 | IP −.38, SG .60, CS .46, INF .85, SR .89 (1.er orden: .938 y .059) |
| G (3 factores) | — | — | — | No: los factores correlacionan .05, .20 y −.10 |

La colonia **no converge** con la parametrización por defecto (carga marcadora en 1); sí con
`std.lv = TRUE`.

**Confiabilidad y validez** (alfa con los datos; CR de Dillon-Goldstein y AVE con las cargas estandarizadas):

| Factor | k | α | CR | AVE | r² máx. con otro factor |
|---|---|---|---|---|---|
| EVEP | 3 | .893 | .897 | .745 | .414 |
| SEGEP | 5 | .897 | .896 | .634 | .246 |
| ACTEP | 3 | .806 | .834 | .628 | .414 |
| IP | 6 | .891 | .889 | .574 | .115 |
| SG | 3 | .901 | .901 | .753 | .268 |
| CS | 9 | .899 | .908 | .532 | .179 |
| INF | 5 | .897 | .898 | .640 | .589 |
| SR | 2 | .772 | .783 | .645 | .589 |
| PART | 4 | .796 | .805 | .514 | .041 |
| RECH | 3 | .889 | .898 | .748 | .011 |
| INTV | 4 | .870 | .877 | .646 | .041 |

Todos superan .70 en α y CR y .50 en AVE, y la AVE de cada factor supera su r² más alto con otro factor
(Fornell-Larcker). El caso más justo es Infraestructura–Satisfacción (r² = .589, AVE de .640 y .645).
KR-20 no aplica: es para ítems 0/1.

**Puntajes factoriales** (espacio público): regresión (el método de Mplus) con media 0 y D.E. de 1.92, 2.03 y
2.02 para 7,814 respondientes; en escala original (interceptos en 0 y medias libres) las medias de los
factores son 6.42, 6.57 y 6.12 (con otro ítem marcador, 6.54, 6.57 y 6.12) (rangos 1.2 a 10.1).

**Invarianza** (espacio público, estados 15, 30 y 26; 1,992 casos: 1,094, 388 y 510): configural CFI = .971, métrica .966 y escalar .957;
las caídas (.005 y .009) cumplen el criterio de Chen (2007). Solo prueba que el ejercicio corre.

**FIML frente a listwise** (espacio público): 7,814 casos contra 4,019, mismo ajuste (CFI = .979, RMSEA =
.058) y cargas que difieren en .02 o menos.

**Extra, Laboratorios 4 y 5.** El SEM de la colonia (`CS ~ IP + a*INF`, `SR ~ c*INF + b*CS`, `IP ~~ INF`)
también corre: CFI = .932, RMSEA = .066, efecto indirecto `a*b` = .052 y efecto total = .739 (sin
estandarizar). **No hay carpeta para esto en los 7 ejercicios.**

## 6. Qué necesito

**Documentos:**

1. **El cuestionario del piloto o el diccionario de `datos Piloto PREP_Final.dta`** (para saber qué es
   `B13`–`G3`), o directamente una **tabla de equivalencias piloto → final**. Con eso se confirma la sección 4.
2. **El cuestionario final con sus filtros**: para saber si los faltantes de `b21`/`b22` son "no sé" y por
   qué 10 espacios no tienen el bloque B.
3. **Un documento de invarianza factorial** y **cuál es el grupo**. Lo ideal es un catálogo de espacios
   (tipo de espacio, tamaño, región) o variables del respondiente; sin eso solo queda agrupar por estado.
4. **Un documento de validez** (en el Tren se usó SEM06) y, si se quiere validez de criterio, una
   **variable criterio**.
5. **El modelo de 2.º orden del PREP** (qué factores forman cada factor general). Si además se quieren
   replicar los ejemplos del Lab 3, faltan sus tres `.dta`.

**Decisiones:**

1. ¿Para la seguridad del espacio público se usan `b14`–`b18` originales (mayor = más seguro, como `B18r`)
   o las `Recod` (mayor = más inseguridad, como el PDF)? Se propone las originales.
2. ¿La colonia se trabaja con 4 factores (`AFE.do`) o con 5 (`CFA_Hogares.inp`)? ¿`SG` va dentro?
3. ¿Entra el bloque G, que es nuevo y no tiene antecedente en el piloto?
4. ¿Se usan errores estándar por conglomerado (`cluster = "espacio"`)?
5. ¿Se agregan carpetas para los Labs 4 y 5 (SEM y efectos indirectos)?

## 7. Erratas en los archivos de referencia

- `AFE.do`, línea 2: dice `factor factor B13 ...`; en Stata falla.
- `EFA_Hogares.inp`: el título dice *Hogares*, pero analiza los ítems del espacio público.
- `CFA_Hogares.inp`, línea 29: `[e10]` no lleva `@0`, así que su intercepto queda libre (probable
  errata). Además usa `Datos_Piloto_MPLus.dat` (sin recodificar) y ML, mientras los otros usan
  `Datos_Piloto_MPLus3.dat` y MLR.
- Lab 2, líneas 203 y 204: `alpha(covariance[5:6,5:6])` y `alpha(covariance[7:11,7:11])` deberían ser
  `[5:8,5:8]` y `[9:11,9:11]`. El KR-20 necesita `KR20.csv`, que no está.
- Lab 3, línea 55: hay un correo electrónico suelto en el script (da error de sintaxis al ejecutarlo).
- Labs 2 a 5: rutas de Windows con `setwd(...)` y acentos con otra codificación.

Salidas (en `output/`, que no se versiona): `ns_nc_99_por_item.csv`, `faltantes_por_item.csv`,
`icc_por_item.csv`, `cargas_AFE_*.csv`, `ajuste_AFC.csv`, `confiabilidad_validez.csv`, `puntajes_EP.csv`,
`invarianza_por_estado.csv` y `fiml_vs_listwise.csv`.
