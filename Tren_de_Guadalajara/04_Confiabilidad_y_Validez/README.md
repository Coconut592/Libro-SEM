# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R`. Referencias: **SEM06_Confiabilidad_y_Validez.pdf** (metodología),
el alfa y la confiabilidad compuesta de `AFE_CFA.R`, y los alfas de SEM02 (.82, .87 y .83).

> **Lo que traen las referencias:**
> - **Confiabilidad:** SEM06 trae el alfa de Cronbach (a mano y por ítem en Stata), la confiabilidad
>   compuesta de Dillon-Goldstein y el KR-20. `AFE_CFA.R` y SEM02 también calculan confiabilidad.
>   Aquí se replica todo.
> - **Validez:** SEM06 solo la presenta de forma **conceptual**: validez de contenido, de criterio y de
>   constructo, sin cálculos ni ejemplo. En los archivos anteriores (`AFE_CFA.R`, los `.inp` y SEM02)
>   **no se había realizado más que la confiabilidad**.
> - **Complemento:** para darle a la validez de constructo un respaldo numérico se agregan la **AVE** y
>   el **criterio de Fornell-Larcker** (Fornell y Larcker, 1981). No vienen en las referencias.

**Datos:** el alfa usa los 306 usuarios con covarianzas por pares, como el `alpha` de Stata del PDF. La
confiabilidad compuesta y la validez usan el AFC de `02_AFC` (170 casos completos).

## Confiabilidad: paso a paso

1. **Alfa a mano** (SEM06, láminas 9–12). Con la matriz de covarianzas de cada factor:
   α = k/(k−1) · (1 − Σ varianzas / Σ de todos los elementos).

   | Factor | k | Σ varianzas | Σ covarianzas | α |
   |---|---|---|---|---|
   | Acceso | 4 | 15.45 | 24.39 | **.816** |
   | Tarjeta | 2 | 8.72 | 6.73 | **.871** |
   | Confort | 4 | 8.84 | 14.74 | **.834** |

   Son los alfas del PDF de SEM02 (.82, .87, .83). Todos son mayores que .70 (Nunnally y Bernstein, 1994).
2. **Alfa por ítem** (equivale a `alpha ..., d item` de Stata, lámina 13): correlación ítem-test,
   correlación ítem-resto y alfa si se elimina el ítem.

   | Factor | Ítem | N | Ítem-test | Ítem-resto | α sin el ítem |
   |---|---|---|---|---|---|
   | Acceso | p4 | 303 | .72 | .53 | .815 |
   | | p5 | 306 | .84 | .68 | .746 |
   | | p61 | 293 | .86 | .75 | .718 |
   | | p62 | 305 | .79 | .60 | .788 |
   | Tarjeta | p63 | 199 | .96 | .78 | — |
   | | p64 | 178 | .94 | .78 | — |
   | Confort | p71 | 305 | .76 | .61 | .816 |
   | | p73 | 306 | .78 | .67 | .803 |
   | | p74 | 306 | .85 | .68 | .793 |
   | | p75 | 306 | .90 | .78 | .733 |

   Quitar cualquier ítem baja el alfa, así que todos aportan a su escala. En Tarjeta, con 2 ítems, el
   "alfa sin el ítem" no aplica: quedaría un solo ítem.
3. **Alfa con la covarianza del modelo** (`AFE_CFA.R`): `alpha(fitted(fit)$cov)` da .835, .878 y .868.
4. **Confiabilidad compuesta de Dillon-Goldstein** (láminas 14–15):
   Ω = (Σλ)² / [(Σλ)² + Σ var(e)], con var(e) = 1 − λ².

   | Factor | Ítem | Coeficiente (λ) | Residual (1 − λ²) |
   |---|---|---|---|
   | Acceso | p4 / p5 / p61 / p62 | .636 / .809 / .891 / .671 | .596 / .346 / .206 / .549 |
   | Tarjeta | p63 / p64 | .830 / .952 | .311 / .093 |
   | Confort | p71 / p73 / p74 / p75 | .664 / .725 / .861 / .958 | .559 / .475 / .259 / .082 |

   Ω: **Acceso .842, Tarjeta .887, Confort .882**.
5. **KR-20: no aplica.** Es para ítems dicotómicos (0/1) y aquí los ítems son escalas de 1 a 10 (6 a 10
   valores distintos). La medida adecuada es el alfa.

## Validez: paso a paso (tipos de SEM06)

6. **De contenido: se argumenta, no se calcula.** Cada ítem debe pertenecer al dominio de su factor (ver
   el glosario del [README del proyecto](../README.md)):
   - *Acceso*: información y torniquetes para entrar y pagar.
   - *Tarjeta*: información y máquinas de la tarjeta inteligente.
   - *Confort*: seguridad (puertas, tren) y comodidad (temperatura, limpieza).

   `p72` (tiempo de traslado) y `p8` (tiempo de espera) no encajan en ninguno. El AFE también los separó.
7. **De criterio: no es posible con esta base.** Requiere un criterio externo que mida lo mismo, por
   ejemplo otro instrumento de satisfacción o una calificación global del servicio. El `.dta` no trae
   ninguno: `p72` y `p8` son otros aspectos del servicio, no una medida externa.
8. **De constructo** (A. teoría, B. correlaciones, C. interpretación empírica):
   - **A. Teoría:** tres dimensiones de la calidad del servicio del tren (Palacios y Vargas, 2009).
   - **B. Correlaciones:** los ítems de un mismo factor correlacionan mucho más entre sí que con los de
     otros factores.

     | Factor | r media dentro del factor | r media con otros factores |
     |---|---|---|
     | Acceso | .53 | .26 |
     | Tarjeta | .80 | .26 |
     | Confort | .58 | .26 |

   - **C. Interpretación empírica:** el AFE recupera los tres factores y el AFC confirma cargas de .64 o
     más, todas significativas.
9. **Complemento (no viene en las referencias): AVE y Fornell-Larcker.**
   - *Convergente*: AVE = promedio de λ², debe ser ≥ .50.
   - *Discriminante*: √AVE debe ser mayor que la correlación con los demás factores.

## Resumen

| Factor | α | α modelo | Ω (CC) | AVE | √AVE | Máx. correlación |
|---|---|---|---|---|---|---|
| Acceso | .816 | .835 | .842 | .576 | .759 | .447 |
| Tarjeta | .871 | .878 | .887 | .798 | .893 | .447 |
| Confort | .834 | .868 | .882 | .656 | .810 | .319 |

- Las tres escalas son **confiables**: α y Ω son mayores que .80.
- La **validez de constructo** se sostiene: las correlaciones dentro de cada factor son mayores que entre
  factores, AVE > .50 y √AVE > las correlaciones.
- La **validez de contenido** se argumenta con el glosario.
- La **validez de criterio** no se puede evaluar con este `.dta`.

Salidas en `output/`: `alfa_por_item.csv`, `confiabilidad_compuesta.csv` y `confiabilidad_validez.csv`.

## Referencias

- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables
  and measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Hernández Sampieri, R., Fernández Collado, C., & Baptista Lucio, P. (2008). *Metodología de la
  investigación*. McGraw Hill.
- Nunnally, J. C., & Bernstein, I. H. (1994). *Psychometric theory*. McGraw Hill.
