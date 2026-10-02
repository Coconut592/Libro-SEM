# =============================================================================
# Libro SEM · PREP
# 04 - Confiabilidad y validez
# =============================================================================
# Referencia: Laboratorio 2 (alfa, KR-20, confiabilidad compuesta de Dillon-Goldstein).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/04_Confiabilidad_y_Validez/output"

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
# Paso 2. AFC de cada bloque (los de 02_AFC)
# -----------------------------------------------------------------------
fits <- list()
for (nm in names(modelos))
  fits[[nm]] <- cfa(modelos[[nm]], data = datos[[nm]], estimator = "MLR", missing = "fiml")

# -----------------------------------------------------------------------
# Paso 3. Alfa de Cronbach
# -----------------------------------------------------------------------
# alpha() acepta la base, la matriz de correlaciones o la de covarianzas (Lab 2).
alfa_datos <- function(items) suppressMessages(psych::alpha(prep[, items], check.keys = FALSE, warnings = FALSE))
alfa_datos(c("b11", "b12", "b13"))$total$raw_alpha        # EVEP

# Alfa con la covarianza que implica el modelo (como en el Lab 2). Ojo: el Lab 2
# toma mal los renglones (5:6 y 7:11); aquí cada factor usa sus propios ítems.
alfa_modelo <- function(fit, items) {
  S <- fitted(fit)$cov
  psych::alpha(S[items, items], warnings = FALSE)$total$raw_alpha
}

# -----------------------------------------------------------------------
# Paso 4. Confiabilidad compuesta, AVE y validez discriminante
# -----------------------------------------------------------------------
# Confiabilidad compuesta (Dillon-Goldstein): CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)], λ estandarizadas.
# AVE = promedio de λ². Fornell-Larcker: la AVE de un factor debe superar su r² más
# alto con otro factor (validez discriminante). HTMT: < .85.
confiabilidad <- function(fit, nombre) {
  s <- standardizedSolution(fit)
  L <- s[s$op == "=~", ]
  res <- do.call(rbind, lapply(split(L, factor(L$lhs, levels = unique(L$lhs))), function(x)
    data.frame(bloque = nombre, factor = x$lhs[1], k = nrow(x),
               alfa = alfa_datos(x$rhs)$total$raw_alpha,
               alfa_modelo = alfa_modelo(fit, x$rhs),
               CR = sum(x$est.std)^2 / (sum(x$est.std)^2 + sum(1 - x$est.std^2)),
               AVE = mean(x$est.std^2))))
  phi <- lavInspect(fit, "cor.lv")
  res$r2_max <- sapply(res$factor, function(f) max(phi[f, rownames(phi) != f]^2))
  res$discriminante <- res$AVE > res$r2_max
  res
}
conf <- do.call(rbind, lapply(names(fits), function(nm) confiabilidad(fits[[nm]], nm)))
rownames(conf) <- NULL
conf[, c("alfa", "alfa_modelo", "CR", "AVE", "r2_max")] <- round(conf[, c("alfa", "alfa_modelo", "CR", "AVE", "r2_max")], 3)
conf
write.csv(conf, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)

# HTMT (Henseler et al., 2015) con las correlaciones por pares entre ítems
htmt <- function(items_por_factor, d) {
  R <- abs(cor(d[, unlist(items_por_factor)], use = "pairwise"))
  fs <- names(items_por_factor)
  H <- matrix(NA, length(fs), length(fs), dimnames = list(fs, fs))
  for (a in fs) for (b in fs) if (a != b) {
    hetero <- mean(R[items_por_factor[[a]], items_por_factor[[b]]])
    mono <- function(it) { r <- R[it, it]; mean(r[lower.tri(r)]) }
    H[a, b] <- hetero / sqrt(mono(items_por_factor[[a]]) * mono(items_por_factor[[b]]))
  }
  round(H, 2)
}
items_hogares <- list(IP = items_hog[1:6], SG = items_hog[7:9], CS = items_hog[10:18],
                      INF = items_hog[19:23], SR = items_hog[24:25])
htmt(items_hogares, prep)        # INF-SR = .77: la más alta, aún bajo .85

# -----------------------------------------------------------------------
# Paso 5. Lo que NO se calcula aquí
# -----------------------------------------------------------------------
# KR-20: es para ítems dicotómicos (0/1); estos ítems van de 1 a 10.
# Validez de contenido y de criterio: no vienen en los archivos de referencia y la
# base no trae una variable criterio externa; ver el README.
