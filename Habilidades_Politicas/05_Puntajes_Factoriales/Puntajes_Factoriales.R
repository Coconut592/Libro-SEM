# =============================================================================
# Libro SEM · Habilidades Políticas
# 05 - Puntajes factoriales
# =============================================================================
# Sin referencia directa: el capítulo valida el instrumento y no calcula
# puntajes. Se sigue el esquema de los otros proyectos (puntajes centrados,
# determinación, pesos de Bartlett, escala original y media ponderada), con
# una novedad: el modelo de segundo orden permite un puntaje de la Habilidad
# Política (HP) además de los de sus cuatro dimensiones.
#   source("Habilidades_Politicas/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Habilidades_Politicas/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 356 estudiantes
# -----------------------------------------------------------------------
# La base no trae identificador: se usa el número de renglón como id.
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
items <- c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9",
           "AS10", "AS11", "AS13", "AS14", "II16", "II17", "II18")
hp$id <- seq_len(nrow(hp))
hp$sexo <- factor(hp$Genero, levels = 1:2, labels = c("Hombre", "Mujer"))
dimensiones <- c("HR", "SA", "AS", "II")

# -----------------------------------------------------------------------
# Paso 2. Puntajes centrados (modelo de segundo orden)
# -----------------------------------------------------------------------
modelo_2do <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18
  HP =~ HR + SA + AS + II'
fit <- cfa(modelo_2do, data = hp, estimator = "ML")

# El método de regresión es el que usa Mplus (FSCORES) para indicadores
# continuos. Los puntajes tienen media 0: están centrados. Con segundo orden
# lavPredict devuelve las cuatro dimensiones y HP.
fs <- lavPredict(fit, method = "regression")
colnames(fs) <- paste0("fs_", colnames(fs))
head(data.frame(id = hp$id, round(fs, 3)))
round(colMeans(fs), 3)       # 0

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje estimado y el factor verdadero:
#   rho = sqrt( diag(C' Sigma^-1 C) / diag(Phi) )
# con C = covarianza entre los ítems y cada factor y Sigma = covarianza
# implicada por el modelo. Para HP, C pasa por las dimensiones:
# cov(ítems, HP) = Lambda %*% cov(dimensiones, HP).
est <- parameterEstimates(fit)
Lam <- matrix(0, length(items), length(dimensiones), dimnames = list(items, dimensiones))
cargas <- est[est$op == "=~" & est$rhs %in% items, ]
for (k in seq_len(nrow(cargas))) Lam[cargas$rhs[k], cargas$lhs[k]] <- cargas$est[k]
Phi   <- lavInspect(fit, "cov.lv")[c(dimensiones, "HP"), c(dimensiones, "HP")]
Sigma <- lavInspect(fit, "implied")$cov[items, items]
C <- Lam %*% Phi[dimensiones, ]
determinacion <- sqrt(diag(t(C) %*% solve(Sigma) %*% C) / diag(Phi))
round(determinacion, 3)
# .92 a .93: HR .93, SA .92, AS .92, II .93 y HP .93. Valores >= .90 indican
# puntajes confiables para usarse en otros análisis.

# -----------------------------------------------------------------------
# Paso 4. Puntajes de Bartlett y pesos factoriales
# -----------------------------------------------------------------------
# Con el modelo de primer orden (cuatro dimensiones). fsm = TRUE agrega la
# matriz de pesos: cuánto aporta cada ítem al puntaje.
modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
fit_1er <- cfa(modelo_1er, data = hp, estimator = "ML")
bartlett <- lavPredict(fit_1er, method = "Bartlett", fsm = TRUE)
pesos <- attr(bartlett, "fsm")[[1]]    # lista con una matriz por grupo (aquí un solo grupo)
round(t(pesos), 3)
# Bartlett es insesgado pero ordena casi igual que la regresión (HR .98, SA .94,
# AS .94 e II .98):
round(diag(cor(fs[, paste0("fs_", dimensiones)], bartlett)), 3)

# -----------------------------------------------------------------------
# Paso 5. Puntajes en escala original (como Puntaje_*_originales.dat)
# -----------------------------------------------------------------------
# Se fijan en 1 las cargas de un ítem marcador por dimensión (HR3, SA8, AS11 e
# II17, los marcadores del Anexo 2 del capítulo) y los interceptos de los
# ítems en 0; así cada dimensión queda en la escala 1-7 del ítem marcador.
# En lavaan hay que liberar las medias de los factores ("HR ~ 1").
modelo_original <- '
  HR =~ HR1 + HR2 + 1*HR3 + HR4 + HR6
  SA =~ SA7 + 1*SA8 + SA9
  AS =~ AS10 + 1*AS11 + AS13 + AS14
  II =~ II16 + 1*II17 + II18
  HR1 ~ 0*1; HR2 ~ 0*1; HR3 ~ 0*1; HR4 ~ 0*1; HR6 ~ 0*1
  SA7 ~ 0*1; SA8 ~ 0*1; SA9 ~ 0*1
  AS10 ~ 0*1; AS11 ~ 0*1; AS13 ~ 0*1; AS14 ~ 0*1
  II16 ~ 0*1; II17 ~ 0*1; II18 ~ 0*1
  HR ~ 1; SA ~ 1; AS ~ 1; II ~ 1'
fit_original <- cfa(modelo_original, data = hp, estimator = "ML")
pe <- parameterEstimates(fit_original)
pe[pe$op == "~1" & pe$lhs %in% dimensiones, c("lhs", "est")]   # medias de los factores
round(colMeans(hp[, c("HR3", "SA8", "AS11", "II17")]), 3)      # medias de los marcadores
# Las medias de los factores (5.17, 5.81, 5.17, 5.33) quedan cerca de las de
# sus marcadores, pero no son iguales: con todos los interceptos en 0 el
# modelo no reproduce exactamente las medias de los demás ítems.
fs2 <- lavPredict(fit_original, method = "regression")
colnames(fs2) <- paste0("fs2_", colnames(fs2))
round(colMeans(fs2), 3)

# -----------------------------------------------------------------------
# Paso 6. Puntajes sumando la media ponderada (cálculo manual)
# -----------------------------------------------------------------------
# Media ponderada = sum(carga_std * media del ítem) / sum(carga_std);
# fs3 = puntaje centrado + media ponderada. Para HP, la media ponderada es
# la de las medias de las dimensiones con sus cargas de segundo orden.
std <- standardizedSolution(fit)
cargas_std <- std[std$op == "=~" & std$rhs %in% items, c("lhs", "rhs", "est.std")]
cargas_std$media <- colMeans(hp[, items])[cargas_std$rhs]
media_pond <- sapply(dimensiones, function(f) {
  d <- cargas_std[cargas_std$lhs == f, ]
  sum(d$est.std * d$media) / sum(d$est.std)
})
gamma <- setNames(std$est.std[std$lhs == "HP" & std$op == "=~"],
                  std$rhs[std$lhs == "HP" & std$op == "=~"])
media_pond["HP"] <- sum(gamma[dimensiones] * media_pond[dimensiones]) / sum(gamma[dimensiones])
round(media_pond, 3)
fs3 <- sweep(fs, 2, media_pond[c(dimensiones, "HP")], "+")
colnames(fs3) <- paste0("fs3_", c(dimensiones, "HP"))

# -----------------------------------------------------------------------
# Paso 7. Comparar con el promedio simple de los ítems
# -----------------------------------------------------------------------
# ¿Cuánto se pierde por sumar sin ponderar? Para cada dimensión y para el total
promedio <- data.frame(
  HR = rowMeans(hp[, c("HR1", "HR2", "HR3", "HR4", "HR6")]),
  SA = rowMeans(hp[, c("SA7", "SA8", "SA9")]),
  AS = rowMeans(hp[, c("AS10", "AS11", "AS13", "AS14")]),
  II = rowMeans(hp[, c("II16", "II17", "II18")]),
  HP = rowMeans(hp[, items]))
round(diag(cor(fs, promedio)), 3)
# El puntaje factorial y el promedio simple correlacionan .94 a .99 (HR .98,
# SA .94, AS .94, II .98 y HP .99): casi el mismo orden de personas. Con tres
# o cuatro ítems por dimensión, las diferencias de ponderación pesan un poco
# más (SA y AS).

# -----------------------------------------------------------------------
# Paso 8. Descriptivos, comparación por género y archivo de puntajes
# -----------------------------------------------------------------------
puntajes <- data.frame(id = hp$id, Genero = hp$Genero, fs, fs2, fs3)
descriptivos <- data.frame(N = colSums(!is.na(puntajes[, -(1:2)])),
                           media = colMeans(puntajes[, -(1:2)]),
                           de = apply(puntajes[, -(1:2)], 2, sd),
                           min = apply(puntajes[, -(1:2)], 2, min),
                           max = apply(puntajes[, -(1:2)], 2, max))
round(descriptivos, 3)
round(cor(puntajes[, c(paste0("fs_", c(dimensiones, "HP")))]), 3)

# Hombres contra mujeres con los puntajes en escala original (fs3, 1-7)
# t de Welch y d de Cohen. (Esta comparación solo es legítima si el
# instrumento es invariante por género: ver 06_Invarianza_Factorial.)
comparar_sexo <- function(v) {
  x <- puntajes[[v]][hp$sexo == "Hombre"]; y <- puntajes[[v]][hp$sexo == "Mujer"]
  t <- t.test(x, y)
  sp <- sqrt(((length(x) - 1) * var(x) + (length(y) - 1) * var(y)) / (length(x) + length(y) - 2))
  c(media_hombres = mean(x), media_mujeres = mean(y), dif = mean(x) - mean(y),
    t = unname(t$statistic), p = t$p.value, d = (mean(x) - mean(y)) / sp)
}
por_sexo <- t(sapply(paste0("fs3_", c(dimensiones, "HP")), comparar_sexo))
round(por_sexo, 3)
# Las mujeres puntúan un poco más alto en las cuatro dimensiones y en HP (de
# .06 a .19 puntos de la escala de 1 a 7), con efectos pequeños (|d| de .08 a
# .21). Solo SA roza la significancia (p = .050, d = -.21) y no sobrevive a
# una corrección por las cinco comparaciones.

write.csv(puntajes, file.path(dir_salida, "puntajes_habilidades_politicas.csv"), row.names = FALSE)
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_puntajes.csv"))
write.csv(round(por_sexo, 3), file.path(dir_salida, "comparacion_por_genero.csv"))
write.csv(round(t(pesos), 3), file.path(dir_salida, "pesos_bartlett.csv"))

png(file.path(dir_salida, "boxplot_puntajes_por_genero.png"), width = 900, height = 520)
par(mfrow = c(1, 5), mar = c(4, 3, 3, 1))
for (v in c(dimensiones, "HP"))
  boxplot(puntajes[[paste0("fs3_", v)]] ~ hp$sexo, col = c("lightblue", "pink"),
          main = v, xlab = "", ylab = "", ylim = c(1, 7))
dev.off()
