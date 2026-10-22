# 00 · Diagnóstico: ¿qué tenemos y qué falta?

Script: `Diagnostico.R` (unos 10 segundos). Lo que se revisó: la base `BASE_ACLnew.dta` (1,089 renglones × 37 columnas) y
`Scripts.do`, el script de Stata que la acompaña. Cada cifra sale de la base real, en R (`lavaan`, `psych`, `MASS`).

## Resumen

1. **Con la base alcanzan los 7 ejercicios**, con tres matices: la **invarianza** solo se puede hacer parcialmente (por
   edad y escolaridad, y con 20 de los 24 ítems), la **validez de criterio** no tiene un criterio independiente, y el
   **FIML** exige tratar los ítems 0/1 como continuos.
2. **Son 1,088 mujeres, no 1,089.** El renglón con `id` 907 viene solo del otro archivo del `merge` de Stata
   (`_merge` = 2): trae sus sociodemográficas, pero ningún ítem ni clase (hallazgo 1).
3. **24 ítems Sí/No sobre violencia en seis ámbitos** (infancia, familia, pareja, trabajo, comunidad y escuela).
   La estructura de seis ámbitos se confirma sola: CFI .987, RMSEA .019 (hallazgo 8).
4. **Los faltantes no son esporádicos, son saltos de pregunta:** 313 mujeres sin ningún ítem de pareja, 249 sin
   ninguno de trabajo y 57 sin ninguno de escuela. Solo **505 de 1,088** contestan los 24 ítems (hallazgo 3).
5. **Los eventos son raros** (8 ítems por debajo del 5 %, uno con 16 mujeres) y **23 de 276 parejas de ítems tienen 2 o
   menos mujeres que digan "Sí" en ambos**: la matriz tetracórica no es definida positiva y el SRMR de los modelos
   ordinales sale inflado (hallazgo 4).
6. **`c` es una clase latente de Mplus** (3 clases, calculada con estos mismos 24 ítems), no una medida independiente,
   y `c_r` **no** es una escala monótona de menos a más violencia (hallazgo 5).
7. **Lo que `Scripts.do` hace y los 7 ejercicios no:** la regresión ordinal de la clase contra las variables
   sociodemográficas (se replica en R, hallazgo 6). **Lo que no hace:** ningún análisis factorial.

## 1. Qué trae cada archivo

| Archivo | Qué es | Procesos que cubre |
|---|---|---|
| `BASE_ACLnew.dta` | Stata 13 (formato 117), 3 nov 2018. **1,089 × 37**: `id`, la clase latente `c` y su recodificación `c_r`, 9 variables sociodemográficas, **24 ítems 0/1 de violencia** y `_merge`. Todas son mujeres (los ítems hablan en femenino); que sean de Veracruz lo da el nombre del proyecto, la base no lo dice | Ninguno (es la materia prima) |
| `Scripts.do` | 4 pasos en Stata: (1) `recode c (1=3)(3=1), gen(c_r)` y `tab1` de las sociodemográficas; (2) nueve regresiones `ologit c_r i.px, or`; (3) `stata2mplus` exporta `id` y los 24 ítems a Mplus (`ACLmplus`) | Análisis de **clases latentes** (en Mplus) y regresión ordinal. **Ningún** análisis factorial |

**Observación sobre `Scripts.do`:** la primera línea (`cd "use "E:\PUED\LIBROS\SEM\LCA Bogart\", clear"`) mezcla el `cd` con
el `use` dentro de las comillas y en Stata marcaría error; lo que se quiso es `cd "E:\PUED\LIBROS\SEM\LCA Bogart\"` y
luego `use BASE_ACLnew.dta, clear`. Y `stata2mplus` es un comando de la comunidad (SSC), no de Stata. **El código y las
salidas de Mplus (el LCA que produjo `c`) no están**: `c` se toma tal como viene.

## 2. Los ejercicios: qué hay y qué se puede

| Ejercicio | ¿Viene en los archivos? | ¿Se puede con la base? | Qué falta |
|---|---|---|---|
| AFE | ❌ No | ✅ Sí: 5 factores claros (6 máximo sin Heywood) | — |
| AFC | ❌ No (solo LCA) | ✅ Sí: 6 ámbitos, CFI .987, RMSEA .019 (SRMR .110 es alto) | — |
| AFC 2.º orden | ❌ No | ✅ Sí, y **contrastable** (9 gl más) | — |
| Confiabilidad y validez | ❌ No | ✅ KR-20, CR, AVE, HTMT, omega. ⚠️ **Criterio**: solo `c_r` (no independiente) y las sociodemográficas | Documento de validez y un criterio externo |
| Puntajes factoriales | ⚠️ Solo la clase `c` | ✅ Sí, con `id` | — |
| Invarianza factorial | ❌ No (solo `ologit` por variable) | ⚠️ **Parcial**: edad y escolaridad, con 5 ámbitos (sin trabajo) | Variable de sexo (todas son mujeres), de región o municipio |
| FIML | ❌ No (Mplus lo hace por defecto) | ✅ Sí, pero con los ítems 0/1 **como continuos** (`lavaan` no tiene FIML con ordinales) | — |

## 3. Lo que se encontró

### Hallazgo 1. Un renglón huérfano

`_merge` vale 3 en 1,088 renglones y 2 en uno: `id` 907. Tiene edad, lectura, escolaridad, ocupación, dinero y estado civil
(`p1`–`p9`) pero ni un solo ítem y `c` vacía. Se quita en todos los ejercicios. `id` es único (1,089 valores distintos) y va de
3 a 1,355, con **267 huecos** en esa serie (casos que no llegaron a esta base).

### Hallazgo 2. Los ítems, sus etiquetas y lo que falta de la serie

Los 24 ítems son 0/1 (No/Sí). **Las etiquetas de Stata se cortan a 80 caracteres**, así que la redacción queda incompleta
(`...había gol`, `...la ob`). La clave está en la letra de cada reactivo (`a)`, `b)`...): en cada serie **faltan reactivos** que la
base no trae (probablemente una selección del cuestionario, como en Violencia Guerrero):

| Serie | Letras en la base | Letras que faltan |
|---|---|---|
| 14 · infancia | a, b, c, d (`p141`–`p144`) | — |
| 16 · familia (último año, sin la pareja) | a, b, e (`p161`, `p162`, `p165`) | c, d (`p163`, `p164`) |
| 17 · pareja (último año) | a, b, c, e, f (`p171`–`p173`, `p175`, `p176`) | d (`p174`) |
| 18 · trabajo ("actualmente o alguna vez") | c, d, e, f (`p183`–`p186`) | a, b (`p181`, `p182`) |
| 19 · comunidad ("cuando camina por la calle") | a, b, c, d (`p191`–`p194`) | — |
| 20 · escuela ("cuando asiste o asistió") | a, b, c, d (`p201`–`p204`) | — |

Las prevalencias (porcentaje que dice "Sí" entre quienes contestan) van de **1.9 % (`p184`, 16 mujeres) a 34.3 % (`p143`)**.
Ocho ítems están por debajo del 5 %: `p144`, `p165`, `p173`, `p183`, `p184`, `p185`, `p186`, `p203`. En violencia el evento raro es
justo lo que importa, así que **no se aplica el criterio 90-10 de EMOVI**: quitar los ítems de trabajo borraría un ámbito completo.

### Hallazgo 3. Los faltantes son saltos de pregunta

| Bloque | Mujeres sin ningún ítem | % | Quién se lo salta |
|---|---|---|---|
| Pareja (`p171`–`p176`) | **313** | 28.8 % | Sin pareja actual (`p9`): 87.2 % de las solteras, separadas, divorciadas y viudas; 0.8 % de las que viven en unión libre o casadas |
| Trabajo (`p183`–`p186`) | **249** | 22.9 % | "Nunca ha trabajado": 39.7 % de las amas de casa (`p5` = 2) contra 6.6 % de las demás |
| Escuela (`p201`–`p204`) | **57** | 5.2 % | Nunca ha ido: 28.8 % de las que no tienen estudios (`p4` = 1) contra 1.2 % de las demás |
| Familia y comunidad | 5 y 7 | < 1 % | Esporádicos |

- Solo **505 de 1,088** (46 %) contestan los 24 ítems; el 11.1 % de las celdas está vacío. Con listwise se pierden **todas**
  las mujeres sin pareja, sin trabajo o sin estudios.
- **No son faltantes al azar:** quien se salta el bloque de **pareja** responde igual en los demás ítems (1 de 19 diferencias,
  lo esperado por azar), pero quien **nunca trabajó** responde distinto en **8 de 20** ítems, con **más** violencia
  (infancia `p142`: 35 % contra 24 %; pareja `p172`: 14 % contra 6 %). Se retoma en [`07_FIML`](../07_FIML/).

### Hallazgo 4. Eventos raros y correlaciones tetracóricas

- De las 276 parejas de ítems, **23 tienen 2 mujeres o menos** que digan "Sí" en ambos y **65 tienen 5 o menos** (ninguna mujer
  dice "Sí" en `p184` y `p172`, ni en `p203` y `p194`). Sus coeficientes tetracóricos son inestables (−.40 a −.60).
- La matriz policórica por pares **no es definida positiva** (eigenvalor menor: −0.32); la de Pearson (phi) sí (+0.27).
  Por eso KMO, Bartlett y el análisis paralelo se hacen con phi (KMO = .79), como en EMOVI.
- Consecuencia práctica: el **SRMR de los modelos ordinales sale alto** (.110) y parte de eso viene de las 65 parejas casi
  vacías (sin ellas baja a .092, que sigue arriba de .08). Ver [`02_AFC`](../02_AFC/).

### Hallazgo 5. La clase latente `c`

`c` es la variable categórica latente de un análisis de clases latentes de Mplus con estos 24 ítems (3 clases). `c_r` es
`4 − c` (el `recode` de `Scripts.do`), de modo que **3 = más violencia**:

| `c_r` | Mujeres | % | Qué reporta (proporción que dice "Sí") | Hechos en promedio |
|---|---|---|---|---|
| 1 | 680 | 62.5 % | Casi nada (máximo .11) | 0.8 |
| 2 | 256 | 23.5 % | **Violencia en la infancia** (`p141` .92, `p142` .76, `p143` .93) y algo en la escuela (`p201` .33) | 4.1 |
| 3 | 152 | 14.0 % | **Varios ámbitos**: pareja (`p171`–`p176` .29–.64), familia, comunidad y escuela | 7.3 |

- **`c_r` no es una escala monótona:** los ítems de infancia son *más* altos en la clase 2 que en la 3. La clase 2 no es
  "violencia moderada" sino "violencia en la infancia".
- **No es un criterio independiente:** sale de los mismos 24 ítems. Sirve para ver que los puntajes factoriales y las clases cuentan
  la misma historia, no para probar que la escala mide violencia (ver [`04_Confiabilidad_y_Validez`](../04_Confiabilidad_y_Validez/)).

### Hallazgo 6. Réplica de `Scripts.do` (`ologit c_r i.px, or`)

Con `MASS::polr` (equivale a `ologit`; razón de momios > 1 = más probabilidad de caer en la clase de más violencia):

| Variable | Categoría contra la de referencia | Razón de momios (IC 95 %) |
|---|---|---|
| `p1` indígena | Sí contra No (28 mujeres) | **2.89** (1.50–5.56) |
| `p3` sabe leer y escribir | Sí contra No | **0.49** (0.34–0.69) |
| `p4` último grado | Primaria / secundaria / preparatoria / universidad contra ninguna | 0.86 / **0.50** / **0.33** / **0.22** |
| `p7` recibe dinero de alguien | Sí contra No | **1.55** (1.19–2.02) |
| `p9` estado civil | Viuda / unión libre contra soltera | **2.31** / **2.23** |
| `p62` conoce los derechos de las mujeres | Sí contra No | **0.73** (0.56–0.95) |
| `p2` edad | 55–64 contra 18–24 | **1.60** (1.00–2.59) |
| `p13` edad al primer embarazo | 25–29 contra menos de 15 | **0.29** (0.11–0.81) |

La escolaridad baja la probabilidad de caer en la clase de más violencia (de .86 a .22). Son asociaciones de a una variable.
Los resultados completos están en `output/ologit_razones_de_momios.csv`.

### Hallazgo 7. Lo que la base no trae

- **Sexo:** todas son mujeres, así que no hay la invarianza hombres-mujeres que se hizo en otros proyectos.
- **Región, municipio o localidad:** no hay (no se puede comparar rural-urbano ni por zona).
- **Diseño muestral:** ni ponderador, ni UPM, ni estrato. Todo el proyecto va **sin ponderar**.
- **Pareja actual:** solo `p9` (estado civil). `p2` (edad) tiene seis categorías, pero la base no trae ninguna de 65 o más.

### Hallazgo 8. Qué admite la base (pruebas rápidas)

| Modelo (WLSMV, `missing = "pairwise"`, 1,088 mujeres) | χ² (gl) | CFI | TLI | RMSEA | SRMR |
|---|---|---|---|---|---|
| 6 ámbitos | 332.3 (237) | **.987** | .985 | **.019** | .110 |
| 1 solo factor | 1,418.2 (252) | .847 | .832 | .065 | .189 |
| 6 ámbitos + factor general (2.º orden) | 345.3 (246) | .987 | .985 | .019 | .114 |

`lavaan` **no** tiene FIML con ítems ordinales (`missing = "fiml" not available in the categorical setting`).
Para la invarianza, el corte más viable es **edad** (665 contra 421) y después **escolaridad** (449 contra 618); aun así, en el
grupo más chico los ítems de trabajo tienen entre 3 y 9 mujeres con "Sí" y el modelo de seis ámbitos se vuelve inadmisible
(ver [`06_Invarianza_Factorial`](../06_Invarianza_Factorial/)).

## 4. Qué necesito

**Documentos:**

1. **El cuestionario** (o las etiquetas completas): las de Stata están cortadas a 80 caracteres. Con él se confirma la redacción de
   los 24 ítems, qué dice cada letra y qué reactivos faltan (`p163`, `p164`, `p174`, `p181`, `p182`).
2. **El código y las salidas de Mplus** (`ACLmplus`): para ver cómo se obtuvo `c` y confirmar las 3 clases.
3. **Un documento de validez** (en el Tren se usó SEM06) y, si se quiere validez de criterio, un criterio externo que no salga de
   estos mismos ítems.
4. Si existe, **sexo, región o municipio, y el diseño muestral** (ponderador, UPM, estrato).
5. Confirmar el **`merge`**: de dónde viene el archivo "using", y por qué el `id` 907 quedó sin ítems.

**Decisiones (ya tomadas):**

1. **1,088 mujeres** (se quita el `id` 907).
2. **Los 24 ítems**, sin criterio 90-10; **seis ámbitos** según el cuestionario (el AFE los recupera casi todos).
3. **Ítems 0/1 como ordinales** (WLSMV, parejas disponibles); **FIML aparte**, con los ítems como continuos (MLR).
4. **Invarianza** por edad y escolaridad con el modelo de 5 ámbitos (sin trabajo).
5. **Sin ponderador**.

Salidas (en `output/`, que no se versiona): `diccionario_items.csv`, `faltantes_estructurales.csv`, `pares_dispersos.csv`,
`perfil_clases.csv`, `ologit_razones_de_momios.csv` y `viabilidad_grupos.csv`.
