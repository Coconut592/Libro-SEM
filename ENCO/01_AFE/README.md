# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R` (unos 25 segundos). **Sin referencia propia:** el documento de INEGI es solo un diccionario y no trae
un modelo factorial. Aquí se explora cuántas dimensiones tienen los 15 ítems del cuestionario básico de la ENCO de
agosto de 2026.

**Pregunta:** los 15 ítems de opinión sobre la situación económica, ¿miden una sola confianza o varias dimensiones?

**Respuesta corta: cuatro dimensiones**, que correlacionan de .41 a .60: la situación del hogar hoy, la del hogar
dentro de 12 meses, la economía del país, y el consumo, ahorro y planes de compra.

## Paso a paso

1. **Datos.** 2,050 personas de 18+ (`encocb_0826.DBF`). Tres arreglos antes de analizar (detalle en el
   [diagnóstico](../00_Diagnostico/README.md)): el «No sabe» pasa a faltante (su código cambia por pregunta; en `P10`
   también el 4, «No tiene ingresos»); se **invierten todas las escalas** para que mayor = más confianza (en el
   cuestionario el 1 es siempre lo más optimista); y **`P12` no se funde**: queda con sus 6 categorías.
2. **Casos.** El AFE usa los **1,935** sin ningún «No sabe»; 115 se quedan fuera aquí (el AFC y los demás sí los usan).
3. **¿Tiene sentido factorizar?** Los ítems son ordinales (2 a 6 categorías), así que se factoriza la matriz
   **policórica** (definida positiva: el eigenvalor menor es .18). KMO = **.91** (de .86 en `P6` a .97 en `P11`) y
   Bartlett χ² = 17,798 (105 gl), p < .001.
4. **¿Cuántos factores?** Eigenvalores 7.34, 1.47, 0.99, 0.92, 0.72, 0.66…: **Kaiser dice 2 y el análisis paralelo
   5**. Se decide con el **AFE de `lavaan`** (WLSMV, ordinal, oblimin):

   | Factores | χ² (gl) | CFI | TLI | RMSEA | SRMR | Varianza residual más baja |
   |---|---|---|---|---|---|---|
   | 1 | 3,829 (90) | .888 | .869 | .147 | .093 | .311 |
   | 2 | 2,386 (76) | .931 | .904 | .125 | .071 | .227 |
   | 3 | 1,326 (63) | .962 | .937 | .102 | .053 | .158 |
   | **4** | **326 (51)** | **.992** | **.983** | **.053** | **.024** | **.166** |
   | 5 | 189 (40) | .996 | .988 | .044 | .016 | .157 |

   Ninguna varianza residual es negativa. **Se escogen 4:** el ajuste ya es bueno, cada factor tiene sentido y el
   quinto solo separa `P14` y `P15` (auto y casa) en un factor de dos ítems.
5. **Cuatro factores** (cargas de patrón, oblimin):

   | Factor | Ítems con carga principal |
   |---|---|
   | **F1 · Hogar hoy** | `P1` (.82), `P3` (.78): situación económica de usted y del hogar frente a hace 12 meses |
   | **F2 · Hogar esperado** | `P2` (.81), `P4` (.78): la misma, dentro de 12 meses |
   | **F3 · País** | `P6` (.79), `P5` (.76); más flojos, `P13` empleo (.44) y `P12` precios (.41) |
   | **F4 · Consumo, ahorro y planes** | `P9` y `P10` (.78), `P14` (.78), `P15` (.71), `P8` (.66), `P7` (.57), `P11` (.41) |

   `P7` y `P8` cargan algo en F1 (.37 y .27) y `P11` en tres factores (.41, .24 y .21): es el ítem menos limpio. Se
   deja en F4 (decisión del proyecto). Los factores correlacionan de .41 (F1–F3) a .60 (F1–F4).
6. **Verificación.** El mismo AFE con `psych` (mínimos residuales, oblimin) da los mismos cuatro factores: coeficiente
   de congruencia de 1.00, .99, 1.00 y 1.00.

**Salidas** (`output/`): `ajuste_AFE.csv` y `cargas_AFE_4_factores.csv`.

**Cuidado.** El AFC (02) se confirma con los mismos datos: la estructura sale de ellos y no es una prueba
independiente. Con 2,050 casos y un solo mes no se partió la muestra. Además `P1`/`P3` y `P2`/`P4` son casi la misma
pregunta (r = .72 y .74), así que los dos primeros factores son de **dos ítems** cada uno.
