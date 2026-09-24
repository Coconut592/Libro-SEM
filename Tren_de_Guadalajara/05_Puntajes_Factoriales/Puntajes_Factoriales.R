# =============================================================================
# Libro SEM · Tren de Guadalajara
# 05 - Puntajes factoriales
# =============================================================================
# Referencias: CFA_Tren.inp / tren.inp (FSCORES, FSDETERMINACY, puntajes
# centrados y en escala original), AFE_CFA.R (lavPredict con Bartlett y
# pesos) y SEM02_Ejemplo_AFE-AFC.pdf (láminas 14-21).
#
# Como en Mplus, el modelo se estima con los 306 usuarios usando MLR y
# FIML (missing = "fiml"); así cada usuario recibe su puntaje aunque le
# falte algún ítem. FIML se explica en la carpeta 06_FIML.
#   source("Tren_de_Guadalajara/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Tren_de_Guadalajara/05_Puntajes_Factoriales/output"

# -----------------------------------------------------------------------
# Paso 1. Datos: los 306 usuarios
# -----------------------------------------------------------------------
tren <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
items <- c("p4", "p5", "p61", "p62", "p63", "p64", "p71", "p73", "p74", "p75")

# -----------------------------------------------------------------------
# Paso 2. Puntajes centrados (Puntaje_tren_centrados.dat)
# -----------------------------------------------------------------------
# Mismo modelo que en Mplus: p5, p63 y p75 son los marcadores (carga = 1);
# NA* libera la carga del primer ítem, igual que "p4*" en Mplus.
modelo <- 'acceso  =~ NA*p4 + 1*p5 + p61 + p62
           tarjeta =~ 1*p63 + p64
           confort =~ NA*p71 + p73 + p74 + 1*p75'
fit <- sem(modelo, data = tren, estimator = "MLR", missing = "fiml")
summary(fit, fit.measures = TRUE, standardized = TRUE)

# lavPredict con el método de regresión es el que usa Mplus (FSCORES)
# para indicadores continuos. Los puntajes tienen media 0: están centrados.
fs <- lavPredict(fit, method = "regression")
colnames(fs) <- paste0("fs_", colnames(fs))
head(data.frame(id = tren$id, round(fs, 3)))

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje estimado y el factor verdadero:
#   rho = sqrt( diag(Phi L' Sigma^-1 L Phi) / diag(Phi) )
# Valores >= 0.90 indican puntajes confiables para usarse en otros análisis.
est   <- lavInspect(fit, "est")
Lam   <- est$lambda
Phi   <- est$psi
Sigma <- lavInspect(fit, "implied")$cov
determinacion <- sqrt(diag(Phi %*% t(Lam) %*% solve(Sigma) %*% Lam %*% Phi) / diag(Phi))
round(determinacion, 3)

# -----------------------------------------------------------------------
# Paso 4. Puntajes de Bartlett y pesos factoriales (script de referencia)
# -----------------------------------------------------------------------
# fsm = TRUE agrega la matriz de pesos: cuánto aporta cada ítem al puntaje.
scores <- lavPredict(fit, method = "Bartlett", fsm = TRUE)
pesos <- attr(scores, "fsm")
pesos
# Bartlett usa solo los ítems observados del factor: quien no respondió ni
# p63 ni p64 queda con NA en tarjeta (el de regresión sí lo estima apoyado
# en los otros factores). Por eso la correlación se calcula por pares.
colSums(is.na(scores))
cor(fs, scores, use = "pairwise.complete.obs")   # regresión y Bartlett ordenan casi igual

# -----------------------------------------------------------------------
# Paso 5. Puntajes en escala original (Puntaje_tren_originales.dat)
# -----------------------------------------------------------------------
# Como en el .inp: [p4@0 p5@0 ...] fija los interceptos en 0 y el marcador
# tiene carga 1, así el factor queda en la escala 1-10 del ítem marcador.
# En lavaan hay que liberar explícitamente las medias de los factores
# ("acceso ~ 1"); si se dejan en 0 el modelo implicaría medias 0 para todos
# los ítems. Las medias estimadas (7.75, 7.35, 8.39) coinciden con las del PDF.
modelo_original <- '
  acceso  =~ NA*p4 + 1*p5 + p61 + p62
  tarjeta =~ 1*p63 + p64
  confort =~ NA*p71 + p73 + p74 + 1*p75
  p4 ~ 0*1;  p5 ~ 0*1;  p61 ~ 0*1; p62 ~ 0*1
  p63 ~ 0*1; p64 ~ 0*1
  p71 ~ 0*1; p73 ~ 0*1; p74 ~ 0*1; p75 ~ 0*1
  acceso ~ 1; tarjeta ~ 1; confort ~ 1'
fit_original <- sem(modelo_original, data = tren, estimator = "MLR", missing = "fiml")
parameterEstimates(fit_original)[parameterEstimates(fit_original)$op == "~1" &
                                   parameterEstimates(fit_original)$lhs %in% c("acceso", "tarjeta", "confort"), ]

fs2 <- lavPredict(fit_original, method = "regression")
colnames(fs2) <- paste0("fs2_", colnames(fs2))

# -----------------------------------------------------------------------
# Paso 6. Puntajes sumando la media ponderada (cálculo manual del PDF)
# -----------------------------------------------------------------------
# Media ponderada de cada factor = sum(carga_std * media del ítem) / sum(carga_std)
# y fs3 = puntaje centrado + media ponderada.
std    <- standardizedSolution(fit)
cargas <- std[std$op == "=~", c("lhs", "rhs", "est.std")]
medias <- colMeans(tren[, items], na.rm = TRUE)
cargas$media <- medias[cargas$rhs]
cargas$prod  <- cargas$est.std * cargas$media
cargas

media_ponderada <- sapply(c("acceso", "tarjeta", "confort"), function(f)
  sum(cargas$prod[cargas$lhs == f]) / sum(cargas$est.std[cargas$lhs == f]))
round(media_ponderada, 3)

fs3 <- sweep(fs, 2, media_ponderada, "+")
colnames(fs3) <- paste0("fs3_", c("acceso", "tarjeta", "confort"))

# -----------------------------------------------------------------------
# Paso 7. Descriptivos, correlaciones y archivo de puntajes
# -----------------------------------------------------------------------
puntajes <- data.frame(id = tren$id, fs, fs2, fs3)
descriptivos <- data.frame(N = colSums(!is.na(puntajes[, -1])),
                           media = colMeans(puntajes[, -1]),
                           de = apply(puntajes[, -1], 2, sd),
                           min = apply(puntajes[, -1], 2, min),
                           max = apply(puntajes[, -1], 2, max))
descriptivos$cv <- ifelse(abs(descriptivos$media) > 0.001,
                          100 * descriptivos$de / descriptivos$media, NA)
round(descriptivos, 3)
round(cor(puntajes[, -1]), 3)

write.csv(puntajes, file.path(dir_salida, "puntajes_tren.csv"), row.names = FALSE)
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_puntajes.csv"))

# Distribución de los puntajes en escala original
png(file.path(dir_salida, "boxplot_puntajes_originales.png"), width = 800, height = 500)
boxplot(fs2, names = c("Acceso", "Tarjeta", "Confort"), col = "lightblue",
        main = "Puntajes factoriales en escala original (1-10)")
dev.off()
