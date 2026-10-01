# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R` (todavía es un esqueleto). Estado: **✅ Cubierto por los archivos**.

## Qué traen los archivos

- Los dos `.inp`: `SAVEDATA: SAVE = FS` (puntajes por regresión, como `lavPredict`). Ambos fijan los
  interceptos en 0 (`[x@0]`), que es la forma de obtener puntajes en la **escala original**.
- Laboratorio 2: `predict()`, Bartlett con pesos (`fsm = TRUE`) y gráficas por `parque`.
- Laboratorio 5: `predict()`, medias ponderadas con las cargas para pasarlos a la escala original y
  `t.test()` entre `parque == 1` y `parque == 2`.

## Con la base (`PREP.dta`)

Sí: los puntajes por regresión (centrados), en escala original (medias de los factores 6.42, 6.57 y 6.12)
y de Bartlett salen sin problema. Con FIML cada respondiente con al menos un ítem recibe puntaje
(7,814 en espacio público).

## Qué falta

La base **no trae `id` del respondiente** (se usa el número de fila) ni la variable `parque` de los
laboratorios; el equivalente es `espacio` (276 espacios).

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
