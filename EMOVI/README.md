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
| [`00_Diagnostico/Recortar_Entrevistado.R`](00_Diagnostico/Recortar_Entrevistado.R) | Recorta el Entrevistado 2023 a la CDMX para poder subirlo | ✅ Probado con datos sintéticos |
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

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Muestra | Solo la **Ciudad de México** (`entidad` = 9), como la tesis |
| Ocupación | Las **6 clases ocupacionales** que trae la base (`clase`, `clasep`, `clasem`, `clase1`), no el ISEI |
| Diseño muestral | Sin ponderador, como la tesis (que no lo menciona) |
| Escala principal | **Riqueza del hogar de origen** (`p26`, `p29`, `p31`, `p32`): una sola escala, de ítems binarios, para AFE, AFC, 2.º orden, confiabilidad y validez, puntajes (el índice de riqueza de la tesis) e invarianza (sexo y 25–40 contra 41–64 años, como la tesis) |
| Ítems binarios | Ordinales (WLSMV), quitando los de menos de 10 % o más de 90 % de "Sí" (criterio de la tesis) |
| FIML | En el AFC de **Origen social** de la tesis (clase del padre y de la madre, índice de riqueza, educación de los padres), con indicadores continuos y MLR: listwise contra FIML. Ahí sí hay faltantes de verdad (la madre sin ocupación) |

Es una propuesta sobre el diccionario: se confirma o se ajusta cuando se vean los datos (por ejemplo, en la CDMX
los ítems básicos como electricidad pueden pasar del 90 % y salir).

## Qué falta: el Entrevistado 2023

El archivo completo pesa 39 MB y no se puede adjuntar. [`00_Diagnostico/Recortar_Entrevistado.R`](00_Diagnostico/Recortar_Entrevistado.R)
lo recorta a la CDMX y le quita el texto libre (debe quedar mucho más chico) y además escribe un resumen en texto:

1. Copia el `.dta` del Entrevistado a `EMOVI/data/` (si no se llama `entrevistado_2023.dta`, cambia `archivo` en el script).
2. Corre `source("EMOVI/00_Diagnostico/Recortar_Entrevistado.R")`.
3. Sube `EMOVI/data/entrevistado_2023_CDMX.dta` (o pega `EMOVI/data/resumen_entrevistado_CDMX.txt`).

Sobre el ingreso: `ingreso_2017.dta` es de la EMOVI 2017 y no se usa con la 2023. El diccionario 2023 sí lista
`ingc_pc` ("Ingreso per cápita del hogar - imputado") dentro del Entrevistado, así que debería venir en el archivo;
el resumen lo confirma.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia las bases a `EMOVI/data/` y en una terminal de R:

```r
source("EMOVI/00_setup_paquetes.R")
source("EMOVI/00_Diagnostico/Diagnostico.R")     # ~40 s
source("EMOVI/00_Diagnostico/Recortar_Entrevistado.R")   # con el Entrevistado en EMOVI/data/
```

Por ahora solo hay diagnóstico; los 7 ejercicios se agregan cuando llegue el Entrevistado.
