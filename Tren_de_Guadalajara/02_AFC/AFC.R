# =============================================================================
# Libro SEM · Tren de Guadalajara
# 02 - Análisis Factorial Confirmatorio (AFC)
# =============================================================================
# Referencias: AFE_CFA.R (análisis confirmatorio), CFA_Tren.inp / tren.inp y
# SEM02_Ejemplo_AFE-AFC.pdf.
#   source("Tren_de_Guadalajara/02_AFC/AFC.R")
# =============================================================================

library(readstata13)
library(psych)
library(sem)
library(lavaan)    # se carga después de sem: sem() pasa a ser la de lavaan
library(semPlot)

dir_salida <- "Tren_de_Guadalajara/02_AFC/output"

# -----------------------------------------------------------------------
# Paso 1. Datos: registros completos sin id, p72 ni p8
# -----------------------------------------------------------------------
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
tren <- tren[complete.cases(tren), ]            # 170 registros completos
tren_reducido <- tren[, -c(1, 9, 13)]           # quita id, p72 y p8 (ver 01_AFE)
names(tren_reducido)

# -----------------------------------------------------------------------
# Paso 2. AFC con el paquete sem (specifyModel)
# -----------------------------------------------------------------------
tren.cov <- round(cov(tren_reducido), 3)
# Sintaxis: Factor -> variable manifiesta, nombre del parámetro, valor inicial.
# Varianzas y covarianzas con "<->". Para tener factores estandarizados se
# fija su varianza en 1.
modelo_tren <- specifyModel(text = "
Acceso->p4,lam1,NA
Acceso->p5,lam2,NA
Acceso->p61,lam3,NA
Acceso->p62,lam4,NA
Tarjeta->p63,lam5,NA
Tarjeta->p64,lam6,NA
Confort->p71,lam7,NA
Confort->p73,lam8,NA
Confort->p74,lam9,NA
Confort->p75,lam10,NA
Acceso <-> Tarjeta,AccTar,NA
Acceso <-> Confort,AccCon,NA
Tarjeta <-> Confort,TarCon,NA
Acceso<->Acceso,NA,1
Tarjeta<->Tarjeta,NA,1
Confort<->Confort,NA,1")

# Se ajusta con la matriz de varianzas y covarianzas (S) y el número de
# observaciones (N)...
mydata.sem <- sem::sem(modelo_tren, S = tren.cov, N = nrow(tren_reducido))
# ...o directamente con los datos
mydata.sem <- sem::sem(modelo_tren, data = tren_reducido, na.action = "na.pass")
stdCoef(mydata.sem)    # cargas estandarizadas
summary(mydata.sem)    # ajuste del modelo

# -----------------------------------------------------------------------
# Paso 3. El mismo AFC con lavaan (sintaxis más intuitiva)
# -----------------------------------------------------------------------
# "=~" se lee "se mide por". Por defecto lavaan fija en 1 la carga del
# primer ítem de cada factor para darle escala.
modelo <- 'Acceso  =~ p4 + p5 + p61 + p62
           Tarjeta =~ p63 + p64
           Confort =~ p71 + p73 + p74 + p75'

fit <- sem(modelo, data = tren_reducido, estimator = "ML")
summary(fit, fit.measures = TRUE)          # fit.measures = TRUE regresa las medidas de ajuste
standardizedSolution(fit)                  # cargas estandarizadas

# -----------------------------------------------------------------------
# Paso 4. Bondad de ajuste
# -----------------------------------------------------------------------
# Criterios usuales (Hu y Bentler, 1999): CFI y TLI >= 0.95 (aceptable
# >= 0.90), RMSEA <= 0.06 (aceptable <= 0.08), SRMR <= 0.08.
ajuste <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli",
                             "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
round(ajuste, 3)

# -----------------------------------------------------------------------
# Paso 5. Normalidad multivariada y estimador MLR (como en el .inp)
# -----------------------------------------------------------------------
# ML supone normalidad multivariada. Los ítems son escalas 1-10 con
# asimetría negativa, así que se revisa con la prueba de Mardia.
mardia(tren_reducido, plot = FALSE)
# Se rechaza la normalidad: por eso el .inp usa ESTIMATOR = MLR, que
# corrige errores estándar y chi-cuadrada (Satorra-Bentler / Yuan-Bentler).
fit_mlr <- sem(modelo, data = tren_reducido, estimator = "MLR")
round(fitMeasures(fit_mlr, c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust",
                             "tli.robust", "rmsea.robust", "srmr")), 3)

# -----------------------------------------------------------------------
# Paso 6. Guardar resultados y diagrama
# -----------------------------------------------------------------------
cargas_std <- standardizedSolution(fit)
# cargas (=~) y correlaciones entre factores (~~ entre variables distintas)
cargas_std <- cargas_std[cargas_std$op == "=~" |
                         (cargas_std$op == "~~" & cargas_std$lhs != cargas_std$rhs), ]
write.csv(cargas_std, file.path(dir_salida, "solucion_estandarizada_AFC.csv"), row.names = FALSE)

# whatLabels = "std" muestra las estimaciones estandarizadas;
# edge.label.cex = tamaño de la letra
png(file.path(dir_salida, "diagrama_AFC.png"), width = 1000, height = 600)
semPaths(fit, whatLabels = "std", edge.label.cex = 1)
dev.off()
semPaths(fit, whatLabels = "std", edge.label.cex = 1)
