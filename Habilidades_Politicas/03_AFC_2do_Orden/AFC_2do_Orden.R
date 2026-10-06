# =============================================================================
# Libro SEM · Habilidades Políticas
# 03 - AFC de segundo orden
# =============================================================================
# Referencias: capítulo (Figura 1, Tabla 5 y Anexo 2: "HP BY HR* SA@1 AS II")
# y presentación (láminas 14-19: comandos cfa de segundo orden en R).
# Es el modelo central del capítulo: las cuatro dimensiones de Ferris (HR, SA,
# AS, II) son manifestaciones de un factor general, la Habilidad Política (HP).
# Misma estructura de pasos que 02_AFC, para poder compararlos.
#   source("Habilidades_Politicas/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)
library(semPlot)

dir_salida <- "Habilidades_Politicas/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 356 estudiantes, 15 ítems, sin faltantes
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
items <- c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9",
           "AS10", "AS11", "AS13", "AS14", "II16", "II17", "II18")
hp <- hp[, c("Genero", items)]

# -----------------------------------------------------------------------
# Paso 2. Especificar el modelo: cuatro factores de primer orden y HP
# -----------------------------------------------------------------------
# Los factores de primer orden se miden con los ítems (igual que en 02_AFC) y
# HP se mide con los cuatro factores. Las 6 correlaciones entre dimensiones se
# sustituyen por 4 cargas de HP. lavaan fija en 1 la primera carga de HP (la
# de HR); Mplus usa SA@1, y eso no cambia la solución estandarizada.
modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
modelo_2do <- paste(modelo_1er, 'HP =~ HR + SA + AS + II', sep = "\n")
dimensiones <- c("HR", "SA", "AS", "II")

# ML, como en Mplus (ESTIMATOR=ML)
fit <- cfa(modelo_2do, data = hp, estimator = "ML")
summary(fit, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Cargas estandarizadas, disturbios y R2
# -----------------------------------------------------------------------
std <- standardizedSolution(fit)
cargas <- std[std$op == "=~" & std$rhs %in% items, c("lhs", "rhs", "est.std", "se", "pvalue")]
round(cargas[, 3:4], 3)
# Cargas de los ítems: de .63 a .81, idénticas a las del AFC de primer orden.
round(lavInspect(fit, "rsquare")[items], 2)

# Cargas de segundo orden
std[std$lhs == "HP" & std$op == "=~", c("rhs", "est.std", "se", "pvalue")]
# HR .82, SA .93, AS .95, II .81 (Tabla 5 del capítulo: .824, .933, .949,
# .805). Todas significativas.

# Varianzas residuales de las dimensiones (disturbios): deben ser positivas;
# una negativa sería un caso Heywood.
std[std$op == "~~" & std$lhs %in% dimensiones & std$lhs == std$rhs, c("lhs", "est.std", "se")]
# R2: proporción de la varianza de cada dimensión que explica HP
round(lavInspect(fit, "rsquare")[dimensiones], 3)
# HP explica el 68% de HR, el 87% de SA, el 90% de AS y el 65% de II. SA y AS
# casi no tienen varianza propia (disturbios de .13 y .10): son, en la
# práctica, el factor general.

# Varianza de cada ítem que se debe a HP (carga del ítem x carga de la
# dimensión, al cuadrado) y a su dimensión en particular
gamma <- setNames(std$est.std[std$lhs == "HP" & std$op == "=~"],
                  std$rhs[std$lhs == "HP" & std$op == "=~"])
varianza_items <- cargas[, c("lhs", "rhs", "est.std")]
varianza_items$via_HP <- (varianza_items$est.std * gamma[varianza_items$lhs])^2
varianza_items$propia <- varianza_items$est.std^2 - varianza_items$via_HP
round(varianza_items[, 3:5], 2)

# -----------------------------------------------------------------------
# Paso 4. Bondad de ajuste
# -----------------------------------------------------------------------
# Criterios (Hu y Bentler, 1999): CFI y TLI >= .95 (aceptable >= .90),
# RMSEA <= .06 (aceptable <= .08), SRMR <= .08; chi2/gl < 3 (el capítulo).
ajuste <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea",
                             "rmsea.ci.lower", "rmsea.ci.upper", "srmr", "aic", "bic"))
round(ajuste, 3)
unname(ajuste["chisq"] / ajuste["df"])    # 2.87
# chi2(86) = 246.604, CFI .931, TLI .915, RMSEA .072 [.062, .083], SRMR .048:
# ajuste ACEPTABLE. Es el resultado de la presentación (lámina 19, columna R).
# El capítulo publica chi2 = 273.894 con 101 gl: es el mismo modelo con Genero
# como variable adicional, sin relación con nada (ver 00_Diagnostico). Con los
# 15 ítems el modelo tiene 86 gl.

# -----------------------------------------------------------------------
# Paso 5. Normalidad multivariada, estimador robusto (MLR) y ordinal
# -----------------------------------------------------------------------
mardia(hp[, items], plot = FALSE)      # se rechaza la normalidad (ver 02_AFC)
fit_mlr <- cfa(modelo_2do, data = hp, estimator = "MLR")
round(fitMeasures(fit_mlr, c("chisq.scaled", "df", "cfi.robust", "tli.robust",
                             "rmsea.robust", "srmr")), 3)
# Con MLR: CFI .948, TLI .937, RMSEA .062.

# Tratamiento ordinal (WLSMV sobre correlaciones policóricas)
fit_ord <- cfa(modelo_2do, data = hp, ordered = items, estimator = "WLSMV")
round(fitMeasures(fit_ord, c("chisq.scaled", "df", "cfi.scaled", "tli.scaled",
                             "rmsea.scaled", "srmr")), 3)
std_ord <- standardizedSolution(fit_ord)
carga_ord <- std_ord[std_ord$op == "=~" & std_ord$rhs %in% items, "est.std"]
round(summary(carga_ord - cargas$est.std), 3)   # las cargas ordinales suben en promedio .03
std_ord[std_ord$lhs == "HP" & std_ord$op == "=~", c("rhs", "est.std")]
# Con ordinal: CFI .967, RMSEA .077; las cargas de HP son .83, .94, .96 y .79.
# Misma estructura y mismas conclusiones.

# -----------------------------------------------------------------------
# Paso 6. Comparación con el AFC de primer orden
# -----------------------------------------------------------------------
# Con cuatro dimensiones el segundo orden SÍ se puede contrastar: 4 cargas de
# HP sustituyen a 6 correlaciones, así que tiene 2 gl más (86 contra 84).
# (Con tres dimensiones, como en el Tren, quedaría justamente identificado.)
fit_1er <- cfa(modelo_1er, data = hp, estimator = "ML")
medidas <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "aic", "bic")
comparacion <- rbind(`Primer orden (4 correlacionados)` = fitMeasures(fit_1er, medidas),
                     `Segundo orden (HP)`               = fitMeasures(fit, medidas))
round(comparacion, 3)
lavTestLRT(fit_1er, fit)
# Delta chi2 = 0.14, 2 gl, p = .93: el factor general explica las
# correlaciones entre dimensiones igual de bien que dejarlas libres. El
# segundo orden es más sencillo y el AIC y el BIC lo prefieren.
# Reglas de Chen (2007): ΔCFI y ΔRMSEA
round(c(delta_cfi = comparacion[2, "cfi"] - comparacion[1, "cfi"],
        delta_rmsea = comparacion[2, "rmsea"] - comparacion[1, "rmsea"]), 4)

# Correlaciones entre dimensiones: observadas (primer orden) contra las que
# implica HP (producto de sus cargas estandarizadas)
round(lavInspect(fit_1er, "cor.lv")[dimensiones, dimensiones], 2)
round(outer(gamma, gamma), 2)
# Las diferencias son de .01 como máximo (SA-AS: .88 observada contra .89 implícita).

# -----------------------------------------------------------------------
# Paso 7. Índices de modificación (solo para mirar; no se modifica el modelo)
# -----------------------------------------------------------------------
mi <- modindices(fit, sort. = TRUE, minimum.value = 10)
head(mi[, c("lhs", "op", "rhs", "mi", "epc", "sepc.all")], 8)
# Los mismos que en el primer orden (MI 17 a 19): HR2 ~~ HR3, AS13 ~~ AS14 y
# AS =~ SA7. Ninguno es grande ni requiere reespecificar.

# -----------------------------------------------------------------------
# Paso 8. Guardar resultados y diagrama
# -----------------------------------------------------------------------
write.csv(std[std$op == "=~" | (std$op == "~~" & std$lhs != std$rhs),
              c("lhs", "op", "rhs", "est.std", "se", "pvalue")],
          file.path(dir_salida, "solucion_estandarizada_2do_orden.csv"), row.names = FALSE)
write.csv(round(comparacion, 3), file.path(dir_salida, "comparacion_1er_2do_orden.csv"))
varianza_items[, 3:5] <- round(varianza_items[, 3:5], 3)
write.csv(varianza_items, file.path(dir_salida, "varianza_items_via_HP.csv"), row.names = FALSE)

# Las etiquetas de las cargas se encimarían: se escalonan a tres alturas a lo
# largo de cada flecha (igual que en 02_AFC).
p <- semPaths(fit, whatLabels = "std", layout = "tree", residuals = FALSE,
              intercepts = FALSE, nCharNodes = 0, sizeMan = 5, sizeLat = 8,
              sizeLat2 = 10, edge.label.cex = 1, DoNotPlot = TRUE)
a_item <- p$graphAttributes$Nodes$names[p$Edgelist$to] %in% lavNames(fit, "ov")
orden <- ave(seq_along(a_item), p$Edgelist$from, FUN = seq_along)
posicion <- rep(.5, length(a_item))
posicion[a_item] <- c(.3, .55, .8)[orden[a_item] %% 3 + 1]
p$graphAttributes$Edges$edge.label.position <- posicion
png(file.path(dir_salida, "diagrama_2do_orden.png"), width = 1800, height = 1000)
plot(p)
dev.off()
plot(p)
