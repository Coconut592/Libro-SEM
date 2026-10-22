# 02 · Análisis Factorial Confirmatorio (AFC) de primer orden

Script: `AFC.R` (unos 6 segundos). **Sin referencia propia:** `Scripts.do` lleva los 24 ítems a un análisis de clases latentes y no
hace AFC. Aquí se confirma la estructura de **seis ámbitos de violencia** que da el cuestionario (y que el [AFE](../01_AFE/) recupera
casi toda), con las 1,088 mujeres.

**Pregunta:** ¿ajustan los seis ámbitos (infancia, familia, pareja, trabajo, comunidad y escuela) y qué tan bien se miden?

**Respuesta corta: sí en CFI, TLI y RMSEA (.987, .985, .019); el SRMR (.110) es la debilidad.** Las cargas van de .47 a .96 y los
factores correlacionan de .31 a .60. Los seis ámbitos ajustan mejor que cinco (familia + trabajo juntos; Δχ² p = .007) y mucho mejor
que un solo factor.

## Paso a paso

1. **Datos.** 1,088 mujeres, 24 ítems 0/1 (se quita el `id` 907, sin ítems).
2. **Modelo.** Un factor por ámbito: `INF` (`p141`–`p144`), `FAM` (`p161`, `p162`, `p165`), `PAR` (`p171`–`p173`, `p175`, `p176`),
   `TRA` (`p183`–`p186`), `COM` (`p191`–`p194`) y `ESC` (`p201`–`p204`).
3. **Estimación.** Ítems 0/1 como **ordinales (WLSMV)** con `missing = "pairwise"`: no se pierden las mujeres que se saltan pareja,
   trabajo o escuela (con listwise quedan 505). `lavaan` no tiene FIML con ordinales; ver [`07_FIML`](../07_FIML/).

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | **6 ámbitos (pairwise)** | 1,088 | 332.3 (237) | **.987** | **.985** | **.019** | .110 |
   | 6 ámbitos (listwise) | 505 | 304.0 (237) | .976 | .972 | .024 | .136 |
   | 5 factores (familia + trabajo) | 1,088 | 366.4 (242) | .984 | .981 | .022 | .118 |
   | 1 factor | 1,088 | 1,418.2 (252) | .847 | .832 | .065 | .189 |

   La solución es admisible (converge, sin varianzas negativas). **6 contra 5 factores:** Δχ² = 16.1 (5 gl), **p = .007**: los
   seis ámbitos ajustan mejor. Se conserva trabajo como factor propio: es un ámbito del cuestionario y correlaciona .60 con familia, no 1.
4. **Cargas estandarizadas** (error estándar entre paréntesis):

   | Factor | Ítem: carga |
   |---|---|
   | INF | `p141` .96 (.01), `p142` .91 (.02), `p143` .94 (.02), `p144` .77 (.05) |
   | FAM | `p161` .86 (.04), `p162` .93 (.04), `p165` .92 (.06) |
   | PAR | `p171` .83 (.04), `p172` .94 (.03), `p173` .89 (.04), `p175` .80 (.04), `p176` .87 (.03) |
   | TRA | `p183` .78 (.08), `p184` .71 (.12), `p185` .76 (.09), `p186` .84 (.08) |
   | COM | `p191` .88 (.07), `p192` .86 (.06), **`p193` .47 (.08), `p194` .48 (.08)** |
   | ESC | `p201` .91 (.03), `p202` .89 (.03), `p203` .79 (.05), `p204` .80 (.03) |

   De **.47** (`p193`) a **.96** (`p141`). Las cargas ordinales son altas porque corrigen por la baja frecuencia de los eventos.
   Las más flojas son **`p193` y `p194`** (comunidad): tocamientos y despojo no se parecen a las ofensas y empujones de `p191` y `p192`
   (según sus etiquetas, que se cortan; el AFE ya los separaba). Los errores estándar más grandes están en **trabajo** (`p184`: .12), con solo 16 a 29 mujeres con "Sí".
5. **Correlaciones entre factores:**

   | | INF | FAM | PAR | TRA | COM | ESC |
   |---|---|---|---|---|---|---|
   | INF | 1 | | | | | |
   | FAM | .57 | 1 | | | | |
   | PAR | .48 | .51 | 1 | | | |
   | TRA | .32 | **.60** | .50 | 1 | | |
   | COM | .31 | .49 | .47 | .45 | 1 | |
   | ESC | .43 | .33 | .37 | .44 | .32 | 1 |

   De .31 a .60: moderadas, que es lo que justifica probar un factor general (ver [`03_AFC_2do_Orden`](../03_AFC_2do_Orden/)).
6. **¿Por qué el SRMR es alto (.110)?** Resume los residuos de todas las correlaciones policóricas, y las **65 parejas de ítems con 5 mujeres
   o menos que digan "Sí" en ambos** (de 276) tienen correlaciones inestables: sus residuos son enormes (hasta −.53, p. ej. `p202`–`p185`:
   una sola mujer). El residuo cuadrático medio es **.167** en esas parejas y **.092** en las demás; el SRMR queda en .092 sin ellas, que
   sigue arriba de .08. Por eso el SRMR se reporta como una debilidad del modelo y no se maquilla.
7. **Índices de modificación** (solo para ver; no se modifica el modelo). El mayor es un residual entre dos ítems raros de ámbitos
   distintos, `p194`–`p202` (MI = 17.1); ninguno pasa de eso. El resto son cargas cruzadas y residuales de parejas casi vacías
   (`p185`–`p194`, `PAR =~ p186`) o dentro del mismo ámbito (`p193`–`p194`, `p161`–`p162`). No se agrega nada.

**Salidas** (`output/`): `ajuste_AFC.csv`, `cargas_AFC.csv` y `correlaciones_factores.csv`.

**Cuidado.** El AFC se confirma con las mismas 1,088 mujeres del AFE: no es una prueba independiente (con ítems tan raros no conviene
partir la muestra). Las cargas de trabajo y de `p193`–`p194` son las menos confiables. Y los ítems 0/1 como ordinales suponen una variable
latente continua detrás de cada "Sí/No": con eventos raros esa suposición pesa.
