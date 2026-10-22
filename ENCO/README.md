# Libro SEM · ENCO

Confianza del consumidor con la **Encuesta Nacional sobre Confianza del Consumidor (ENCO)** de INEGI, periodo
**agosto de 2026** (`0826`). La referencia es el documento de INEGI «Estructura de la base de datos» (6 de octubre
de 2025, `fd_enco_v7.pdf`), que es solo un diccionario: **no hay tesis, script ni modelo previo que replicar**.

Base de trabajo: tres tablas en formato **DBF** (dBase), que se leen directo en R con `foreign::read.dbf`, sin
convertirlas:

| Archivo | Unidad | Filas | Para qué |
|---|---|---|---|
| `encocb_0826.DBF` | Persona de 18+ elegida | 2,050 | Cuestionario básico: los **15 ítems** `P1`–`P15` |
| `encocs_0826.DBF` | Integrante del hogar | 6,670 | Sexo, edad, escolaridad, ocupación, ingreso (grupos y criterios) |
| `encoviv_0826.DBF` | Vivienda | 2,336 | Resultado de la entrevista y tamaño del hogar (no entra al modelo) |

Como marca el `.gitignore` del repositorio, **no se versionan**: cópialas con su nombre original (con `.DBF` en
mayúsculas) a `ENCO/data/`, junto con el PDF si quieres tenerlo a la mano.

## Estado

> **Hecho el diagnóstico** ([`00_Diagnostico/`](00_Diagnostico/)): **la base alcanza para los 7 ejercicios.** Salen
> 4 factores limpios (AFE: CFI .992; AFC: CFI .975, RMSEA .071) y un factor general de segundo orden. Los scripts de
> los 7 ejercicios (`01_AFE` a `07_FIML`) **se hacen cuando se confirmen las decisiones** de abajo.

| Carpeta | Ejercicio | Qué dice el diagnóstico |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué traían los archivos y si alcanzan | ✅ Hecho |
| `01_AFE/` | Análisis factorial exploratorio | Corre: KMO .91, 4 factores (paralelo: 5) |
| `02_AFC/` | AFC de primer orden | Corre: CFI .975, TLI .969, RMSEA .071, SRMR .048 |
| `03_AFC_2do_Orden/` | AFC de segundo orden | Corre: cargas .68 a .92; **se puede contrastar** (2 gl más) |
| `04_Confiabilidad_y_Validez/` | α, CR, AVE, HTMT, criterio | α .73–.91; `PAIS` débil (AVE .43); criterio solo sociodemográfico |
| `05_Puntajes_Factoriales/` | Puntajes factoriales | Corre: 2,050 puntajes; r = .97 con el promedio simple |
| `06_Invarianza_Factorial/` | AFC multigrupo | Corre por sexo, edad, escolaridad y ciudad; cumple Chen |
| `07_FIML/` | Listwise contra FIML | Corre con ítems continuos; aporta poco (5.6 % incompletos) |

## Los 15 ítems y el modelo propuesto

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

## Decisiones propuestas

Conviene revisarlas (el detalle está en el [diagnóstico](00_Diagnostico/README.md#6-qué-necesito)):

| Tema | Decisión |
|---|---|
| Número de factores | **4**, por el ajuste del AFE (el análisis paralelo pide 5, que solo separa auto y casa) |
| `P11` | Se queda en `CONS` (el menos limpio: carga .41 en el AFE) |
| `P12` | Se **funden** «Disminuirán mucho» y «poco» (5 y 26 casos); el código 5 «Aumentarán igual» es ambiguo |
| «No sabe» | A faltante (`NA`); el código cambia por pregunta (6, 4, 3 o 7). `P10` = 4 «No tiene ingresos» también |
| Dirección | Se invierten todas las escalas: **mayor = más confianza** |
| Ítems | Ordinales (**WLSMV**), `missing = "pairwise"` |
| Diseño muestral | **Sin ponderador ni conglomerado** (`FACTOR`, `UPM`), como EMOVI; el diagnóstico revisa la sensibilidad |
| Invarianza | Sexo, edad (18-39 / 40-59 / 60+), escolaridad (4) y gran ciudad (CDMX, Guadalajara, Monterrey) contra resto; umbrales y cargas juntos |
| FIML | Con ítems **continuos** (MLR), porque `lavaan` no tiene FIML con ordinales |

## Lo que conviene tener presente

- **Un solo mes (agosto de 2026):** no hay invarianza en el tiempo ni comparación entre meses.
- **Los ítems no forman una escala homogénea:** mezclan 2, 3, 5 y 6 categorías; `P1`/`P3` y `P2`/`P4` son casi la
  misma pregunta (r de .72 y .74), por eso dos factores tienen solo dos ítems.
- **`PAIS` es el factor débil** (α .73, AVE .43, `P12` carga .48) y **`CONS` no pasa Fornell-Larcker** frente a
  `HOGA` (AVE .597, r² .62): por eso el segundo orden tiene sentido.
- **El ICC oficial no se reproduce:** falta la nota metodológica de INEGI; solo se compara con un promedio simple.
- **El AFC confirma con los mismos datos del AFE:** no se partió la muestra.
- **FIML:** hay faltantes reales (115 «No sabe», 5.6 %), pero el resultado casi no cambia frente a quitarlos.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia los `.DBF` a `ENCO/data/` y en una terminal de R:

```r
source("ENCO/00_setup_paquetes.R")
source("ENCO/00_Diagnostico/Diagnostico.R")   # ~2 min
```

`foreign` viene con R; los demás paquetes los instala `00_setup_paquetes.R`.

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
