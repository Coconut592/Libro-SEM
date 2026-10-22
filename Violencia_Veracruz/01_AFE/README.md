# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R` (unos 30 segundos). **Sin referencia propia:** `Scripts.do` pasa de la base directo a un análisis de clases
latentes en Mplus (24 ítems → 3 clases) sin explorar su estructura factorial. Aquí se explora antes cuántos factores tienen los
24 ítems de violencia.

**Pregunta:** los 24 hechos de violencia (infancia, familia, pareja, trabajo, comunidad y escuela), ¿forman una sola dimensión o
varias?

**Respuesta corta: varias, y casi coinciden con los ámbitos del cuestionario.** Con **5 factores** el ajuste es muy bueno
(CFI .988, RMSEA .022) y cada factor tiene sentido: infancia, familia **y trabajo juntos**, pareja, comunidad y escuela. Con 6 el
ajuste mejora (CFI .996) sin caso Heywood, pero **trabajo no sale como factor propio**. Un factor único no sirve (CFI .847).

## Paso a paso

1. **Datos.** 1,088 mujeres (se quita el renglón huérfano `id` 907) y los 24 ítems 0/1. Solo **505** contestan los 24 (pareja, trabajo y
   escuela se saltan por cuestionario; ver [`00_Diagnostico`](../00_Diagnostico/)). Las demás entran con **parejas disponibles**.
   **No se aplica el criterio 90-10 de EMOVI:** 8 ítems están por debajo del 5 %, pero en violencia el evento raro es el objeto de estudio.
2. **¿Tiene sentido factorizar?** La matriz tetracórica **no es definida positiva** (eigenvalor menor −0.32; 23 parejas de ítems con 2
   mujeres o menos con "Sí" en ambos), y KMO y Bartlett salen sin sentido sobre ella. Con la correlación de Pearson (phi) por pares
   (eigenvalor menor +0.27): **KMO = .79** (aceptable) y **Bartlett χ² = 4,875** (276 gl, *n* = 841, el promedio armónico de las
   mujeres por pareja de ítems), p < .001. Los ítems con menor adecuación (.62–.70) son los raros: `p194`, `p185`, `p193`, `p184` y `p183`.
3. **¿Cuántos factores?** Eigenvalores 4.56, 1.99, 1.83, 1.76, 1.37, 1.21, 1.15, 1.03, 0.90…: Kaiser y el análisis paralelo dicen **8**,
   pero con ítems 0/1 y eventos raros estos criterios sobrestiman (separan ítems por su frecuencia). Se decide con el **AFE de
   `lavaan`** (WLSMV, ordinal, oblimin), que sí da ajuste:

   | Factores | χ² (gl) | CFI | TLI | RMSEA | SRMR | Varianza residual más baja |
   |---|---|---|---|---|---|---|
   | 1 | 1,418.2 (252) | .847 | .832 | .065 | .189 | .164 |
   | 2 | 905.8 (229) | .911 | .893 | .052 | .169 | .107 |
   | 3 | 524.1 (207) | .958 | .944 | .038 | .136 | .101 |
   | 4 | 357.2 (186) | .978 | .967 | .029 | .099 | .095 |
   | **5** | **253.6 (166)** | **.988** | **.981** | **.022** | **.083** | .093 |
   | 6 | 180.9 (147) | .996 | .992 | .015 | .069 | .071 |
   | 7 | 141.0 (129) | .998 | .997 | .009 | .061 | **−.077** |

   Con 7 factores una varianza residual ya es negativa (caso Heywood). **El SRMR es alto en todos** (.06 a .19) por las parejas casi
   vacías (ver [`02_AFC`](../02_AFC/)). Se examinan 5 y 6.
4. **Cinco factores** (cargas de patrón, oblimin; entre paréntesis, cargas cruzadas de .30 o más):

   | Factor | Ítems con carga principal |
   |---|---|
   | **F1 · Infancia** | `p143` (.89), `p142` (.87), `p141` (.86), `p144` (.70; también .32 en F3) |
   | **F2 · Familia y trabajo** | `p161` (.79), `p185` (.76), `p162` (.75), `p183` (.60), `p165` (.58), `p186` (.54; .43 en F3), `p184` (.45; .43 en F5) |
   | **F3 · Pareja** | `p171` (.91), `p172` (.88), `p176` (.86), `p173` (.82), `p175` (.64) |
   | **F4 · Comunidad** | `p192` (.82), `p191` (.79), `p194` (.56), `p193` (.41) |
   | **F5 · Escuela** | `p201` (.92), `p202` (.90), `p204` (.74), `p203` (.65) |

   Los factores correlacionan de .14 a .36. **Familia y trabajo se fusionan:** los ítems de trabajo son muy raros (entre 16 y 29 mujeres con "Sí") y, ya
   como factor, trabajo correlaciona .60 con familia, más que con cualquier otro ámbito (ver [`02_AFC`](../02_AFC/)).
5. **Seis factores:** infancia, pareja y escuela siguen claros, pero **trabajo no sale como factor propio** (`p183` y `p185` cargan en el
   de familia; `p184` en el de escuela) y **comunidad se parte en dos** (`p191`–`p192` por un lado, `p193`–`p194` por otro, con `p185` y
   `p175` cargando también ahí). Las cargas de esta solución son menos limpias.
6. **Los seis ámbitos del cuestionario sí se ven en las correlaciones** (policóricas por pares):

   | Bloque | Ítems | *r* media dentro | *r* media fuera |
   |---|---|---|---|
   | infancia | 4 | .79 | .30 |
   | familia | 3 | .76 | .37 |
   | pareja | 5 | .72 | .31 |
   | trabajo | 4 | .56 | .26 |
   | comunidad | 4 | .43 | .22 |
   | escuela | 4 | .70 | .24 |

   Los ítems de un bloque correlacionan más entre sí que con los demás, salvo comunidad (.43) y trabajo (.56), los más débiles.

**Qué se lleva al AFC:** los **seis ámbitos** (que son los del cuestionario), y se compara contra la solución de **cinco factores** del
AFE (familia + trabajo juntos) y contra un solo factor (ver [`02_AFC`](../02_AFC/)).

**Salidas** (`output/`): `ajuste_AFE.csv`, `cargas_AFE_5_factores.csv`, `cargas_AFE_6_factores.csv` y `correlaciones_dentro_fuera.csv`.

**Cuidado.** El AFC (02) se confirma con las mismas 1,088 mujeres del AFE: la estructura sale de estos datos y no es una prueba
independiente. Y las cargas de los ítems raros (trabajo) tienen errores estándar grandes.
