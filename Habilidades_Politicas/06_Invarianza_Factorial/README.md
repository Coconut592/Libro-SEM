# 06 · Invarianza factorial por género

Script: `Invarianza_Factorial.R`.

> **Sin referencia propia.** El capítulo y la presentación no hacen invarianza. Se sigue la secuencia
> estándar de invarianza de medición (Meredith, 1993; Vandenberg y Lance, 2000): configural → métrica →
> escalar → estricta, con los criterios de Chen (2007), igual que en los otros proyectos.

**Pregunta:** ¿hombres y mujeres entienden igual los ítems del PSI? Si hay invarianza, sus puntajes y sus
medias latentes se pueden comparar. Se prueba en dos niveles: el modelo de **4 factores** y el de **segundo
orden** (el del capítulo).

## Por qué esta agrupación y sus limitaciones

A diferencia del Tren y de Guerrero, aquí **sí hay una variable de grupo sustantiva**: `Genero`, con 161
hombres y 195 mujeres. Pero conviene leer los resultados con cautela:

1. **Las etiquetas son una deducción.** El `.dta` guarda 1 y 2 sin etiqueta. Por las frecuencias (161 y 195)
   y el capítulo, **1 = hombre y 2 = mujer**.
2. **El modelo no ajusta del todo bien dentro de cada grupo** (requisito previo). Con MLR:

   | Grupo | N | χ² esc. (gl) | CFI rob. | TLI rob. | RMSEA rob. | SRMR |
   |---|---|---|---|---|---|---|
   | Hombres | 161 | 178.6 (84) | .890 | .862 | .097 | .063 |
   | Mujeres | 195 | 190.3 (84) | .895 | .869 | .090 | .064 |

   Con los 356 juntos el CFI era .947 (MLR). **La secuencia de invarianza parte de un modelo configural de
   ajuste mediocre** (CFI .89, RMSEA .09).
3. **En los hombres la solución es inadmisible.** La correlación SA–AS estimada es **1.05** (mayor que 1;
   lavaan avisa que la matriz de los factores no es definida positiva); en las mujeres es .68. En los
   hombres, Sinceridad aparente y Astucia social son **indistinguibles**. En el modelo de segundo orden
   esto se ve como una varianza residual **negativa** de SA (−.15, caso Heywood) y una carga de SA sobre HP
   mayor que 1 (1.07; en las mujeres .79).
4. **Tamaño de los grupos.** Con 161 y 195 personas el análisis es razonable pero no holgado; por eso se
   usa el criterio más estricto de Chen para muestras chicas o desiguales (ΔCFI ≥ −.005) además del usual
   (−.010).

## Paso a paso

1. **Grupo.** `sexo` = Hombre / Mujer. La base se ordena por género porque lavaan numera los grupos en el
   orden en que aparecen los datos (no por los niveles del factor), y se quiere que el grupo 1 (referencia,
   media latente 0) sean los hombres. El script lo verifica.
2. **Modelos anidados** con `group = "sexo"` y `group.equal`: *configural* (misma estructura, todo libre),
   *métrica* (`"loadings"`), *escalar* (`+ "intercepts"`: permite comparar medias latentes) y *estricta*
   (`+ "residuals"`). Con MLR por la no normalidad.
3. **Comparación** con la diferencia de χ² escalada (Satorra-Bentler) y los cambios en CFI y RMSEA.

### A. Cuatro factores

| Modelo | χ² esc. (gl) | CFI rob. | TLI rob. | RMSEA rob. | SRMR | ΔCFI | ΔRMSEA | Δχ² (gl), p |
|---|---|---|---|---|---|---|---|---|
| Configural | 368.3 (168) | .893 | .866 | .093 | .060 | — | — | — |
| Métrica | 380.2 (179) | .892 | .873 | .090 | .065 | −.001 | −.003 | 12.0 (11), p = .36 |
| Escalar | 398.3 (190) | .890 | .878 | .089 | .067 | −.002 | −.002 | 16.7 (11), p = .12 |
| Estricta | 418.3 (205) | .886 | .883 | .087 | .067 | −.004 | −.002 | 21.3 (15), p = .13 |

**Se sostienen todos los niveles, incluida la invarianza estricta**: ΔCFI nunca pasa de −.004 y el RMSEA
incluso baja.

**El estimador importa en la estricta.** Con ML (sin corrección por no normalidad) la invarianza estricta
se rechaza (Δχ² = 31.2, 15 gl, **p = .008**; ΔCFI = −.007) mientras que métrica (p = .15) y escalar (p = .11)
se sostienen. Se reporta MLR, que es el apropiado con estos datos.

### B. Diferencias en las medias latentes (modelo escalar)

Con invarianza escalar se pueden comparar las medias de los factores (hombres = 0):

| Factor | Mujeres − hombres | E.E. | z | p | d |
|---|---|---|---|---|---|
| HR | +0.03 | 0.105 | 0.29 | .77 | .03 |
| **SA** | **+0.31** | 0.123 | 2.50 | **.012** | **.30** |
| AS | +0.15 | 0.109 | 1.34 | .18 | .16 |
| II | +0.08 | 0.115 | 0.68 | .50 | .08 |

Las mujeres puntúan más en **Sinceridad aparente** (d = .30). Con una corrección de Bonferroni por 4
comparaciones queda en p = .048. En las demás dimensiones no hay diferencias.

### C. Segundo orden (el modelo del capítulo)

Secuencia de Chen, Sousa y West (2005), con MLR:

| Modelo | χ² esc. (gl) | CFI rob. | RMSEA rob. | SRMR | ΔCFI | ΔRMSEA | Δχ² (gl), p |
|---|---|---|---|---|---|---|---|
| 1. Configural | 369.6 (172) | .894 | .091 | .060 | — | — | — |
| 2. Cargas de 1.er orden | 381.0 (183) | .894 | .089 | .066 | .000 | −.003 | 11.4 (11), p = .41 |
| 3. + cargas de 2.º orden | 390.2 (186) | .890 | .089 | .076 | −.003 | +.001 | 9.4 (3), **p = .025** |
| 4. + interceptos de los ítems | 406.0 (196) | .888 | .088 | .077 | −.002 | −.001 | 15.1 (10), p = .13 |
| 5. + interceptos de las dimensiones | 414.5 (200) | .886 | .088 | .078 | −.002 | .000 | 8.7 (4), p = .07 |
| 6. + residuos de los ítems | 433.4 (215) | .883 | .086 | .077 | −.003 | −.002 | 20.4 (15), p = .16 |
| 7. + disturbios de las dimensiones | 438.4 (220) | .882 | .085 | .088 | −.001 | −.001 | 6.2 (5), p = .29 |

- **Por los índices** (ΔCFI ≥ −.005, ΔRMSEA ≤ .015) se sostienen los siete niveles.
- **Por la χ²**, solo el paso 3 (cargas de segundo orden iguales) se rechaza (p = .025). La prueba score
  señala `HP =~ SA` (X² = 6.9, p = .009) y `HP =~ II` (6.3, p = .012). Es el problema del punto 3 de arriba:
  en los hombres SA carga 1.07 en HP y en las mujeres .79; II carga .77 en hombres y .82 en mujeres.
- **Diferencia en HP** (modelo del paso 5): las mujeres puntúan +0.135 (E.E. .085, p = .11; d = .17):
  pequeña y no significativa.

## Lectura

- **A nivel de ítems, el PSI es invariante por género** (hasta la estricta con MLR): los ítems se
  relacionan igual con sus factores, tienen los mismos interceptos y el mismo error. Los puntajes de hombres
  y mujeres son comparables.
- **A nivel del factor general hay un matiz:** la relación entre HP y sus dimensiones **no es idéntica**,
  sobre todo para SA. No se rechaza por los índices de ajuste, pero sí por la χ², y tiene una explicación
  sustantiva: en los hombres SA y AS no se distinguen de HP.
- **Diferencia sustantiva:** las mujeres puntúan más en Sinceridad aparente (d = .30). En HP total, no.
- **Reservas:** el ajuste de partida es mediocre en cada grupo y hay una solución inadmisible en los
  hombres. Las conclusiones de invarianza son **débiles** y deben leerse con eso en mente.

## Salidas

`output/ajuste_invarianza_4_factores.csv`, `ajuste_invarianza_2do_orden.csv` y
`medias_latentes_mujeres.csv`.
