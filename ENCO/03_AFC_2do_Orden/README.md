# 03 · AFC de segundo orden: Confianza del consumidor

Script: `AFC_2do_Orden.R` (unos 5 segundos). **Sin referencia:** el documento de INEGI no trae un modelo de segundo
orden. Los cuatro factores correlacionan de .54 a .79, así que se prueba si los gobierna un **factor general**: la
confianza del consumidor (`CONF`).

**Pregunta:** ¿hay un factor general de confianza por encima de hogar hoy, hogar esperado, país y consumo?

**Respuesta corta: sí**, con cargas de .68 a .92 y el mismo ajuste que el primer orden. Y, a diferencia de EMOVI, aquí
el segundo orden **se puede contrastar** contra el primero.

## Paso a paso

1. **Modelo.** Los cuatro factores de [`02`](../02_AFC/) más `CONF =~ HOGA + HOGE + PAIS + CONS`.
2. **Ajuste.**

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | 1.er orden (4 factores) | 2,050 | 960 (84) | .975 | .969 | .071 | .048 |
   | 2.º orden (`CONF`) | 2,050 | 952 (86) | .975 | .970 | .070 | .049 |

   Con 4 factores el segundo orden **no queda justo identificado** (en EMOVI, con 3, sí): 6 correlaciones se
   reemplazan por 4 cargas, así que hay 2 grados de libertad más. La diferencia de χ² escalada es Δχ²(2) = 19.2,
   **p < .001**: la prueba rechaza (con 2,050 casos detecta diferencias mínimas), pero CFI, TLI, RMSEA y SRMR casi no
   cambian: **el factor general describe las correlaciones entre factores igual de bien** y con menos parámetros.
3. **Cargas de segundo orden y varianza explicada de cada factor:**

   | Factor | Carga en `CONF` | R² | Varianza residual del factor |
   |---|---|---|---|
   | `HOGA` Hogar hoy | .85 | .72 | .23 |
   | `HOGE` Hogar esperado | .79 | .62 | .31 |
   | `PAIS` País | .68 | .47 | .29 |
   | `CONS` Consumo, ahorro y planes | **.92** | **.84** | .12 |

   Ninguna varianza residual es negativa ni la carga pasa de 1: **no hay caso Heywood**. `CONS` es el factor que más se
   parece al general; `PAIS` es el que más varianza propia conserva (la economía del país no se reduce a la confianza
   del hogar). Las cargas de primer orden no cambian (diferencia máxima de .001).
4. **¿Hace falta el segundo orden?** Un solo factor con los 15 ítems ajusta mucho peor (CFI .889, RMSEA .146) que los
   cuatro factores con un general encima (CFI .975, RMSEA .070): la estructura de **cuatro dimensiones bajo un factor
   general** es la que describe los datos.

**Salidas** (`output/`): `ajuste_2do_orden.csv` y `cargas_segundo_orden.csv`.

**Cuidado.** El factor general se apoya sobre todo en `CONS` y `HOGA`. Los factores `HOGA` y `HOGE` tienen solo dos
ítems cada uno, casi duplicados (`P1`/`P3`, `P2`/`P4`).
