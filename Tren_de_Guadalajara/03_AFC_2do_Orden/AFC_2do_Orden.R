# =============================================================================
# Libro SEM · Tren de Guadalajara
# 03 - AFC de segundo orden
# =============================================================================
# Referencia: CFA_2doOrden.inp (F1 F2 F3 de primer orden y G BY F1 F2 F3).
# Aquí G = Satisfacción con el servicio, medida por Acceso, Tarjeta y Confort.
#   source("Tren_de_Guadalajara/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(semPlot)

dir_salida <- "Tren_de_Guadalajara/03_AFC_2do_Orden/output"

# -----------------------------------------------------------------------
# Paso 1. Mismos datos que en el AFC (170 registros completos)
# -----------------------------------------------------------------------
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
tren <- tren[complete.cases(tren), ]
tren_reducido <- tren[, -c(1, 9, 13)]   # sin id, p72 ni p8

# -----------------------------------------------------------------------
# Paso 2. Especificar el modelo de segundo orden
# -----------------------------------------------------------------------
# Los factores de primer orden se miden con los ítems (igual que en el AFC)
# y el factor de segundo orden G se mide con los tres factores:
# equivale a "G BY F1 F2 F3;" de Mplus. Ya no se estiman las correlaciones
# entre factores: G explica lo que tienen en común.
modelo_2do <- 'Acceso  =~ p4 + p5 + p61 + p62
               Tarjeta =~ p63 + p64
               Confort =~ p71 + p73 + p74 + p75
               G       =~ Acceso + Tarjeta + Confort'

fit_2do <- sem(modelo_2do, data = tren_reducido, estimator = "ML")
summary(fit_2do, fit.measures = TRUE, standardized = TRUE)   # como OUTPUT: STDYX

# -----------------------------------------------------------------------
# Paso 3. Revisar la solución
# -----------------------------------------------------------------------
std <- standardizedSolution(fit_2do)
std[std$lhs == "G" & std$op == "=~", ]       # cargas de segundo orden
# Varianzas residuales de los factores de primer orden (disturbios):
# deben ser positivas; una negativa sería un caso Heywood.
std[std$op == "~~" & std$lhs %in% c("Acceso", "Tarjeta", "Confort") & std$lhs == std$rhs, ]
write.csv(std, file.path(dir_salida, "solucion_estandarizada_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Comparación con el AFC de primer orden
# -----------------------------------------------------------------------
modelo_1er <- 'Acceso  =~ p4 + p5 + p61 + p62
               Tarjeta =~ p63 + p64
               Confort =~ p71 + p73 + p74 + p75'
fit_1er <- sem(modelo_1er, data = tren_reducido, estimator = "ML")

medidas <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "aic", "bic")
round(rbind(primer_orden = fitMeasures(fit_1er, medidas),
            segundo_orden = fitMeasures(fit_2do, medidas)), 3)
# Con TRES factores de primer orden el segundo orden está justamente
# identificado: 3 cargas de G sustituyen a 3 correlaciones entre factores.
# El ajuste es idéntico al del AFC y no se puede probar con los datos; la
# decisión de usar G es teórica (existe una satisfacción general detrás de
# las tres dimensiones). Se identifica porque lavaan fija en 1 la primera
# carga de G (como Mplus).

png(file.path(dir_salida, "diagrama_2do_orden.png"), width = 1000, height = 700)
semPaths(fit_2do, whatLabels = "std", edge.label.cex = 1)
dev.off()
semPaths(fit_2do, whatLabels = "std", edge.label.cex = 1)
