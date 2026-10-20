# 05 · Puntajes factoriales: índice de riqueza del hogar de origen

Script: `Puntajes_Factoriales.R` (unos 20 segundos). **Referencia:** la tesis (Anexo 2) obtiene el índice de
riqueza `ind_or` (de −1.389 a 1.755) como puntaje de un CFA binario y lo compara con un índice por componentes
principales (correlación .93).

**Pregunta:** ¿qué puntajes salen del modelo de segundo orden y se parecen a un índice simple?

**Respuesta corta:** salen los **740** puntajes (ningún faltante) y el de riqueza general correlaciona **.98** con
la proporción de bienes y **.98** con el primer componente principal (la tesis: .93).

## Paso a paso

1. **Puntajes.** Del modelo de segundo orden de [`03`](../03_AFC_2do_Orden/), método EBM (el de `lavaan` para
   ítems ordinales): ESP, BAS, TEC y RIQ. Con `missing = "pairwise"` quien contestó `NS` también recibe puntaje.

   | | ESP | BAS | TEC | RIQ |
   |---|---|---|---|---|
   | Media | 0.01 | −0.01 | 0.05 | 0.00 |
   | Desviación estándar | 0.82 | 0.71 | 0.73 | 0.70 |
   | Mínimo | −1.78 | −1.68 | −1.52 | −1.64 |
   | Máximo | 2.16 | 1.90 | 1.83 | 1.87 |

   La media es casi 0; la desviación (.7 a .8) es menor que 1 porque el puntaje se encoge hacia la media.
2. **Contra un índice simple y uno por componentes principales**, como la tesis:

   | RIQ contra | r |
   |---|---|
   | Proporción de bienes (media de los 29 ítems) | .978 |
   | Primer componente principal (651 casos completos) | .983 |

3. **¿Tiene sentido?** Promedio de RIQ por educación del padre (1 primaria o menos … 4 profesional): −.21, .20,
   .38, .49. Por educación de la madre: −.27, .25, .64, .62 (queda igual en profesional, con solo 32 madres).
4. **Archivo.** `output/puntajes_riqueza.csv` trae el folio (`index`) y los cuatro puntajes de cada entrevistado,
   para unirlo con el resto del Entrevistado.

**Salidas** (`output/`): `puntajes_riqueza.csv` y `comparacion_indices.csv`.

**Cuidado.** El puntaje de riqueza no es comparable en nivel con el de la tesis (otro año, otra muestra, otros
ítems): sirve para ordenar a los hogares de la CDMX en esta encuesta.
