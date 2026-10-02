# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R`. Referencias: `SAVEDATA: SAVE = FS` de los dos `.inp` y Laboratorios 2 y 5.

**Objetivo:** un puntaje por respondiente en cada factor (espacio público, colonia y G) para usarlo en otros
análisis. Se estima con MLR y FIML: cada respondiente con al menos un ítem del bloque recibe puntaje
(7,814 en espacio público, 8,239 en colonia y 7,805 en G).

## Paso a paso

1. **Centrados** (`SAVE = FS`). `lavPredict(method = "regression")`, el método de Mplus; media 0.
2. **Determinación** (`FSDETERMINACY`): .92 a .96 en los 11 factores (el menor, Participación .916), todos
   ≥ .90: puntajes confiables.
3. **Bartlett y pesos** (Lab 2, `fsm = TRUE`). Bartlett usa solo los ítems observados del factor, así que
   40, 111 y 101 respondientes quedan con `NA` en calificación, seguridad y actividades. Con regresión
   todos tienen puntaje; donde ambos existen correlacionan .95 a .997 (mismo factor).
4. **Escala original** (los `[x@0]` de los `.inp`). Interceptos en 0, marcador con carga 1 y **medias de los
   factores libres** (`F ~ 1`); si se dejan en 0 el modelo implicaría media 0 en todos los ítems. Medias
   (marcadores `b11`/`b18`/`b22`): 6.54, 6.57 y 6.12 en espacio público; 5.53, 5.74, 6.96, 6.04 y 6.13 en
   colonia; 5.50, 2.68 y 7.04 en G. Los factores de G que usan ítems `g06`–`g08` van de 1 a 10 con
   "mayor = más de acuerdo con conductas incívicas" (promedio 2.7).
5. **Media ponderada** (Lab 5): Σ(λ · media del ítem) / Σλ, sumada al puntaje centrado (columnas `fsm_*`).
6. **Entre espacios.** Los laboratorios comparan `parque == 1` con `parque == 2`; la base no trae `parque`.
   El equivalente es el espacio: se guarda el promedio por espacio (266 con datos de espacio público; 10 sin
   el bloque B). Como ejemplo, la calificación del espacio es mayor en Veracruz (6.70) que en México (6.05),
   t de Welch = −6.96, p < .001.

Los tres tipos de puntaje ordenan casi igual (en calificación, r = .999 entre versiones).

Salidas: `puntajes_PREP.csv` (un renglón por respondiente; `id` es el número de fila porque la base no trae
identificador), `puntajes_por_espacio.csv`, `descriptivos_puntajes.csv`, `determinacion.csv` y
`boxplot_puntajes_originales.png`.
