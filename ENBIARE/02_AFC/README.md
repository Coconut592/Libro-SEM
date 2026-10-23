# 02 · Análisis Factorial Confirmatorio (AFC)

Script: `AFC.R` (un minuto). **Sin referencia propia:** los modelos salen del AFE (01) y del contenido de los
ítems. Dos modelos de primer orden con las 31,166 personas, estimados con **MLR** (sin faltantes: no hace falta FIML).

**Pregunta:** ¿las estructuras de cinco factores del AFE se confirman, y mejor que las más simples?

**Respuesta corta: sí.** Satisfacción (17 ítems) ajusta bien (CFI .952, RMSEA .047) y confianza (11 ítems) también en
CFI (.968), con un RMSEA alto (.088) que se explica por una carga cruzada de `pb1_10`. En las dos escalas ganan los
cinco factores contra uno, dos o cuatro, y la estructura se confirma en una mitad de la muestra que no la generó.

## Los modelos

| Escala | Factor | Ítems |
|---|---|---|
| **SAT** · Satisfacción | `NIV` Nivel de vida y logros | `pa3_01` nivel de vida, `pa3_02` salud, `pa3_03` logros, `pa3_08` perspectivas a futuro |
| | `REL` Relaciones | `pa3_04` personales, `pa3_05` vida social, `pa3_06` familiar, `pa3_07` afectiva |
| | `AUT` Autonomía y actividad | `pa3_09` tiempo libre, `pa3_10` libertad para decidir, `pa3_12` actividad principal |
| | `BAR` Hogar y vecindario | `pa3_13` vivienda, `pa3_14` vecindario |
| | `CIU` Ciudad y país | `pa3_11` seguridad ciudadana, `pa3_15` ciudad, `pa3_16` servicios públicos, `pa3_17` país |
| **CONF** · Confianza | `INT` Interpersonal | `pb1_01` la mayoría de la gente, `pb1_02` la que conoce |
| | `POL` Policías | `pb1_04` municipal, `pb1_05` estatal |
| | `MIL` Fuerzas armadas | `pb1_06` Guardia Nacional, `pb1_07` Ejército y Marina |
| | `JUS` Justicia | `pb1_08` ministerio público, `pb1_09` juzgados y tribunales |
| | `PLT` Política | `pb1_10` cámaras, `pb1_11` partidos, `pb1_12` funcionarios |

`pb1_03` (medios de comunicación) queda fuera: no pertenece a ningún factor (ver 01).

## Paso a paso

1. **AFC con MLR.** Los dos convergen y son admisibles (sin varianzas negativas). MLR por la asimetría (hasta −2.5)
   de las escalas 0-10.
2. **Bondad de ajuste** (Hu y Bentler, 1999: CFI y TLI ≥ .95, RMSEA ≤ .06, SRMR ≤ .08):

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | SAT, 5 factores | 4,419 (109) | .952 | .941 | .047 | .032 |
   | CONF, 5 factores | 5,468 (34) | .968 | .949 | .088 | .027 |

   Con 31 mil casos la χ² siempre rechaza; se leen los índices. En SAT todos pasan, salvo un TLI de .941 (aceptable).
   En CONF, CFI y SRMR son buenos y el **RMSEA (.088) no**: con 34 gl el RMSEA se infla, y además hay una
   especificación que falta (paso 5b).
3. **Cargas estandarizadas** (todas significativas, p < .001):

   | Escala | Cargas por factor |
   |---|---|
   | SAT | NIV .66 · .61 · .73 · .64 — REL .75 · .65 · .61 · .55 — AUT .60 · .63 · .68 — BAR .64 · .69 — CIU .60 · .76 · .66 · .67 |
   | CONF | INT .84 · .68 — POL .86 · .96 — MIL .95 · .85 — JUS .91 · .89 — PLT .86 · .86 · .89 |

   Las de **satisfacción son moderadas (.55–.76)**: cada factor explica entre 30 % y 57 % de la varianza de cada
   ítem (la AVE, en 04, queda en .41–.45). Las de **confianza son altas (.68–.96)**.
4. **Correlaciones entre factores:**
   - SAT, de **.44** (REL–CIU) a **.82** (NIV–REL); NIV con AUT, .81; REL con AUT, .74; BAR con CIU, .69. Los tres factores
     "personales" (NIV, REL, AUT) correlacionan .74–.82; los de entorno (BAR, CIU), menos con ellos (.44–.65).
   - CONF, de **.35** (INT–MIL) a **.83** (JUS–PLT); los cuatro factores institucionales, .67–.83; la confianza
     interpersonal con ellos, .35–.46.

   Esto anticipa el segundo orden (03) y la validez discriminante (04).
5. **Índices de modificación** (los mayores). SAT: la vivienda y el vecindario (`BAR`) cargan también en `NIV` (MI
   1,119) y en `CIU` (784); `pa3_14` con `pa3_15` y `pa3_03` con `pa3_04` covarían (MI ≈ 830). CONF: `pb1_10` carga también
   en justicia (MI 4,558) y `pb1_11` con `pb1_12` covarían (3,673). Con 31 mil casos todos son grandes y **no se agrega
   ninguno** al modelo principal.

   **5b. Confianza con una carga cruzada.** `pb1_10` (cámaras de diputados y senadores) carga .51 en política y .38 en
   justicia en el AFE. Si se agrega:

   | Variante de CONF | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | Base (estructura simple) | 5,468 (34) | .968 | .949 | .088 | .027 |
   | + `pb1_10` también en `JUS` | 2,694 (33) | **.985** | **.974** | **.062** | .018 |
   | + residual `pb1_11` ~~ `pb1_12` | 3,160 (33) | .982 | .970 | .067 | .022 |

   La carga cruzada lleva el ajuste a "bueno" en todo. Se deja la **estructura simple como principal** (es la que pasa al
   segundo orden y a la invarianza) y esta variante queda como sensibilidad: el RMSEA alto de CONF viene de ese ítem,
   no de una estructura equivocada.
6. **Contra modelos más simples** (cada uno es un caso anidado de cinco factores):

   | Modelo | CFI | TLI | RMSEA | SRMR | BIC |
   |---|---|---|---|---|---|
   | SAT 1 factor | .786 | .755 | .096 | .072 | 2,129,126 |
   | SAT 4 factores (`BAR` y `CIU` juntos) | .926 | .911 | .058 | .048 | 2,106,672 |
   | **SAT 5 factores** | **.952** | **.941** | **.047** | **.032** | **2,102,394** |
   | CONF 1 factor | .772 | .715 | .208 | .084 | 1,505,210 |
   | CONF 2 factores (personas / instituciones) | .809 | .755 | .193 | .063 | 1,495,707 |
   | CONF 4 factores (`JUS` y `PLT` juntos) | .929 | .898 | .125 | .037 | 1,464,309 |
   | **CONF 5 factores** | **.968** | **.949** | **.088** | **.027** | **1,454,201** |

   Δχ² escalada de 5 contra 4 factores: 2,181 (4 gl) en SAT y 4,622 (4 gl) en CONF, p < .001. Gana el de cinco en CFI,
   RMSEA, SRMR y BIC en las dos. Un solo factor no sirve (CFI < .79).
7. **Sensibilidad: estimador y diseño muestral.**

   | Escala | Variante | CFI | RMSEA | Carga media | Mayor cambio en cargas | Error estándar |
   |---|---|---|---|---|---|---|
   | SAT | MLR (base) | .952 | .047 | .655 | — | 1 |
   | | WLSMV (ordinal, 11 categorías) | .966 | .062 | .710 | .118 | — |
   | | MLR con conglomerado (UPM) | .952 | .047 | .655 | 0 | ×1.01 |
   | | MLR ponderado (`fac_ele`) | .950 | .049 | .661 | .014 | ×1.45 |
   | CONF | MLR (base) | .968 | .088 | .867 | — | 1 |
   | | WLSMV | .980 | .140 | .887 | .051 | — |
   | | MLR con conglomerado | .968 | .088 | .867 | 0 | ×1.02 |
   | | MLR ponderado | .969 | .087 | .863 | .052 | ×1.51 |

   - El **conglomerado** (4,704 UPM de 6.6 personas, ICC .025) no cambia nada.
   - **Ponderar** sube los errores estándar ×1.45–1.51 (efecto de Kish 2.23) y mueve las cargas hasta .014 en SAT y .052 en
     CONF; el CFI, ≤ .002.
   - **WLSMV** mejora el CFI y sube las cargas (en SAT la media pasa de .65 a .71; hasta .12 en un ítem): las
     correlaciones policóricas corrigen el techo de las respuestas. Mismos factores. Su RMSEA en CONF (.140) no es de fiar
     con 34 gl.

   Se trabaja con **MLR sin ponderador**, como EMOVI y ENCO: el AFC estima la estructura de medida, no medias
   poblacionales (para eso, 05).
8. **Validación cruzada.** Se parte la muestra al azar (15,513 y 15,653). El AFE (ML, oblimin, 5 factores) de la mitad
   A agrupa los ítems **exactamente** como el modelo en las dos escalas; el AFC en la mitad B:

   | Modelo | N | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | SAT, mitad B | 15,653 | .950 | .938 | .048 | .032 |
   | SAT, mitad A | 15,513 | .955 | .944 | .046 | .032 |
   | CONF, mitad B | 15,653 | .968 | .947 | .090 | .027 |
   | CONF, mitad A | 15,513 | .969 | .950 | .086 | .028 |

   Mismo ajuste que con todos: la estructura se confirma en datos que no la generaron.

**Salidas** (`output/`): `ajuste_AFC.csv`, `solucion_estandarizada_AFC.csv`, `comparacion_modelos.csv`,
`confianza_variantes.csv`, `sensibilidad_AFC.csv`, `validacion_cruzada.csv` y los diagramas.

**Lo que conviene tener presente.** El RMSEA de CONF (.088) y el TLI de SAT (.941) son lo menos bueno del ajuste. Las
cargas de satisfacción son moderadas y los factores correlacionan alto: ambos puntos pasan al 03 y 04.
