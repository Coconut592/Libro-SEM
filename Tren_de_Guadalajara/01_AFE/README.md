# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R`. Referencias: primer ejemplo de `AFE_CFA.R` y láminas 4–7 del PDF.

**Objetivo:** explorar la estructura de correlación de los 12 ítems, decidir cuántos factores hay y qué
ítems forman cada uno, antes de proponer el AFC.

## Paso a paso

1. **Datos.** Se lee `imsctren2006.dta` con `read.dta13()` y, como en la referencia, se usan solo los
   registros completos (`complete.cases`): **170 de 306** usuarios. Casi todos los faltantes están en
   `p63`/`p64` (tarjeta).
2. **¿Tiene sentido factorizar?** Con `KMO()` se obtiene **KMO = 0.81**, una adecuación muestral buena.
   `cortest.bartlett()` da χ² = 1156, gl = 66, p < .001: los ítems están correlacionados.
3. **Componentes principales.** `prcomp(scale. = TRUE)` da los eigenvalores 4.84, 2.22, 1.39, 0.84, …
   **Tres eigenvalores son mayores que 1** (criterio de Kaiser) y juntos explican el 70% de la varianza.
4. **Análisis paralelo.** `parallel()` compara esos eigenvalores con los de datos aleatorios (100
   réplicas, percentil 95). Los tres primeros superan a los simulados (1.36, 1.26, 1.18) y el cuarto no
   (0.84 < 1.10). Se retienen **3 factores**. La gráfica de codo queda en `output/grafica_codo.png`.
5. **AFE.** `fa(fm = "ml", nfactors = 3, rotate = "varimax")`:

   | Ítem | ML1 (Confort) | ML2 (Acceso) | ML3 (Tarjeta) | Comunalidad |
   |---|---|---|---|---|
   | p4 | .30 | **.62** | .06 | .47 |
   | p5 | .32 | **.76** | .13 | .70 |
   | p61 | .04 | **.84** | .27 | .78 |
   | p62 | −.14 | **.75** | .06 | .58 |
   | p63 | .16 | .16 | **.86** | .80 |
   | p64 | .19 | .22 | **.84** | .79 |
   | p71 | **.63** | .08 | .35 | .53 |
   | p72 | .39 | .10 | .10 | *.17* |
   | p73 | **.72** | .09 | .10 | .54 |
   | p74 | **.88** | .08 | .03 | .78 |
   | p75 | **.92** | .12 | .09 | .88 |
   | p8 | *.42* | *.48* | .22 | .45 |

6. **Depuración.** Se eliminan dos ítems para el AFC:
   - `p72` (tiempo de traslado): comunalidad de 0.17, el factor casi no la explica.
   - `p8` (tiempo de espera): carga parecida en dos factores (carga cruzada).

   Coincide con el `USEV ARE p4-p64 p71 p73-p75` de los `.inp` y con `tren[,-c(1,9,13)]` en `AFE_CFA.R`.

## Comparación con Mplus (`EFA_Tren_MPLUS_out.pdf`)

La salida de Mplus hace el AFE con los **306** usuarios (FIML, MLR, rotación promax) para 1 a 5 factores.
Con 3 factores, RMSEA = .069 y SRMR = .039, y aparecen los mismos factores: Acceso (p4–p62), Tarjeta
(p63–p64) y Confort (p71–p75). `p72` (.37) y `p8` (≈.25 en dos factores) vuelven a ser los ítems débiles.
Las soluciones de 4 y 5 factores ajustan mejor, pero sus factores extra se forman con uno o dos ítems
(`p74`/`p75`, `p8`) y tienen determinación baja (.72–.82). Por eso se mantienen 3 factores.
