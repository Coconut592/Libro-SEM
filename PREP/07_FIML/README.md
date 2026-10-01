# 07 · Datos faltantes: listwise vs FIML

Script: `FIML.R` (todavía es un esqueleto). Estado: **✅ Cubierto por los archivos**.

## Qué traen los archivos

- `cfa_espacio_publico.pdf`: Mplus con `TYPE = H1 missing` (12 patrones de faltantes, tabla de cobertura
  de covarianzas, 25 casos sin ningún dato excluidos).
- Laboratorios 4 y 5: `sem(..., missing = "fiml")` en `lavaan`.

## Con la base (`PREP.dta`)

Sí. En el espacio público FIML usa **7,814 casos contra 4,019** de listwise (el doble), con el mismo
ajuste (CFI = .979) y cargas que difieren en .02 o menos. Los faltantes son altos: `b21` y `b22` ~33%,
`b18` 22%.

## Qué falta

Nada técnico. Falta el cuestionario para saber si los faltantes son "no sabe" o saltos de pregunta (FIML
supone que faltan al azar, MAR); ver `00_Diagnostico/README.md`.

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
