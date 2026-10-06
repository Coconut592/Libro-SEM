# 07 · Datos faltantes: FIML

Script: `FIML.R` (unos 10 minutos por el paso 4). Referencias: el `Missing are all (-9999)` y el
`ESTIMATOR = ML` de los Anexos 1 y 2 del capítulo (Mplus).

> **La base no tiene datos faltantes.** Los 356 estudiantes contestaron los 15 ítems, y ni siquiera aparece
> el código `-9999` que declara la sintaxis de Mplus. Con datos completos, **FIML y ML son lo mismo**. Para
> poder mostrar qué hace FIML, los pasos 3 y 4 **quitan datos a propósito** (faltantes simulados). Es un
> ejercicio didáctico: **esos resultados no son sobre los datos reales.**

## Paso a paso

1. **¿Cuántos faltan?** Ninguno: 0 de 5,340 respuestas (356 × 15) y 356 de 356 casos completos.
2. **Con datos completos, FIML = ML.** Se ajusta el modelo de segundo orden con `missing = "fiml"` y sin
   él: mismo χ² (246.604, 86 gl), mismo CFI (.931) y estimaciones idénticas (diferencia máxima ~10⁻¹⁵).
3. **Un ejemplo con faltantes simulados** (semilla 2026), con dos mecanismos:
   - **MCAR** (completamente al azar): cada respuesta se pierde con probabilidad de 5%, sin relación con
     nada.
   - **MAR** (al azar dado lo observado): los 12 ítems de HR, SA y AS se pierden con más probabilidad
     cuando la persona puntúa **alto en Influencia interpersonal** (II16–II18, siempre observados).
     Promedio de faltantes: 7%. Es el caso que sesga a la eliminación por lista y que FIML corrige, porque
     FIML usa a II.

   Cargas estandarizadas de segundo orden (sobre HP) en este conjunto:

   | | N | HR | SA | AS | II |
   |---|---|---|---|---|---|
   | Datos completos | 356 | .824 | .933 | .949 | .805 |
   | MCAR, listwise | 163 | .873 | .924 | .982 | .808 |
   | MCAR, FIML | 356 | .821 | .932 | .940 | .797 |
   | MAR, listwise | 151 | **.763** | .954 | .927 | **.720** |
   | MAR, FIML | 356 | .837 | .930 | .951 | .797 |

   Con solo 5% de respuestas perdidas, la eliminación por lista tira el **54% de la muestra** (con MAR,
   el 58%). Con MAR subestima las cargas de II y HR; FIML queda casi igual que los datos completos.
4. **Repetido 200 veces** por mecanismo (la "verdad" es la solución con los 356 completos). Promedios sobre
   las 19 cargas estandarizadas:

   | Mecanismo | Método | Casos | Soluciones admisibles | Sesgo medio | Sesgo absoluto | RMSE | E.E. media |
   |---|---|---|---|---|---|---|---|
   | MCAR | Listwise | 165 | 81.5% | −.001 | .035 | .044 | .046 |
   | MCAR | **FIML** | 356 | 100% | .000 | .009 | **.011** | **.033** |
   | MAR | Listwise | 152 | 77.0% | −.021 | .044 | .054 | .052 |
   | MAR | **FIML** | 356 | 100% | −.002 | .008 | **.011** | **.033** |

   Sesgo medio por carga de segundo orden (sobre HP):

   | Mecanismo | Método | HR | SA | AS | II |
   |---|---|---|---|---|---|
   | MCAR | Listwise | −.001 | −.004 | .003 | −.002 |
   | MCAR | FIML | .000 | −.001 | .000 | .000 |
   | MAR | Listwise | **−.041** | **+.037** | **−.046** | **−.046** |
   | MAR | FIML | .000 | .003 | −.005 | −.001 |

## Lectura

- **MCAR:** ninguno de los dos métodos tiene sesgo, pero **FIML es mucho más preciso**: usa los 356 casos,
  su error (RMSE) es una cuarta parte y sus errores estándar son 30% menores. La eliminación por lista,
  además, produce una **solución inadmisible** (no converge o trae varianzas negativas) en 1 de cada 5
  réplicas, por la falta de casos; con FIML, nunca.
- **MAR:** la eliminación por lista **se sesga** (subestima unas .04–.05 las cargas de HR, AS e II sobre
  HP) porque se queda con las personas que puntúan bajo en II. FIML no tiene sesgo, porque usa la
  información de II de quienes perdieron otros ítems.
- **Para el libro:** con datos reales y completos, como los de este capítulo, FIML no es necesario. Estos
  resultados muestran por qué conviene usarlo en cuanto haya faltantes: por eficiencia (MCAR) y por
  sesgo (MAR). La salvedad de siempre: FIML supone MAR, y eso no se puede comprobar con los datos.
- **Límites:** son faltantes inducidos con un mecanismo sencillo sobre un solo conjunto de datos, y el
  modelo (el de 2.º orden) es el mismo con el que se simula y se estima.

## Salidas

`output/resumen_simulacion.csv`, `ejemplo_un_conjunto.csv` y `sesgo_cargas_segundo_orden.csv`.
