# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R`. **Sin referencia propia** (en el Tren se usó `CFA_2doOrden.inp`, `G BY F1 F2 F3`).

**Objetivo:** plantear un factor general, **G = Satisfacción con la vida**, que explica lo que tienen en
común los seis dominios de `a1`–`a24`: pareja, familia, economía, vida social, bienestar personal y
trabajo.

**Por qué solo la satisfacción.** Los seis dominios se relacionan entre sí (correlaciones de .17 a .65,
todas positivas, ver [`02_AFC`](../02_AFC/)). En cambio, los seis factores de violencia y clima social
tienen correlaciones de signos mixtos (−.24 a .52): confianza–desempeño (.52) e inseguridad–riesgo
(.52) son pares aislados, y un factor de segundo orden con dos factores de primer orden no está
identificado. No forman un constructo general.

## Paso a paso

1. **Datos.** Las 294 personas con FIML (ver [`07_FIML`](../07_FIML/)): 71 no contestan los ítems de
   pareja y 202 de 294 contestan los 24 ítems.
2. **Modelo.** Los factores de primer orden se miden con sus ítems (igual que en el AFC) y se agrega
   `G =~ pareja + familia + economia + social + personal + trabajo`. Las 15 correlaciones entre dominios
   se sustituyen por 6 cargas de G. lavaan fija en 1 la primera carga de G (pareja) para darle escala.
3. **Solución estandarizada.** Todas las cargas de G son significativas y las varianzas residuales de
   los dominios (disturbios) son positivas: **no hay casos Heywood**.

   | Dominio | Carga en G (E.E.) | Disturbio | R² (varianza que explica G) |
   |---|---|---|---|
   | pareja | .39 (.12) | .85 | .16 |
   | familia | .45 (.09) | .80 | .20 |
   | economia | .75 (.06) | .44 | .56 |
   | social | .72 (.05) | .48 | .52 |
   | personal | .81 (.05) | .34 | .66 |
   | trabajo | .74 (.05) | .45 | .55 |

   G explica más de la mitad de economía, vida social, bienestar personal y trabajo, pero solo el 16% de
   pareja y el 20% de familia: son dominios relacionales que dependen menos de la satisfacción general.
4. **Comparación con el primer orden.** A diferencia del Tren (3 factores: el segundo orden quedaba
   justamente identificado y su ajuste era idéntico), aquí **sí se puede contrastar**: 6 cargas de G
   sustituyen a 15 correlaciones, y el modelo tiene 9 gl más.

   | Modelo | χ² esc. (gl) | CFI rob. | TLI rob. | RMSEA rob. | SRMR | AIC | BIC |
   |---|---|---|---|---|---|---|---|
   | Primer orden (6 correlacionados) | 381.0 (237) | .957 | .950 | .055 | .047 | **24103** | 24423 |
   | Segundo orden (G) | 409.1 (246) | .951 | .945 | .058 | .068 | 24125 | 24412 |
   | Segundo orden + cov. pareja–familia | 400.3 (245) | .954 | .948 | .056 | .057 | 24113 | **24404** |

   - **Diferencia de χ² escalada** (Satorra-Bentler, por usar MLR): primer contra segundo orden,
     Δχ² = 28.9, 9 gl, **p < .001**. La prueba **rechaza** que G explique todas las correlaciones.
   - **Reglas de Chen (2007):** ΔCFI = −.007 (se acepta si es ≥ −.010) y ΔRMSEA = +.003 (se acepta si
     es ≤ .015). Se pensaron para comparar modelos de invarianza y aquí se usan como regla práctica. Por
     ellas G es **aceptable**. El BIC prefiere el segundo orden y el AIC el de primer orden.

   Con un N de 294, la chi-cuadrada detecta diferencias pequeñas; el modelo con G es más sencillo y
   ajusta bien, pero no es perfecto.
5. **¿De dónde viene la diferencia?** De **pareja–familia**: correlacionan .40 y G implica .18 (el
   producto .39 × .45). Es el mayor índice de modificación de las covarianzas entre disturbios (12.2).
   Se probó (de forma exploratoria, no planeada de antemano) agregar esa covarianza:
   - Δχ² = 6.9, 1 gl, p = .009. El CFI sube a .954 y el BIC es el menor de los tres (24404).
   - La covarianza estandarizada es .30 (E.E. .11) y las cargas de G casi no cambian (.36, .43, .74,
     .73, .81, .75).

   Pareja y familia comparten algo más que G. Como es un parámetro agregado **mirando los datos**, se
   reporta como hallazgo y no como modelo final.
6. **Salidas.** `output/solucion_estandarizada_2do_orden.csv`, `output/comparacion_1er_2do_orden.csv` y
   `output/diagrama_2do_orden.png` (`semPaths`, con las etiquetas de las cargas escalonadas para que no se
   encimen).

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance.
  *Structural Equation Modeling, 14*(3), 464–504.
