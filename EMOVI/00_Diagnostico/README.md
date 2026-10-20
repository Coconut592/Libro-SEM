# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 40 segundos). Lo que se revisó: las dos tesis (la completa,
`Tesis_Modelo_SEM_Movilidad_Social_CDMX_3jul2020_final.pdf`, y `Tesis_SEMOVI.pdf`, que son las págs. 29 a 54
escaneadas de la misma tesis), el diccionario `Diccionario_ESRU_EMOVI_2023.xlsx` (hojas Hogar y Entrevistado)
y las bases `hogar_2023.dta` e `ingreso_2017.dta`. Cada cifra sale de las bases reales, en R (`lavaan`, `psych`).

> **Actualización:** este diagnóstico se hizo antes de tener el Entrevistado 2023. Ya llegó (recortado a la CDMX,
> 740 casos) y los 7 ejercicios están hechos en [`01_AFE`](../01_AFE/) a [`07_FIML`](../07_FIML/). Lo que sigue
> es el diagnóstico original; `Recortar_Entrevistado.R` generó el archivo de trabajo.

## Resumen

1. **Con lo que se subió no se pueden hacer los análisis de movilidad social.** Falta el archivo del
   **Entrevistado de la ESRU-EMOVI 2023** (294 variables según el diccionario: hogar de origen a los 14 años,
   padres, ocupaciones, riqueza, salud mental…). Lo que hay es el *roster* del hogar y **una sola variable** de
   ingreso de 2017.
2. **El roster sí corre los 7 ejercicios, pero solo sobre 11 dificultades funcionales** (`p12_1`–`p12_11`):
   no es el tema y la batería es rarísima (0.13 % a 4.61 %; el 90.5 % no tiene ninguna). Sirve para probar el
   código, no para un capítulo (hallazgo 4).
3. **`ingreso_2017.dta` no tiene estructura factorial** (una variable, `ingc_pc`) y **no se une** con el roster
   2023: es otra ola y otra llave (hallazgo 2).
4. **Con el Entrevistado 2023, según el diccionario, los 7 ejercicios son factibles** (sección 2) y el modelo de
   la tesis se reconstruye, con dos huecos: **no viene el ISEI** (se usan las 6 clases ocupacionales que sí trae) y
   **no hay "edad a la que dejó la escuela"** (hallazgos 5 y 6).
5. **Lo que la tesis no hace** y se agregaría: AFE, AFC de 2.º orden, invarianza de medida (compara trayectorias
   entre sexos y edades con pruebas de Wald sin probar antes que el instrumento mide igual) y puntajes (salvo el
   índice de riqueza).
6. **El FIML tiene una trampa:** en `lavaan` no existe con ítems ordinales (hallazgo 7). Sí con indicadores
   continuos, que es el caso del SEM de la tesis.

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| `hogar_2023.dta` | *Roster* de la ESRU-EMOVI 2023: **55,477 integrantes** de **17,843 hogares** × 56 variables (sexo, edad, parentesco, escuela `p8`–`p10`, actividad `p11` y 11 dificultades funcionales `p12`–`p15`). `p5 == 1` marca al entrevistado | Solo la batería `p12` (no es movilidad) |
| `ingreso_2017.dta` | **17,665 × 2**: `folio` (22 dígitos, texto) e `ingc_pc` (ingreso per cápita del hogar, 2017) | Ninguno (una variable) |
| `Diccionario_ESRU_EMOVI_2023.xlsx` | Hoja **Hogar** (56 variables, coincide con `hogar_2023.dta`) y hoja **Entrevistado** (294 variables) | Describe la base que **falta** |
| Tesis completa (79 págs.) | Sánchez Flores (UNAM, 2019): SEM tipo Blau y Duncan con la ESRU-EMOVI **2017**, Ciudad de México (n = 3,117), en Mplus | AFC (3 latentes), SEM, grupos por sexo y edad, FIML, índice de riqueza (CFA binario) |
| `Tesis_SEMOVI.pdf` (26 págs.) | Págs. 29–54 de la misma tesis (escaneadas, sin texto): variables, AFC y resultados | Igual |

## 2. Los ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con lo subido? | ¿Con el Entrevistado 2023? (según el diccionario) | Qué falta |
|---|---|---|---|---|
| AFE | ❌ No: la tesis va directo al AFC | ⚠️ Solo `p12` (no es movilidad) | ✅ Riqueza (`p26`–`p32`), carencias (`p106`), depresión (`p107`), colonia (`p33`, `p98`) | El Entrevistado |
| AFC | ✅ Sí: Origen social, Educación, Primera ocupación y el índice de riqueza (CFA binario, n = 17,665) | ⚠️ Solo `p12` | ✅ Los de la tesis y la riqueza del hogar | El Entrevistado |
| AFC 2.º orden | ❌ No | ⚠️ Corre, pero da un caso Heywood (hallazgo 4) | ✅ Riqueza (vivienda, casa, bienes, activos) u Origen social (riqueza, educación y ocupación de los padres) | Decidir el modelo |
| Confiabilidad y validez | ⚠️ α, Ω y KR-20; **validez no** | ⚠️ Solo `p12` (α ordinal .935) | ✅ α, ω, KR-20, AVE, discriminante; criterio externo con `p103`/`p104` o `ingc_pc` | Documento de validez |
| Puntajes factoriales | ⚠️ Solo el índice de riqueza (Anexo 2) | ⚠️ Solo `p12`: el 90.5 % recibe el mismo puntaje | ✅ Índice de riqueza y de las demás escalas | El Entrevistado |
| Invarianza factorial | ❌ **No**: compara coeficientes con Wald, sin probar la medida | ⚠️ `p12` por sexo pasa (ΔCFI = +.001) | ✅ Sexo, cohorte (4), región (5), rural-urbano; y **14 años vs hoy** (los mismos 9 ítems de colonia) | Definir el grupo |
| FIML | ✅ Sí: en el SEM (ISEI de la madre en 1,149 de 3,117; ocupación actual en 1,911) | ❌ `p12` no tiene faltantes | ✅ En el SEM, con indicadores continuos. ⚠️ Con ítems binarios no hay FIML en `lavaan` (hallazgo 7) | Decidir el tratamiento |

## 3. Lo que se encontró

### Hallazgo 1. Falta el archivo del Entrevistado

El diccionario describe dos bases. `hogar_2023.dta` es la primera: sus 56 columnas coinciden exactamente con la hoja
Hogar. **La segunda, la del Entrevistado, no está.** De sus 294 variables solo `index`, `edad`, `p8`, `p9` y `p10`
coinciden por nombre con el roster. Las dos hojas empiezan con `index` ("Folio identificador"), que debería ser la
llave para unirlas.

### Hallazgo 2. `ingreso_2017.dta` es una variable y de otra ola

- **17,665 filas**, el N de la ESRU-EMOVI 2017 según la tesis, con 17,665 folios únicos de 22 dígitos.
- `ingc_pc`: mínimo 277, mediana 3,335, media 5,561, máximo 152,903; asimetría 6.8; sin faltantes ni ceros.
- Con una sola variable no hay AFE ni AFC. Tampoco se une con el roster 2023: las dos EMOVI son **muestras
  independientes** (no un panel) y `index` (2 a 28,647) no es el `folio` (ningún folio coincide).
- Cuidado con el nombre: el diccionario del Entrevistado 2023 lista **su propia** `ingc_pc` (la última variable),
  así que el ingreso 2023 debería venir dentro de ese archivo. `ingreso_2017.dta` es el archivo de ingreso que la
  EMOVI 2017 distribuye aparte; solo serviría como criterio externo si se trabajara el Entrevistado 2017.

### Hallazgo 3. Lo que el roster sí da del tema

- **17,843 entrevistados** (`p5 == 1`), de **25 a 64 años** (la población objetivo de la EMOVI): 9,947 mujeres y
  7,896 hombres.
- Nivel de estudios (`p9`) en 17,842 y con grado (`p10`) en 17,489. Alcanza para la **Educación** del
  entrevistado, pero `y6` y `y7` de la tesis salen del mismo par de preguntas: no son indicadores independientes.
- Padre o madre del entrevistado en el hogar hoy: **3,084 hogares (17.3 %)**. No sirven como origen social: es el
  hogar **actual**, no el de los 14 años, y es un subconjunto selecto (padres vivos que conviven con el hijo).

### Hallazgo 4. La batería `p12` corre los 7 ejercicios, pero no sirve para el libro

Once dificultades Sí/No por integrante (ver, oír, caminar, recordar, bañarse/vestirse, comunicarse, relacionarse,
autocuidado, comodidad ante situaciones, contacto físico, estabilidad emocional). `Diagnostico.R` la analiza
completa (55,477 personas):

| Qué se ve | Resultado |
|---|---|
| Prevalencias | De **0.13 %** (`p12_10`, 73 personas) a **4.61 %** (`p12_1`). **Las 11 caen bajo el criterio 90-10 de la propia tesis** (Anexo 2: se excluye lo que tiene menos de 10 % o más de 90 %) |
| Sin dificultad | **90.5 %** no tiene ninguna (coincide exactamente con `p12_97`, "puede realizar todas las actividades") |
| Faltantes | **0**: el FIML no aplica (`p13`–`p15` faltan por salto de pregunta, no al azar) |
| Personas con las dos dificultades de una pareja | Mínimo **8**, mediana 58 (de ahí salen las tetracóricas) |
| AFE (tetracórica, mínimos residuales) | KMO .85; el análisis paralelo pide **4** factores; RMSEA **.245 / .253 / .224** y TLI .71 / .69 / .76 con 1, 2 y 3 factores: ninguno ajusta |
| AFC (WLSMV) | 1 factor: CFI .961, RMSEA .020, SRMR .088. 3 factores (sensorial, cognitivo, social; supuesto mío): CFI .981, RMSEA .014, SRMR .052. **El AFE y el AFC dan veredictos opuestos sobre los mismos ítems** |
| 2.º orden | Con 3 factores queda justo identificado (mismo ajuste). **Varianza residual negativa** en `COG` (−0.012) y carga estandarizada de 1.01 (caso Heywood); `COG`–`SOC` correlacionan .88 |
| Confiabilidad | α ordinal .935, CR .948, AVE .636 (1 factor) |
| Puntajes | **235** patrones de respuesta en 55,477 personas; el 90.5 % comparte el mismo puntaje |
| Invarianza por sexo (26,952 hombres, 28,506 mujeres; 19 "otro" fuera) | Configural CFI .981, RMSEA .014; umbrales y cargas iguales CFI .982, RMSEA .013: pasa, pero con ítems tan raros casi cualquier cosa pasa |
| Independencia | 3.1 personas por hogar: las observaciones no son independientes y no hay variable de agrupación útil |

Conclusión: técnicamente corre todo (sirve para probar el código y los paquetes), pero **no hay un resultado
interpretable**, y no es movilidad social.

### Hallazgo 5. Qué pide la tesis y dónde está en 2023

Cada fila es una variable manifiesta de la Tabla 1 de la tesis. Todas las variables 2023 marcadas existen en la hoja
Entrevistado del diccionario (se verifica en el script); solo `p9` y `p10` están también en el roster.

| Latente | Variable de la tesis | Variables 2023 | Estatus | Nota |
|---|---|---|---|---|
| Origen social | `x1 pisei_oc`: ISEI del padre | `p48_SINCO`, `cmop`, `clasep` | Construir | **No hay ISEI**: falta la tabla SINCO → CIUO-08 → ISEI-08 |
| | `x2 misei_oc`: ISEI de la madre | `p54_SINCO`, `cmom`, `clasem` | Construir | Igual; en 2017 solo 1,149 de 3,117 tenían dato |
| | `x3 ind_or`: índice de riqueza | `p25`, `p26a–e`, `p29a–g`, `p30`, `p31a–o`, `p32a–o` (44) | Construir | CFA binario (tesis: 12 de 26 ítems, n = 17,665); los ítems 2023 no son idénticos |
| | `x4 pmax_edu`: máx. nivel de los padres (6) | `p42a/b`, `p43a/b` | Construir | `educp` y `educm` traen 4 categorías, no 6 |
| | `x5 anesc_p`: años de escolaridad de los padres | `p42a/b`, `p43a/b` | Construir | Falta la regla nivel + grado → años |
| Educación | `y6 Educ`: nivel (6) | `p9`, `p10` (`educ` trae 4) | Construir | También en el roster |
| | `y7 Anesc`: años de escolaridad | `p9`, `p10` | Construir | Mismo par que `y6` |
| | `y8 p64`: edad a la que dejó la escuela | — | **No existe** | `p61` es la edad en que dejó de **trabajar**; `p8`, si asiste hoy |
| Primera ocupación | `y9 p98`: edad al primer empleo | `p77` | Directo | |
| | `y10 jisei_1o`: ISEI del primer empleo | `p79_SINCO`, `cmoe1`, `clase1` | Construir | Sin ISEI; en la tesis su carga fue .31 |
| Logro ocupacional | `z4 jisei_oc`: ISEI actual | `p64_SINCO`, `cmo`, `clase`, `ocup` | Construir | Solo ocupados: en 2017, 1,911 de 3,117 |
| Demográficas, muestra y diseño | edad y sexo; CDMX | `edad`, `sexo`, `cohorte`; `entidad` (CDMX = 9) | Directo | |
| | diseño muestral | `factor`, `upm_muestra`, `est` | Directo | La tesis no los menciona |

De las 11 manifiestas: **1 directa, 9 por construir (4 de ellas necesitan el ISEI) y 1 que no existe.** Sin `y8`, la
latente Educación queda con dos indicadores derivados del mismo par de preguntas.

### Hallazgo 6. Bloques de ítems del Entrevistado 2023 para AFE, AFC, 2.º orden e invarianza

Según el diccionario (sin la base no se sabe el N, los faltantes ni las prevalencias). El `NS` viene como **8**: habrá
que pasarlo a faltante antes de analizar (en PREP pasó lo mismo con el 99).

| Bloque | Variables | Ítems | Respuestas |
|---|---|---|---|
| Riqueza del hogar de origen (14 años) | `p26a–e`, `p29a–g`, `p31a–o`, `p32a–o` (+ `p25`, `p30`) | 42 (+ 2) | Sí / No / NS |
| Colonia a los 14 años | `p33a–i` | 9 | Sí / No / NS |
| Riqueza del hogar actual | `p94a–g`, `p95a–e`, `p96a–r`, `p97a–n` | 44 | Sí / No |
| Colonia actual | `p98a–i` | 9 | Sí / No / NS |
| Carencias: qué es indispensable | `p105a–o` | 15 | Sí es necesario / No / NS |
| Carencias: qué tiene el hogar | `p106a–o` | 15 | Sí / No por falta de recursos / No lo quieren / No, otra razón |
| Depresión | `p107a–g` (`p107g`, "disfrutó de la vida", es positivo) | 7 | 4 frecuencias (de "rara vez" a "todo el tiempo") |
| Ansiedad | `p108a–b` | 2 | 4 frecuencias |

También hay la posición subjetiva del hogar (`p103` ahora, `p104` a los 14 años, escala 1 a 10) y `p109`
(igualdad de oportunidades), útiles como criterio externo. Los **mismos 9 ítems de colonia** a los 14 años y hoy
permiten una invarianza **en el tiempo**; los bienes del hogar (`p31` frente a `p96`) la permiten solo para los
ítems en común.

### Hallazgo 7. FIML con ítems ordinales

Probado en `lavaan` 0.6-17 con ítems binarios y faltantes: `missing = "fiml"` con `ordered` da
`ERROR: missing = "fiml" not available in the categorical setting`. Quedan **`pairwise`** (con WLSMV), **`listwise`**
o **tratar los ítems como continuos con MLR + FIML**. El SEM de la tesis (ISEI, años, edades) sí es continuo.
La tesis dice usar WLSMV "con FIML" en el índice de riqueza; en Mplus, WLSMV maneja los faltantes por pares
disponibles, así que conviene confirmar qué se hizo.

### Hallazgo 8. Observaciones sobre la tesis (para tenerlas presentes al replicar)

- **El ajuste "satisfactorio" no lo es del todo.** SRMR de .108 (general), .115 (sexo) y .123 (edad), y el
  modelo por edad tiene **TLI = .899 y RMSEA = .089**: por sus propios criterios (Cuadro 6: TLI > .90; RMSEA cerca
  de .09, "poco deseable") no cumple.
- **Primera ocupación es una latente débil:** dos indicadores, carga del ISEI .31, α = .31, Ω = .65.
- **Educación:** la figura 5 da α = .73 y el texto repite α = .59 (el de Origen social). Y donde dice "Omega…
  inferior a 0.07" debe ser 0.7.
- En 5.4 la latente exógena se llama "Capital social" y en el resto del texto, "Origen social".
- **No hay invarianza de medida:** compara coeficientes entre sexos y grupos de edad (Wald) sin probar antes que
  Origen social, Educación y Primera ocupación se miden igual en los grupos. Es justo el ejercicio que falta.

## 4. Qué necesito

**Documentos:**

1. **El archivo del Entrevistado de la ESRU-EMOVI 2023** (`.dta`, 294 variables). Es lo único indispensable. Como
   pesa 39 MB, se recorta a la CDMX con [`Recortar_Entrevistado.R`](Recortar_Entrevistado.R) antes de subirlo.
2. Si se quiere **replicar la tesis con 2017**: el Entrevistado 2017 (se une con `ingreso_2017.dta` por `folio`) y
   su diccionario.
3. ~~La tabla SINCO → CIUO-08 → ISEI-08~~ **Ya no hace falta:** se usan las 6 clases ocupacionales.
4. La **regla de conversión nivel + grado → años de escolaridad** (el Cuadro 5 de la tesis da las 6 categorías,
   no los años).
5. Un **documento de validez** (en el Tren se usó SEM06) y, si se quiere validez de criterio, confirmar cuál es
   el criterio (¿`p103`/`p104`, `ingc_pc`?).

**Decisiones (ya tomadas):**

1. **Solo la CDMX** (`entidad` = 9), como la tesis.
2. **Las 6 clases ocupacionales** de la base (`clase`, `clasep`, `clasem`, `clase1`), sin ISEI. Esto elimina la
   necesidad de la tabla SINCO → ISEI (punto 3 de arriba).
3. **Sin ponderador**, como la tesis.
4. **Una sola escala para los ejercicios:** la riqueza del hogar de origen (`p26`, `p29`, `p31`, `p32`), con ítems
   binarios como ordinales (WLSMV) y el criterio 90-10 de la tesis; **2.º orden** con los bloques que salgan del AFE
   (vivienda, bienes y activos, a priori); invarianza por sexo y por 25–40 contra 41–64 años. El **FIML** va en el AFC
   de Origen social con indicadores continuos (MLR). Se confirma con los datos.
5. El Entrevistado no cabe como adjunto (39 MB): se recorta a la CDMX con `Recortar_Entrevistado.R`.

Los puntos 2 y 4 de los documentos siguen pendientes: la regla nivel + grado → años de escolaridad y, si se quiere
validez de criterio, confirmar el criterio (`p104`, `ingc_pc`).

Salidas (en `output/`, que no se versiona): `mapeo_tesis_2023.csv`, `bloques_items_2023.csv`,
`bateria_dificultades_prevalencia.csv` y `bateria_dificultades_ajuste.csv`.
