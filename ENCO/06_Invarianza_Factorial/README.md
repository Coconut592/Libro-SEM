# 06 · Invarianza factorial: Confianza del consumidor

Script: `Invarianza_Factorial.R` (unos 30 segundos). **Sin referencia:** el documento de INEGI no trae invarianza. Antes
de comparar la confianza entre grupos conviene probar que los 15 ítems miden igual en cada uno.

**Pregunta:** ¿miden igual los 15 ítems a hombres y mujeres, a tres grupos de edad, a dos niveles de escolaridad y a
la gran ciudad frente al resto?

**Respuesta corta: sí por el criterio de Chen, en los cuatro grupos**, con una salvedad: la prueba de χ² rechaza la
igualdad de **umbrales** (con 2,050 casos es muy sensible), y en estudios y gran ciudad también la de cargas.

## Paso a paso

1. **Grupos elegidos.** Los ítems de `ENCOCS` permiten muchas agrupaciones, pero **`P12` no se funde** y su categoría
   «Disminuirán mucho» tiene solo 5 casos en toda la base: si una categoría queda vacía en algún grupo, `lavaan` no
   puede estimar su umbral y se detiene. Se revisó qué agrupaciones se pueden usar:

   | Agrupación | Categorías vacías |
   |---|---|
   | **Sexo** (2) | ninguna ✅ |
   | **Edad** (3: 18–39 / 40–59 / 60+) | ninguna ✅ |
   | **Estudios** (2: hasta secundaria / medio superior o más) | ninguna ✅ |
   | **Gran ciudad** (2: CDMX, Guadalajara y Monterrey / resto) | ninguna ✅ |
   | Edad (4: 18–29 / 30–44 / 45–59 / 60+) | `P12` en 45–59 ❌ |
   | Estudios (4: primaria o menos … superior) | `P12` en dos grupos ❌ |
   | Ciudad (4: CDMX / Guadalajara / Monterrey / resto) | `P3`, `P12` en Guadalajara; `P1`, `P3`, `P12` en Monterrey ❌ |

   Se usan las **cuatro primeras**: sexo y edad (la edad es el mayor correlato de la confianza, r = −.33), escolaridad
   y ciudad (la ENCO es urbana y la escolaridad se asocia con el ingreso). Tamaños: sexo 862 / 1,188; edad 773 / 747 /
   530; estudios 769 / 1,279 (2 sin dato); ciudad 766 / 1,284. «Medio superior o más» incluye normal y carrera técnica
   (el PDF no dice si requirieron preparatoria). Con más grupos habría que fundir las colas de `P12`, lo que se decidió
   no hacer.
2. **Pasos con ítems ordinales.** *Configural* (todo libre), *umbrales* iguales y *umbrales + cargas* iguales
   (Millsap y Tein, 2004: se restringen juntos porque `P9` y `P10` son binarios). Criterio de Chen (2007): ΔCFI de −.010
   o menos y ΔRMSEA de .015 o menos, contra el configural. Modelo de cuatro factores, WLSMV, `missing = "pairwise"`.

   | Grupo | Modelo | χ² (gl) | CFI | RMSEA | ΔCFI | ΔRMSEA | p (Δχ², contra el paso anterior) |
   |---|---|---|---|---|---|---|---|
   | Sexo | Configural | 1,030 (168) | .975 | .071 | | | |
   | | Umbrales | 1,085 (196) | .974 | .067 | −.001 | −.004 | < .001 |
   | | Umbrales + cargas | 995 (207) | .977 | .061 | +.002 | −.010 | .29 |
   | Edad | Configural | 1,141 (252) | .971 | .072 | | | |
   | | Umbrales | 1,197 (308) | .971 | .065 | .000 | −.007 | .001 |
   | | Umbrales + cargas | 1,098 (330) | .975 | .058 | +.004 | −.014 | .46 |
   | Estudios | Configural | 1,040 (168) | .975 | .071 | | | |
   | | Umbrales | 1,091 (196) | .974 | .067 | −.001 | −.004 | < .001 |
   | | Umbrales + cargas | 1,019 (207) | .976 | .062 | +.001 | −.009 | .003 |
   | Gran ciudad | Configural | 1,026 (168) | .976 | .071 | | | |
   | | Umbrales | 1,038 (196) | .977 | .065 | +.001 | −.006 | .047 |
   | | Umbrales + cargas | 967 (207) | .979 | .060 | +.003 | −.011 | .043 |

   - **Por Chen hay invarianza de umbrales y cargas en los cuatro grupos:** ΔCFI de −.001 a +.004 y ΔRMSEA de −.004 a
     −.014. (Con WLSMV el CFI escalado a veces sube al restringir; lo que cuenta es que no baje más de .010.)
   - **La χ² es más exigente:** rechaza la igualdad de **umbrales** en los cuatro grupos (p de < .001 a .047) y la de
     cargas en **estudios** (p = .003) y **gran ciudad** (p = .043); en **sexo y edad** las cargas no se rechazan
     (p = .29 y .46). Con 2,050 casos la prueba detecta diferencias pequeñas: **se acepta la invarianza** con la
     salvedad de que las diferencias, si las hay, están en los umbrales. No se buscó cuáles pesan más.
3. **Ajuste del modelo en cada grupo** (conviene saberlo antes de comparar):

   | Grupo | N | CFI | RMSEA | SRMR | Categoría más rara (casos) |
   |---|---|---|---|---|---|
   | Hombres | 862 | .976 | .070 | .052 | 3 |
   | Mujeres | 1,188 | .974 | .072 | .051 | 2 |
   | 18–39 | 773 | .962 | .081 | .058 | 3 |
   | 40–59 | 747 | .969 | .071 | .056 | 1 |
   | 60+ | 530 | .984 | .059 | .057 | 1 |
   | Hasta secundaria | 769 | .975 | .069 | .053 | 1 |
   | Medio superior o más | 1,279 | .974 | .073 | .050 | 4 |
   | Gran ciudad | 766 | .982 | .066 | .052 | 1 |
   | Resto | 1,284 | .971 | .074 | .050 | 4 |

   Todos aceptables; el más flojo es 18–39 (CFI .962, RMSEA .081).

**Salidas** (`output/`): `invarianza.csv`, `ajuste_por_grupo.csv` y `categorias_vacias_por_agrupacion.csv`.

**Cuidado.** En varios grupos la categoría más rara tiene 1 a 4 casos (`P11`, `P3`, `P1`, `P12`): sus umbrales son
frágiles. Es la invarianza **entre grupos en un mismo mes**; no hay invarianza **en el tiempo** (solo se tiene agosto de
2026). Con esto ya hay base para comparar la confianza entre estos grupos.
