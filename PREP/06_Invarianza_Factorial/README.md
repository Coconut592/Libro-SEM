# 06 · Invarianza factorial

Script: `Invarianza_Factorial.R` (todavía es un esqueleto). Estado: **❌ No viene en los archivos**.

## Qué traen los archivos

- Ningún archivo trata invarianza ni modelos multigrupo.

## Con la base (`PREP.dta`)

Técnicamente sí. Como ejemplo ilustrativo, el modelo de espacio público entre 3 estados (México, Veracruz
y Sonora; 1,992 casos) da CFI = .971 (configural), .966 (métrica) y .957 (escalar): caídas de .005 y
.009, dentro del criterio de Chen (2007). Eso solo demuestra que corre; no es una hipótesis del estudio.

## Qué falta

**Un documento de invarianza** y **definir el grupo**. La base no trae sexo, edad ni nada del
respondiente: lo único que agrupa es `espacio` y la clave `ID_MPIO` (de ahí sale el estado). Sería mejor
un catálogo de espacios (tipo, tamaño, región) o variables del respondiente.

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
