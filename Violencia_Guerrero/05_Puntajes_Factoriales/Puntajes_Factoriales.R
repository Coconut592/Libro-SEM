# =============================================================================
# Libro SEM · Violencia Guerrero
# 05 - Puntajes factoriales
# =============================================================================
# Sin referencia propia. Se calculan los mismos tres tipos de puntaje del Tren
# (centrados, en escala original y por media ponderada) más su determinación
# y los pesos de Bartlett. Como en Mplus, el modelo se estima con las 294
# personas usando MLR y FIML (missing = "fiml"): así cada persona recibe su
# puntaje aunque le falte algún ítem. FIML se explica en 07_FIML.
#   source("Violencia_Guerrero/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Guerrero/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, factores y marcadores
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
guerrero$fila <- seq_len(nrow(guerrero))   # el folio no es único: 3 folios se repiten

factores <- list(
  pareja      = c("a1", "a2", "a3", "a4"),
  familia     = c("a5", "a6", "a7", "a8"),
  economia    = c("a9", "a10", "a11", "a12"),
  social      = c("a13", "a14", "a15", "a16"),
  personal    = c("a17", "a18", "a19", "a20"),
  trabajo     = c("a21", "a22", "a23", "a24"),
  cohesion    = c("b1", "b2", "b3", "b4", "b9"),
  confianza   = c("b10", "b11", "b12", "b13"),
  inseguridad = c("c4", "c5", "c6", "c7", "c8"),
  riesgo      = c("c11", "c12", "c13"),
  libertad    = c("c19", "c20"),
  desempeno   = c("f2", "f3", "f4"))
items <- unlist(factores)

# El marcador es el ítem que da escala al factor (carga = 1): en la escala
# original, el factor queda en los puntos de 1 a 10 del marcador. Se elige el
# ítem con la carga estandarizada más alta de cada factor (ver 02_AFC).
marcadores <- c(pareja = "a2", familia = "a5", economia = "a11", social = "a16",
                personal = "a18", trabajo = "a22", cohesion = "b2",
                confianza = "b12", inseguridad = "c7", riesgo = "c12",
                libertad = "c19", desempeno = "f4")

# Sintaxis de lavaan: "NA*" libera la carga del primer ítem (como "p4*" en
# Mplus) y "1*" fija la del marcador.
sintaxis <- function(f) {
  otros <- setdiff(factores[[f]], marcadores[[f]])
  terminos <- c(paste0("NA*", otros[1]), otros[-1], paste0("1*", marcadores[[f]]))
  paste0(f, " =~ ", paste(terminos, collapse = " + "))
}
modelo <- paste(sapply(names(factores), sintaxis), collapse = "\n")
cat(modelo, "\n")

# Quien no contestó NINGÚN ítem de un factor no tiene información para ese
# factor: su puntaje se deja en NA (la regresión se lo asignaría apoyándose
# solo en los otros factores).
sin_datos <- sapply(factores, function(it) rowSums(!is.na(guerrero[, it])) == 0)
colSums(sin_datos)       # 71 personas sin pareja y 10 sin familia; en los demás, de 0 a 5
poner_na <- function(fs) {
  for (f in colnames(sin_datos)) fs[sin_datos[, f], f] <- NA
  fs
}

# -----------------------------------------------------------------------
# Paso 2. Puntajes centrados
# -----------------------------------------------------------------------
# Se estima el AFC de 12 factores con los 294 (MLR + FIML, ~1 minuto). Los
# factores tienen media 0 (por defecto, con los interceptos libres).
fit <- cfa(modelo, data = guerrero, estimator = "MLR", missing = "fiml")
lavInspect(fit, "converged")

# lavPredict con el método de regresión es el que usa Mplus (FSCORES) para
# indicadores continuos. Los puntajes tienen media ~0: están centrados, y su
# unidad es un punto del ítem marcador.
fs <- poner_na(lavPredict(fit, method = "regression"))
colnames(fs) <- paste0("fs_", colnames(fs))
head(data.frame(fila = guerrero$fila, round(fs, 3)[, 1:4]))
colSums(is.na(fs))

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje estimado y el factor verdadero:
#   rho = sqrt( diag(Phi L' Sigma^-1 L Phi) / diag(Phi) )
# Valores >= 0.90 indican puntajes confiables para usarse en otros análisis.
# Es la determinación para quien contestó todos los ítems.
est   <- lavInspect(fit, "est")
Lam   <- est$lambda
Phi   <- est$psi
Sigma <- lavInspect(fit, "implied")$cov
determinacion <- sqrt(diag(Phi %*% t(Lam) %*% solve(Sigma) %*% Lam %*% Phi) / diag(Phi))
round(determinacion, 3)
write.csv(data.frame(factor = names(determinacion), determinacion = round(determinacion, 3)),
          file.path(dir_salida, "determinacion_puntajes.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Puntajes de Bartlett y pesos factoriales
# -----------------------------------------------------------------------
# fsm = TRUE agrega la matriz de pesos: cuánto aporta cada ítem al puntaje.
scores <- lavPredict(fit, method = "Bartlett", fsm = TRUE)
pesos <- attr(scores, "fsm")
if (is.list(pesos)) pesos <- pesos[[1]]
round(pesos[c("pareja", "familia"), unlist(factores[c("pareja", "familia")])], 3)
# Bartlett usa solo los ítems observados del factor. A quien no contestó ninguno
# lavaan le deja NA o un puntaje de 0 (la media del factor), y ninguno de los
# dos tiene información: se enmascara igual que el de regresión.
scores <- poner_na(scores)
colSums(is.na(scores))
# La correlación entre ambos métodos se calcula por pares
round(diag(cor(poner_na(lavPredict(fit, method = "regression")), scores,
               use = "pairwise.complete.obs")), 3)      # regresión y Bartlett ordenan casi igual

# -----------------------------------------------------------------------
# Paso 5. Puntajes en escala original
# -----------------------------------------------------------------------
# Como en el .inp del Tren (interceptos en 0 y marcador con carga 1) el factor
# queda en la escala 1-10 del marcador. Aquí se fija en 0 SOLO el intercepto
# del marcador y se liberan las medias de los factores ("factor ~ 1"): los
# demás interceptos quedan libres y el ajuste es el mismo que en el paso 2.
# (Fijar en 0 los interceptos de todos los ítems, como en el Tren, exige que
# la media de cada ítem sea carga x media del factor: es una restricción
# fuerte y no hace falta.)
intercepto_0 <- paste0(marcadores, " ~ 0*1", collapse = "\n")
medias_libres <- paste0(names(factores), " ~ 1", collapse = "\n")
modelo_original <- paste(modelo, intercepto_0, medias_libres, sep = "\n")
fit_original <- cfa(modelo_original, data = guerrero, estimator = "MLR", missing = "fiml")

# Medias estimadas de los factores (FIML) y medias observadas del marcador
pe <- parameterEstimates(fit_original)
medias_factor <- pe[pe$op == "~1" & pe$lhs %in% names(factores), c("lhs", "est", "se")]
medias_factor$media_marcador <- colMeans(guerrero[, marcadores], na.rm = TRUE)[marcadores[medias_factor$lhs]]
medias_factor[, 2:4] <- round(medias_factor[, 2:4], 3)
medias_factor
# La media estimada del factor coincide con la media observada del marcador
# (diferencias de hasta .03): en la escala original, el factor es "un ítem
# marcador sin error de medida".

fs2 <- poner_na(lavPredict(fit_original, method = "regression"))
colnames(fs2) <- paste0("fs2_", colnames(fs2))

# -----------------------------------------------------------------------
# Paso 6. Puntajes sumando la media ponderada (cálculo manual de SEM02)
# -----------------------------------------------------------------------
# Media ponderada de cada factor = sum(carga_std * media del ítem) / sum(carga_std)
# y fs3 = puntaje centrado + media ponderada.
std    <- standardizedSolution(fit)
cargas <- std[std$op == "=~", c("lhs", "rhs", "est.std")]
medias <- colMeans(guerrero[, items], na.rm = TRUE)
cargas$media <- medias[cargas$rhs]
cargas$prod  <- cargas$est.std * cargas$media

media_ponderada <- sapply(names(factores), function(f)
  sum(cargas$prod[cargas$lhs == f]) / sum(cargas$est.std[cargas$lhs == f]))
round(media_ponderada, 3)

fs3 <- sweep(fs, 2, media_ponderada, "+")
colnames(fs3) <- paste0("fs3_", names(factores))

# -----------------------------------------------------------------------
# Paso 7. Puntaje del factor general G (segundo orden, ver 03)
# -----------------------------------------------------------------------
# G = Satisfacción con la vida. Se predice con el modelo de segundo orden de
# los 24 ítems de satisfacción. G está medida por los dominios, así que la
# tienen casi todos (quien no tiene pareja la tiene por los otros cinco). Se
# estandariza a media 0 y D.E. 1.
modelo_2do <- paste(
  '  pareja   =~ a1 + a2 + a3 + a4
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24',
  'G =~ pareja + familia + economia + social + personal + trabajo', sep = "\n")
fit_2do <- cfa(modelo_2do, data = guerrero, estimator = "MLR", missing = "fiml")
fs_G <- as.numeric(scale(lavPredict(fit_2do, method = "regression")[, "G"]))

# -----------------------------------------------------------------------
# Paso 8. Descriptivos, comparación con el promedio simple y archivo
# -----------------------------------------------------------------------
puntajes <- data.frame(fila = guerrero$fila, folio = guerrero$folio,
                       sin_pareja = sin_datos[, "pareja"], fs, fs2, fs3, fs_G)
cols <- setdiff(names(puntajes), c("fila", "folio", "sin_pareja"))
descriptivos <- data.frame(N = colSums(!is.na(puntajes[, cols])),
                           media = colMeans(puntajes[, cols], na.rm = TRUE),
                           de = apply(puntajes[, cols], 2, sd, na.rm = TRUE),
                           min = apply(puntajes[, cols], 2, min, na.rm = TRUE),
                           max = apply(puntajes[, cols], 2, max, na.rm = TRUE))
round(descriptivos[grepl("^fs2_", rownames(descriptivos)), ], 2)    # escala original

# Las tres versiones de un mismo factor son el mismo puntaje desplazado (fs2 = fs +
# media del factor; fs3 = fs + media ponderada): su correlación es 1
round(sapply(names(factores), function(f)
  min(cor(puntajes[, paste0(c("fs_", "fs2_", "fs3_"), f)], use = "pairwise.complete.obs"))), 3)

# ¿Qué agrega el puntaje factorial al promedio simple de los ítems? Se
# correlaciona el puntaje en escala original con el promedio de los ítems del
# factor (con los que la persona sí contestó).
promedio <- sapply(factores, function(it) ifelse(rowSums(!is.na(guerrero[, it])) == 0, NA,
                                                  rowMeans(guerrero[, it], na.rm = TRUE)))
round(sapply(names(factores), function(f)
  cor(puntajes[, paste0("fs2_", f)], promedio[, f], use = "pairwise.complete.obs")), 3)

puntajes[, cols] <- round(puntajes[, cols], 4)
write.csv(puntajes, file.path(dir_salida, "puntajes_guerrero.csv"), row.names = FALSE)
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_puntajes.csv"))

# Distribución de los puntajes en escala original
png(file.path(dir_salida, "boxplot_puntajes_originales.png"), width = 1200, height = 600)
par(mar = c(7, 4, 4, 1))   # margen inferior para los nombres de los factores
boxplot(fs2, names = names(factores), las = 2, col = "lightblue",
        main = "Puntajes factoriales en escala original (marcador, 1-10)")
dev.off()
