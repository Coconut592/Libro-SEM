# 02 · Análisis Factorial Confirmatorio (AFC) de primer orden

Script: `AFC.R` (unos 10 segundos). **Sin referencia:** el documento de INEGI no trae un modelo. Se confirma la
estructura de cuatro factores que salió del AFE, con los 2,050 casos de agosto de 2026.

**Pregunta:** ¿se confirma la estructura de cuatro factores?

**Respuesta corta: sí.** CFI .975, TLI .969, RMSEA .071, SRMR .048; cargas de .48 a .91. El RMSEA es el punto flojo.

## Paso a paso

1. **Datos y modelo** (igual que en el AFE). Cada ítem va en el factor donde más carga:

   - `HOGA` (hogar hoy): `P1`, `P3`
   - `HOGE` (hogar dentro de 12 meses): `P2`, `P4`
   - `PAIS` (economía del país): `P5`, `P6`, `P12`, `P13`
   - `CONS` (consumo, ahorro y planes): `P7`, `P8`, `P9`, `P10`, `P11`, `P14`, `P15`

2. **Estimación.** Ítems **ordinales (WLSMV)** con `missing = "pairwise"`: se conservan las 115 personas con algún «No
   sabe» (con listwise quedan 1,935). `lavaan` no tiene FIML con ítems ordinales; ver [`07_FIML`](../07_FIML/).

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | **4 factores (pairwise)** | 2,050 | 960 (84) | **.975** | **.969** | **.071** | **.048** |
   | 4 factores (listwise) | 1,935 | 945 (84) | .974 | .968 | .073 | .049 |
   | 4 factores sin `P11` | 2,050 | 679 (71) | .981 | .976 | .065 | .045 |
   | 5 factores (`PLAN` aparte) | 2,050 | 806 (80) | .979 | .973 | .067 | .042 |
   | 1 factor con los 15 ítems | 2,050 | 4,009 (90) | .889 | .870 | .146 | .093 |

   Listwise da lo mismo. Sin `P11` mejora algo, pero se deja (decisión del proyecto). Con 5 factores el avance es
   poco y `PLAN` tendría dos ítems. **Un solo factor ajusta mucho peor:** las cuatro dimensiones son reales.
3. **Cargas estandarizadas** (sin varianzas negativas):

   | Factor | Ítem (carga) |
   |---|---|
   | `HOGA` | `P1` .91, `P3` .89 |
   | `HOGE` | `P2` .90, `P4` .91 |
   | `PAIS` | `P5` .74, `P6` .71, `P13` .66, **`P12` .48** |
   | `CONS` | `P7` .85, `P8` .82, `P9` .79, `P11` .77, `P10` .77, `P14` .72, `P15` .67 |

   Correlaciones entre factores: `HOGA`–`HOGE` .66, `HOGA`–`PAIS` .54, `HOGA`–`CONS` **.79**, `HOGE`–`PAIS` .58,
   `HOGE`–`CONS` .71, `PAIS`–`CONS` .62. El ítem más débil es `P12` (precios).
4. **Índices de modificación** (solo para ver; no se modifica el modelo). Los mayores: `P11` cargaría también en
   `HOGE` (123) y en `PAIS` (99), y los residuales `P14`–`P15` (103), `P5`–`P6` (69) y `P9`–`P10` (68): parejas de
   preguntas muy parecidas. No se agregan: el ajuste ya es bueno.

## ¿Por qué no se pondera? (decisión del proyecto)

El ponderador `FACTOR` (factor de expansión de la población de 18+) **no se usa en los modelos**. Las razones:

1. **Qué se estima.** Un modelo factorial estima cómo se relacionan los ítems con los factores (estructura de
   medida), no totales ni medias de la población. Los ponderadores corrigen probabilidades desiguales de selección para
   *inferir a la población*; si el modelo está bien especificado, estimar con o sin ellos apunta a la misma estructura, y
   ponderar solo agrega varianza.
2. **Cuesta precisión.** Los pesos van de 4,812 a 88,119 (18 a 1) y su efecto de diseño (Kish) es **1.26**: los 2,050
   casos valen como unos **1,630**.
3. **Se probó y no cambia nada.** El mismo modelo ordinal con ponderador (`sampling.weights`):

   | | Sin ponderador | Con ponderador |
   |---|---|---|
   | CFI | .975 | .975 |
   | RMSEA | .071 | .062 |
   | Máx. diferencia en cargas estandarizadas | | .021 |
   | Máx. diferencia en correlaciones entre factores | | .029 |
   | Errores estándar de las cargas (con / sin) | | × 1.10 |

   Mismo ajuste, mismas cargas (hasta .02) y mismas correlaciones entre factores (hasta .03). Con ítems continuos
   (MLR y FIML) el resultado es parecido: hasta .03 en las cargas.
4. **No se puede hacer del todo bien.** Con ítems categóricos `lavaan` 0.6-17 **no admite `cluster`** (`categorical +
   clustered is not supported yet`), así que no se puede corregir por las **583 UPM**; y las tablas no traen variable de
   estrato. Ponderar sin corregir los errores estándar por el diseño daría una precisión engañosa. (Con ítems continuos,
   agrupar por UPM multiplica los errores estándar solo por 1.04: hay a lo más 4 entrevistados por UPM.)
5. **Consistencia** con el resto del libro: EMOVI tampoco pondera.

**Dónde sí se usa el ponderador:** en [`05_Puntajes_Factoriales`](../05_Puntajes_Factoriales/), para la **media de la
población** de los puntajes por grupo (cambia en .03 o menos). **Límite:** si la selección dependiera de las
respuestas aun dado el modelo, los parámetros no ponderados serían sesgados; la sensibilidad indica que aquí no es el
caso. Las cargas describen la **estructura de medida de esta muestra**, no totales poblacionales.

**Salidas** (`output/`): `ajuste_AFC.csv`, `cargas_AFC.csv` y `sensibilidad_ponderador.csv`.

**Cuidado.** El RMSEA de .071 está en la zona aceptable (≤ .08) pero no es bajo. Se confirma con los mismos datos del
AFE.
