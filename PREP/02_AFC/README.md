# 02 · Análisis Factorial Confirmatorio (AFC)

Script: `AFC.R`. Referencias: `CFA_Espacio_Publico.inp`, `CFA_Hogares.inp`, `cfa_espacio_publico.pdf` y
Laboratorios 2 y 5.

**Objetivo:** probar los modelos que sugiere el AFE: espacio público (3 factores), colonia (5) y bloque G (3).

## Paso a paso

1. **Modelos.** `=~` ("se mide por"); lavaan fija en 1 la primera carga. Estimador **MLR** y **FIML**, como
   Mplus: entran 7,814 (espacio público), 8,239 (colonia) y 7,805 (G) respondientes. G no incluye `g05`.
2. **Bondad de ajuste** (Hu y Bentler, 1999):

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | Espacio público | 622 (41) | .979 | .972 | .058 | .031 |
   | Colonia | 5,484 (265) | .938 | .930 | .059 | .034 |
   | G | 501 (41) | .985 | .979 | .045 | .025 |

   Con tanta muestra el χ² siempre es significativo; se juzga por CFI, RMSEA y SRMR. En el espacio
   público el piloto (75 casos) daba CFI = .890 y RMSEA = .108.
3. **Cargas estandarizadas.** Todas significativas: .71–.92 (espacio público), .46–.91 (colonia; la menor
   es `d09`) y .52–.92 (G).
4. **Correlaciones entre factores.** Espacio público: calificación–seguridad .50, calificación–actividades
   .64, seguridad–actividades .43. Colonia: la única alta es **Infraestructura–Satisfacción .77**
   (Satisfacción tiene solo 2 ítems); inseguridad percibida correlaciona de −.25 a −.34 con los demás.
   G: .05, .20 y −.10.
5. **Índices de modificación (colonia).** Los mayores son covarianzas entre residuales de ítems vecinos
   (`e02`–`e03`, `d05`–`d06`, `d01`–`d02`): redacción parecida. No se agregan.
6. **Errores estándar por conglomerado.** Los respondientes están agrupados en 276 espacios (ICC ≈ .21).
   Con `cluster = "espacio"` los errores estándar de las cargas suben **37%** y el ajuste casi no cambia
   (CFI = .980).

Salidas: `ajuste_AFC.csv`, `solucion_estandarizada_AFC.csv` y `diagrama_AFC_*.png`.
