# 07 · Datos faltantes: FIML

Script: `FIML.R` (y `Validacion_Little.R`, opcional). **Sin referencia propia:** en el Tren se explicó FIML con
`missing = "fiml"` (`AFE_CFA.R`), el `.inp` (Mplus usa FIML por defecto con MLR) y SEM02.

**Objetivo:** usar las 294 personas en lugar de las 160 completas. FIML (*Full Information Maximum
Likelihood*) no imputa: cada persona aporta a la verosimilitud con los ítems que sí contestó.

> Aquí el problema es mayor que en el Tren: solo **160 de 294 (54%)** contestan los 46 ítems, y los
> faltantes de pareja (71 personas) son **estructurales**, no una no-respuesta común.

## Paso a paso

1. **¿Cuánto falta y dónde?**
   - Falta el **4.1%** de las celdas. Los ítems con más faltantes: `a3` y `a4` (74), `a2` (72), `a1` (71),
     `c6` (38), `c8` (23), `c13` (16) y `a6` (12).
   - Solo 160 personas están completas: con eliminación por lista (listwise) se pierde el **46% de la
     muestra y a todas las personas sin pareja**.
   - Hay 71 patrones distintos de faltantes. Por bloque de contenido: ninguno (160), solo pareja (43), solo
     inseguridad (14), pareja + inseguridad (8), solo riesgo (6) y cohesión + inseguridad (5).
2. **¿Faltan completamente al azar (MCAR)?** FIML es insesgado si los datos son MCAR o MAR (la probabilidad
   de faltar depende solo de variables observadas); eliminar por lista exige MCAR.
   - **Pruebas t (como en el Tren).** Si faltar fuera independiente de lo observado, quienes dejan en blanco
     un ítem no deberían diferir en los demás. Casi no hay diferencias univariadas: de 0 a 3 pruebas con
     p < .05 de ~40 (por azar se esperan ~2):

     | Faltante | Personas | Ítems comparados | p < .05 | Esperadas por azar |
     |---|---|---|---|---|
     | sin pareja (`a1`–`a4`) | 71 | 42 | 1 | 2.1 |
     | falta `c6` | 38 | 41 | 3 | 2.1 |
     | falta `c8` | 23 | 41 | 0 | 2.1 |
     | falta `c13` | 16 | 41 | 1 | 2.1 |
     | sin familia (`a5`–`a8`) | 10 | 38 | 1 | 1.9 |
   - **Prueba de Little (1988)**, que compara todos los patrones a la vez (H0: los datos son MCAR). Se
     implementó a mano con las medias y covarianzas ML de `lavCor(missing = "fiml")`:

     | Ítems | χ² | gl | p | Patrones |
     |---|---|---|---|---|
     | 46 | 3,336 | 2,898 | 2 × 10⁻⁸ | 71 |
     | 42 (sin `a1`–`a4`) | 2,773 | 2,390 | 7 × 10⁻⁸ | 63 |

     **Se rechaza MCAR**, y también sin los ítems de pareja: no es solo el bloque estructural. La
     eliminación por lista puede sesgar. Little no distingue MAR de "no al azar" (MNAR), así que MAR es un
     supuesto, pero uno más débil que MCAR.
3. **Listwise contra FIML.** Mismo modelo y estimador (MLR):

   | Modelo | Método | N | χ² esc. (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|---|
   | 12 factores | Listwise | 160 | 1369.4 (923) | .914 | .903 | .055 | .053 |
   | | **FIML** | **294** | 1322.6 (923) | **.950** | **.944** | **.040** | **.043** |
   | Satisfacción (6) | Listwise | 202 | 397.3 (237) | .934 | .924 | .067 | .053 |
   | | **FIML** | **294** | 381.0 (237) | **.957** | **.950** | **.055** | **.047** |
   | Violencia y clima (6) | Listwise | 218 | 296.0 (194) | .961 | .954 | .050 | .047 |
   | | **FIML** | **294** | 306.1 (194) | **.968** | **.962** | **.046** | **.042** |

   Con FIML el ajuste es mejor. No es una prueba de que FIML sea "más correcto" (son muestras distintas: el
   listwise deja fuera a las 71 personas sin pareja), pero sí muestra qué se gana.
4. **Estimaciones.** Las cargas y correlaciones estandarizadas cambian poco, pero los errores estándar con
   FIML son menores:

   | Modelo | Carga media (listwise / FIML) | Dif. máx. en cargas | **E.E. FIML / listwise** | Dif. máx. en correlaciones |
   |---|---|---|---|---|
   | 12 factores | .823 / .815 | .106 | **.848** | .147 |
   | Satisfacción (6) | .822 / .824 | .072 | **.922** | .098 |
   | Violencia y clima (6) | .802 / .805 | .050 | **.921** | .103 |

   FIML usa más información: sus errores estándar son **8% a 15% menores**. Con el listwise del modelo de 12
   factores, que **sí se estima** pero con un caso por parámetro (160 casos y 158 parámetros), son ~18%
   mayores. Las cargas ítem por ítem de ambos métodos están en `output/cargas_listwise_vs_FIML.csv`.
5. **Cobertura.** La proporción de personas con información en cada par de ítems tiene mínimo **.67**
   (`c6` con `a3`) y media **.92**; solo 6 pares quedan por debajo de .70. Mplus pide al menos .10.
6. **Los faltantes de pareja son estructurales: ¿cuánto importan?** Las 71 personas sin pareja no tienen
   satisfacción con la pareja; FIML (MAR) la trata como un dato que podría haber existido. Si esas personas
   influyeran en el modelo, el de satisfacción cambiaría al quitarlas. Se compara FIML con las 294 y FIML solo
   con las 223 con pareja: las cargas difieren hasta **.048**, las correlaciones entre factores hasta **.039**
   (hasta .012 las de pareja con los demás factores) y el CFI pasa de .957 a .952. **Los 71 faltantes
   estructurales casi no mueven el modelo de medida.**

> **Supuesto a discutir.** Quien no tiene pareja no "dejó de contestar": la pregunta no le aplica. FIML estima
> la satisfacción con la pareja como si esas 71 personas hubieran podido contestarla. Para el **modelo de
> medida** (cargas, correlaciones) no importa, como muestra el paso 6, pero **no hay que interpretar** su
> puntaje de pareja: por eso en [`05_Puntajes_Factoriales`](../05_Puntajes_Factoriales/) quedan en `NA`.

## Validación de la prueba de Little

`Validacion_Little.R` (opcional, ~1 minuto) comprueba la implementación. Primero, un EM escrito aparte
(sin lavaan) da las mismas medias y covarianzas que `lavCor(missing = "fiml")` en los datos reales
(diferencias de 2 × 10⁻⁶ y 2 × 10⁻⁵). Después, con simulaciones de 300 réplicas (8 variables, 294 casos):
bajo **MCAR** rechaza H0 el 3% de las veces al nivel del 5% (no la rechaza de más), y con datos **MAR** y
**MNAR** la rechaza el 100%.

Salidas en `output/`: `ajuste_listwise_vs_FIML.csv`, `estimaciones_listwise_vs_FIML.csv`,
`cargas_listwise_vs_FIML.csv` y `prueba_little_MCAR.csv`.

## Referencias

- Enders, C. K., & Bandalos, D. L. (2001). The relative performance of full information maximum likelihood
  estimation for missing data in structural equation models. *Structural Equation Modeling, 8*(3), 430–457.
- Little, R. J. A. (1988). A test of missing completely at random for multivariate data with missing values.
  *Journal of the American Statistical Association, 83*(404), 1198–1202.
