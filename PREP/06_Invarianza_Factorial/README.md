# 06 · Invarianza factorial

Script: `Invarianza_Factorial.R`.

> **Este ejercicio no viene en los archivos de referencia.** Se sigue la secuencia estándar (Meredith,
> 1993): configural → métrica → escalar → estricta, con los criterios de Chen (2007).
>
> **Es ilustrativo:** la base no trae sexo, edad ni tipo de espacio, así que el grupo es el **estado**
> (sale de `ID_MPIO`): México (15), Veracruz (30) y Sonora (26), los de más respondientes. Falta que el
> equipo defina el grupo que le interesa.

**Pregunta:** ¿los respondientes de distintos estados entienden igual los ítems? Si hay invarianza escalar,
las medias de los factores se pueden comparar entre estados.

## Paso a paso

1. **Secuencia** con MLR y FIML. Se mantiene un nivel si el CFI cae ≤ .01 y el RMSEA sube ≤ .015.

   | Bloque (N) | Nivel | CFI | RMSEA | ΔCFI | ΔRMSEA |
   |---|---|---|---|---|---|
   | Espacio público (1,992) | configural | .971 | .069 | | |
   | | métrica | .966 | .070 | −.005 | .001 |
   | | escalar | .957 | .074 | −.009 | .004 |
   | | estricta | .917 | .097 | **−.040** | .023 |
   | G (1,991) | configural | .981 | .055 | | |
   | | métrica | .975 | .058 | −.006 | .003 |
   | | escalar | .953 | .076 | **−.022** | .018 |
   | Colonia (2,025) | configural | .933 | .062 | | |
   | | métrica | .930 | .062 | −.003 | .000 |
   | | escalar | .906 | .070 | **−.024** | .008 |

2. **Lectura.** Los tres bloques tienen **invarianza métrica** (las cargas son iguales entre estados).
   Espacio público llega hasta la **escalar** (ΔCFI = −.009, al límite), no a la estricta. G y colonia
   **no tienen invarianza escalar**: no conviene comparar sus medias entre estados.
3. **¿Qué ítems fallan?** En el modelo escalar de espacio público, las restricciones que más empeoran el
   ajuste son los interceptos de `b18` (droga) y `b14` (alcohol) entre México y Veracruz, y el de `b26`.
4. **Sensibilidad.** Con 5 estados (agrega Guanajuato y Sinaloa; 2,710 casos) el espacio público queda igual:
   métrica ΔCFI = −.004 y escalar −.010 (borderline).
5. **Cuidado.** Con 3 grupos de ~400 a 1,000 casos lavaan avisó de varianzas negativas en alguno de
   los modelos con restricciones; y con grupos tan distintos en tamaño, la potencia no es pareja.

Salidas: `invarianza_por_estado.csv` e `invarianza_EP_5_estados.csv`.

## Qué falta

El grupo. Lo ideal es un **catálogo de espacios** (tipo de espacio: parque, plaza, unidad deportiva;
tamaño; región) o variables del respondiente (sexo, edad). También un documento de invarianza del curso
para seguir su criterio.
