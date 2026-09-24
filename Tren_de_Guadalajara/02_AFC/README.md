# 02 · Análisis Factorial Confirmatorio (AFC)

Script: `AFC.R`. Referencias: análisis confirmatorio de `AFE_CFA.R`, `CFA_Tren.inp`/`tren.inp` y láminas
8–13 del PDF.

**Objetivo:** probar el modelo de 3 factores correlacionados que sugiere el AFE, con 10 ítems (sin `p72`
ni `p8`) y los 170 registros completos.

## Paso a paso

1. **Datos.** Registros completos y `tren[, -c(1, 9, 13)]` quita `id`, `p72` y `p8`.
2. **AFC con `sem`.** Como en la referencia: `specifyModel()` con la sintaxis `Factor->ítem, nombre,
   valor inicial`. Las varianzas de los factores se fijan en 1 (factores estandarizados). Se ajusta con
   la matriz de covarianzas (`S`, `N`) y con los datos, y se revisan `stdCoef()` y `summary()`.
   - `sem` y `lavaan` tienen una función `sem()`. Por eso se escribe `sem::sem()`, y al cargar `lavaan`
     después, `sem()` sin prefijo es la de lavaan.
3. **AFC con `lavaan`.** Mismo modelo con `=~` ("se mide por"): `Acceso =~ p4 + p5 + p61 + p62`, etc.
   lavaan fija en 1 la carga del primer ítem de cada factor. Se estima por ML.
4. **Cargas estandarizadas** (`standardizedSolution()`). Todas son significativas y mayores que .60:

   | Acceso | | Tarjeta | | Confort | |
   |---|---|---|---|---|---|
   | p4 | .64 | p63 | .83 | p71 | .66 |
   | p5 | .81 | p64 | .95 | p73 | .72 |
   | p61 | .89 | | | p74 | .86 |
   | p62 | .67 | | | p75 | .96 |

   Correlaciones entre factores: Acceso–Tarjeta .45, Acceso–Confort .29, Tarjeta–Confort .32.
5. **Bondad de ajuste** (criterios de Hu y Bentler, 1999):

   | χ² (gl) | CFI | TLI | RMSEA [IC 90%] | SRMR |
   |---|---|---|---|---|
   | 135.8 (32), p < .001 | .895 | .852 | .138 [.115, .163] | .097 |

   Las cargas son altas, pero **el ajuste global es pobre**: CFI < .90 y RMSEA > .08.
6. **Normalidad y MLR.** La prueba de Mardia rechaza la normalidad multivariada (asimetría y curtosis,
   p < .001), porque los ítems 1–10 están cargados hacia calificaciones altas. Por eso el `.inp` usa
   `ESTIMATOR = MLR`. Con MLR: χ² escalada = 109.6, CFI robusto = .901, RMSEA robusto = .133.
7. **Salidas.** `output/solucion_estandarizada_AFC.csv` y `output/diagrama_AFC.png` (`semPaths`).

> Con los 306 casos y FIML (como el PDF) el ajuste mejora: CFI = .920, RMSEA = .102, SRMR = .069. Ver
> [`06_FIML`](../06_FIML/).
