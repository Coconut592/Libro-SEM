# 05 · Puntajes factoriales: los seis ámbitos y la violencia general

Script: `Puntajes_Factoriales.R` (unos 45 segundos). **Sin referencia propia.** Se sigue EMOVI (ítems 0/1): puntajes **EBM** (*empirical Bayes
modal*, el método de `lavaan` para ítems ordinales) de los seis ámbitos y del factor general (segundo orden de [`03`](../03_AFC_2do_Orden/)), su
determinación y una comparación con un índice simple (el conteo de hechos) y con la clase latente `c_r`.

> Los puntajes en **escala original** y por **media ponderada** de los demás proyectos **no aplican** aquí: con ítems 0/1 no hay un ítem marcador cuyos
> puntos sirvan de escala.

**Pregunta:** ¿se pueden calcular puntajes de violencia por mujer, y valen la pena frente a sumar los "Sí"?

**Respuesta corta: sí se pueden (1,088 puntajes generales; determinación de .90 a .98), pero se parecen mucho al conteo de hechos (r = .955)
y en la parte baja no distinguen:** el 35 % de las mujeres no reporta nada y casi comparte el mismo puntaje.

## Paso a paso

1. **Datos y modelo:** el de segundo orden de [`03`](../03_AFC_2do_Orden/) (1,088 mujeres, WLSMV, `missing = "pairwise"`).
2. **Puntajes (EBM).** Todas las mujeres reciben `VIO` (se apoya en los ámbitos que sí contestó). Pero quien no contestó **ningún** ítem de un ámbito no tiene
   información para él: el EBM le asignaría un valor apoyándose solo en los otros ámbitos, así que su puntaje queda en **`NA`**:

   | Puntaje | Mujeres con puntaje | `NA` | Media | D.E. | Mín. | Máx. |
   |---|---|---|---|---|---|---|
   | `INF` infancia | 1,088 | 0 | 0.19 | 0.59 | −0.34 | 2.28 |
   | `FAM` familia | 1,083 | 5 | 0.23 | 0.51 | −0.24 | 2.22 |
   | `PAR` pareja | 775 | **313** | 0.21 | 0.52 | −0.24 | 2.06 |
   | `TRA` trabajo | 839 | **249** | 0.17 | 0.41 | −0.19 | 2.23 |
   | `COM` comunidad | 1,081 | 7 | 0.20 | 0.50 | −0.23 | 2.29 |
   | `ESC` escuela | 1,031 | 57 | 0.21 | 0.56 | −0.25 | 2.06 |
   | **`VIO` general** | **1,088** | 0 | 0.19 | 0.40 | −0.23 | 1.88 |

   Las medias quedan en .17–.23 (no 0): el EBM da la **moda** de la distribución posterior y la distribución es muy asimétrica (35 % no reporta nada).
   Las desviaciones (.40 a .59) son menores que 1 porque el puntaje se encoge hacia la moda.
3. **Determinación** (correlación entre el puntaje y el factor verdadero, para quien contestó todos los ítems; se calcula con las covarianzas implicadas por el
   modelo, que valen para el puntaje lineal de regresión y son una aproximación para el EBM; se pide ≥ .90):

   | `INF` | `FAM` | `PAR` | `TRA` | `COM` | `ESC` | `VIO` |
   |---|---|---|---|---|---|---|
   | .981 | .969 | .974 | .936 | .937 | .962 | **.903** |

   Todos pasan de .90; `VIO` apenas, porque depende de los seis ámbitos a la vez.
4. **Contra un índice simple.** Correlación de `VIO` con el **conteo de hechos** (cuántos de los 24 reporta): **.955** (Pearson) y **.960** (Spearman); con la
   proporción de "Sí" entre los ítems contestados, .954 y .959. El puntaje se parece mucho al conteo, pero pesa distinto: un hecho raro (`p184`) cuenta
   más que uno frecuente (`p141`) y no castiga a quien se saltó bloques.
5. **Efecto suelo.** Hay 507 patrones de respuesta distintos en las 1,088 mujeres. **384 (35.3 %) no reportan ningún hecho** y casi comparten el mismo puntaje
   (−0.23 a −0.14, según los bloques que se saltaron): en la parte baja la escala **no distingue**. El puntaje separa a las que sí reportan, no a las que no.
6. **¿Tiene sentido?** Promedio de `VIO` por clase latente `c_r`: **−0.05, 0.43 y 0.82** (ρ de Spearman = .78; no es independiente: `c_r` sale de los mismos ítems).
   Por escolaridad (`p4`) baja: **.29, .26, .18, .13 y .03** (de ninguna a universidad).
7. **Archivo con `id`.** `puntajes_violencia.csv`: `id`, `c_r` y los siete puntajes (4 decimales) de cada mujer.

**Salidas** (`output/`): `puntajes_violencia.csv`, `descriptivos_puntajes.csv`, `determinacion_puntajes.csv` y `comparacion_indices.csv`.

**Cuidado.**
- Los puntajes de **pareja, trabajo y escuela** son `NA` para quien se saltó el bloque. No son "cero violencia": son "no aplica".
- El puntaje depende del modelo (los seis ámbitos y el segundo orden). Si se cambia el modelo (por ejemplo, 5 ámbitos), cambian.
- Con tantos hechos raros, la determinación (aproximada para el EBM) es optimista respecto de lo que pasa con una mujer que reportó un solo hecho.
