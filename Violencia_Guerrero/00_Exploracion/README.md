# 00 · Exploración de la base

Script: `Exploracion.R`. **Sin referencias:** no hay código, PDF ni diccionario; solo el `.dta`.

**Objetivo:** saber qué trae `cap4_GRO.dta` y qué análisis (AFE, AFC, 2do orden, confiabilidad y
validez, puntajes, invarianza, FIML) se pueden hacer con él. El glosario de variables y la tabla de
viabilidad están en el [README del proyecto](../README.md).

## Qué trae la base

- **294 personas** y 47 columnas: `folio` y **46 ítems**. Todos son escalas de **1 a 10** (enteros).
- **No trae** etiquetas de valor (no se sabe qué significan el 1 ni el 10), ni variable de grupo (sexo,
  edad, municipio...). Los ítems saltan números (`b5`–`b8`, `c9`–`c10`...): es una selección de la
  encuesta original.
- Nadie responde todo igual (0 casos con desviación cero).

## Paso a paso

1. **Lectura.** `read.dta13()` lee bien los acentos de las etiquetas. Rango 1–10 en los 46 ítems.
2. **Diccionario** (`output/diccionario_variables.csv`). Se agrupan los ítems en **12 bloques** por la
   redacción de sus etiquetas: `a1`–`a24` son seis dominios de cuatro ítems y `b`, `c`, `f` son
   percepciones sobre vecinos, autoridades, seguridad y gobierno. Con N, % de faltantes, media, D.E.,
   asimetría y curtosis.
3. **Folio.** No es un identificador único:
   - 3 folios aparecen dos veces. En el **292** coinciden **39 de 41** respuestas (casi seguro es la
     misma encuesta capturada dos veces). En el 135 y el 137 solo coinciden 12 de 44 y 10 de 40
     (parecen personas distintas con el folio repetido por error).
   - Faltan 34 folios entre el 1 y el 325.
   - **No es un número de control inocuo:** 12 de 46 ítems se relacionan con el folio (se esperarían
     ~2): `a9`, `a11`–`a14`, `a16`–`a20`, `c19`, `c20`. Parece reflejar el orden o el lote del
     levantamiento, y no se sabe qué significa. La proporción de personas sin pareja es ~26–30% en los
     tres primeros cuartos de folio y 12% en el último.
4. **Datos faltantes.**
   - Solo **160 de 294** personas (54%) contestan los 46 ítems; 202 contestan los 24 de satisfacción y
     218 los 22 de violencia y clima social.
   - Los más incompletos son `a1`–`a4` (71–74, ~25%), `c6` (38, 13%), `c8` (23, 8%) y `c13` (16, 5%).
   - Los de **pareja son estructurales:** 71 personas no contestan ninguno de los cuatro ítems (casi
     seguro no tienen pareja). Los demás faltantes son esporádicos, salvo que quien no tiene pareja
     también deja en blanco los ítems de familia (11–14% contra ~1%) y `c6` (21% contra 10%).
   - Quien no tiene pareja **no responde distinto** en lo demás: solo `a17` difiere (8.66 contra 7.93,
     p = .007), 1 de 42 ítems (por azar se esperarían ~2). Eso apoya usar FIML (ver
     [`07_FIML`](../07_FIML/)).
5. **Correlaciones.** Los ítems de un bloque correlacionan mucho más entre sí que con los demás:

   | Bloque | k | r media dentro | r mínima dentro | r media fuera |
   |---|---|---|---|---|
   | pareja | 4 | .661 | .563 | .135 |
   | familia | 4 | .671 | .565 | .131 |
   | economia | 4 | .757 | .704 | .219 |
   | social | 4 | .647 | .573 | .194 |
   | personal | 4 | .691 | .604 | .202 |
   | trabajo | 4 | .632 | .581 | .184 |
   | cohesion | 5 | .672 | .608 | .111 |
   | confianza | 4 | .750 | .628 | .137 |
   | inseguridad | 5 | .532 | .402 | −.028 |
   | riesgo | 3 | .568 | .434 | −.005 |
   | libertad | 2 | .640 | .640 | .134 |
   | desempeno | 3 | .746 | .726 | .082 |

   Entre bloques casi siempre es < .30, salvo dos grupos: los **seis dominios de satisfacción** se
   relacionan entre sí (.12–.43) y `confianza`–`desempeno` (.39) e `inseguridad`–`riesgo` (.31). El mapa
   de calor (`output/mapa_correlaciones.png`) muestra los 12 bloques sobre la diagonal.
6. **Distribución** (`output/histogramas_items.png`). En los 46 ítems juntos, el 19% de las respuestas
   es 10 y el 11% es 1, y solo el 3% es 4.
   - **Efecto techo:** en pareja, familia, personal y trabajo, entre 24% y 43% responde 10
     (asimetría de −1.4 a −2.4).
   - **Efecto suelo:** en confianza y desempeño, entre 29% y 42% responde 1 (asimetría positiva; la
     moda es 1, igual que en `c8` y `c13`).
   - **Apilamiento en 5:** el 5 (9.5% de las respuestas) supera en mediana 1.85 veces al promedio de
     4 y 6, y en **33 de 46 ítems** lo supera por más del 50%. Es el punto medio de la escala: hay
     preferencia por esa respuesta.

   No hay normalidad, y con estos efectos tratar los ítems como continuos es un supuesto. Por eso se
   usa **MLR** y se revisa una alternativa ordinal (ver [`02_AFC`](../02_AFC/)).
7. **Sensibilidad al folio 292.** Se ajustan los modelos de cada instrumento con los 294 casos y sin el
   segundo renglón del 292: la mayor diferencia en una carga estandarizada es **.002** (satisfacción) y
   **.0045** (violencia y clima social). Se conservan los 294 casos tal como vienen.

## Qué sigue

Con 46 ítems, 294 personas y solo 160 completas, **no conviene partir de casos completos** como en el
Tren (se perdería el 46% de la muestra y a todas las personas sin pareja; ver [`07_FIML`](../07_FIML/)).
Se trabaja con los 294 y FIML desde el AFE. Y la estructura de 12 bloques es tan clara que el AFE se puede
hacer sobre los 46 ítems a la vez: ver [`01_AFE`](../01_AFE/).

Salidas en `output/`: `diccionario_variables.csv`, `comparacion_con_sin_pareja.csv`,
`correlaciones_dentro_fuera.csv`, `correlaciones_entre_bloques.csv`, `mapa_correlaciones.png` y
`histogramas_items.png`.
