# 05 · Puntajes factoriales: Confianza del consumidor

Script: `Puntajes_Factoriales.R` (unos 40 segundos). **Sin referencia:** el documento de INEGI no trae puntajes
factoriales. Se calculan los de los cuatro factores y los del factor general (segundo orden), y se comparan con un
promedio simple de los ítems, como el indicador de INEGI (el ICC promedia cinco de estas preguntas). Aquí **sí se usa el
ponderador `FACTOR`**, que es donde corresponde: para estimar medias de la población, no para el modelo.

**Pregunta:** ¿qué puntaje de confianza recibe cada persona y tiene sentido?

**Respuesta corta:** 2,050 puntajes; `CONF` correlaciona **.97** con el promedio simple de los 15 ítems y **.90** con el
de los cinco del ICC; baja con la edad, como se espera.

## Paso a paso

1. **Modelo** de segundo orden (igual que en [`03`](../03_AFC_2do_Orden/)).
2. **Puntajes (EBM**, el método de `lavaan` para ítems ordinales). Con `missing = "pairwise"` cada persona recibe
   puntaje aunque tenga un «No sabe»: **las 2,050**, sin ningún `NA`.

   | | `HOGA` | `HOGE` | `PAIS` | `CONS` | `CONF` |
   |---|---|---|---|---|---|
   | Media | 0.00 | 0.00 | 0.00 | 0.01 | 0.00 |
   | Desviación | 0.83 | 0.82 | 0.63 | 0.77 | 0.69 |
   | Mínimo | −2.60 | −2.48 | −1.97 | −2.25 | −2.11 |
   | Máximo | 2.52 | 2.24 | 2.35 | 2.46 | 2.27 |

   Media cercana a 0 y desviación de .6 a .8: el puntaje se encoge hacia la media. Los puntajes de los factores
   correlacionan de .67 a .87 entre sí (los factores latentes, de .54 a .79) y `CONF` con `CONS`, .98.
3. **Contra un promedio simple de los ítems** (reescalados a 0–1):

   | Contra | r |
   |---|---|
   | Promedio simple de los 15 ítems | **.971** |
   | Promedio simple de los 5 ítems del ICC (`P3`, `P4`, `P5`, `P6`, `P8`) | .904 |

   El puntaje factorial y el promedio dicen casi lo mismo; el factorial pondera cada ítem por su carga (`P12`, con
   .48, pesa menos) y el promedio los trata por igual. **No es la fórmula oficial del ICC** (no está en estos
   archivos): es un promedio simple de las mismas cinco preguntas.
4. **¿Tiene sentido?** Promedio de `CONF` por grupo, de la **muestra** y de la **población** (con el ponderador):

   | Grupo | n | Muestra | Población |
   |---|---|---|---|
   | 18–29 años | 358 | .35 | .34 |
   | 30–44 | 633 | .13 | .14 |
   | 45–59 | 529 | −.13 | −.16 |
   | 60+ | 530 | −.25 | −.25 |
   | Hombres | 862 | .11 | .12 |
   | Mujeres | 1,188 | −.07 | −.08 |

   La confianza **baja con la edad** y los hombres puntúan más alto. Con ponderador los promedios cambian en .03 o
   menos: la media de la muestra y la de la población casi coinciden en estos grupos.
5. **Puntajes guardados** con la llave de la persona (`FOL`, `CVE_ENT`, `CON`, `V_SEL`, `N_HOG`, `H_MUD`, `N_REN`; no
   hay un id único).

**Salidas** (`output/`): `puntajes_confianza.csv`, `comparacion_indices.csv` y `confianza_por_grupo.csv`.

**Cuidado.** Los puntajes salen del modelo estimado sin ponderar (ver [`02`](../02_AFC/README.md#por-qué-no-se-pondera-decisión-del-proyecto));
las medias poblacionales del paso 4 ponderan solo el promedio, no el modelo. Las comparaciones entre grupos suponen
invarianza ([`06`](../06_Invarianza_Factorial/)).
