# =============================================================================
# Libro SEM · Habilidades Políticas
# 02 - Análisis Factorial Confirmatorio (AFC) de primer orden
# =============================================================================
# Referencias: capítulo (Tabla 5, Anexo 2: sintaxis de Mplus con ESTIMATOR=ML)
# y presentación (láminas 16-19: el mismo modelo en R). El capítulo ajusta
# primero 18 reactivos y luego, quitando HR5, AS12 e II15, 15; la base solo
# trae los 15, así que este es el modelo final del capítulo.
#   source("Habilidades_Politicas/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)
library(semPlot)

dir_salida <- "Habilidades_Politicas/02_AFC/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 356 estudiantes, 15 ítems, sin faltantes
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
items <- c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9",
           "AS10", "AS11", "AS13", "AS14", "II16", "II17", "II18")
hp <- hp[, c("Genero", items)]

# -----------------------------------------------------------------------
# Paso 2. Especificar el modelo: cuatro factores correlacionados
# -----------------------------------------------------------------------
# "=~" se lee "se mide por". lavaan fija en 1 la carga del primer ítem de cada
# factor para darle escala y deja libres las covarianzas entre factores.
#   HR = Habilidad en redes          SA = Sinceridad aparente
#   AS = Astucia social              II = Influencia interpersonal
modelo <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'

# ML, como en Mplus (ESTIMATOR=ML)
fit <- cfa(modelo, data = hp, estimator = "ML")
summary(fit, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Cargas estandarizadas y correlaciones entre factores
# -----------------------------------------------------------------------
std <- standardizedSolution(fit)
cargas <- std[std$op == "=~", c("lhs", "rhs", "est.std", "se", "pvalue")]
round(cargas[, 3:4], 3)
# Cargas de .63 a .81, todas con p < .001. Coinciden con la Tabla 5 del
# capítulo (ver 00_Diagnostico: en la tabla, AS10, AS11 y AS13 traen los
# valores de otro ítem).
# R2 de cada ítem (varianza que explica su factor)
round(lavInspect(fit, "rsquare"), 2)

correlaciones <- lavInspect(fit, "cor.lv")
round(correlaciones, 3)
# De .66 (HR-II) a .89 (SA-AS). Cuando dos factores correlacionan tanto
# (> .85), la validez discriminante es dudosa: SA y AS casi no se distinguen.
# Esto anticipa la solución de un factor general (segundo orden).

# -----------------------------------------------------------------------
# Paso 4. Bondad de ajuste
# -----------------------------------------------------------------------
# Criterios (Hu y Bentler, 1999): CFI y TLI >= .95 (aceptable >= .90),
# RMSEA <= .06 (aceptable <= .08), SRMR <= .08; chi2/gl < 3 (el capítulo).
ajuste <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea",
                             "rmsea.ci.lower", "rmsea.ci.upper", "srmr", "aic", "bic"))
round(ajuste, 3)
unname(ajuste["chisq"] / ajuste["df"])    # 2.93
# chi2(84) = 246.5 (p < .001), CFI .930, TLI .912, RMSEA .074 [.063, .084],
# SRMR .048: ajuste ACEPTABLE (CFI/TLI > .90, RMSEA < .08, SRMR < .08), no
# bueno (CFI/TLI < .95). chi2/gl = 2.93 < 3.

# -----------------------------------------------------------------------
# Paso 5. Normalidad multivariada y estimador robusto (MLR)
# -----------------------------------------------------------------------
# ML supone normalidad multivariada. Los ítems tienen asimetría negativa
# (hasta -1.5 en SA7 y SA8) y la prueba de Mardia la rechaza con claridad.
mardia(hp[, items], plot = FALSE)
# MLR corrige la chi-cuadrada y los errores estándar (Yuan-Bentler).
fit_mlr <- cfa(modelo, data = hp, estimator = "MLR")
round(fitMeasures(fit_mlr, c("chisq.scaled", "df", "cfi.robust", "tli.robust",
                             "rmsea.robust", "srmr")), 3)
# Con MLR el ajuste mejora (CFI .947, RMSEA .063): el rechazo de normalidad
# inflaba la chi-cuadrada. La conclusión no cambia: el modelo ajusta.

# Los ítems son ordinales (1 a 7): se verifica con un tratamiento ordinal
# (WLSMV sobre correlaciones policóricas).
fit_ord <- cfa(modelo, data = hp, ordered = items, estimator = "WLSMV")
round(fitMeasures(fit_ord, c("chisq.scaled", "df", "cfi.scaled", "tli.scaled",
                             "rmsea.scaled", "srmr")), 3)
carga_ord <- standardizedSolution(fit_ord)
carga_ord <- carga_ord[carga_ord$op == "=~", "est.std"]
round(summary(carga_ord - cargas$est.std), 3)   # las cargas ordinales suben en promedio .03

# -----------------------------------------------------------------------
# Paso 6. ¿Cuatro factores, tres o uno?
# -----------------------------------------------------------------------
# El AFE (01_AFE) sugiere 3 factores (SA y AS juntos), y SA-AS correlacionan
# .89. Se comparan con modelos anidados (se juntan factores):
modelo_3f <- '
  HR  =~ HR1 + HR2 + HR3 + HR4 + HR6
  SAS =~ SA7 + SA8 + SA9 + AS10 + AS11 + AS13 + AS14
  II  =~ II16 + II17 + II18'
modelo_1f <- paste("HP =~", paste(items, collapse = " + "))
fit_3f <- cfa(modelo_3f, data = hp, estimator = "ML")
fit_1f <- cfa(modelo_1f, data = hp, estimator = "ML")

medidas <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "aic", "bic")
comparacion <- rbind(`4 factores (Ferris)` = fitMeasures(fit, medidas),
                     `3 factores (SA+AS)`  = fitMeasures(fit_3f, medidas),
                     `1 factor`            = fitMeasures(fit_1f, medidas))
round(comparacion, 3)
lavTestLRT(fit, fit_3f, fit_1f)
# 4 contra 3 factores: Delta chi2 = 12.6, 3 gl, p = .006 (el de 4 ajusta
# mejor), pero el AIC y el CFI casi no cambian y el BIC prefiere el de 3
# (16581 contra 16587). Un solo factor ajusta claramente peor (CFI .835,
# RMSEA .109). La teoría de 4 factores se sostiene, con SA y AS muy cercanos.

# -----------------------------------------------------------------------
# Paso 7. Índices de modificación (solo para mirar; no se modifica el modelo)
# -----------------------------------------------------------------------
mi <- modindices(fit, sort. = TRUE, minimum.value = 10)
head(mi[, c("lhs", "op", "rhs", "mi", "epc", "sepc.all")], 8)
# Los mayores (MI 17 a 19): HR2 ~~ HR3, AS13 ~~ AS14 y AS =~ SA7 (carga cruzada). Los dos primeros son
# residuos correlacionados dentro del mismo factor. Ninguno es grande ni
# requiere reespecificar; el capítulo tampoco usa los índices:
# reespecifica quitando ítems (5, 12 y 15).

# -----------------------------------------------------------------------
# Paso 8. Guardar resultados y diagrama
# -----------------------------------------------------------------------
solucion <- std[std$op == "=~" | (std$op == "~~" & std$lhs != std$rhs),
                c("lhs", "op", "rhs", "est.std", "se", "pvalue")]
write.csv(solucion, file.path(dir_salida, "solucion_estandarizada_AFC.csv"), row.names = FALSE)
write.csv(round(comparacion, 3), file.path(dir_salida, "comparacion_4_3_1_factores.csv"))

# Las etiquetas de las cargas se encimarían: se escalonan a tres alturas a lo
# largo de cada flecha. La flecha punteada es la carga fijada en 1 (marcador)
# del modelo sin estandarizar; la etiqueta ya muestra su valor estandarizado.
p <- semPaths(fit, whatLabels = "std", layout = "tree", residuals = FALSE,
              intercepts = FALSE, nCharNodes = 0, sizeMan = 5, sizeLat = 8,
              edge.label.cex = 1, DoNotPlot = TRUE)
a_item <- p$graphAttributes$Nodes$names[p$Edgelist$to] %in% lavNames(fit, "ov")
orden <- ave(seq_along(a_item), p$Edgelist$from, FUN = seq_along)
posicion <- rep(.5, length(a_item))
posicion[a_item] <- c(.3, .55, .8)[orden[a_item] %% 3 + 1]
p$graphAttributes$Edges$edge.label.position <- posicion
png(file.path(dir_salida, "diagrama_AFC.png"), width = 1800, height = 900)
plot(p)
dev.off()
plot(p)
