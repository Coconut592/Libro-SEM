# 06 · Invarianza factorial

Script: `Invarianza_Factorial.R`.

> **Sin referencia propia.** Se sigue la secuencia estándar de invarianza de medición (Meredith, 1993;
> Vandenberg y Lance, 2000): configural → métrica → escalar → estricta, con los criterios de Chen (2007),
> igual que en el Tren.

**Pregunta:** ¿las personas con pareja y las que no la tienen entienden igual los ítems? Si hay
invarianza, sus puntajes se pueden comparar (y también sus medias latentes).

## Por qué esta agrupación y sus limitaciones

El `.dta` no trae ninguna variable de grupo (sexo, edad, municipio). La única que se puede construir es
la misma idea de "responde tarjeta" del Tren: **si la persona contestó los ítems de pareja** (`a1`–`a4`)
**o no**: **Con pareja** (223) contra **Sin pareja** (71, no contestan ninguno de los cuatro).

1. **Solo algunos factores.** El factor pareja no existe para quien no contestó sus ítems, así que se
   excluye. Y con 71 personas en el grupo pequeño **no todos los modelos son estimables**: el de los 6
   factores de violencia y clima da en "Sin pareja" una solución **inadmisible** (varianzas negativas).
   Se usan dos modelos:
   - **A. Satisfacción:** 5 dominios (familia, economía, vida social, bienestar personal y trabajo), 20
     ítems.
   - **B. Institucional:** cohesión vecinal, confianza en las autoridades y desempeño del gobierno, 12
     ítems.
2. **El significado del grupo es un supuesto.** "No contestó pareja" casi seguro es "no tiene pareja",
   pero el `.dta` no lo dice. Además quien no tiene pareja deja en blanco los ítems de familia con más
   frecuencia (11–14% contra ~1%; ver [`00_Exploracion`](../00_Exploracion/)).
3. **Tamaño del grupo.** Con 71 personas, el grupo pequeño no llega al mínimo usual de unos 100 por
   grupo. Con ese tamaño solo serían detectables diferencias de medias latentes de unas 0.4–0.5
   desviaciones estándar o más (el error estándar es de ~0.14–0.19 D.E.).
4. **Ajuste configural en el grupo pequeño.** El modelo A ajusta de forma marginal en "Sin pareja" (CFI
   = .90, RMSEA = .10), así que **sus resultados son más débiles** que los del B.
5. **No es una comparación sustantiva.** Tener o no pareja no es la variable de grupo que se querría
   (sexo, municipio...). Si se consigue, se cambia `guerrero$grupo` en una línea. El folio tampoco sirve:
   se relaciona con las respuestas, pero no se sabe qué significa (ver [`00_Exploracion`](../00_Exploracion/)).

## Paso a paso

1. **Grupo.** `grupo = "Sin pareja"` si `a1`–`a4` son todos `NA`. El primer nivel (Con pareja) es la
   referencia.
2. **Ajuste por grupo** (requisito previo), con los 294 (FIML) y MLR:

   | Modelo | Grupo | N | χ² esc. (gl) | CFI rob. | TLI rob. | RMSEA rob. | SRMR |
   |---|---|---|---|---|---|---|---|
   | A. Satisfacción | Con pareja | 223 | 254.1 (160) | .958 | .950 | .060 | .047 |
   | | Sin pareja | 71 | 290.3 (160) | **.902** | .884 | **.101** | .075 |
   | B. Institucional | Con pareja | 223 | 93.9 (51) | .975 | .968 | .066 | .037 |
   | | Sin pareja | 71 | 90.0 (51) | .942 | .925 | .098 | .070 |
3. **Modelos anidados** con `group = "grupo"` y `group.equal`: *configural* (misma estructura, todo
   libre), *métrica* (`"loadings"`: cargas iguales), *escalar* (`+ "intercepts"`: interceptos iguales; es
   lo que permite comparar medias latentes) y *estricta* (`+ "residuals"`: varianzas residuales iguales).
4. **Comparación.** Diferencia de χ² escalada (`lavTestLRT`, Satorra-Bentler) y cambios en CFI, RMSEA y
   SRMR. Chen (2007) acepta un nivel si ΔCFI ≥ −.010 y ΔRMSEA ≤ .015.

   **A. Satisfacción (5 dominios, 20 ítems)**

   | Modelo | χ² esc. (gl) | CFI rob. | RMSEA rob. | SRMR | ΔCFI | ΔRMSEA | Δχ² (gl), p |
   |---|---|---|---|---|---|---|---|
   | Configural | 535.7 (320) | .942 | .072 | .054 | — | — | — |
   | Métrica | 539.9 (335) | .942 | .070 | .060 | .000 | −.002 | 11.7 (15), p = .70 |
   | Escalar | 559.9 (350) | .942 | .069 | .060 | −.001 | −.001 | 18.7 (15), p = .23 |
   | Estricta | 604.2 (370) | .931 | .073 | .061 | **−.010** | +.004 | 39.5 (20), **p = .006** |

   **B. Institucional (3 factores, 12 ítems)**

   | Modelo | χ² esc. (gl) | CFI rob. | RMSEA rob. | SRMR | ΔCFI | ΔRMSEA | Δχ² (gl), p |
   |---|---|---|---|---|---|---|---|
   | Configural | 184.1 (102) | .967 | .075 | .045 | — | — | — |
   | Métrica | 193.3 (111) | .968 | .072 | .049 | .000 | −.003 | 8.4 (9), p = .50 |
   | Escalar | 198.8 (120) | .970 | .067 | .050 | +.002 | −.005 | 4.7 (9), p = .86 |
   | Estricta | 205.6 (132) | .967 | .066 | .051 | −.002 | −.001 | 12.5 (12), p = .41 |
5. **¿Qué parámetro rompe la estricta del modelo A?** `lavTestScore`: las varianzas residuales de `a19`
   (X² = 14.2), `a10` (9.4), `a24` (8.9), `a22` (8.3) y `a18` (7.7), y el intercepto de `a17` (8.4). (Con
   MLR es la prueba score ordinaria: es orientativa.)
6. **Medias latentes** (con la invarianza escalar, "Sin pareja" menos "Con pareja"; `d` = diferencia en
   desviaciones estándar del factor en el grupo de referencia):

   | Modelo | Factor | Diferencia (E.E.) | p | d |
   |---|---|---|---|---|
   | A | familia | +0.14 (0.25) | .57 | .09 |
   | | economia | −0.32 (0.25) | .20 | −.19 |
   | | social | −0.11 (0.33) | .75 | −.05 |
   | | personal | −0.40 (0.25) | .11 | −.30 |
   | | trabajo | +0.01 (0.21) | .98 | .00 |
   | B | cohesion | +0.26 (0.29) | .37 | .13 |
   | | confianza | +0.34 (0.31) | .26 | .17 |
   | | desempeno | +0.39 (0.28) | .18 | .20 |

   Ninguna diferencia es significativa.

## Conclusión

- **Modelo B (institucional): se sostiene toda la secuencia, incluida la estricta** (todas las Δχ² con
  p > .40, ΔCFI ≤ .002). Cohesión, confianza y desempeño se miden igual con y sin pareja.
- **Modelo A (satisfacción): se sostienen la métrica y la escalar**; la estricta no (Δχ² p = .006 y ΔCFI
  = −.010, justo en el límite de Chen). Los ítems miden igual y sus interceptos son comparables; solo
  difieren algunas varianzas residuales (`a19`, `a10`, `a24`...). Para comparar medias latentes basta
  con la escalar.
- **Medias latentes:** con la invarianza escalar establecida, quien no tiene pareja **no difiere
  significativamente** en ninguno de los 8 factores (|d| ≤ .31), aunque con 71 personas solo se detectarían
  diferencias grandes.

Por las limitaciones de arriba (grupo pequeño, ajuste marginal del modelo A en ese grupo y un grupo
definido por un dato faltante), este ejercicio muestra **cómo** se hace una invarianza; debe leerse con
cautela como evidencia sobre las personas de Guerrero.

Salidas en `output/`: `ajuste_invarianza_satisfaccion.csv`, `ajuste_invarianza_institucional.csv` y
`medias_latentes_sin_vs_con_pareja.csv`.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance.
  *Structural Equation Modeling, 14*(3), 464–504.
- Meredith, W. (1993). Measurement invariance, factor analysis and factorial invariance.
  *Psychometrika, 58*(4), 525–543.
- Vandenberg, R. J., & Lance, C. E. (2000). A review and synthesis of the measurement invariance
  literature. *Organizational Research Methods, 3*(1), 4–70.
