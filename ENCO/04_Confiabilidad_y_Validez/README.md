# 04 · Confiabilidad y validez: Confianza del consumidor

Script: `Confiabilidad_y_Validez.R` (unos 40 segundos). **Sin referencia:** el documento de INEGI no trae confiabilidad ni
validez. Aquí se calculan: alfa ordinal, confiabilidad compuesta (CR) y AVE de cada factor, validez discriminante
(Fornell-Larcker y HTMT), omega y validez de criterio con variables del cuestionario sociodemográfico que no entraron
al modelo.

**Pregunta:** ¿qué tan confiables son los cuatro factores y se distinguen entre sí?

**Respuesta corta: confiabilidad alta en tres factores** (α y CR de .90 a .91) **y floja en `PAIS`** (α .73, AVE .43).
Se distinguen por HTMT (todos bajo .85), pero `CONS` apenas no pasa Fornell-Larcker frente a `HOGA`.

## Paso a paso

1. **Datos y modelo** (igual que en [`02`](../02_AFC/)); el sociodemográfico (`encocs_0826.DBF`) se une por las siete
   variables de identificación.
2. **Confiabilidad.** Alfa ordinal (alfa de Cronbach sobre la matriz policórica, porque los ítems son ordinales),
   CR = (Σλ)² / [(Σλ)² + Σ(1 − λ²)] y AVE = promedio de λ² (se pide > .50):

   | Factor | k | α ordinal | CR | AVE | r² máx. con otro factor | ¿AVE > r²? |
   |---|---|---|---|---|---|---|
   | `HOGA` | 2 | .896 | .896 | .812 | .620 | Sí |
   | `HOGE` | 2 | .900 | .900 | .818 | .503 | Sí |
   | `PAIS` | 4 | .727 | .743 | **.425** | .383 | Sí (pero AVE < .50) |
   | `CONS` | 7 | .910 | .912 | .597 | .620 | **No** (por poco) |

   `PAIS` es el flojo: α .73, CR .74 y AVE .43, por `P12` (carga .48). **Fornell-Larcker:** la AVE de cada factor debe
   superar su r² más alto con otro factor; `HOGA`, `HOGE` y `PAIS` lo cumplen (el r² de `PAIS` es bajo, .38) y `CONS` no
   (AVE .597 contra r² = .62 con `HOGA`). **Omega** (policóricas, 4 grupos): jerárquico **.76** y total **.95**: el
   factor general explica la mayor parte de la varianza común.
3. **Validez discriminante: HTMT** (promedio de las correlaciones entre ítems de dos factores sobre la raíz del
   producto de los promedios dentro de cada uno; se pide < .85):

   | Par | r entre factores | HTMT |
   |---|---|---|
   | `HOGA`–`HOGE` | .66 | .66 |
   | `HOGA`–`PAIS` | .54 | .55 |
   | `HOGA`–`CONS` | .79 | .77 |
   | `HOGE`–`PAIS` | .58 | .58 |
   | `HOGE`–`CONS` | .71 | .70 |
   | `PAIS`–`CONS` | .62 | .62 |

   Los seis bajo .85: **por HTMT los factores se distinguen**; por Fornell-Larcker, `CONS` y `HOGA` no del todo.
   Comparten mucho (r de .54 a .79), que es lo que justifica el segundo orden ([`03`](../03_AFC_2do_Orden/)).
4. **Validez de criterio.** Correlación de Spearman del puntaje `CONF` (segundo orden, EBM) con variables del
   sociodemográfico que no entraron al modelo. **No hay un criterio «oro» en estos archivos.**

   | Criterio | Spearman | n |
   |---|---|---|
   | Edad | **−.33** | 2,050 |
   | Estudios (0 ninguno … 9 doctorado) | .16 | 2,048 |
   | Ingreso mensual (log) | .20 | 810 |
   | Está ocupado | .17 | 2,050 |

   Los signos son los esperados (la confianza baja con la edad y sube con más estudios, ingreso y empleo), con
   correlaciones de moderadas a bajas. El ingreso solo es válido en 810 personas: 762 no tienen dato de ingreso y 478 lo
   dejaron sin especificar (999999); se llevó a pesos por mes según el periodo (`I_PER`).

**Salidas** (`output/`): `confiabilidad.csv`, `htmt.csv` y `validez_criterio.csv`.

**Cuidado.** `PAIS` queda con AVE de .43: conviene leer sus resultados con cautela. No hay documento de validez ni
criterio externo de INEGI; los criterios son sociodemográficos.
