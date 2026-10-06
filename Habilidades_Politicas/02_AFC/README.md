# 02 · Análisis Factorial Confirmatorio (AFC) de primer orden

Script: `AFC.R`. Referencias: Tabla 5 y Anexo 2 del capítulo (sintaxis de Mplus con `ESTIMATOR = ML`) y
láminas 16–19 de la presentación (el mismo modelo en R).

**Objetivo:** probar el modelo de **4 factores correlacionados** de Ferris con los 15 ítems de la base:
Habilidad en redes (HR, 5 ítems), Sinceridad aparente (SA, 3), Astucia social (AS, 4) e Influencia
interpersonal (II, 3). Es el modelo final del capítulo, después de quitar `HR5`, `AS12` e `II15`. El primer
modelo (18 ítems) no se puede correr: la base no trae esos ítems (ver [`00_Diagnostico`](../00_Diagnostico/)).

## Paso a paso

1. **Datos.** 356 estudiantes, 15 ítems de 1 a 7, sin faltantes.
2. **Modelo.** `HR =~ HR1 + HR2 + HR3 + HR4 + HR6`, etc., estimado por **ML** como en Mplus. lavaan fija en
   1 la primera carga de cada factor y deja libres las covarianzas entre factores.
3. **Cargas estandarizadas.** Todas significativas (p < .001), entre **.63 y .81**:

   | HR | | SA | | AS | | II | |
   |---|---|---|---|---|---|---|---|
   | `HR1` | .65 | `SA7` | .72 | `AS10` | .66 | `II16` | .73 |
   | `HR2` | .75 | `SA8` | .74 | `AS11` | .69 | `II17` | .79 |
   | `HR3` | .76 | `SA9` | .64 | `AS13` | .63 | `II18` | .81 |
   | `HR4` | .71 | | | `AS14` | .66 | | |
   | `HR6` | .67 | | | | | | |

   Coinciden con la Tabla 5 del capítulo, salvo que en la tabla `AS10`, `AS11` y `AS13` traen los valores
   de otro ítem (ver [`00_Diagnostico`](../00_Diagnostico/), hallazgo 2).

   **Correlaciones entre factores:**

   | | HR | SA | AS |
   |---|---|---|---|
   | SA | .77 | | |
   | AS | .78 | **.89** | |
   | II | .66 | .75 | .77 |

   Son altas. Con SA–AS = .89 la **validez discriminante es dudosa**: los dos factores casi no se
   distinguen. Esto anticipa el factor general del segundo orden.
4. **Ajuste** (criterios del capítulo, Tabla 4, y de Hu y Bentler, 1999):

   | χ² (gl) | χ²/gl | CFI | TLI | RMSEA [IC 90%] | SRMR |
   |---|---|---|---|---|---|
   | 246.5 (84), p < .001 | 2.93 | .930 | .912 | .074 [.063, .084] | .048 |

   Ajuste **aceptable**: CFI y TLI > .90, SRMR < .08, χ²/gl < 3. El RMSEA (.074) es aceptable (< .08), pero
   no bueno (> .06), y CFI y TLI no llegan a .95.
5. **Normalidad, MLR y tratamiento ordinal.** La prueba de Mardia rechaza la normalidad multivariada
   (p < .001; asimetría hasta −1.5). Con tres estimaciones la conclusión no cambia:

   | Estimador | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | ML (capítulo) | 246.5 (84) | .930 | .912 | .074 | .048 |
   | MLR (robusto) | 164.3 (84) | .947 | .933 | .063 | .048 |
   | WLSMV (ítems ordinales) | 276.4 (84) | .965 | .956 | .080 | .049 |

   Con MLR el ajuste mejora (el rechazo de normalidad inflaba la χ²). Tratando los ítems como ordinales
   las cargas suben en promedio .03.
6. **¿Cuatro factores, tres o uno?** El AFE sugiere 3 (SA y AS juntos). Se compara con modelos anidados:

   | Modelo | χ² (gl) | CFI | RMSEA | SRMR | AIC | BIC |
   |---|---|---|---|---|---|---|
   | **4 factores (Ferris)** | 246.5 (84) | .930 | .074 | .048 | **16447** | 16587 |
   | 3 factores (SA + AS juntos) | 259.1 (87) | .926 | .075 | .049 | 16454 | **16581** |
   | 1 factor | 473.0 (90) | .835 | .109 | .066 | 16662 | 16778 |

   - 4 contra 3: Δχ² = 12.6, 3 gl, **p = .006** (el de 4 ajusta mejor), pero el CFI casi no cambia y el
     **BIC prefiere el de 3**.
   - Un solo factor ajusta claramente peor: **no es unidimensional**.
   - La estructura de 4 factores se sostiene, pero SA y AS están muy cerca.
7. **Índices de modificación** (solo para mirar; no se modifica el modelo). Los mayores (MI de 17 a 19):
   `HR2 ~~ HR3`, `AS13 ~~ AS14` (residuos correlacionados dentro del mismo factor) y `AS =~ SA7` (carga
   cruzada). Ninguno es grande. El capítulo tampoco usa los índices: reespecifica quitando ítems.
8. **Salidas.** `output/solucion_estandarizada_AFC.csv`, `comparacion_4_3_1_factores.csv` y
   `diagrama_AFC.png` (`semPaths`).

## Qué replica del capítulo y qué no

- **Sí:** las cargas de la Tabla 5 (con el orden de columnas de la base) y las correlaciones entre ítems de
  la lámina 15.
- **No se puede:** el AFC de 18 ítems (Tabla 3).
- El ajuste publicado en Mplus (χ² = 273.9, 101 gl) incluye a `Genero` en el modelo; el de este AFC (sin
  ella) es el correcto. Ver [`00_Diagnostico`](../00_Diagnostico/).
