# =============================================================================
# Libro SEM · PREP
# 05 - Puntajes factoriales
# =============================================================================
# Referencias: SAVEDATA (SAVE = FS) de los dos .inp y Laboratorios 2 y 5 (predict, Bartlett, medias ponderadas).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/05_Puntajes_Factoriales/output"

# -----------------------------------------------------------------------
# Paso 1. Datos
# -----------------------------------------------------------------------
# convert.factors = FALSE evita que Stata convierta las escalas 1-10 en factores.
prep <- read.dta13("PREP/data/PREP.dta", convert.factors = FALSE)
prep$id <- seq_len(nrow(prep))          # la base no trae id: se usa el número de fila
prep$estado <- prep$ID_MPIO %/% 1000    # clave INEGI: estado (1-32) * 1000 + municipio

items_ep  <- c("b11", "b12", "b13", "b14", "b15", "b16", "b17", "b18", "b21", "b22", "b26")
items_hog <- c(sprintf("c%02d", 1:9), sprintf("d%02d", 1:9), sprintf("e%02d", 1:5), sprintf("f%02d", 1:2))
items_g   <- sprintf("g%02d", 1:12)

# En los bloques c a f el "99 = Ns/Nc" viene como valor: se pasa a faltante.
# (b14-b18 se usan en su versión original: mayor = más seguro, como B18r-B21r del piloto.)
for (v in items_hog) prep[[v]][prep[[v]] %in% 99] <- NA

# Equivalencias piloto -> base (por contenido; ver 00_Diagnostico/README.md)
m_ep <- 'EVEP  =~ b11 + b12 + b13
         SEGEP =~ b14 + b15 + b16 + b17 + b18
         ACTEP =~ b21 + b22 + b26'
m_hog <- 'IP  =~ c01 + c02 + c03 + c04 + c05 + c06
          SG  =~ c07 + c08 + c09
          CS  =~ d01 + d02 + d03 + d04 + d05 + d06 + d07 + d08 + d09
          INF =~ e01 + e02 + e03 + e04 + e05
          SR  =~ f01 + f02'
m_g <- 'PART =~ g01 + g02 + g03 + g04
        RECH =~ g06 + g07 + g08
        INTV =~ g09 + g10 + g11 + g12'
modelos <- list(EP = m_ep, Hogares = m_hog, G = m_g)
items_modelo <- list(EP = items_ep, Hogares = items_hog, G = setdiff(items_g, "g05"))
# lavaan ignora a quien no tiene ningún ítem del modelo; aquí se quitan para saber cuántos quedan
con_info <- function(items) prep[rowSums(!is.na(prep[, items])) > 0, ]
datos <- lapply(items_modelo, con_info)
medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(fit, nombre) {
  m <- round(as.numeric(fitMeasures(fit, medidas)), 3)
  data.frame(modelo = nombre, N = lavInspect(fit, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}

# -----------------------------------------------------------------------
# Paso 2. Puntajes centrados (SAVE = FS de Mplus)
# -----------------------------------------------------------------------
# Se estima cada AFC con MLR y FIML; así cada respondiente con al menos un ítem del
# bloque recibe puntaje. lavPredict(method = "regression") es el método de Mplus y
# da puntajes con media 0 (centrados). Hogares tarda ~1 min.
fits <- list(); fs <- list()
for (nm in names(modelos)) {
  fits[[nm]] <- cfa(modelos[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml")
  fs[[nm]] <- lavPredict(fits[[nm]], method = "regression")
  colnames(fs[[nm]]) <- paste0("fs_", colnames(fs[[nm]]))
}
sapply(fs, nrow)                               # 7,814 / 8,239 / 7,805 respondientes con puntaje

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje estimado y el factor verdadero:
#   rho = sqrt( diag(Phi L' Sigma^-1 L Phi) / diag(Phi) ); >= .90 = confiable.
determinacion <- function(fit) {
  est <- lavInspect(fit, "est")
  Lam <- est$lambda; Phi <- est$psi; Sigma <- lavInspect(fit, "implied")$cov
  sqrt(diag(Phi %*% t(Lam) %*% solve(Sigma) %*% Lam %*% Phi) / diag(Phi))
}
det_tab <- do.call(rbind, lapply(names(fits), function(nm)
  data.frame(bloque = nm, factor = names(determinacion(fits[[nm]])),
             determinacion = round(determinacion(fits[[nm]]), 3), row.names = NULL)))
det_tab
write.csv(det_tab, file.path(dir_salida, "determinacion.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Bartlett y pesos factoriales (Lab 2)
# -----------------------------------------------------------------------
# fsm = TRUE agrega la matriz de pesos: cuánto aporta cada ítem al puntaje. Bartlett
# usa solo los ítems observados del factor: quien no respondió ninguno queda con NA.
bt <- lavPredict(fits$EP, method = "Bartlett", fsm = TRUE)
pesos <- attr(bt, "fsm")
pesos
colSums(is.na(bt))
cor(fs$EP, bt, use = "pairwise.complete.obs")   # regresión y Bartlett ordenan casi igual

# -----------------------------------------------------------------------
# Paso 5. Puntajes en escala original (interceptos en 0, como [x@0] de los .inp)
# -----------------------------------------------------------------------
# Con el marcador en 1 y los interceptos en 0 el factor queda en la escala 1-10 del
# ítem marcador. En lavaan hay que liberar las medias de los factores ("F ~ 1"); si no,
# el modelo implicaría media 0 en todos los ítems. Marcadores parecidos a los .inp.
estructura <- list(
  EP = list(EVEP = c("b11", "b12", "b13"), SEGEP = c("b14", "b15", "b16", "b17", "b18"),
            ACTEP = c("b21", "b22", "b26")),
  Hogares = list(IP = sprintf("c%02d", 1:6), SG = sprintf("c%02d", 7:9), CS = sprintf("d%02d", 1:9),
                 INF = sprintf("e%02d", 1:5), SR = c("f01", "f02")),
  G = list(PART = sprintf("g%02d", 1:4), RECH = sprintf("g%02d", 6:8), INTV = sprintf("g%02d", 9:12)))
marcador <- list(EP = c(EVEP = "b11", SEGEP = "b18", ACTEP = "b22"),
                 Hogares = c(IP = "c01", SG = "c08", CS = "d02", INF = "e05", SR = "f02"),
                 G = c(PART = "g01", RECH = "g07", INTV = "g10"))
modelo_original <- function(est, marc) {
  lin <- sapply(names(est), function(f) {
    it <- est[[f]]
    term <- ifelse(it == marc[[f]], paste0("1*", it), ifelse(it == it[1], paste0("NA*", it), it))
    paste0(f, " =~ ", paste(term, collapse = " + "))
  })
  inter <- paste0(unlist(est), " ~ 0*1")
  paste(c(lin, inter, paste0(names(est), " ~ 1")), collapse = "\n")
}
fs2 <- list(); medias_factor <- list()
for (nm in names(modelos)) {
  f <- cfa(modelo_original(estructura[[nm]], marcador[[nm]]), data = datos[[nm]],
           estimator = "MLR", missing = "fiml")
  cat(nm, "convergió:", lavInspect(f, "converged"), "\n")
  pe <- parameterEstimates(f)
  medias_factor[[nm]] <- pe[pe$op == "~1" & pe$lhs %in% names(estructura[[nm]]), c("lhs", "est")]
  fs2[[nm]] <- lavPredict(f, method = "regression")
  colnames(fs2[[nm]]) <- paste0("fso_", colnames(fs2[[nm]]))
}
medias_factor

# -----------------------------------------------------------------------
# Paso 6. Media ponderada (cálculo del Lab 5)
# -----------------------------------------------------------------------
# media ponderada del factor = Σ(carga * media del ítem) / Σ carga, y
# fsm = puntaje centrado + media ponderada.
fs3 <- list()
for (nm in names(modelos)) {
  s <- standardizedSolution(fits[[nm]]); L <- s[s$op == "=~", c("lhs", "rhs", "est.std")]
  L$media <- colMeans(prep[, L$rhs], na.rm = TRUE)[L$rhs]
  mp <- sapply(unique(L$lhs), function(f) with(L[L$lhs == f, ], sum(est.std * media) / sum(est.std)))
  fs3[[nm]] <- sweep(fs[[nm]], 2, mp, "+")
  colnames(fs3[[nm]]) <- paste0("fsm_", names(mp))
  cat(nm, "medias ponderadas:", round(mp, 2), "\n")
}

# -----------------------------------------------------------------------
# Paso 7. Descriptivos, archivo de puntajes y comparación entre espacios
# -----------------------------------------------------------------------
# Un renglón por respondiente (id = número de fila de PREP.dta).
una <- function(nm) data.frame(id = datos[[nm]]$id, fs[[nm]], fs2[[nm]], fs3[[nm]])
puntajes <- Reduce(function(a, b) merge(a, b, by = "id", all = TRUE), lapply(names(modelos), una))
puntajes <- merge(prep[, c("id", "espacio", "ID_MPIO", "estado")], puntajes, by = "id")
write.csv(round(puntajes, 3), file.path(dir_salida, "puntajes_PREP.csv"), row.names = FALSE)

cols <- grep("^fs", names(puntajes), value = TRUE)
descriptivos <- data.frame(N = colSums(!is.na(puntajes[, cols])),
                           media = colMeans(puntajes[, cols], na.rm = TRUE),
                           de = apply(puntajes[, cols], 2, sd, na.rm = TRUE),
                           min = apply(puntajes[, cols], 2, min, na.rm = TRUE),
                           max = apply(puntajes[, cols], 2, max, na.rm = TRUE))
round(descriptivos, 2)
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_puntajes.csv"))

# Los tres tipos ordenan casi igual a los respondientes
round(cor(puntajes[, c("fs_EVEP", "fso_EVEP", "fsm_EVEP")], use = "pairwise"), 3)

# Los laboratorios comparan los puntajes entre dos parques (parque == 1 vs 2). La base
# final no trae `parque`; su equivalente es el espacio. Se resumen por espacio.
por_espacio <- aggregate(puntajes[, c("fso_EVEP", "fso_SEGEP", "fso_ACTEP")],
                         by = list(espacio = puntajes$espacio), FUN = mean, na.rm = TRUE)
round(sapply(por_espacio[, -1], summary), 2)
write.csv(round(por_espacio, 3), file.path(dir_salida, "puntajes_por_espacio.csv"), row.names = FALSE)

# Ejemplo de comparación entre dos estados (a falta de `parque`): t de Welch
t.test(fso_EVEP ~ estado, data = puntajes[puntajes$estado %in% c(15, 30), ])

png(file.path(dir_salida, "boxplot_puntajes_originales.png"), width = 900, height = 500)
boxplot(puntajes[, c("fso_EVEP", "fso_SEGEP", "fso_ACTEP")], names = c("Calificación", "Seguridad", "Actividades"),
        col = "lightblue", main = "Espacio público: puntajes en escala original (1-10)")
dev.off()
