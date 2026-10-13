# Libro SEM · EMOVI

Movilidad social con la **ESRU-EMOVI** (Encuesta ESRU de Movilidad Social en México, CEEY). La referencia es la
tesis de Sánchez Flores (UNAM, 2019), que modela con SEM, al estilo de Blau y Duncan, cómo el **origen social**
llega al **logro ocupacional** a través de la **educación** y la **primera ocupación** (ESRU-EMOVI 2017, Ciudad de
México, n = 3,117, Mplus).

Las bases van en `EMOVI/data/`. Como marca el `.gitignore` del repositorio, **no se versionan**: copia ahí
`hogar_2023.dta`, `ingreso_2017.dta` y `Diccionario_ESRU_EMOVI_2023.xlsx` antes de correr los scripts.

## Estado: diagnóstico hecho, falta el archivo del Entrevistado

| Carpeta | Contenido | Estado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | ✅ |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué trae cada archivo, qué pide la tesis y qué hay en el diccionario 2023, y qué corre con lo que se tiene | ✅ |
| `01_AFE/` a `07_FIML/` | Los 7 ejercicios, con la estructura de los demás proyectos | ⏳ Esperan el Entrevistado 2023 |

> **Con lo subido hasta ahora no se pueden hacer los análisis de movilidad social.** El diccionario describe dos
> bases de la ESRU-EMOVI 2023 y solo se tiene el *roster* del hogar (`hogar_2023.dta`, 55,477 integrantes); falta
> la del **Entrevistado** (294 variables: hogar de origen, padres, ocupaciones, riqueza, salud mental…).
> `ingreso_2017.dta` es una sola variable (`ingc_pc`) de otra ola. Detalle y cifras en
> [`00_Diagnostico/`](00_Diagnostico/).

## ¿Qué análisis se pueden hacer?

| Análisis | Con lo subido | Con el Entrevistado 2023 (según el diccionario) |
|---|---|---|
| **AFE** | ⚠️ Solo 11 dificultades funcionales (`p12`), que no es movilidad | ✅ Riqueza del hogar de origen, carencias, depresión, colonia |
| **AFC** | ⚠️ Igual | ✅ Origen social, Educación, Primera ocupación y riqueza (sin ISEI ni "edad en que dejó la escuela") |
| **AFC de 2.º orden** | ⚠️ Corre, con un caso Heywood | ✅ Riqueza (vivienda, casa, bienes, activos) u Origen social |
| **Confiabilidad y validez** | ⚠️ Solo `p12` | ✅ α, ω, KR-20, AVE, discriminante; criterio con `p103`/`p104` o `ingc_pc` |
| **Puntajes factoriales** | ⚠️ El 90.5 % recibe el mismo puntaje | ✅ Índice de riqueza (el de la tesis) y demás escalas |
| **Invarianza factorial** | ⚠️ `p12` por sexo, trivial | ✅ Sexo, cohorte, región, rural-urbano y 14 años vs hoy |
| **FIML** | ❌ `p12` no tiene faltantes | ✅ En el SEM con indicadores continuos; ⚠️ con ítems binarios no existe en `lavaan` |

## Qué falta

1. **El archivo del Entrevistado de la ESRU-EMOVI 2023** (indispensable).
2. La tabla **SINCO → CIUO-08 → ISEI-08** o la decisión de usar las 6 clases ocupacionales.
3. La regla **nivel + grado → años de escolaridad**.
4. Decisiones: muestra (¿CDMX o todo el país?), ponderador, escala de cada ejercicio y tratamiento de los
   ítems binarios. Están listadas en [`00_Diagnostico/`](00_Diagnostico/).

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia las bases a `EMOVI/data/` y en una terminal de R:

```r
source("EMOVI/00_setup_paquetes.R")
source("EMOVI/00_Diagnostico/Diagnostico.R")     # ~40 s
```

Por ahora solo hay diagnóstico; los 7 ejercicios se agregan cuando llegue el Entrevistado.
