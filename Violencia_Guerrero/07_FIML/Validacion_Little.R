# =============================================================================
# Libro SEM · Violencia Guerrero
# 07 - Validación de la prueba MCAR de Little (opcional)
# =============================================================================
# FIML.R implementa la prueba de Little a mano. Este script comprueba que esa
# implementación funciona, de dos formas:
#   1. Con un EM escrito aparte (sin lavaan): debe dar las mismas medias y
#      covarianzas que lavCor(missing = "fiml") en los datos reales.
#   2. Con simulación: bajo MCAR debe rechazar H0 el 5% de las veces (al 5%) y
#      con p-valores uniformes; con datos MAR y MNAR debe rechazar casi siempre.
# Es opcional: no se usa en el resto del proyecto. Tarda unos 2 minutos.
#   source("Violencia_Guerrero/07_FIML/Validacion_Little.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(MASS)       # mvrnorm, para simular

# -----------------------------------------------------------------------
# Funciones
# -----------------------------------------------------------------------
# EM para la normal multivariada con datos faltantes (media y covarianza ML)
em_mvn <- function(x, tol = 1e-8, maxit = 2000) {
  n <- nrow(x); p <- ncol(x); m <- is.na(x)
  mu <- colMeans(x, na.rm = TRUE); S <- diag(apply(x, 2, var, na.rm = TRUE), p)
  grupos <- split(seq_len(n), apply(m, 1, paste, collapse = ""))   # un grupo por patrón
  for (it in seq_len(maxit)) {
    T1 <- numeric(p); T2 <- matrix(0, p, p)
    for (g in grupos) {
      falta <- m[g[1], ]; obs <- !falta; xg <- x[g, , drop = FALSE]
      if (any(falta)) {
        B <- S[falta, obs, drop = FALSE] %*% solve(S[obs, obs])
        xg[, falta] <- sweep(t(B %*% t(sweep(xg[, obs, drop = FALSE], 2, mu[obs]))), 2, mu[falta], "+")
        C <- matrix(0, p, p); C[falta, falta] <- S[falta, falta] - B %*% S[obs, falta, drop = FALSE]
        T2 <- T2 + length(g) * C
      }
      T1 <- T1 + colSums(xg); T2 <- T2 + crossprod(xg)
    }
    mu_nuevo <- T1 / n; S_nuevo <- T2 / n - tcrossprod(mu_nuevo)
    listo <- max(abs(c(mu_nuevo - mu, S_nuevo - S))) < tol
    mu <- mu_nuevo; S <- S_nuevo
    if (listo) break
  }
  list(mu = mu, Sigma = S, iteraciones = it)
}

# Prueba de Little con medias y covarianzas ML dadas (como en FIML.R)
little_mcar <- function(x, mu, Sigma) {
  m <- is.na(x); patron <- apply(m, 1, paste, collapse = ""); d2 <- 0; gl <- 0
  for (pt in unique(patron)) {
    filas <- which(patron == pt); obs <- !m[filas[1], ]
    if (!any(obs)) next
    dif <- colMeans(x[filas, obs, drop = FALSE]) - mu[obs]
    d2 <- d2 + length(filas) * drop(t(dif) %*% solve(Sigma[obs, obs]) %*% dif)
    gl <- gl + sum(obs)
  }
  gl <- gl - ncol(x)
  c(chi2 = d2, gl = gl, p = pchisq(d2, gl, lower.tail = FALSE))
}

# -----------------------------------------------------------------------
# Paso 1. Mi EM contra el de lavaan, en los datos reales
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
x <- as.matrix(guerrero[, setdiff(names(guerrero), "folio")])
em <- em_mvn(x)
em$iteraciones
lav <- lavCor(x, missing = "fiml", output = "sampstat")
signif(max(abs(em$mu - lav$mean[colnames(x)])), 3)                      # diferencia máxima en medias
signif(max(abs(em$Sigma - lav$cov[colnames(x), colnames(x)])), 3)       # y en covarianzas

# -----------------------------------------------------------------------
# Paso 2. Simulación: calibración (MCAR) y potencia (MAR, MNAR)
# -----------------------------------------------------------------------
# 8 variables correlacionadas (r = .5^|i-j|), 294 casos, 300 réplicas por tipo.
#   MCAR: cada dato falta con probabilidad .15, sin relación con nada.
#   MAR : x1 falta si x2 es alta; x3 falta si x4 es alta (depende de lo observado).
#   MNAR: x1 falta si el propio x1 es alto (depende de lo no observado).
set.seed(123)
n <- 294; p <- 8; reps <- 300
Sig <- 0.5 ^ abs(outer(1:p, 1:p, "-"))
simular <- function(tipo) {
  y <- mvrnorm(n, rep(0, p), Sig)
  if (tipo == "MCAR") y[matrix(runif(n * p) < .15, n, p)] <- NA
  if (tipo == "MAR") {
    y[, 1][y[, 2] > 0.3 & runif(n) < .8] <- NA
    y[, 3][y[, 4] > 0.3 & runif(n) < .8] <- NA
  }
  if (tipo == "MNAR") y[, 1][y[, 1] > 0.5 & runif(n) < .9] <- NA
  y <- y[rowSums(!is.na(y)) > 0, ]
  e <- em_mvn(y, tol = 1e-7)
  little_mcar(y, e$mu, e$Sigma)
}
resultados <- lapply(c(MCAR = "MCAR", MAR = "MAR", MNAR = "MNAR"), function(tp)
  t(replicate(reps, simular(tp))))
t(sapply(resultados, function(r)
  c(rechazo_5pct = mean(r[, "p"] < .05), rechazo_1pct = mean(r[, "p"] < .01), p_medio = mean(r[, "p"]))))
# Bajo MCAR los p-valores deben ser uniformes: prueba de Kolmogorov-Smirnov
ks.test(resultados$MCAR[, "p"], "punif")$p.value
