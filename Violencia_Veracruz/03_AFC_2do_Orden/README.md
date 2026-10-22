# 03 · AFC de segundo orden: violencia contra las mujeres

Script: `AFC_2do_Orden.R` (unos 5 segundos). **Sin referencia propia:** `Scripts.do` no hace segundo orden. Los seis ámbitos del
[AFC](../02_AFC/) correlacionan de .31 a .60, así que se prueba si los gobierna un factor general: `VIO`, la **violencia contra las
mujeres**.

**Pregunta:** ¿hay un factor general de violencia por encima de infancia, familia, pareja, trabajo, comunidad y escuela?

**Respuesta corta: sí, y a diferencia de EMOVI aquí el segundo orden se puede contrastar.** Con seis factores de primer orden
el segundo orden tiene **9 grados de libertad más** (15 correlaciones entre factores se reemplazan por 6 cargas) y ajusta casi igual:
ΔCFI = .000, Δχ² p = **.051** (justo en el límite). Las cargas van de .56 a .78.

## Paso a paso

1. **Datos y modelo de primer orden:** los mismos de [`02_AFC`](../02_AFC/) (1,088 mujeres, WLSMV, `missing = "pairwise"`).
2. **Segundo orden:** `VIO =~ INF + FAM + PAR + TRA + COM + ESC`. La solución converge y es admisible (sin varianzas negativas).

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | 1.er orden (6 factores) | 1,088 | 332.3 (237) | .987 | .985 | .019 | .110 |
   | **2.º orden (VIO)** | 1,088 | 345.3 (246) | **.987** | **.985** | **.019** | .114 |

   **¿Pierde ajuste al imponer un factor general?** Diferencia de χ² escalada (Satorra, 2000): **Δχ² = 16.9 (9 gl), p = .051**; el criterio
   de Chen (2007) (ΔCFI de −.010 o menos) se cumple de sobra. El factor general explica las correlaciones entre ámbitos sin perder ajuste que
   valga la pena. Las cargas de primer orden casi no cambian (hasta .016).
3. **Cargas de segundo orden** y varianza del ámbito que explica el factor general (R²):

   | Ámbito | Carga en VIO | Error estándar | R² |
   |---|---|---|---|
   | Familia (`FAM`) | **.78** | .044 | .61 |
   | Pareja (`PAR`) | .70 | .056 | .48 |
   | Infancia (`INF`) | .69 | .043 | .47 |
   | Trabajo (`TRA`) | .67 | .073 | .45 |
   | Comunidad (`COM`) | .58 | .058 | .33 |
   | Escuela (`ESC`) | .56 | .052 | .31 |

   Todas significativas (p < .001) y ninguna cerca de 1 (no hay caso Heywood). El factor general explica entre el **31 %** (escuela) y el **61 %**
   (familia) de la varianza de cada ámbito; queda entre 39 % y 69 % propia. Familia es el ámbito que más se parece al general; escuela y
   comunidad, el que menos.
4. **¿Hace falta el segundo orden?** Contra **un solo factor con los 24 ítems** (CFI .847, RMSEA .065): el factor único ajusta mucho peor
   que los seis ámbitos con un general encima (CFI .987, RMSEA .019). Los ámbitos son reales y el factor general los resume.

**Salidas** (`output/`): `ajuste_2do_orden.csv` y `cargas_segundo_orden.csv`.

**Cuidado.**
- La prueba χ² está **justo en el límite** (p = .051): con otra muestra podría rechazar. El criterio de Chen sí se cumple con holgura.
- El factor general resume las correlaciones entre ámbitos, pero **no todos los ámbitos aplican a todas las mujeres** (pareja, trabajo y escuela
  se saltan por cuestionario): `VIO` se estima apoyándose en los ámbitos que cada mujer sí contestó.
- Sigue sin ser una prueba independiente (mismos datos que el AFE).
