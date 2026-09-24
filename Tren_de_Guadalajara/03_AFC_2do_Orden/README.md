# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R`. Referencia: `CFA_2doOrden.inp` (`G BY F1 F2 F3;`).

**Objetivo:** plantear un factor general, **G = Satisfacción con el servicio**, que explica lo que tienen
en común Acceso, Tarjeta y Confort.

## Paso a paso

1. **Datos.** Los mismos del AFC: 170 registros completos y 10 ítems.
2. **Modelo.** Los factores de primer orden se miden igual que en el AFC y se agrega
   `G =~ Acceso + Tarjeta + Confort`, el equivalente a `G BY F1 F2 F3;` en Mplus. Las correlaciones
   entre factores se sustituyen por las cargas de G. lavaan fija en 1 la primera carga de G para darle
   escala, igual que Mplus.
3. **Solución estandarizada** (como `OUTPUT: STDYX`):

   | | Carga en G | Varianza residual (disturbio) |
   |---|---|---|
   | Acceso | .64 | .60 |
   | Tarjeta | .71 | .50 |
   | Confort | .45 | .80 |

   Todas las cargas son significativas y las varianzas residuales son positivas: **no hay casos
   Heywood**. G explica el 40%, 50% y 20% de la varianza de Acceso, Tarjeta y Confort.
4. **Comparación con el primer orden.** El ajuste es **idéntico** (χ² = 135.8, gl = 32, CFI = .895,
   RMSEA = .138). No es un error: con **tres** factores de primer orden, el segundo orden está justamente
   identificado (3 cargas en lugar de 3 correlaciones). Los datos no pueden distinguir un modelo del
   otro, así que elegir G es una decisión teórica. Con cuatro o más factores de primer orden sí se
   podría probar.
5. **Salidas.** `output/solucion_estandarizada_2do_orden.csv` y `output/diagrama_2do_orden.png`.
