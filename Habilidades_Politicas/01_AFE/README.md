# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R`. **Sin referencia propia:** el capítulo y la presentación van directo al AFC. Se hizo con
la misma receta que en los demás proyectos (KMO, Bartlett, eigenvalores, análisis paralelo, ML con rotación
oblimin).

**Pregunta:** si no se le dice a los datos la teoría de Ferris, ¿recuperan los cuatro factores (HR, SA, AS,
II)?

**Respuesta corta: solo en parte.** HR e II salen claros; Sinceridad aparente (SA) y Astucia social (AS) se
mezclan. Un factor general fuerte domina los datos.

## Paso a paso

1. **Datos.** Los 356 estudiantes y los 15 ítems, ordenados por factor teórico.
2. **¿Tiene sentido factorizar?** **KMO = .92** (todos los ítems entre .89 y .95) y **Bartlett**
   χ² = 2373.9, 105 gl, p < .001. Los ítems comparten mucha varianza.
3. **Eigenvalores.** 6.71, 1.25, 1.09, 0.79, 0.68... El criterio de Kaiser (> 1) retiene **3**. El primero
   explica el 45% de la varianza: hay un factor general fuerte.
4. **Análisis paralelo** (500 réplicas, ML): recomienda **3 factores** (y 1 componente). El cuarto
   eigenvalor observado (.22) queda apenas sobre la media simulada (.19), así que no se descarta. Con solo 100 réplicas el resultado cambia entre 3 y 4
   según la semilla, por eso se usan 500. Gráfica en `output/grafica_codo.png`.
5. **AFE por ML con rotación oblimin**, de 1 a 4 factores. Oblimin y no varimax porque los factores se
   correlacionan (.45 a .60 aquí).

   | Factores | χ² (gl) | TLI | RMSEA | BIC | Varianza |
   |---|---|---|---|---|---|
   | 1 | 463.1 (90) | .808 | .108 | −65.7 | 40.8% |
   | 2 | 289.5 (76) | .869 | .089 | −157.0 | 46.2% |
   | **3** | 159.1 (63) | **.929** | **.065** | **−211.0** | 51.1% |
   | 4 | 103.3 (51) | .952 | .054 | −196.3 | 55.1% |

   El BIC es el menor con **3** factores; con 4, el RMSEA y el TLI mejoran, pero el BIC empeora.
6. **Tres factores** (cargas de patrón):

   | | ML1 | ML2 | ML3 | Teoría |
   |---|---|---|---|---|
   | `HR1` `HR2` `HR3` `HR4` `HR6` | **.56 .80 .75 .70 .54** | | | HR |
   | `II16` `II17` `II18` | | **.68 .73 .85** | | II |
   | `SA7` | .17 | **.34** | .28 | SA |
   | `SA8` `SA9` | | | **.51 .52** | SA |
   | `AS13` `AS14` | | | **.79 .57** | AS |
   | `AS10` | **.35** | .04 | **.33** | AS (carga cruzada) |
   | `AS11` | **.31** | .24 | .23 | AS (carga en tres factores) |

   - **ML1 = HR** y **ML2 = II**, como la teoría (`SA7` se les pega con .34).
   - **ML3 mezcla SA y AS:** `SA8`, `SA9`, `AS13` y `AS14`. Astucia social y Sinceridad aparente **no se
     separan**.
   - `AS10` y `AS11` no tienen un factor claro (cargas de .23 a .35 repartidas).
7. **Cuatro factores** (los de la teoría): solo HR e II salen como en la teoría. El cuarto factor es
   prácticamente **un solo ítem** (`SA8`, carga .96 y comunalidad 1.00: un caso Heywood, es decir, una
   solución impropia), y `SA7` y `SA9` se van a otros factores (II y AS). Los factores correlacionan de
   .45 a .57.

## Lectura

- Los datos apoyan **3 factores claros** (HR, II y un bloque SA+AS) y admiten un cuarto. Esto va en la
  misma dirección que el AFC ([`02_AFC`](../02_AFC/)): SA y AS correlacionan **.89**, y en el segundo
  orden SA y AS casi no tienen varianza propia ([`03_AFC_2do_Orden`](../03_AFC_2do_Orden/)).
- **No contradice al capítulo:** el AFC confirma la estructura de 4 factores con ajuste aceptable (el
  AFC es una prueba de la teoría; el AFE explora sin ella). Pero **sí matiza** que Ferris separe SA de AS.
- Ningún ítem se elimina a partir del AFE (el capítulo ya quitó `HR5`, `AS12` e `II15`).

## Salidas

`output/ajuste_AFE_1_a_4_factores.csv`, `cargas_AFE_3_factores.csv`, `cargas_AFE_4_factores.csv` y
`grafica_codo.png`.
