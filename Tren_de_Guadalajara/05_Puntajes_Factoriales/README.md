# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R`. Referencias: `CFA_Tren.inp` y `tren.inp` (`FSCORES`, `FSDETERMINACY`),
`lavPredict()` de `AFE_CFA.R` y láminas 14–21 del PDF.

**Objetivo:** calcular para cada usuario su puntaje en Acceso, Tarjeta y Confort, para usarlo en otros
análisis.

**Muestra:** como Mplus, se usan los **306 usuarios** con MLR y FIML (`missing = "fiml"`). Así todos
reciben puntaje aunque les falte algún ítem (ver [`06_FIML`](../06_FIML/)). Los marcadores son los del
`.inp`: `p5@1`, `p63@1` y `p75@1`.

## Paso a paso

1. **Puntajes centrados** (`Puntaje_tren_centrados.dat`). `lavPredict(method = "regression")`, el mismo
   método que usa Mplus. Tienen media 0. Coinciden con el PDF: id 10101 → −0.711, −0.225, 0.131.
2. **Determinación** (`FSDETERMINACY`). Es la correlación entre el puntaje estimado y el factor:
   √[diag(ΦΛ'Σ⁻¹ΛΦ) / diag(Φ)]. Da **Acceso .924, Tarjeta .959 y Confort .935**, igual que Mplus. Como
   son mayores que .90, los puntajes son confiables.
3. **Bartlett y pesos.** Como en `AFE_CFA.R`: `lavPredict(method = "Bartlett", fsm = TRUE)` da los pesos
   de cada ítem en el puntaje. Bartlett usa solo los ítems observados de cada factor, así que los
   104 usuarios que no respondieron `p63` ni `p64` quedan con `NA` en Tarjeta. El método de regresión sí
   les asigna puntaje, apoyándose en su correlación con los otros factores. Donde ambos existen,
   correlacionan .99 o más.
4. **Escala original** (`Puntaje_tren_originales.dat`). El `.inp` fija los interceptos en 0
   (`[p4@0 p5@0 ...]`) con carga 1 en el marcador, así el factor queda en la escala 1–10. En lavaan hay
   que **liberar las medias de los factores** (`acceso ~ 1`). Si se dejan en 0, el modelo implica media
   0 en todos los ítems y el ajuste se derrumba (χ² ≈ 1541). Medias estimadas: 7.75, 7.35 y 8.40 (PDF:
   7.75, 7.37, 8.39). Los puntajes difieren del PDF en la segunda decimal (10101: 7.20 vs 7.18) por
   diferencias numéricas entre lavaan y Mplus.
5. **Media ponderada (cálculo manual del PDF).** Para cada factor, media ponderada = Σ(λ · media del
   ítem) / Σλ, con λ estandarizadas: **7.643, 7.342 y 8.464**, idénticas al PDF. Luego
   `fs3 = puntaje centrado + media ponderada`.
6. **Descriptivos y correlaciones.** Los tres tipos de puntaje ordenan casi igual a los usuarios
   (r ≥ .95 entre versiones del mismo factor).

| Puntaje | Media | D.E. | Mín. | Máx. |
|---|---|---|---|---|
| fs_acceso / fs_tarjeta / fs_confort | 0 | 1.55 / 1.53 / 1.39 | −5.64 / −6.16 / −6.39 | 2.37 / 2.49 / 1.80 |
| fs2 (escala original) | 7.76 / 7.35 / 8.40 | 1.33 / 1.50 / 0.88 | 2.90 / 1.29 / 4.55 | 9.84 / 9.76 / 9.62 |
| fs3 (media ponderada) | 7.64 / 7.34 / 8.46 | 1.55 / 1.53 / 1.39 | 2.01 / 1.19 / 2.07 | 10.01 / 9.83 / 10.26 |

El Confort es la dimensión mejor evaluada y la Tarjeta la peor. Salidas: `output/puntajes_tren.csv` (un
renglón por usuario), `output/descriptivos_puntajes.csv` y `output/boxplot_puntajes_originales.png`.
