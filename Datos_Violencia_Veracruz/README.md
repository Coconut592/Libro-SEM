# Libro SEM · Datos Violencia Veracruz

Base de trabajo: `data/BASE_ACLnew.dta` (Stata 13), encuesta sobre violencia contra las mujeres en Veracruz. **No se versiona
en el repositorio** (son microdatos de una encuesta sobre violencia): cópiala manualmente a
`Datos_Violencia_Veracruz/data/BASE_ACLnew.dta` antes de correr los scripts.

Encuesta a **1,089 mujeres** con variables sociodemográficas y **24 indicadores dicotómicos de
violencia** (0 = No, 1 = Sí) en 6 ámbitos, que son los candidatos para el modelo de clases latentes.

| Ámbito | Variables | Prevalencia de "Sí" (% válidos) |
|---|---|---|
| Niñez | `p141`–`p144` | 4.6 – 34.3 |
| Familia (último año, sin pareja) | `p161`, `p162`, `p165` | 2.5 – 10.9 |
| Pareja (último año) | `p171`–`p173`, `p175`, `p176` | 4.8 – 15.9 |
| Trabajo | `p183`–`p186` | 1.9 – 3.5 |
| Comunidad / calle | `p191`–`p194` | 5.1 – 11.9 |
| Escuela | `p201`–`p204` | 4.0 – 22.0 |

Sociodemográficas: `p1` indígena, `p2` edad (grupos), `p3` lee y escribe, `p4` escolaridad,
`p5` ocupación, `p7` recibe dinero de persona/programa, `p9` estado civil, `p13` edad al primer
embarazo, `p62` conoce los derechos de las mujeres. `c`/`c_r` es una agrupación de 3 categorías
**sin etiquetas** (`c_r` = `c` invertida) — falta confirmar qué representa.

## Scripts

| Script | Qué hace |
|---|---|
| `scripts/00_setup_paquetes.R` | Instala/carga `tidyverse`, `haven`, `labelled`, `naniar`, `psych`, `poLCA` |
| `scripts/01_analisis_exploratorio.R` | Análisis exploratorio completo (ver abajo) |

`01_analisis_exploratorio.R`, por secciones:

1. Lectura del `.dta` con `haven` (encoding latin1) y eliminación del único caso `_merge = 2`, que no tiene respuestas.
2. Diccionario de variables a partir de las etiquetas de Stata.
3. Variable de agrupación `c`.
4. Perfil sociodemográfico (tablas y gráfica de barras).
5. Datos faltantes y **saltos de cuestionario**.
6. Prevalencia de cada indicador de violencia.
7. Conteos por ámbito (número de violencias y "al menos una").
8. Correlaciones tetracóricas y KR-20 (alfa) por ámbito.
9. Violencia según `c`, condición indígena, edad, escolaridad y estado civil (con chi-cuadrada).
10. Implicaciones para el LCA: casos completos, patrones de respuesta, recodificación 1/2 para `poLCA`.

Las tablas (`.csv`) y gráficas (`.png`) se guardan en `output/` (no se versionan).

## Cómo correrlo en VSCode

1. Instala R (≥ 4.1) y, en VSCode, la extensión **R** (REditorSupport). En la consola de R:
   `install.packages(c("languageserver", "httpgd"))` (el segundo muestra las gráficas en un panel de VSCode).
2. Abre la carpeta raíz del repositorio (`Libro-SEM`) en VSCode.
3. Abre una terminal de R (`Ctrl+Shift+P` → *R: Create R terminal*) y corre:

```r
source("Datos_Violencia_Veracruz/scripts/00_setup_paquetes.R")
source("Datos_Violencia_Veracruz/scripts/01_analisis_exploratorio.R")
```

O abre el script y ve ejecutando sección por sección con `Ctrl+Enter`. Los objetos
(`base`, `prevalencias`, `faltantes`, etc.) se pueden inspeccionar en el panel *R Workspace* o
con `View(prevalencias)`.

## Hallazgos que condicionan el LCA

- **Los datos faltantes son estructurales, no al azar.** Pareja (~29% NA) falta casi solo en
  mujeres solteras, separadas, divorciadas o viudas; trabajo (~23% NA) se concentra en amas de
  casa; `p13` (~20% NA) corresponde a quienes no han estado embarazadas.
- Con los 24 indicadores solo quedan **505 casos completos**; sin los ámbitos de pareja y
  trabajo, **986**. Hay que decidir si esos ámbitos entran al modelo, si se modela la
  submuestra a la que aplican o si se usan indicadores resumen por ámbito.
- Varios indicadores tienen prevalencia < 5% (`p144`, `p165`, `p173`, todo trabajo, `p203`):
  aportan poca información y pueden dar probabilidades condicionales en la frontera (0 o 1).
- `poLCA` necesita las categorías codificadas 1, 2, … (no 0/1): el script deja lista `base_lca`.
