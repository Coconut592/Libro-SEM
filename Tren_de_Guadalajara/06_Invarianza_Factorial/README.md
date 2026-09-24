# 06 · Invarianza factorial

Script: `Invarianza_Factorial.R`.

> **Este ejercicio no viene en los archivos de referencia** (`AFE_CFA.R`, los `.inp` ni los PDF). Se
> sigue la secuencia estándar de invarianza de medición (Meredith, 1993; Vandenberg y Lance, 2000):
> configural → métrica → escalar → estricta, con los criterios de Chen (2007).

**Pregunta:** ¿los usuarios que respondieron las preguntas de la tarjeta y los que no las respondieron
entienden igual los ítems de Acceso y Confort? Si hay invarianza, sus puntajes se pueden comparar.

## Por qué esta agrupación y sus limitaciones

El `.dta` no trae ninguna variable de grupo (sexo, línea, estación). La única que se puede construir es
**responde tarjeta** (respondió `p63` o `p64`; 202 casos) contra **no responde tarjeta** (104 casos).

1. **Solo 2 factores.** El factor Tarjeta no existe para quien no respondió sus ítems, así que la
   invarianza se prueba solo en **Acceso y Confort** (8 ítems), no en el modelo completo.
2. **El significado del grupo es un supuesto.** "No respondió" podría significar "no usa tarjeta" o
   "no contestó". El `.dta` no permite distinguirlo.
3. **Tamaño del grupo.** Con 104 casos, el grupo pequeño apenas llega al mínimo usual de unos 100 por
   grupo.
4. **Modelo configural débil.** Invarianza supone que el modelo base ajusta bien en cada grupo. Aquí
   el ajuste es limitado (RMSEA ≥ .11), así que **los resultados son ilustrativos**.

## Paso a paso

1. **Grupo.** `grupo = "No responde tarjeta"` si `p63` y `p64` son `NA`.
2. **Modelo.** `acceso =~ p4 + p5 + p61 + p62` y `confort =~ p71 + p73 + p74 + p75`, con los 306
   usuarios, FIML y MLR (como en Mplus).
3. **Ajuste por grupo** (requisito previo):

   | Grupo | N | CFI rob. | TLI rob. | RMSEA rob. | SRMR |
   |---|---|---|---|---|---|
   | No responde tarjeta | 104 | .914 | .873 | .113 | .059 |
   | Responde tarjeta | 202 | .899 | .851 | .147 | .088 |

4. **Modelos anidados** con `group = "grupo"` y `group.equal`:
   - *Configural*: misma estructura, todo libre.
   - *Métrica*: `"loadings"`, cargas iguales.
   - *Escalar*: `+ "intercepts"`, interceptos iguales; es lo que permite comparar medias latentes.
   - *Estricta*: `+ "residuals"`, varianzas residuales iguales.
5. **Comparación.** Diferencia de χ² escalada (`lavTestLRT`, Satorra-Bentler) y cambios en CFI y RMSEA.
   Chen (2007) acepta un nivel si ΔCFI ≥ −.010 y ΔRMSEA ≤ .015.

   | Modelo | χ² esc. (gl) | CFI rob. | RMSEA rob. | SRMR | ΔCFI | Δχ² (gl), p |
   |---|---|---|---|---|---|---|
   | Configural | 131.0 (38) | .903 | .137 | .078 | — | — |
   | Métrica | 140.6 (44) | .896 | .131 | .095 | −.007 | 10.6 (6), p = .101 |
   | Escalar | 157.9 (50) | .887 | .128 | .098 | −.008 | 16.7 (6), p = .010 |
   | Estricta | 188.4 (58) | .859 | .133 | .105 | −.029 | 29.6 (8), p < .001 |

6. **Parámetros problemáticos** (`lavTestScore` sobre el escalar). Los interceptos de `p62` (máquina de
   fichas) y `p74` (temperatura) son los que más difieren entre grupos, junto con la carga de `p75`.

## Conclusión

- **Métrica: se sostiene** con los dos criterios. Las cargas de Acceso y Confort son iguales en ambos
  grupos.
- **Escalar: evidencia mixta.** ΔCFI (−.008) la acepta, pero la χ² la rechaza (p = .010). Los ítems
  responsables son `p62` y `p74`. Antes de comparar medias latentes convendría liberar esos interceptos
  (invarianza parcial).
- **Estricta: no se sostiene.** ΔCFI = −.029.

Por las limitaciones de arriba, sobre todo el ajuste configural débil y un grupo definido por un dato
faltante, este ejercicio muestra **cómo** se hace una invarianza. No debe usarse como evidencia sustantiva
sobre los usuarios del tren.

Salida: `output/ajuste_invarianza.csv`.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance.
  *Structural Equation Modeling, 14*(3), 464–504.
- Meredith, W. (1993). Measurement invariance, factor analysis and factorial invariance.
  *Psychometrika, 58*(4), 525–543.
- Vandenberg, R. J., & Lance, C. E. (2000). A review and synthesis of the measurement invariance
  literature. *Organizational Research Methods, 3*(1), 4–70.
