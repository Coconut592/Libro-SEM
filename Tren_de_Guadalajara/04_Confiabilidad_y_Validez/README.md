# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R`. Referencias: sección de alfa de Cronbach y confiabilidad compuesta
de Dillon-Goldstein de `AFE_CFA.R`, y la lámina 12 del PDF (alfas).

> **Qué se agregó:** las referencias solo traen **confiabilidad**. Para la **validez** se agregan la
> validez convergente (AVE) y la discriminante (criterio de Fornell-Larcker, 1981), los criterios
> estándar para un AFC.

## Paso a paso

1. **Datos y modelo.** El AFC de `02_AFC` (170 completos, ML).
2. **Alfa de Cronbach.**
   - *Con la covarianza del modelo*, como en la referencia: `fitted(fit)$cov` es la matriz que reproduce
     el AFC y `alpha()` la acepta directamente.
   - *Con los datos observados*: con los 306 casos (faltantes por pares) se obtienen los alfas del PDF.
3. **Confiabilidad compuesta (Dillon-Goldstein).** CC = (Σλ)² / [(Σλ)² + Σ(1 − λ²)], con las cargas
   estandarizadas λ.
4. **Validez convergente (AVE).** El promedio de λ² debe ser ≥ .50: el factor explica al menos la mitad
   de la varianza de sus ítems.
5. **Validez discriminante (Fornell-Larcker).** La √AVE de cada factor debe ser mayor que su correlación
   con los demás factores.

## Resultados

| Factor | Ítems | α datos (PDF) | α modelo | CC | AVE | √AVE | Máx. correlación |
|---|---|---|---|---|---|---|---|
| Acceso | 4 | .82 | .84 | .84 | .58 | .76 | .45 |
| Tarjeta | 2 | .87 | .88 | .89 | .80 | .89 | .45 |
| Confort | 4 | .83 | .87 | .88 | .66 | .81 | .32 |

- **Confiabilidad:** alfa y CC son mayores que .80 en los tres factores.
- **Convergente:** la AVE es mayor que .50 en los tres factores y todas las cargas superan .60.
- **Discriminante:** en todos los casos √AVE es mayor que la correlación máxima: los factores son
  distintos entre sí.

Tabla en `output/confiabilidad_validez.csv`.
