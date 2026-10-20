# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R` (unos 20 segundos). **Sin referencia propia:** la tesis pasa directo al AFC y construye el
índice de riqueza del hogar de origen con un CFA (Anexo 2). Aquí se explora antes la estructura de esos ítems en
la CDMX en 2023.

**Pregunta:** los ítems sobre cómo era la vivienda y qué tenía el hogar a los 14 años, ¿miden una sola riqueza o
varias dimensiones?

**Respuesta corta: tres dimensiones**, que correlacionan de .48 a .63: espacios de la vivienda, servicios y
bienes básicos, y tecnología y confort.

## Paso a paso

1. **Datos.** 740 entrevistados de la CDMX (`entidad` = 9). Los 42 ítems Sí/No de riqueza (`p26`, `p29`, `p31`,
   `p32`), con `NS` (8) pasado a faltante.
2. **Criterio 90-10 de la tesis (Anexo 2).** Se quitan los ítems que casi todos o casi nadie tenían: **quedan
   29 de 42**. Sale `p26b` (electricidad, 95 % de los hogares) y 12 más con menos de 10 %: casi todo el
   bloque de activos financieros (`p32b`–`p32d`, `p32g`, `p32i`–`p32o`) y `p31n` (5 %, motocicleta). **En la CDMX
   el bloque `p32` casi desaparece**: solo quedan `p32a`, `p32e`, `p32f` y `p32h`.
3. **Casos.** 651 sin ningún `NS` y 89 con al menos uno.
4. **¿Tiene sentido factorizar?** KMO = **.91** y Bartlett χ² = 6,461 (406 gl), p < .001. Se hacen con la
   correlación de Pearson porque la tetracórica de estos datos no es definida positiva (el eigenvalor menor es
   −0.19) y KMO y Bartlett salen sin sentido sobre ella.
5. **¿Cuántos factores?** Eigenvalores 7.97, 2.39, 1.70, 1.39, 1.16, 1.02…: Kaiser y el análisis paralelo
   dicen **6**, pero con ítems 0/1 estos criterios suelen sobrestimar. Se decide con el **AFE de `lavaan`**
   (WLSMV, ordinal, oblimin), que sí da ajuste:

   | Factores | CFI | TLI | RMSEA | SRMR | Varianza residual más baja |
   |---|---|---|---|---|---|
   | 1 | .954 | .951 | .054 | .101 | .149 |
   | 2 | .976 | .972 | .041 | .082 | .085 |
   | **3** | **.985** | **.981** | **.034** | **.070** | .034 |
   | 4 | .991 | .987 | .027 | .060 | .028 |
   | 5 | .995 | .992 | .022 | .053 | **−.004** |

   Con 5 factores una varianza residual ya es negativa. **Se escogen 3:** buen ajuste, cada factor con sentido y
   el cuarto (`p32e`, `p32f`, `p32h`: cuentas y tarjetas) tendría solo tres ítems.
6. **Tres factores** (cargas de patrón, oblimin):

   | Factor | Ítems con carga principal |
   |---|---|
   | **F1 · Espacios de la vivienda** | `p29e` cuarto de TV (.85), `p29d` cuarto de lavado (.82), `p29b` jardín (.72), `p29f` cochera (.57), `p29c` patio, `p26e` servicio doméstico, `p32a` otra vivienda; `p31f` tostador y `p31g` aspiradora (.48–.49, con carga también en F3) |
   | **F2 · Servicios y bienes básicos** | `p31e` TV (.86), `p31c` refri (.82), `p31a` estufa (.81), `p31b` lavadora, `p31d` teléfono fijo, `p26a` agua, `p26d` boiler, `p31m` DVD, `p31o` bicicleta y las cuentas y tarjetas `p32e` cuenta de ahorro (.86), `p32f` tarjeta de crédito (.83), `p32h` cuenta de nómina |
   | **F3 · Tecnología y confort** | `p31l` internet (.97), `p31j` celular (.91), `p31k` computadora (.86), `p31i` microondas (.61), `p31h` TV de paga (.60) |

   `p29a` (sala o comedor) y `p26c` (baño dentro) cargan casi igual en F1 y F2; en el AFC se dejan la sala con los
   espacios y el baño con los servicios.

**Salidas** (`output/`): `ajuste_AFE.csv` y `cargas_AFE_3_factores.csv`.

**Cuidado.** El AFC (02) se confirma con los mismos 740 casos: la estructura sale de estos datos y no es una
prueba independiente. Con 740 casos no conviene partirlos en dos.
