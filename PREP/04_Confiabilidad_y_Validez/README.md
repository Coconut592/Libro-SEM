# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R`. Referencia: Laboratorio 2 (alfa, KR-20, confiabilidad compuesta).

> **Lo que traen los archivos:** solo confiabilidad. De **validez** (contenido, criterio, constructo) no
> hay nada. Para darle respaldo numérico a la validez de constructo se agregan la **AVE**, el criterio de
> **Fornell-Larcker** y el **HTMT**, igual que en `Tren_de_Guadalajara`. Faltan un documento de validez y
> una variable criterio.

## Paso a paso

1. **Alfa de Cronbach** con los datos (`psych::alpha`) y con la covarianza del modelo (como el Lab 2).
   El Lab 2 toma mal los renglones del alfa (`[5:6,5:6]`, `[7:11,7:11]`); aquí cada factor usa sus ítems.
2. **Confiabilidad compuesta** (Dillon-Goldstein): CR = (Σλ)² / [(Σλ)² + Σ(1 − λ²)], con λ estandarizadas.
3. **AVE** = promedio de λ². **Fornell-Larcker:** la AVE debe superar el r² más alto con otro factor.

| Factor | k | α | α modelo | CR | AVE | r² máx. |
|---|---|---|---|---|---|---|
| EVEP | 3 | .893 | .893 | .897 | .745 | .414 |
| SEGEP | 5 | .897 | .895 | .896 | .634 | .246 |
| ACTEP | 3 | .806 | .830 | .834 | .628 | .414 |
| IP | 6 | .891 | .888 | .889 | .574 | .115 |
| SG | 3 | .901 | .901 | .901 | .753 | .268 |
| CS | 9 | .899 | .894 | .908 | .532 | .179 |
| INF | 5 | .897 | .897 | .898 | .640 | .589 |
| SR | 2 | .772 | .773 | .783 | .645 | .589 |
| PART | 4 | .796 | .797 | .805 | .514 | .041 |
| RECH | 3 | .889 | .895 | .898 | .748 | .011 |
| INTV | 4 | .870 | .867 | .877 | .646 | .041 |

Todos superan .70 en α y CR y .50 en AVE, y la validez discriminante se cumple en los 11 factores. Lo más
justo: **Infraestructura–Satisfacción** (r² = .589; HTMT = .77, bajo el .85). Entre los demás factores de
la colonia el HTMT es de .24 a .52.

4. **KR-20: no aplica.** Es para ítems 0/1 y aquí van de 1 a 10 (en el Lab 2 además falta `KR20.csv`).

Salida: `output/confiabilidad_validez.csv`.
