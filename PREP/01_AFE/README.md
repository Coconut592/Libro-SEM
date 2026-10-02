# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R`. Referencias: `AFE.do`, `EFA_Hogares.inp` y Laboratorio 2.

**Objetivo:** ver cuántos factores hay en cada bloque y qué ítems forman cada uno, antes del AFC.

## Paso a paso

1. **Datos.** `PREP.dta` (8,242 respondientes). El "99 = Ns/Nc" de los bloques c a f se pasa a `NA` y se
   usan los casos completos de cada bloque, como `AFE.do`. Las equivalencias con el piloto están en
   [`00_Diagnostico`](../00_Diagnostico/README.md).
2. **¿Tiene sentido factorizar?** `KMO()` y `cortest.bartlett()`.
3. **¿Cuántos factores?** Eigenvalores > 1 (Kaiser) y análisis paralelo del Lab 2
   (`nFactors::parallel`, 100 réplicas, percentil 95), más la variante con factores ML.
4. **AFE.** `fa(fm = "ml", rotate = "varimax")`.

| Bloque | Ítems | N | KMO | Kaiser | Paralelo (comp. / ML) | RMSEA | TLI |
|---|---|---|---|---|---|---|---|
| Espacio público | 11 | 4,019 | .89 | 3 | 3 / 3 | .050 | .979 |
| Colonia | 25 | 5,880 | .93 | 4 | 4 / 5 | .068 | .912 |
| G (participación y civismo) | 12 | 6,627 | .78 | 3 | 3 / 4 | .050 | .970 |

**Espacio público (3 factores):** calificación (`b11`–`b13`, cargas .74–.86), seguridad (`b14`–`b18`,
.70–.81) y actividades (`b21`, `b22`; `b26` carga .54 ahí y .37 en calificación).

**Colonia (4 factores):** inseguridad percibida (`c01`–`c06`), seguridad (`c07`–`c09`), cohesión
(`d01`–`d09`) e infraestructura con satisfacción (`e01`–`e05` más `f01`–`f02`, cargas .52–.83). Con 5
factores el quinto solo recoge una carga cruzada de `d02`: **Satisfacción no se separa de
Infraestructura**, aunque `CFA_Hogares.inp` las propone separadas. `d09` ("pediría prestado dinero a un
vecino") es el ítem débil (comunalidad .24).

**G (3 factores):** participación (`g01`–`g04`), rechazo a conductas incívicas (`g06`–`g08`) e
intervención (`g09`–`g12`). `g05` (vendedores ambulantes) no carga en ninguno (comunalidad .03).

Salidas (`output/`): `cargas_AFE_*.csv` y `grafica_codo_*.png`.
