# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R` (todavía es un esqueleto). Estado: **⚠️ Parcial**.

## Qué traen los archivos

- Laboratorio 2: alfa de Cronbach (`alpha`, con datos y con covarianzas), KR-20 a mano y confiabilidad
  compuesta de Dillon-Goldstein con las cargas del AFC.
- **No hay nada de validez** (contenido, criterio, constructo, AVE, discriminante).

## Con la base (`PREP.dta`)

Sí. Alfa entre .77 y .90, confiabilidad compuesta entre .78 y .91 y AVE entre .51 y .75 en los 11
factores. Fornell-Larcker se cumple en todos (la AVE supera al r² más alto entre factores). **KR-20 no
aplica**: es para ítems 0/1 y estos van de 1 a 10.

## Qué falta

Un documento de validez (en `Tren_de_Guadalajara` se usó SEM06) y una **variable criterio** si se quiere
validez de criterio. Además, el Laboratorio 2 tiene un error: `alpha(covariance[5:6,5:6])` y
`alpha(covariance[7:11,7:11])` deberían ser `[5:8,5:8]` y `[9:11,9:11]`.

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
