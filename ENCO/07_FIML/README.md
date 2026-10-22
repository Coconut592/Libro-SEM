# 07 · FIML: Confianza del consumidor con datos faltantes

Script: `FIML.R` (unos 5 segundos). **Sin referencia:** el documento de INEGI no trae tratamiento de faltantes. Los
únicos faltantes **reales** son los «No sabe»: 115 personas (5.6 %). Se hace el AFC de cuatro factores y se compara
listwise contra FIML. **No se simulan faltantes** (decisión del proyecto).

**Pregunta:** ¿cuánto se gana con FIML y cambia el resultado?

**Respuesta corta:** se conservan **115 casos más (1,935 → 2,050)** y el resultado **casi no cambia**: cargas hasta .007
distintas y errores estándar 2 % menores.

## Paso a paso

1. **Cuántos datos faltan.** Por ítem, de 1 caso (`P1`, `P3`, `P7`, `P14`, `P15`) a 34 (`P13`, 1.7 %); `P10` (33), `P9`
   (23) y `P6` (14) le siguen. **1,935 completos** y 115 con algún faltante: 96 tienen **un** ítem sin respuesta, 14
   tienen dos y el máximo es 9. Son faltantes por «No sabe» (y `P10` = 4, «No tiene ingresos»); no por salto de
   pregunta.
2. **¿Es al azar?** Quien no sabe es **mayor** (+.022 en logit por año, p < .001) y, algo más, **mujer** (+.41, p = .046):
   el faltante depende de variables que sí se observan, que es el supuesto de FIML (MAR). No se puede comprobar que no
   dependa también de lo que no se contestó. Los 115 puntúan algo más bajo en lo que sí contestaron (.54 contra .58 en
   el promedio de 0 a 1), coherente con que sean mayores.
3. **El modelo y su limitación.** Los mismos cuatro factores de [`02`](../02_AFC/), con MLR y `std.lv = TRUE`.
   **`lavaan` no ofrece FIML con ítems ordinales** (probado: `missing = "fiml" not available in the categorical
   setting`), solo con indicadores continuos: aquí los ítems se tratan como **numéricos**. No es lo ideal con ítems de 2 o 3
   categorías (`P7`–`P10`, `P14`, `P15`); por eso el ajuste es peor que en el AFC ordinal.

   | Modelo | N | χ² (84 gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | Listwise | 1,935 | 764 | .935 | .918 | .068 | .046 |
   | **FIML** | **2,050** | 777 | .936 | .920 | .067 | .043 |

   El ajuste es el mismo (con ítems ordinales, en 02: CFI .975, RMSEA .071).
4. **Cargas estandarizadas y errores estándar:**

   | Factor | Ítem | Carga listwise | Carga FIML | EE listwise | EE FIML | EE FIML / listwise |
   |---|---|---|---|---|---|---|
   | `HOGA` | `P1` | .859 | .856 | .015 | .015 | 1.00 |
   | | `P3` | .840 | .839 | .015 | .015 | 1.00 |
   | `HOGE` | `P2` | .853 | .854 | .017 | .017 | 1.00 |
   | | `P4` | .855 | .858 | .017 | .017 | 1.00 |
   | `PAIS` | `P5` | .706 | .709 | .019 | .019 | 1.00 |
   | | `P6` | .700 | .699 | .021 | .020 | .95 |
   | | `P12` | .424 | .427 | .028 | .028 | 1.00 |
   | | `P13` | .565 | .558 | .025 | .025 | 1.00 |
   | `CONS` | `P7` | .759 | .761 | .012 | .012 | 1.00 |
   | | `P8` | .746 | .744 | .013 | .013 | 1.00 |
   | | `P9` | .655 | .654 | .008 | .007 | .88 |
   | | `P10` | .645 | .639 | .008 | .008 | 1.00 |
   | | `P11` | .666 | .667 | .017 | .016 | .94 |
   | | `P14` | .533 | .530 | .018 | .017 | .94 |
   | | `P15` | .526 | .525 | .018 | .018 | 1.00 |

   Las cargas cambian hasta **.007** y los errores estándar de FIML son **98 %** de los de listwise (en el promedio): con
   5.6 % de casos incompletos y casi todos con un solo ítem faltante, **el FIML casi no aporta**: da el mismo resultado y
   conserva a las 115 personas. Las correlaciones entre factores cambian hasta .01.
5. **Contra el AFC ordinal (02).** Las cargas continuas son más bajas (de .43 a .86 contra .48 a .91), sobre todo en
   los ítems de 2 y 3 categorías (`P9`, `P10`, `P14`, `P15`: de .13 a .19 menos), pero el orden es el mismo (r = .93):
   tratar los ítems como continuos para el FIML no cambia la estructura.

**Salidas** (`output/`): `faltantes.csv`, `ajuste_listwise_vs_fiml.csv` y `cargas_listwise_vs_fiml.csv`.

**Cuidado.** Es la única forma de FIML disponible con estos datos, y su beneficio es mínimo. Si el libro necesita un
ejemplo donde el FIML cambie el resultado, esta base no lo da (se descartó simular faltantes). Los resultados de los
demás ejercicios (AFC, puntajes, invarianza) usan `pairwise`, que también conserva a las 115 personas.
