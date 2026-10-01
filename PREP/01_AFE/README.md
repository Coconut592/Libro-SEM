# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R` (todavía es un esqueleto). Estado: **✅ Cubierto por los archivos**.

## Qué traen los archivos

- `AFE.do` (Stata): AFE por máxima verosimilitud del espacio público (3 factores) y de la colonia
  (22 ítems, 4 factores, `rotate, kaiser blanks(0.399)`, `estat kmo`).
- `EFA_Hogares.inp` (Mplus): `TYPE EFA 1 3`, MLR, varimax, faltantes. **Ojo:** el título dice *Hogares*, pero
  `USEV` trae los ítems del **espacio público** (`B13`–`B25`).
- Laboratorio 2: componentes principales, análisis paralelo (`nFactors::parallel`) y `fa(fm = "ml",
  rotate = "varimax")`, que es lo mismo que ya se hizo en `Tren_de_Guadalajara/01_AFE`.

## Con la base (`PREP.dta`)

Sí. Con los casos completos de cada bloque: **espacio público** (11 ítems, 4,019 casos) KMO = .89 y 3
factores; **colonia** (25 ítems, 5,880 casos) KMO = .93 y 4 factores; **bloque G** (12 ítems, 6,627 casos)
KMO = .78 y 3 factores. Cargas y comunalidades en `00_Diagnostico/output/cargas_AFE_*.csv`.

## Qué falta

Nada de documentos. Solo confirmar las equivalencias piloto → base (ver `00_Diagnostico/README.md`) y si
la colonia se explora con 4 factores (como `AFE.do`) o con 5 (como `CFA_Hogares.inp`).

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
