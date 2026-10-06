# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 10 segundos). Lo que se revisó: el capítulo
(`Cap_6._AFC_ValidacionFinal.pdf`), su presentación (`CAP_6_AFC_FINAL_VALIDACIÓN.pptx`) y la base
`Cap6_AFC_2orden.dta`. Los modelos del capítulo se corrieron con la base real en R (`lavaan`).

## Resumen

1. **La base alcanza para los 7 ejercicios**, con dos matices: el **FIML** no tiene qué hacer porque no hay
   faltantes (se simulan, ver [`07_FIML`](../07_FIML/)) y la **validez de criterio** no se puede (no hay
   criterio externo).
2. **La base trae solo la versión de 15 ítems.** Faltan `HR5`, `AS12` e `II15`, que el capítulo elimina. El
   primer modelo del capítulo (18 reactivos, χ² = 500.161) **no se puede reproducir**.
3. **El modelo final del capítulo sí se reproduce**: las 19 cargas de su Tabla 5 coinciden con `lavaan` al
   milésimo, y también sus índices de ajuste, **pero solo si se agrega `Genero` como variable adicional**.
   Los números publicados incluyen, sin querer, a una variable que no es parte del modelo (hallazgo 1).
4. **La Tabla 5 del capítulo tiene tres cargas con la etiqueta cambiada** (hallazgo 2).
5. **Lo que el capítulo no hace** y se agregó para completar los siete ejercicios: AFE, confiabilidad
   compuesta, AVE y validez discriminante, puntajes factoriales, invarianza por género y FIML.

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| Capítulo (PDF, 22 págs.) | *Validación del inventario de habilidades políticas de Ferris mediante AFC de segundo orden* (López-Lemus y Zavala). Marco conceptual del PSI, las condiciones de un AFC (Tabla 2), los índices de ajuste (Tabla 4), el AFC de 18 ítems (Tabla 3) y de 15 (Tabla 5), y la sintaxis de **Mplus** (Anexos 1 y 2) | AFC, AFC de 2.º orden |
| Presentación (PPTX, 20 láminas) | Resumen del capítulo con la redacción de los ítems (lám. 11), la matriz de correlaciones de Stata (lám. 15), y el **mismo modelo corrido en R con `lavaan`** (láms. 16–19) | AFC, AFC de 2.º orden, confiabilidad (`alpha` en Stata) |
| `Cap6_AFC_2orden.dta` | **356 filas × 16 columnas**: `Genero` y 15 ítems de 1 a 7, **sin faltantes**, sin etiquetas de variable ni de valor y sin identificador | los 7 |

## 2. Los 7 ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con la base? | Qué falta |
|---|---|---|---|
| AFE | ❌ No | ✅ Sí | — |
| AFC | ✅ Sí (Tabla 5, Anexo 2) | ✅ Sí, solo los 15 ítems | La base de 18 ítems |
| AFC 2.º orden | ✅ Sí, es el tema del capítulo | ✅ Sí | — |
| Confiabilidad y validez | ⚠️ Alfa (Ferris: .90; lám. 16: `alpha`); validez de constructo conceptual | ✅ Sí, **salvo validez de criterio** | Variable criterio |
| Puntajes factoriales | ❌ No | ✅ Sí | `id` del estudiante |
| Invarianza factorial | ❌ No | ✅ **Por género**: hay variable de grupo real | Etiquetas de `Genero` |
| FIML | ⚠️ Solo `Missing are all (-9999)` | ⚠️ **No hay faltantes**: ejercicio con datos simulados | Una base con faltantes reales |

## 3. Lo que se encontró

### Hallazgo 1. El ajuste publicado incluye a `Genero` en el modelo

Con 15 ítems, el modelo de segundo orden tiene **86 gl** (120 momentos − 34 parámetros). El capítulo
publica **101 gl**. Esos 15 gl de diferencia son lo que agrega **una variable más**: con `Genero` como
variable 16 hay 136 momentos y 35 parámetros (su varianza), es decir, 101 gl. La sintaxis del Anexo 2
declara `Genero` en `Names are` y **no trae `USEVARIABLES`**: Mplus usa entonces todas las variables de
`Names` y a `Genero` la deja sin relación con nada.

Agregándola en `lavaan` (`Genero ~~ Genero`, sin covarianzas) salen **exactamente** los números del capítulo:

| | χ² | gl | CFI | TLI | RMSEA | SRMR | BIC ajustado |
|---|---|---|---|---|---|---|---|
| Capítulo (Mplus) | 273.894 | 101 | .926 | .912 | .069 | .048 | 17026.484 |
| `lavaan` **con** `Genero` | 273.894 | 101 | .926 | .912 | .069 | .051 | 17026.484 |
| `lavaan` **sin** `Genero` (el modelo que el capítulo describe) | **246.604** | **86** | **.931** | **.915** | **.072** | **.048** | 16507.580 |

- El BIC ajustado de Mplus (17026.484) coincide con el modelo con `Genero` **y estructura de medias**
  (Mplus estima siempre las medias).
- El SRMR publicado (.048) es el del modelo **sin** `Genero`; con ella da .051.
- La lámina 19 de la presentación, columna **R**, trae el modelo bien especificado (χ² = 246.604).
- **Lo que cambia con el modelo correcto:** χ²/gl pasa de 2.71 a **2.87**, el RMSEA de .069 a **.072**, y
  CFI y TLI mejoran un poco. **Las conclusiones del capítulo no cambian** (CFI y TLI > .90, RMSEA < .08,
  SRMR < .05), pero los números que se citen deben ser los de la fila de abajo.
- Lo que no se pudo ver es el archivo `HP15R.dta.dat` que usó Mplus, así que esto es una **explicación
  consistente con los 6 números**, no una verificación directa.

### Hallazgo 2. Tabla 5: AS10, AS11 y AS13 tienen los valores de otro ítem

Comparando por etiqueta, 16 de las 19 cargas de la Tabla 5 coinciden con `lavaan`. Las otras tres no:

| Etiqueta en la Tabla 5 | Carga publicada | Carga de ese ítem en `lavaan` | Es la carga de… |
|---|---|---|---|
| `AS10` | .693 | .655 | `AS11` |
| `AS11` | .626 | .693 | `AS13` |
| `AS13` | .655 | .626 | `AS10` |

Los **tres valores publicados sí existen en el modelo**, pero asignados a otro ítem. Se reproducen los 19
(cargas y errores estándar, con diferencias de ≤ .001) si se lee la tabla en el orden de las columnas de la
base (`AS11 AS13 AS10 AS14`, que es también el orden del Anexo 2) en lugar del orden numérico. La salida de
R de la lámina 17 de la presentación sí trae `AS10 = .655`, `AS11 = .693`, `AS13 = .626`. O bien la tabla
está mal etiquetada, o bien los nombres de las columnas de la base están en otro orden: **hay que
confirmarlo con las autoras** (es lo que cambia qué ítem es el más débil de Astucia social: `AS13`, .63).

### Otras diferencias menores entre los documentos

- La lámina 19 escribe **89 gl** para el modelo en R; con χ² = 246.604 el modelo solo puede tener 86. Su
  BIC (16586.903) no coincide con ningún modelo probado (16574.9 el de segundo orden, 16586.5 el de
  primer orden): probablemente una transcripción.
- La Tabla 5 imprime RMSEA = .06, y el texto dice .069 (que redondea a .07).
- **Tabla 3 (18 ítems), no verificable:** los ítems que se eliminan (HR5 .661, AS12 .717, II15 .666) no son
  los de menor carga de esa tabla (HR3 .522, AS14 .554, HR6 .606...), aunque el texto dice que se eliminaron
  "especialmente aquellos que cuentan con las cargas factoriales más bajas" y que se valoró su contenido.
  Y HR3 sube de .522 (18 ítems) a .755 (15 ítems) al quitar solo HR5, un salto grande. Con el
  problema de etiquetas de la Tabla 5, conviene revisar también esta tabla contra la base de 18 ítems.

### Hallazgos de la base

1. **Ítems:** 15, todos entre 1 y 7, sin faltantes. Medias de 4.9 a 5.9; asimetría negativa (−0.5 a
   −1.5; `SA7` y `SA8` son las más sesgadas, con 40% y 33% respondiendo "7"). Kaiser-Meyer-Olkin = **.92**.
2. **`Genero`:** el `.dta` guarda 1 (n = 161) y 2 (n = 195) sin etiqueta. El capítulo reporta 161 hombres y
   195 mujeres, así que **1 = hombre y 2 = mujer** (deducido de las frecuencias).
3. **Sin identificador.** Hay 36 renglones repetidos exactos (41 si se ignora el género); con ítems
   concentrados en 5–7 es plausible por azar. No se elimina ninguno.
4. **No normalidad.** La prueba de Mardia rechaza la normalidad multivariada (asimetría y curtosis,
   p < .001). El capítulo usa ML (Mplus) y aquí también, pero se verifica con MLR y con un tratamiento
   ordinal ([`02_AFC`](../02_AFC/)).
5. **Condiciones de la Tabla 2 del capítulo** (revisadas con la base): todas se cumplen —más de 2 ítems por
   factor (5, 3, 4 y 3), KMO .92 > .50, 23.7 observaciones por ítem (≥ 5), sin datos perdidos— **salvo la
   última, la multicolinealidad entre latentes**: las correlaciones entre dimensiones van de .66 a **.89**
   (SA–AS). Es la clave de varios resultados posteriores.
6. **Estructura real de los datos:** el AFE no recupera los cuatro factores de la teoría limpiamente (el
   análisis paralelo recomienda 3) y, por género, hay una solución inadmisible en los hombres (SA y AS
   correlacionan 1.05) ([`01_AFE`](../01_AFE/), [`06_Invarianza_Factorial`](../06_Invarianza_Factorial/)).

## 4. Qué conviene confirmar con las autoras

| Pregunta | Por qué importa |
|---|---|
| ¿Cuál es el archivo de Mplus (`HP15R.dta.dat`) y trae `Genero`? | Confirmar el hallazgo 1 |
| ¿Están bien las etiquetas de `AS10`, `AS11` y `AS13` en la Tabla 5 o en la base? | Hallazgo 2 |
| La base de **18 ítems** (con `HR5`, `AS12` e `II15`) | Reproducir la Tabla 3 y el criterio para eliminar ítems |
| Qué significan `Genero` = 1 y 2 | Está deducido de las frecuencias |
| El número de ítem de cada frase del PSI | La presentación da la redacción por factor pero no por número (ver el glosario en [`../README.md`](../README.md)) |
| Una variable criterio (desempeño, ascensos u otra medida) | Validez de criterio |
