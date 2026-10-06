# 02 · Análisis Factorial Confirmatorio (AFC)

Script: `AFC.R`. **Sin referencia propia** (en el Tren: `AFE_CFA.R`, los `.inp` y el PDF).

**Objetivo:** probar el modelo de **12 factores correlacionados** que recupera el AFE
([`01_AFE`](../01_AFE/)), con los 46 ítems, cada uno en un solo factor.

## Diferencias con el Tren

1. **Muestra.** El Tren partió de 170 registros completos y luego pasó a FIML. Aquí **no conviene**:
   solo 160 de 294 personas contestan los 46 ítems y el modelo tiene 158 parámetros (sin contar medias),
   alrededor de un caso por parámetro. Con esas 160 el modelo sí se estima, pero con errores estándar
   ~18% mayores, peor ajuste (CFI .914 contra .950) y sin ninguna de las 71 personas sin pareja. Se usa
   **MLR + FIML con las 294** desde el principio (ver [`07_FIML`](../07_FIML/)).
2. **Solo `lavaan`.** El Tren repetía el AFC con `sem::specifyModel()` porque lo hacía la referencia. Aquí
   no hay referencia y se usa solo `lavaan`.

## Paso a paso

1. **Datos.** Las 294 personas.
2. **AFC con `lavaan`** (`cfa()`). `Factor =~ item1 + item2 + ...`; lavaan fija en 1 la carga del primer
   ítem de cada factor y deja que los 12 factores correlacionen. `estimator = "MLR"` y
   `missing = "fiml"`. Tarda alrededor de un minuto.
3. **Bondad de ajuste** (criterios de Hu y Bentler, 1999), medidas robustas:

   | χ² esc. (gl) | CFI | TLI | RMSEA [IC 90%] | SRMR |
   |---|---|---|---|---|
   | 1322.6 (923), p < .001 | .950 | .944 | .040 [.035, .046] | .043 |

   El ajuste es **bueno**: CFI y TLI ≈ .95, RMSEA < .06 y SRMR < .08. La chi-cuadrada rechaza el modelo
   exacto (p < .001), algo habitual en modelos grandes; se juzga por los índices aproximados.
4. **Cargas estandarizadas** (`output/solucion_estandarizada_AFC.csv`). Van de **.64 a .94**, todas
   significativas (p < .001):

   | Factor | Ítems (carga) |
   |---|---|
   | pareja | a1 .69, a2 .91, a3 .80, a4 .86 |
   | familia | a5 .91, a6 .76, a7 .82, a8 .81 |
   | economia | a9 .81, a10 .89, a11 .91, a12 .88 |
   | social | a13 .80, a14 .81, a15 .79, a16 .82 |
   | personal | a17 .84, a18 .89, a19 .85, a20 .75 |
   | trabajo | a21 .81, a22 .84, a23 .76, a24 .80 |
   | cohesion | b1 .81, b2 .85, b3 .84, b4 .82, b9 .78 |
   | confianza | b10 .80, b11 .92, b12 .92, b13 .83 |
   | inseguridad | c4 .69, c5 .78, c6 .76, c7 .79, c8 .64 |
   | riesgo | c11 .64, c12 .94, c13 .70 |
   | libertad | c19 .88, c20 .73 |
   | desempeno | f2 .86, f3 .84, f4 .89 |

   Solo cuatro cargas quedan por debajo de .70: `c11` y `c8` (.64), `a1` (.69) y `c4` (.69).

   **Correlaciones entre factores** (`output/correlaciones_factores_AFC.csv`): las 66 van de −.24
   (inseguridad–desempeño) a .65 (personal–trabajo). Solo 8 superan .50 y una pasa de .60: **no hay
   factores redundantes**.
5. **Normalidad y MLR.** La prueba de Mardia (con las 160 personas completas, que es lo que necesita)
   rechaza la normalidad multivariada: asimetría b1p = 888.2 y curtosis b2p = 2,413.6 (z = 19.6),
   p < .001. Por eso MLR corrige la chi-cuadrada y los errores estándar. El factor de escala es **1.12**:
   la no normalidad infla la chi-cuadrada estándar un 12% (1,485.5 contra 1,322.6). Con las medidas sin
   corregir: CFI = .934 y RMSEA = .046.
6. **Modelos por instrumento.** Los 12 factores salen de dos grupos de ítems que, por su numeración y su
   contenido, parecen dos secciones distintas del cuestionario (no se tiene el cuestionario):

   | Modelo | Parámetros | χ² esc. (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | 12 factores (46 ítems) | 204 | 1322.6 (923) | .950 | .944 | .040 | .043 |
   | Satisfacción (6 factores, 24 ítems) | 87 | 381.0 (237) | .957 | .950 | .055 | .047 |
   | Violencia y clima (6 factores, 22 ítems) | 81 | 306.1 (194) | .968 | .962 | .046 | .042 |

   Los tres ajustan bien. Los de cada instrumento ajustan algo mejor porque tienen menos ítems.
7. **Sensibilidad: ¿y si los ítems se tratan como ordinales?** Tratar escalas de 10 puntos con efecto
   techo y suelo como continuas es un supuesto. Se repite cada instrumento con WLSMV y correlaciones
   policóricas (`missing = "pairwise"`; no hay FIML en WLSMV, así que es solo una verificación):

   | Instrumento | CFI | RMSEA | SRMR | Carga media MLR → ordinal | Dif. media / máx. |
   |---|---|---|---|---|---|
   | Satisfacción | .985 | .052 | .044 | .824 → .846 | +.021 / .082 |
   | Violencia y clima | .987 | .050 | .050 | .805 → .836 | +.030 / .123 |

   El ajuste es igual o mejor y las cargas suben .02–.03 en promedio (los ítems ordinales sufren menos
   atenuación). **La estructura es la misma.** (El modelo ordinal de los 12 factores a la vez tiene más
   de 500 parámetros, la mayoría umbrales, con 294 personas: su matriz de varianzas queda singular y
   lavaan avisa. Por eso se verifica por instrumento, donde los parámetros son menos que las personas.)
8. **Ajuste local.**
   - **Residuos de correlación** (observada menos implicada): solo **32 de 1,035 (3%)** superan |.10| y
     el mayor es .156 (`a19`–`a3`).
   - **Índices de modificación:** 26 parámetros con mi ≥ 10. Los dos mayores están **dentro del factor
     social**: `a15`–`a16` (72.4) y `a13`–`a14` (70.9); siguen `a19`–`b10` (21.6), `a14`–`a16` (20.9),
     `a14`–`a15` (18.3) y `a18`–`a21` (18.3).
   - En `social`, las correlaciones observadas son `a13`–`a14` .76 y `a15`–`a16` .77, contra .57–.60 entre
     los pares cruzados, mientras que el modelo implica ~.65 para todas. Son **dos pares de ítems de
     contenido más cercano**: actividades sociales (`a13` frecuencia, `a14` diversidad) y medio social
     (`a15` tipo de personas, `a16` vida social en general). El factor se sostiene (cargas .79–.82) y
     **no se modifica el modelo**: los índices son para revisar, no para modificar a ciegas.
9. **Salidas** (`output/`): `solucion_estandarizada_AFC.csv`, `ajuste_modelos.csv`,
   `correlaciones_factores_AFC.csv`, `indices_modificacion.csv`, `diagrama_AFC_satisfaccion.png` y
   `diagrama_AFC_violencia_clima.png` (`semPaths`, con las correlaciones entre factores como flechas
   dobles sin etiqueta; sus valores están en la tabla).

> **Tiempos.** Calcular las medidas de ajuste robustas con FIML y 46 ítems tarda más de 2 minutos cada
> vez que se piden. El script las calcula **una sola vez** (`fitMeasures(fit)`) y por eso `summary()` no
> lleva `fit.measures = TRUE`. En total el script tarda unos 5 minutos.

> **Aviso.** El AFE y el AFC usan la **misma muestra**: el AFC no es una confirmación independiente.
> Como comprobación opcional, `Validacion_cruzada.R` (~5 min) divide la muestra al azar en dos mitades de
> 147 personas (tres particiones): AFE en una mitad y AFC (ML + FIML) en la otra. El AFC en la mitad
> ajusta peor y menos estable que con las 294 (CFI = .90, .88 y .83; RMSEA = .058, .062 y .074, contra
> CFI = .934 y RMSEA = .046 con todos; el modelo tiene 158 parámetros). Una partición dio una carga
> estandarizada de 1.01 (varianza residual negativa). Conclusión: **la estructura se replica, pero la
> muestra no alcanza para dividirla**.

## Referencias

- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis:
  Conventional criteria versus new alternatives. *Structural Equation Modeling, 6*(1), 1–55.
