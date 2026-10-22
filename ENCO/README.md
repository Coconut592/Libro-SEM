# Libro SEM · ENCO

Confianza del consumidor con la **Encuesta Nacional sobre Confianza del Consumidor (ENCO)** de INEGI, periodo
**agosto de 2026** (`0826`). La referencia es el documento de INEGI «Estructura de la base de datos» (6 de octubre
de 2025, `fd_enco_v7.pdf`), que es solo un diccionario: **no hay tesis, script ni modelo previo que replicar**. El
modelo sale del AFE y del contenido de las preguntas.

Base de trabajo: tres tablas en formato **DBF** (dBase), que se leen directo en R con `foreign::read.dbf`, sin
convertirlas:

| Archivo | Unidad | Filas | Para qué |
|---|---|---|---|
| `encocb_0826.DBF` | Persona de 18+ elegida | 2,050 | Cuestionario básico: los **15 ítems** `P1`–`P15` |
| `encocs_0826.DBF` | Integrante del hogar | 6,670 | Sexo, edad, escolaridad, ocupación, ingreso (grupos y criterios) |
| `encoviv_0826.DBF` | Vivienda | 2,336 | Resultado de la entrevista y tamaño del hogar (no entra al modelo) |

Como marca el `.gitignore` del repositorio, **no se versionan**: cópialas con su nombre original (con `.DBF` en
mayúsculas) a `ENCO/data/`, junto con el PDF si quieres tenerlo a la mano.

## Qué se hizo

> **Una sola escala para los ejercicios:** los 15 ítems de opinión (`P1`–`P15`) sobre la situación económica, con **4
> factores** (hogar hoy, hogar dentro de 12 meses, país, consumo y ahorro) y un factor general de segundo orden:
> **Confianza del consumidor**.

| Carpeta | Ejercicio | Resultado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué traían los archivos y si alcanzan | La base alcanza para los 7 ejercicios |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 4 factores (CFI .992, RMSEA .053); Kaiser pide 2 y el paralelo 5 |
| [`02_AFC/`](02_AFC/) | AFC de primer orden | CFI .975, TLI .969, RMSEA .071; cargas de .48 a .91; sin ponderador (justificado) |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | Cargas .68–.92; mismo ajuste; **contrastable** (2 gl más) |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | α ordinal, CR, AVE, HTMT, omega, criterio | α .73–.91; `PAIS` flojo (AVE .43); HTMT ≤ .77; criterio: edad −.33 |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes factoriales | 2,050 puntajes; r = .97 con el promedio simple; baja con la edad |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo | Sexo, edad, escolaridad y ciudad: cumplen Chen; la χ² rechaza umbrales |
| [`07_FIML/`](07_FIML/) | Listwise contra FIML | 1,935 → 2,050 casos; casi no cambia nada (ítems continuos) |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los resultados.
Las tablas se guardan en su `output/`, que no se versiona. **Cada script es independiente.**

## Los 15 ítems y el modelo

Todos son de opinión sobre la situación económica; el código 1 es siempre la respuesta más optimista (se invierten
para que mayor = más confianza). Los marcados con **ICC** son las cinco preguntas del Índice de Confianza del
Consumidor.

| Factor | Ítems |
|---|---|
| `HOGA` Hogar hoy | `P1`, `P3` (ICC): situación económica de usted y del hogar, frente a hace 12 meses |
| `HOGE` Hogar esperado | `P2`, `P4` (ICC): la misma, dentro de 12 meses |
| `PAIS` Economía del país | `P5` (ICC), `P6` (ICC), `P12` (precios), `P13` (empleo) |
| `CONS` Consumo, ahorro y planes | `P7`, `P8` (ICC), `P9`, `P10`, `P11`, `P14`, `P15`: compras, vacaciones, ahorro, auto y casa |
| `CONF` (2.º orden) | Confianza del consumidor |

## Decisiones que se tomaron

| Tema | Decisión |
|---|---|
| Número de factores | **4**, por el ajuste del AFE (el análisis paralelo pide 5, que solo separa auto y casa en un factor de dos ítems) |
| `P11` | **Se queda** en `CONS`, aunque es el ítem menos limpio (sin él el RMSEA baja de .071 a .065) |
| `P12` | **No se funde**: se queda con sus 6 categorías (el código 5, «Aumentarán igual», es ambiguo). Consecuencia: en la invarianza solo se pueden usar agrupaciones sin categorías vacías |
| «No sabe» | A faltante (`NA`); el código cambia por pregunta (6, 4, 3 o 7); `P10` = 4 «No tiene ingresos» también |
| Dirección | Se invierten todas las escalas: **mayor = más confianza** |
| Ítems | Ordinales (**WLSMV**), `missing = "pairwise"` |
| Diseño muestral | **Sin ponderador ni conglomerado** en los modelos (ver abajo) |
| Invarianza | **Sexo, edad (18-39 / 40-59 / 60+), escolaridad (hasta secundaria / medio superior o más) y gran ciudad (CDMX, Guadalajara, Monterrey) contra resto.** Las agrupaciones con más categorías dejan categorías vacías en `P12` |
| FIML | Solo con los **faltantes reales** («No sabe»), con ítems **continuos** (MLR), porque `lavaan` no tiene FIML con ordinales. **Sin faltantes simulados** |

### ¿Por qué sin ponderador?

1. **Qué se estima:** la estructura de medida (cómo se relacionan ítems y factores), no totales ni medias de la
   población; con el modelo bien especificado, ponderar o no apunta a la misma estructura y ponderar agrega varianza
   (efecto de diseño 1.26: los 2,050 casos valen como unos 1,630).
2. **Se probó:** con el mismo modelo ordinal, ponderado y sin ponderar dan el mismo CFI (.975), cargas que difieren
   hasta .02 y correlaciones entre factores hasta .03.
3. **No se puede hacer del todo bien:** con ítems categóricos `lavaan` no admite conglomerados (583 UPM) y las tablas no
   traen estrato, así que los errores estándar ponderados serían engañosamente precisos.
4. **Consistencia** con EMOVI. **Donde sí se pondera:** la media poblacional de los puntajes por grupo (05).

Detalle y tabla de sensibilidad en [`02_AFC`](02_AFC/README.md#por-qué-no-se-pondera-decisión-del-proyecto).

## Lo que conviene tener presente

- **Un solo mes (agosto de 2026):** no hay invarianza en el tiempo ni comparación entre meses.
- **Los ítems no forman una escala homogénea:** mezclan 2, 3, 5 y 6 categorías; `P1`/`P3` y `P2`/`P4` son casi la
  misma pregunta (r de .72 y .74), por eso dos factores tienen solo dos ítems.
- **`PAIS` es el factor débil** (α .73, AVE .43, `P12` carga .48) y **`CONS` no pasa Fornell-Larcker** frente a
  `HOGA` (AVE .597, r² .62): por eso el segundo orden tiene sentido.
- **El AFC confirma con los mismos datos del AFE:** no se partió la muestra.
- **Invarianza:** por Chen se cumple, pero la χ² rechaza la igualdad de umbrales; en varios grupos hay categorías con 1
  a 4 casos.
- **FIML:** hay faltantes reales (115 «No sabe», 5.6 %), pero el resultado casi no cambia frente a quitarlos.
- **El ICC oficial no se reproduce:** falta la nota metodológica de INEGI; solo se compara con un promedio simple de
  las mismas cinco preguntas.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia los `.DBF` a `ENCO/data/` y en una terminal de R (los tiempos
son aproximados):

```r
source("ENCO/00_setup_paquetes.R")
source("ENCO/01_AFE/AFE.R")                                          # ~25 s
source("ENCO/02_AFC/AFC.R")                                          # ~10 s
source("ENCO/03_AFC_2do_Orden/AFC_2do_Orden.R")                      # ~5 s
source("ENCO/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~40 s
source("ENCO/05_Puntajes_Factoriales/Puntajes_Factoriales.R")        # ~40 s
source("ENCO/06_Invarianza_Factorial/Invarianza_Factorial.R")        # ~30 s
source("ENCO/07_FIML/FIML.R")                                        # ~5 s
```

`foreign` viene con R; los demás paquetes los instala `00_setup_paquetes.R`. El diagnóstico previo (qué traían los
archivos) corre con `source("ENCO/00_Diagnostico/Diagnostico.R")` (~2 min).

## Referencias

- Instituto Nacional de Estadística y Geografía (2025). *Encuesta Nacional sobre Confianza del Consumidor. Estructura
  de la base de datos* (6 de octubre de 2025).
- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance. *Structural
  Equation Modeling, 14*(3), 464–504.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables and
  measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in
  variance-based structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1), 115–135.
- Millsap, R. E., & Tein, J.-Y. (2004). Assessing factorial invariance in ordered-categorical measures.
  *Multivariate Behavioral Research, 39*(3), 479–515.
- Sobre la composición del ICC (fuente secundaria; falta confirmarla con la nota técnica de INEGI): «Confianza del
  consumidor (1/2)», *La Razón*, 9 de octubre de 2023, <https://www.razon.com.mx/opinion/2023/10/09/confianza-del-consumidor-12/>.
