# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R`. **Sin referencia directa:** el capítulo valida el instrumento pero no
calcula puntajes. Se sigue el esquema de los otros proyectos (puntajes centrados, determinación, pesos de
Bartlett, escala original y media ponderada), con una ventaja: el modelo de segundo orden da **un puntaje de
Habilidad Política (HP)** además de los de sus cuatro dimensiones.

**Objetivo:** asignar a cada estudiante un puntaje por dimensión y un puntaje general de HP, y ver cuánto
valen frente al simple promedio de los ítems.

## Paso a paso

1. **Datos.** Los 356 estudiantes. La base no trae identificador: se usa el número de renglón como `id`.
2. **Puntajes centrados.** Se ajusta el modelo de segundo orden ([`03_AFC_2do_Orden`](../03_AFC_2do_Orden/))
   y se predicen con `lavPredict(method = "regression")`, el método que usa Mplus (`FSCORES`). Devuelve 5
   puntajes (`fs_HR`, `fs_SA`, `fs_AS`, `fs_II`, `fs_HP`) con media 0.
3. **Determinación** (correlación entre el puntaje y el factor verdadero):

   | HR | SA | AS | II | HP |
   |---|---|---|---|---|
   | .931 | .920 | .924 | .925 | .931 |

   Todas ≥ .90: los puntajes son confiables para usarse en otros análisis. El de HP, que se calcula a
   través de las dimensiones, queda igual de bien determinado que los de las dimensiones.
4. **Bartlett y pesos.** Con el modelo de primer orden: cada ítem aporta solo a su dimensión (por ejemplo,
   `HR2` pesa .216 y `HR1` .139 en HR; `SA8` .397 en SA; `II18` .374 en II). Los puntajes de Bartlett
   correlacionan .98 (HR), .94 (SA), .94 (AS) y .98 (II) con los de regresión.
5. **Escala original (1–7).** Se fijan en 1 las cargas de un ítem marcador por dimensión (`HR3`, `SA8`, `AS11`
   e `II17`, los marcadores del Anexo 2 del capítulo) y los interceptos de los ítems en 0. Las medias de las
   dimensiones: HR 5.17, SA 5.81, AS 5.17, II 5.33 (las de los marcadores: 5.21, 5.76, 5.32, 5.27; no son
   iguales porque con todos los interceptos en 0 el modelo no reproduce exactamente las medias).
6. **Media ponderada.** Puntaje centrado + la media ponderada de la dimensión (cargas estandarizadas por
   la media de cada ítem): HR 5.12, SA 5.70, AS 5.22, II 5.39 y **HP 5.36**. Es la versión más cómoda para
   reportar: `fs3_*`, en la escala de 1 a 7.
7. **Contra el promedio simple de los ítems.** Correlación entre el puntaje factorial y el promedio: HR
   .98, SA .94, AS .94, II .98 y HP **.99**. Para fines prácticos dan casi el mismo orden de personas.
   Con 3 y 4 ítems por dimensión (SA y AS), las diferencias de ponderación pesan un poco más. **El promedio
   simple de los 15 ítems es una buena aproximación de HP** (consistente con el omega jerárquico de
   [`04`](../04_Confiabilidad_y_Validez/)).
8. **Descriptivos** (puntajes fs3, escala de 1 a 7):

   | | Media | D.E. | Mín. | Máx. |
   |---|---|---|---|---|
   | HR | 5.12 | 0.82 | 2.15 | 6.58 |
   | SA | 5.70 | 0.90 | 1.82 | 7.15 |
   | AS | 5.22 | 0.81 | 1.84 | 6.69 |
   | II | 5.39 | 0.92 | 1.88 | 6.82 |
   | **HP** | **5.36** | **0.68** | 2.49 | 6.56 |

   Algunos puntajes de SA pasan de 7 (máximo 7.15): es normal en puntajes factoriales de regresión, que no
   están acotados a la escala del ítem.
9. **Uso: hombres contra mujeres** (puntajes fs3; t de Welch; d de Cohen):

   | | Hombres | Mujeres | Dif. | t | p | d |
   |---|---|---|---|---|---|---|
   | HR | 5.08 | 5.14 | −0.06 | −0.70 | .49 | −.08 |
   | SA | 5.59 | 5.78 | −0.19 | −1.96 | **.050** | −.21 |
   | AS | 5.15 | 5.29 | −0.14 | −1.55 | .12 | −.17 |
   | II | 5.33 | 5.43 | −0.10 | −1.01 | .31 | −.11 |
   | **HP** | 5.30 | 5.41 | −0.12 | −1.58 | .12 | −.17 |

   Las mujeres puntúan un poco más alto en todo, con efectos pequeños. Solo SA roza la significancia
   (p = .050) y no sobrevive a una corrección por las cinco comparaciones. Esta comparación solo es
   legítima si el instrumento es invariante por género
   ([`06_Invarianza_Factorial`](../06_Invarianza_Factorial/)), que en general se sostiene.

## Salidas

`output/puntajes_habilidades_politicas.csv` (`id`, `Genero` y los 14 puntajes: `fs_*`, `fs2_*` y `fs3_*`),
`descriptivos_puntajes.csv`, `comparacion_por_genero.csv`, `pesos_bartlett.csv` y
`boxplot_puntajes_por_genero.png`.
