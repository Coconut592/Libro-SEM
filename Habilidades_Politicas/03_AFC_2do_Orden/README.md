# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R`. Referencias: Figura 1, Tabla 5 y Anexo 2 del capítulo (`HP BY HR* SA@1 AS II`) y
láminas 14–19 de la presentación (comandos `cfa` de segundo orden en R). **Es el modelo central del
capítulo.** Tiene la misma estructura de pasos que [`02_AFC`](../02_AFC/) para poder compararlos.

**Objetivo:** probar que las cuatro dimensiones de Ferris (HR, SA, AS, II) son manifestaciones de un factor
general, la **Habilidad Política (HP)**, con los mismos 15 ítems del AFC de primer orden.

## Paso a paso

1. **Datos.** 356 estudiantes, 15 ítems de 1 a 7, sin faltantes.
2. **Modelo.** Los factores de primer orden se miden con sus ítems (igual que en el AFC) y se agrega
   `HP =~ HR + SA + AS + II`. Las 6 correlaciones entre dimensiones se sustituyen por 4 cargas de HP.
   lavaan fija en 1 la primera carga de HP (la de HR); Mplus usa `SA@1`, y eso no cambia la solución
   estandarizada. Estimado por **ML**, como el capítulo.
3. **Cargas estandarizadas, disturbios y R².** Las cargas de los ítems son las del AFC de primer orden
   (.63 a .81). Todas las cargas de HP son significativas y **no hay casos Heywood**:

   | Dimensión | Carga en HP (E.E.) | Disturbio | R² (varianza que explica HP) | Tabla 5 del capítulo |
   |---|---|---|---|---|
   | HR | .824 (.029) | .322 | .68 | .824 |
   | SA | .933 (.028) | .130 | .87 | .933 |
   | AS | .949 (.026) | .100 | .90 | .949 |
   | II | .805 (.031) | .352 | .65 | .805 |

   **SA y AS casi no tienen varianza propia**: HP explica el 87% y el 90% de ellas. Para los ítems, la parte
   de su varianza que viaja por HP va de .28 (`HR1`) a .48 (`SA8`) y la propia de su dimensión de .04 a
   .23 (`output/varianza_items_via_HP.csv`).
4. **Ajuste** (criterios del capítulo y de Hu y Bentler, 1999):

   | χ² (gl) | χ²/gl | CFI | TLI | RMSEA [IC 90%] | SRMR |
   |---|---|---|---|---|---|
   | 246.604 (86), p < .001 | 2.87 | .931 | .915 | .072 [.062, .083] | .048 |

   Ajuste **aceptable**, como concluye el capítulo.

   > **Ojo con la cifra publicada.** El capítulo reporta χ² = 273.894 con 101 gl, CFI .926 y RMSEA .069.
   > Esos números son los de un modelo que incluye a `Genero` como variable adicional. Con los 15 ítems
   > el modelo tiene **86 gl** y los valores correctos son los de arriba (los de la lámina 19, columna R).
   > Ver [`00_Diagnostico`](../00_Diagnostico/).
5. **Normalidad, MLR y tratamiento ordinal.** Mardia rechaza la normalidad (ver `02_AFC`). La conclusión no
   cambia:

   | Estimador | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | ML (capítulo) | 246.6 (86) | .931 | .915 | .072 | .048 |
   | MLR (robusto) | 164.2 (86) | .948 | .937 | .062 | .048 |
   | WLSMV (ítems ordinales) | 267.9 (86) | .967 | .959 | .077 | .049 |

   Con WLSMV las cargas de los ítems suben en promedio .03 y las de HP quedan en .83, .94, .96 y .79.
6. **Comparación con el primer orden.** Con cuatro dimensiones el segundo orden **sí se puede contrastar**
   (4 cargas de HP sustituyen a 6 correlaciones: 2 gl más):

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR | AIC | BIC |
   |---|---|---|---|---|---|---|---|
   | Primer orden (4 correlacionados) | 246.5 (84) | .930 | .912 | .074 | .048 | 16447 | 16587 |
   | Segundo orden (HP) | 246.6 (86) | .931 | .915 | .072 | .048 | **16443** | **16575** |

   - **Δχ² = 0.14, 2 gl, p = .93:** el factor general explica las correlaciones entre dimensiones igual de
     bien que dejarlas libres. ΔCFI = +.001, ΔRMSEA = −.001. El AIC y el BIC prefieren el segundo orden.
   - Las correlaciones que implica HP difieren de las observadas en .01 como máximo.
7. **Índices de modificación** (solo para mirar). Los mismos que en el primer orden (MI de 17 a 19):
   `HR2 ~~ HR3`, `AS13 ~~ AS14` y `AS =~ SA7`. Ninguno es grande.
8. **Salidas.** `output/solucion_estandarizada_2do_orden.csv`, `comparacion_1er_2do_orden.csv`,
   `varianza_items_via_HP.csv` y `diagrama_2do_orden.png` (equivale a la Figura 1 del capítulo y a la 2 de
   la presentación).

## Lectura

- **El segundo orden se sostiene:** ajusta tan bien como el de primer orden y con menos parámetros. La
  Habilidad Política puede entenderse como un factor general (cargas de .81 a .95).
- **Pero el factor general es casi SA y AS.** Con cargas de .93 y .95 y disturbios de .13 y .10, estas dos
  dimensiones casi no se distinguen de HP. Coincide con el AFE, con la correlación SA–AS (.89) y con la
  validez discriminante ([`04_Confiabilidad_y_Validez`](../04_Confiabilidad_y_Validez/)).
- **Para el libro:** los números del ajuste que se citen deben ser los de este modelo (86 gl), no los de la
  Tabla 5.
