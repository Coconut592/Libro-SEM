# =============================================================================
# Libro SEM · PREP
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Referencias: AFE.do, EFA_Hogares.inp y Laboratorio 2 (componentes, paralelo, fa ML varimax).
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(nFactors)
library(ggplot2)
dir_salida <- "PREP/01_AFE/output"

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

# -----------------------------------------------------------------------
# Paso 2. Un AFE por bloque, con casos completos (como AFE.do y el Lab 2)
# -----------------------------------------------------------------------
# KMO y Bartlett: ¿tiene sentido factorizar? Eigenvalores (Kaiser > 1) y análisis
# paralelo (Lab 2): ¿cuántos factores? fa(): máxima verosimilitud + varimax.
afe <- function(items, nf, nombre) {
  x <- prep[complete.cases(prep[, items]), items]
  cat("\n=====", nombre, "| N completos =", nrow(x), "\n")
  cat("KMO =", round(KMO(x)$MSA, 3), "\n")
  b <- cortest.bartlett(cor(x), n = nrow(x))
  cat("Bartlett: chi2 =", round(b$chisq), " gl =", b$df, " p =", signif(b$p.value, 2), "\n")

  eigenvalores <- eigen(cor(x))$values
  cat("Kaiser (eigenvalores > 1):", sum(eigenvalores > 1), "\n")
  set.seed(2013)
  ap <- parallel(subject = nrow(x), var = ncol(x), rep = 100, cent = .05)
  cat("Análisis paralelo (componentes):", sum(eigenvalores > ap$eigen$qevpea), "factores\n")
  cat("Análisis paralelo (factores ML):", fa.parallel(x, fm = "ml", fa = "fa", n.iter = 100, plot = FALSE)$nfact, "\n")

  # Gráfica de codo con la línea del análisis paralelo
  datos <- data.frame(componente = seq_along(eigenvalores), eigenvalor = eigenvalores,
                      paralelo = ap$eigen$qevpea)
  g <- ggplot(datos, aes(componente, eigenvalor)) + geom_line(col = "red") + geom_point() +
    geom_line(aes(y = paralelo), col = "blue", linetype = 2) + geom_hline(yintercept = 1) +
    labs(title = paste("Gráfica de codo:", nombre))
  ggsave(file.path(dir_salida, paste0("grafica_codo_", nombre, ".png")), g, width = 7, height = 4.5)

  f <- fa(x, nfactors = nf, fm = "ml", rotate = "varimax")
  cat("ML,", nf, "factores: RMSEA =", round(f$RMSEA[1], 3), " TLI =", round(f$TLI, 3),
      " varianza acumulada =", round(tail(f$Vaccounted["Cumulative Var", ], 1), 3), "\n")
  cargas <- cbind(round(unclass(f$loadings), 2), comunalidad = round(f$communality, 2))
  print(cargas)                       # lo importante: cargas > .40 y comunalidades > .30
  write.csv(cargas, file.path(dir_salida, paste0("cargas_AFE_", nombre, ".csv")))
  invisible(f)
}

afe(items_ep, 3, "EP")                # calificación, seguridad y actividades
afe(items_hog, 4, "Hogares")          # 4 factores (AFE.do); con ML el paralelo sugiere 5
afe(items_g, 3, "G")                  # participación, rechazo a conductas e intervención

# -----------------------------------------------------------------------
# Paso 3. Hogares con 5 factores (como CFA_Hogares.inp)
# -----------------------------------------------------------------------
# Con 5 factores el quinto solo recoge una carga cruzada de d02: Satisfacción
# (f01, f02) no se separa de Infraestructura (e01-e05).
x <- prep[complete.cases(prep[, items_hog]), items_hog]
f5 <- fa(x, nfactors = 5, fm = "ml", rotate = "varimax")
print(round(unclass(f5$loadings), 2), cutoff = .3)
