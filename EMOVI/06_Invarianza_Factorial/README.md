# 06 · Invarianza factorial: Riqueza del hogar de origen

Script: `Invarianza_Factorial.R` (unos 40 segundos). **Referencia:** la tesis compara los coeficientes del SEM
entre mujeres y hombres y entre 25–40 y 41–64 años con pruebas de Wald, **sin probar antes que las escalas se
miden igual en esos grupos**. Este ejercicio llena ese hueco para la riqueza, con los mismos grupos.

**Pregunta:** ¿miden igual los 29 ítems de riqueza a hombres y mujeres, y a las dos cohortes?

**Respuesta corta:** **sí por sexo**; **por edad, con una salvedad:** el criterio de Chen se cumple pero la
prueba de χ² rechaza.

## Paso a paso

1. **Grupos.** 318 hombres y 422 mujeres (`sexo`: 1 hombre, 2 mujer); 372 de 25 a 40 años y 368 de 41 a 64.
2. **Pasos con ítems binarios.** Los umbrales y las cargas se restringen juntos (Millsap y Tein, 2004):
   *configural* (todo libre) contra *umbrales + cargas iguales*. Criterio de Chen (2007): ΔCFI de −.010 o menos y
   ΔRMSEA de .015 o menos. Modelo de tres factores, WLSMV, `missing = "pairwise"`.

   | Grupo | Modelo | χ² (gl) | CFI | RMSEA | ΔCFI | ΔRMSEA | p (Δχ²) |
   |---|---|---|---|---|---|---|---|
   | Sexo | Configural | 1,052.6 (748) | .980 | .033 | | | |
   | Sexo | Umbrales + cargas | 1,070.4 (771) | .980 | .032 | **.000** | −.001 | **.503** |
   | Edad | Configural | 1,032.2 (748) | .973 | .032 | | | |
   | Edad | Umbrales + cargas | 1,076.9 (771) | .971 | .033 | **−.002** | .001 | **.001** |

   - **Sexo:** hay invarianza: ΔCFI = 0 y la χ² no rechaza (p = .50).
   - **Edad:** ΔCFI = −.002 y ΔRMSEA = .001, dentro del criterio de Chen; pero la prueba de χ² escalada rechaza
     (p = .001). Con ~370 por grupo y 29 ítems, la χ² es sensible a diferencias pequeñas: **se acepta la
     invarianza con esta salvedad**. No se buscó qué ítems pesan más en la diferencia.
3. **Ajuste del modelo en cada grupo** (conviene saberlo antes de comparar):

   | Grupo | N | CFI | RMSEA | SRMR |
   |---|---|---|---|---|
   | Hombres | 318 | .988 | .027 | .098 |
   | Mujeres | 422 | .972 | .039 | .100 |
   | 25–40 | 372 | .957 | .039 | .108 |
   | 41–64 | 368 | .983 | .026 | .108 |

   Todos aceptables en CFI y RMSEA; el SRMR ronda .10 (habitual con WLSMV y pocos casos). El más flojo es el de
   25–40 (CFI .957).

**Salidas** (`output/`): `invarianza.csv` y `ajuste_por_grupo.csv`.

**Cuidado.** Es la invarianza de la **escala de riqueza**, no del SEM completo de la tesis. Con esto ya hay base
para comparar la riqueza entre estos grupos.
