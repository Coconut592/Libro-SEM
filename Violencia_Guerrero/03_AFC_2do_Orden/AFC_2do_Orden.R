# =============================================================================
# Libro SEM · Violencia Guerrero
# 03 - AFC de segundo orden
# =============================================================================
# Sin referencia (en el Tren: CFA_2doOrden.inp, "G BY F1 F2 F3"). Aquí
# G = Satisfacción con la vida, medida por los seis dominios de a1-a24: pareja,
# familia, economía, vida social, bienestar personal y trabajo. Los seis se
# correlacionan entre sí (.17 a .65, todas positivas; ver 02_AFC). Los otros
# seis factores (b, c, f) no forman un constructo general: sus correlaciones
# tienen signos mixtos (-.24 a .52), así que no se les plantea un 2do orden.
#   source("Violencia_Guerrero/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(semPlot)

dir_salida <- "Violencia_Guerrero/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: las 294 personas, ítems de satisfacción (a1-a24)
# -----------------------------------------------------------------------
# Se usa FIML (ver 07_FIML): 71 personas no contestan los ítems de pareja
# (no tienen pareja) y 202 de 294 contestan los 24 ítems.
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
sum(complete.cases(guerrero[, paste0("a", 1:24)]))

# -----------------------------------------------------------------------
# Paso 2. Especificar el modelo de segundo orden
# -----------------------------------------------------------------------
# Los factores de primer orden se miden con los ítems (igual que en el AFC) y
# G se mide con los seis factores. Ya no se estiman las 15 correlaciones
# entre dominios: G explica lo que tienen en común. lavaan fija en 1 la
# primera carga de G (pareja) para darle escala.
modelo_1er <- '
  pareja   =~ a1 + a2 + a3 + a4
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24'
modelo_2do <- paste(modelo_1er,
  'G =~ pareja + familia + economia + social + personal + trabajo', sep = "\n")

fit_2do <- cfa(modelo_2do, data = guerrero, estimator = "MLR", missing = "fiml")
summary(fit_2do, fit.measures = TRUE, standardized = TRUE)

# -----------------------------------------------------------------------
# Paso 3. Revisar la solución
# -----------------------------------------------------------------------
std <- standardizedSolution(fit_2do)
dominios <- c("pareja", "familia", "economia", "social", "personal", "trabajo")
std[std$lhs == "G" & std$op == "=~", c("rhs", "est.std", "se", "pvalue")]   # cargas de segundo orden

# Varianzas residuales de los factores de primer orden (disturbios): deben ser
# positivas; una negativa sería un caso Heywood.
std[std$op == "~~" & std$lhs %in% dominios & std$lhs == std$rhs, c("lhs", "est.std", "se")]

# R2: proporción de la varianza de cada dominio que explica G
round(lavInspect(fit_2do, "rsquare")[dominios], 3)
# G explica más de la mitad de economía, vida social, bienestar personal y
# trabajo, pero solo el 16% de pareja y el 20% de familia: son dominios
# relacionales que dependen menos de la satisfacción general.

# -----------------------------------------------------------------------
# Paso 4. Comparación con el AFC de primer orden
# -----------------------------------------------------------------------
# Con SEIS factores de primer orden el segundo orden SÍ se puede contrastar
# (en el Tren, con tres, quedaba justamente identificado): 6 cargas de G
# sustituyen a 15 correlaciones, así que el modelo tiene 9 gl más.
fit_1er <- cfa(modelo_1er, data = guerrero, estimator = "MLR", missing = "fiml")

medidas <- c("chisq.scaled", "df", "cfi.robust", "tli.robust", "rmsea.robust",
             "srmr", "aic", "bic")
comparacion <- rbind(primer_orden = fitMeasures(fit_1er, medidas),
                     segundo_orden = fitMeasures(fit_2do, medidas))
round(comparacion, 3)

# Diferencia de chi-cuadrada escalada (Satorra-Bentler 2001), por usar MLR.
# lavaan avisa que la columna Chisq trae la estadística estándar: el
# resultado correcto es "Chisq diff".
lavTestLRT(fit_1er, fit_2do)
# Chen (2007): se acepta el modelo más restringido si el CFI no baja más de
# .010 y el RMSEA no sube más de .015.
round(c(delta_cfi = comparacion[2, "cfi.robust"] - comparacion[1, "cfi.robust"],
        delta_rmsea = comparacion[2, "rmsea.robust"] - comparacion[1, "rmsea.robust"],
        delta_srmr = comparacion[2, "srmr"] - comparacion[1, "srmr"]), 3)
# La chi-cuadrada rechaza G (p < .001), pero el CFI baja .007 y el RMSEA sube
# .003: por esos criterios G es aceptable. El BIC (que castiga los
# parámetros) prefiere el 2do orden y el AIC el de primer orden.

# -----------------------------------------------------------------------
# Paso 5. ¿De dónde viene la diferencia?
# -----------------------------------------------------------------------
# Correlaciones entre dominios: observadas (primer orden) contra las que
# implica G (producto de sus cargas estandarizadas).
cargas_G <- std$est.std[std$lhs == "G" & std$op == "=~"]
names(cargas_G) <- std$rhs[std$lhs == "G" & std$op == "=~"]
round(lavInspect(fit_1er, "cor.lv")[dominios, dominios], 2)
round(outer(cargas_G, cargas_G), 2)
# La mayor diferencia es pareja-familia: .40 observada contra .18 implicada.

# Índices de modificación de las covarianzas entre disturbios
mi <- modindices(fit_2do, sort. = TRUE, minimum.value = 5)
mi <- mi[mi$op == "~~" & mi$lhs %in% dominios & mi$rhs %in% dominios, ]
head(mi[, c("lhs", "op", "rhs", "mi", "epc")], 5)

# Prueba (exploratoria, no planeada de antemano): el 2do orden con una
# covarianza entre los disturbios de pareja y familia
fit_2do_cov <- cfa(paste(modelo_2do, "pareja ~~ familia", sep = "\n"),
                   data = guerrero, estimator = "MLR", missing = "fiml")
comparacion <- rbind(comparacion,
                     segundo_orden_cov = fitMeasures(fit_2do_cov, medidas))
round(comparacion, 3)
lavTestLRT(fit_2do, fit_2do_cov)
std_cov <- standardizedSolution(fit_2do_cov)
std_cov[std_cov$lhs == "pareja" & std_cov$op == "~~" & std_cov$rhs == "familia",
        c("est.std", "se", "pvalue")]
round(std_cov$est.std[std_cov$lhs == "G" & std_cov$op == "=~"], 3)   # cargas de G casi iguales
# Con la covarianza pareja-familia el ajuste mejora (Delta chi2 = 6.9, 1 gl,
# p < .01; CFI .954, BIC el menor de los tres), y las cargas de G casi no
# cambian. Pero es un parámetro agregado mirando los datos: se reporta como
# hallazgo (pareja y familia comparten algo más que G), no como modelo final.

# -----------------------------------------------------------------------
# Paso 6. Guardar resultados y diagrama
# -----------------------------------------------------------------------
write.csv(std, file.path(dir_salida, "solucion_estandarizada_2do_orden.csv"), row.names = FALSE)
write.csv(round(comparacion, 3), file.path(dir_salida, "comparacion_1er_2do_orden.csv"))

# Las etiquetas de las cargas de los ítems se encimarían: se alternan dos
# alturas a lo largo de cada flecha.
p <- semPaths(fit_2do, whatLabels = "std", layout = "tree", residuals = FALSE,
              intercepts = FALSE, nCharNodes = 0, sizeMan = 4, sizeLat = 7,
              sizeLat2 = 9, edge.label.cex = .8, DoNotPlot = TRUE)
a_item <- p$graphAttributes$Nodes$names[p$Edgelist$to] %in% lavNames(fit_2do, "ov")
orden <- ave(seq_along(a_item), p$Edgelist$from, FUN = seq_along)
posicion <- rep(.5, length(a_item))
posicion[a_item] <- c(.4, .75)[orden[a_item] %% 2 + 1]
p$graphAttributes$Edges$edge.label.position <- posicion
png(file.path(dir_salida, "diagrama_2do_orden.png"), width = 2400, height = 1100)
plot(p)
dev.off()
plot(p)
