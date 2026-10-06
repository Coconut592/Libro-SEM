# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R`. Referencias: Figura 1, Tabla 5 y Anexo 2 del capítulo (`HP BY HR* SA@1 AS II`) y
láminas 14–19 de la presentación (comandos `cfa` de segundo orden en R). **Es el modelo central del
capítulo.**

**Objetivo:** probar que las cuatro dimensiones de Ferris (HR, SA, AS, II) son manifestaciones de un factor
general, la **Habilidad Política (HP)**. El capítulo lo justifica así: las puntuaciones de cada dimensión
dependen del factor general, pero cada una conserva un error propio (la parte que HP no explica).

## Paso a paso

1. **Datos.** 356 estudiantes, 15 ítems, estimación por ML (como el `ESTIMATOR=ML` del capítulo).
2. **Modelo.** Los factores de primer orden se miden con sus ítems (igual que en el AFC) y se agrega
   `HP =~ HR + SA + AS + II`. Las 6 correlaciones entre dimensiones se sustituyen por 4 cargas de HP.
   lavaan fija en 1 la primera carga de HP (la de HR); Mplus usa `SA@1`. Eso no cambia la solución
   estandarizada.
3. **Solución estandarizada.** Todas las cargas de HP son significativas y **no hay casos Heywood**
   (todas las varianzas residuales de las dimensiones son positivas):

   | Dimensión | Carga en HP (E.E.) | Disturbio | R² (varianza que explica HP) | Tabla 5 del capítulo |
   |---|---|---|---|---|
   | HR | .824 (.029) | .322 | .68 | .824 |
   | SA | .933 (.028) | .130 | .87 | .933 |
   | AS | .949 (.026) | .100 | .90 | .949 |
   | II | .805 (.031) | .352 | .65 | .805 |

   Las cuatro cargas coinciden con las del capítulo. **SA y AS casi no tienen varianza propia**: HP explica
   el 87% y el 90% de ellas. En la práctica, SA y AS son el factor general.

   Para los ítems, la parte de su varianza que viaja por HP (carga del ítem × carga de la dimensión, al
   cuadrado) va de .28 (`HR1`) a .48 (`SA8`), y la propia de su dimensión de .04 a .23
   (`output/varianza_items_via_HP.csv`). Los ítems de SA y AS son casi todo factor general; los de II y HR
   conservan más varianza de dimensión.
4. **Ajuste** (criterios del capítulo, Tabla 4):

   | χ² (gl) | χ²/gl | CFI | TLI | RMSEA [IC 90%] | SRMR | BIC |
   |---|---|---|---|---|---|---|
   | 246.604 (86), p < .001 | 2.87 | .931 | .915 | .072 [.062, .083] | .048 | 16575 |

   Cumple los criterios (CFI y TLI > .90, RMSEA ≤ .08, SRMR < .08, χ²/gl < 3), como concluye el capítulo.
   Con MLR (los datos no son normales): χ² escalada = 164.2, CFI = .948, TLI = .937, RMSEA = .062.

   > **Ojo con la cifra publicada.** El capítulo reporta χ² = 273.894 con 101 gl, CFI .926 y RMSEA .069.
   > Esos números son los de un modelo que incluye a `Genero` como variable adicional. Con los 15 ítems
   > el modelo tiene **86 gl**, y los valores correctos son los de la tabla de arriba (los que trae la
   > lámina 19, columna R). Ver [`00_Diagnostico`](../00_Diagnostico/).
5. **Comparación con el primer orden.** Con cuatro dimensiones el segundo orden **sí se puede contrastar**
   (en el Tren, con tres factores, quedaba justamente identificado): 4 cargas de HP sustituyen a 6
   correlaciones, 2 gl más.

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR | AIC | BIC |
   |---|---|---|---|---|---|---|---|
   | Primer orden (4 correlacionados) | 246.5 (84) | .930 | .912 | .074 | .048 | 16447 | 16587 |
   | Segundo orden (HP) | 246.6 (86) | .931 | .915 | .072 | .048 | **16443** | **16575** |

   - **Δχ² = 0.14, 2 gl, p = .93.** El factor general explica las correlaciones entre dimensiones **igual de
     bien** que dejarlas libres. ΔCFI = +.001 y ΔRMSEA = −.001.
   - El segundo orden es más sencillo y el AIC y el BIC lo prefieren.
   - Las correlaciones entre dimensiones que implica HP (producto de sus cargas) difieren de las
     observadas en .01 como máximo (SA–AS: .88 observada contra .89 implícita).

## Lectura

- **El segundo orden se sostiene:** ajusta tan bien como el de primer orden y con menos parámetros. La
  Habilidad Política puede entenderse como un factor general (las cargas son de .81 a .95).
- **Pero el factor general es casi SA y AS.** Con cargas de .93 y .95, y disturbios de .13 y .10, el
  segundo orden no distingue bien a estas dos dimensiones del propio HP. Coincide con el AFE (que las
  junta), con la correlación SA–AS (.89) y con la validez discriminante
  ([`04_Confiabilidad_y_Validez`](../04_Confiabilidad_y_Validez/)).
- **Para el libro:** el capítulo es un buen ejemplo didáctico del AFC de 2.º orden. Los números del ajuste
  que se citen deben ser los de este modelo (86 gl), no los de la Tabla 5.

## Salidas

`output/solucion_estandarizada_2do_orden.csv`, `comparacion_1er_2do_orden.csv`,
`varianza_items_via_HP.csv` y `diagrama_2do_orden.png` (equivale a la Figura 1 del capítulo y a la 2 de la
presentación, con las cargas estandarizadas).
