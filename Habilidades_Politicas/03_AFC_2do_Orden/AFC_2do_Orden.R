# =============================================================================
# Libro SEM · Habilidades Políticas
# 03 - AFC de segundo orden
# =============================================================================
# Referencias: capítulo (Figura 1, Tabla 5 y Anexo 2: "HP BY HR* SA@1 AS II")
# y presentación (láminas 14-19: comandos cfa de segundo orden en R).
# Este es el modelo central del capítulo: las cuatro dimensiones de Ferris
# (HR, SA, AS, II) son manifestaciones de un factor general, la Habilidad
# Política (HP).
#   source("Habilidades_Politicas/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(semPlot)

dir_salida <- "Habilidades_Politicas/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 356 estudiantes, 15 ítems
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
items <- c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9",
           "AS10", "AS11", "AS13", "AS14", "II16", "II17", "II18")
hp <- hp[, c("Genero", items)]

# -----------------------------------------------------------------------
# Paso 2. Especificar el modelo de segundo orden
# -----------------------------------------------------------------------
# Los factores de primer orden se miden con los ítems (igual que en el AFC) y
# HP se mide con los cuatro factores. Ya no se estiman las 6 correlaciones
# entre dimensiones: HP explica lo que tienen en común. lavaan fija en 1 la
# primera carga de HP (la de HR) para darle escala; Mplus usa SA@1 en el
# anexo del capítulo, y eso no cambia la solución estandarizada.
modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
modelo_2do <- paste(modelo_1er, 'HP =~ HR + SA + AS + II', sep = "\n")

fit_2do <- cfa(modelo_2do, data = hp, estimator = "ML")
summary(fit_2do, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Revisar la solución
# -----------------------------------------------------------------------
std <- standardizedSolution(fit_2do)
dimensiones <- c("HR", "SA", "AS", "II")
std[std$lhs == "HP" & std$op == "=~", c("rhs", "est.std", "se", "pvalue")]
# Cargas de segundo orden: HR .82, SA .93, AS .95, II .81 (Tabla 5 del
# capítulo: .824, .933, .949, .805). Todas significativas.

# Varianzas residuales de las dimensiones (disturbios): deben ser positivas;
# una negativa sería un caso Heywood.
std[std$op == "~~" & std$lhs %in% dimensiones & std$lhs == std$rhs, c("lhs", "est.std", "se")]
# R2: proporción de la varianza de cada dimensión que explica HP
round(lavInspect(fit_2do, "rsquare")[dimensiones], 3)
# HP explica el 68% de HR, el 87% de SA, el 90% de AS y el 65% de II. SA y AS
# casi no tienen varianza propia (disturbios de .13 y .10): son, en la
# práctica, el factor general.

# Varianza de cada ítem que se debe a HP (carga del ítem x carga de la
# dimensión, al cuadrado) y a su dimensión en particular
cargas_items <- std[std$op == "=~" & std$rhs %in% items, c("lhs", "rhs", "est.std")]
gamma <- setNames(std$est.std[std$lhs == "HP" & std$op == "=~"],
                  std$rhs[std$lhs == "HP" & std$op == "=~"])
cargas_items$via_HP <- (cargas_items$est.std * gamma[cargas_items$lhs])^2
cargas_items$propia <- cargas_items$est.std^2 - cargas_items$via_HP
round(cargas_items[, 3:5], 2)

# -----------------------------------------------------------------------
# Paso 4. Bondad de ajuste
# -----------------------------------------------------------------------
# Criterios del capítulo (Tabla 4): chi2/gl < 3, CFI y TLI > .90, RMSEA <= .08
# (aceptable), SRMR cercano a 0.
ajuste <- fitMeasures(fit_2do, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea",
                                 "rmsea.ci.lower", "rmsea.ci.upper", "srmr", "aic", "bic"))
round(ajuste, 3)
unname(ajuste["chisq"] / ajuste["df"])    # 2.87
# chi2(86) = 246.604, CFI .931, TLI .915, RMSEA .072 [.062, .083], SRMR .048.
# Es el resultado de la presentación (lámina 19, columna R). El capítulo
# publica chi2 = 273.894 con 101 gl: es el mismo modelo con Genero como
# variable adicional, sin relación con nada (ver 00_Diagnostico). Con los
# 15 ítems el modelo tiene 86 gl.

# Con MLR (los datos no son normales; ver 02_AFC)
fit_mlr <- cfa(modelo_2do, data = hp, estimator = "MLR")
round(fitMeasures(fit_mlr, c("chisq.scaled", "df", "cfi.robust", "tli.robust",
                             "rmsea.robust", "srmr")), 3)

# -----------------------------------------------------------------------
# Paso 5. Comparación con el AFC de primer orden
# -----------------------------------------------------------------------
# Con cuatro dimensiones el segundo orden SÍ se puede contrastar: 4 cargas de
# HP sustituyen a 6 correlaciones, así que tiene 2 gl más (86 contra 84).
# (Con tres dimensiones, como en el Tren, quedaría justamente identificado.)
fit_1er <- cfa(modelo_1er, data = hp, estimator = "ML")
medidas <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "aic", "bic")
comparacion <- rbind(primer_orden = fitMeasures(fit_1er, medidas),
                     segundo_orden = fitMeasures(fit_2do, medidas))
round(comparacion, 3)

# Diferencia de chi-cuadrada (modelos anidados)
lavTestLRT(fit_1er, fit_2do)
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
# Paso 6. Guardar resultados y diagrama
# -----------------------------------------------------------------------
write.csv(std, file.path(dir_salida, "solucion_estandarizada_2do_orden.csv"), row.names = FALSE)
write.csv(round(comparacion, 3), file.path(dir_salida, "comparacion_1er_2do_orden.csv"))
cargas_items[, 3:5] <- round(cargas_items[, 3:5], 3)
write.csv(cargas_items, file.path(dir_salida, "varianza_items_via_HP.csv"), row.names = FALSE)

# Las etiquetas de las cargas se encimarían: se escalonan a tres alturas a lo
# largo de cada flecha.
p <- semPaths(fit_2do, whatLabels = "std", layout = "tree", residuals = FALSE,
              intercepts = FALSE, nCharNodes = 0, sizeMan = 5, sizeLat = 8,
              sizeLat2 = 10, edge.label.cex = 1, DoNotPlot = TRUE)
a_item <- p$graphAttributes$Nodes$names[p$Edgelist$to] %in% lavNames(fit_2do, "ov")
orden <- ave(seq_along(a_item), p$Edgelist$from, FUN = seq_along)
posicion <- rep(.5, length(a_item))
posicion[a_item] <- c(.3, .55, .8)[orden[a_item] %% 3 + 1]
p$graphAttributes$Edges$edge.label.position <- posicion
png(file.path(dir_salida, "diagrama_2do_orden.png"), width = 1800, height = 1000)
plot(p)
dev.off()
plot(p)
