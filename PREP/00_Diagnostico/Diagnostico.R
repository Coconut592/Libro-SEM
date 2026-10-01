# =============================================================================
# Libro SEM · PREP
# 00 - Diagnóstico de la base: ¿se pueden hacer los 7 ejercicios con PREP.dta?
# =============================================================================
# Referencias: EFA_Hogares.inp, CFA_Hogares.inp, CFA_Espacio_Publico.inp,
# AFE.do, cfa_espacio_publico.pdf y los Laboratorios 2 a 5 (todos hechos con
# el PILOTO). Este script no es parte del libro: solo comprueba, con la base
# final, que cada ejercicio corre, y deja las cifras que respaldan el README.
# Tarda unos 7 minutos (los AFC con FIML sobre 8,242 casos son lo más lento).
#   source("PREP/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(readstata13)
library(psych)
library(nFactors)
library(lavaan)

dir_salida <- "PREP/00_Diagnostico/output"

# -----------------------------------------------------------------------
# Paso 1. Leer la base
# -----------------------------------------------------------------------
# convert.factors = FALSE evita que Stata convierta las escalas 1-10 en factores.
prep <- read.dta13("PREP/data/PREP.dta", convert.factors = FALSE)
dim(prep)                        # 8,242 respondientes y 59 variables
prep$id <- seq_len(nrow(prep))   # la base no trae identificador del respondiente

# Bloques de ítems. Las equivalencias con las variables del piloto (B13-G3)
# están en el README: son por contenido y falta que se confirmen.
items_ep  <- c("b11", "b12", "b13", "b14", "b15", "b16", "b17", "b18",
               "b21", "b22", "b26")                       # espacio público
items_hog <- c(sprintf("c%02d", 1:9), sprintf("d%02d", 1:9),
               sprintf("e%02d", 1:5), sprintf("f%02d", 1:2))   # colonia / hogares
items_g   <- sprintf("g%02d", 1:12)                       # participación y civismo (nuevo)

# -----------------------------------------------------------------------
# Paso 2. "99 = Ns/Nc": ¿viene como faltante?
# -----------------------------------------------------------------------
# En los bloques b y g el 99 ya es NA, pero en c, d, e y f sigue siendo un
# valor (la media de c05 sería 17 en una escala de 1 a 10).
n99 <- sapply(prep[, c(items_ep, items_hog, items_g)], function(x) sum(x %in% 99))
n99[n99 > 0]
write.csv(data.frame(item = names(n99), n_99 = n99), file.path(dir_salida, "ns_nc_99_por_item.csv"),
          row.names = FALSE)

for (v in items_hog) prep[[v]][prep[[v]] %in% 99] <- NA   # 99 pasa a faltante
range(prep[, items_hog], na.rm = TRUE)                    # ahora 1 a 10

# -----------------------------------------------------------------------
# Paso 3. Datos faltantes
# -----------------------------------------------------------------------
todos <- c(items_ep, items_hog, items_g)
faltantes <- data.frame(item = todos,
                        n_NA = colSums(is.na(prep[, todos])),
                        pct_NA = round(100 * colMeans(is.na(prep[, todos])), 1))
faltantes[order(-faltantes$pct_NA), ][1:10, ]             # b21 y b22 (~33%) son los peores
write.csv(faltantes, file.path(dir_salida, "faltantes_por_item.csv"), row.names = FALSE)

# Casos completos por bloque: es lo que se conserva con listwise
sapply(list(EP = items_ep, Hogares = items_hog, G = items_g),
       function(it) sum(complete.cases(prep[, it])))

# Respondientes sin NINGÚN ítem de espacio público
sin_ep <- rowSums(!is.na(prep[, items_ep])) == 0
sum(sin_ep)                                  # 428 (5%)
sum(sin_ep & rowSums(!is.na(prep[, items_hog])) > 0)   # casi todos sí contestaron la colonia
tab <- table(prep$espacio[sin_ep])
length(tab)                                  # ocurre en 31 espacios...
sum(tab == table(prep$espacio)[names(tab)])  # ...y en 10 NADIE tiene el bloque B

# ¿Los faltantes de b21/b22 son "no sé" o saltos del cuestionario?
# Si el 80% de quien no contesta b21 sí contesta b26, parece "Ns/Nc".
round(prop.table(table(b21_falta = is.na(prep$b21), b26_contesta = !is.na(prep$b26)), 1), 3)

# -----------------------------------------------------------------------
# Paso 4. Estructura de los datos: respondientes dentro de espacios
# -----------------------------------------------------------------------
# ID_MPIO es la clave INEGI: estado (1 a 32) * 1000 + municipio.
prep$estado <- prep$ID_MPIO %/% 1000
c(espacios = length(unique(prep$espacio)), municipios = length(unique(prep$ID_MPIO)),
  estados = length(unique(prep$estado)))
table(table(prep$espacio))                   # casi todos los espacios tienen 30 respondientes

# Correlación intraclase (ANOVA de una vía) de cada ítem por espacio
icc1 <- function(y, g) {
  d <- na.omit(data.frame(y, g))
  a <- anova(lm(y ~ factor(g), d))
  k <- mean(table(d$g))
  (a[1, 3] - a[2, 3]) / (a[1, 3] + (k - 1) * a[2, 3])
}
icc <- sapply(todos, function(v) icc1(prep[[v]], prep$espacio))
round(range(icc), 2); round(median(icc), 2)  # entre .12 y .39, mediana .21
1 + (30 - 1) * median(icc)                   # efecto de diseño ~7 (para medias de ítems)
write.csv(data.frame(item = todos, icc = round(icc, 3)), file.path(dir_salida, "icc_por_item.csv"),
          row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Forma de los ítems y dirección de las escalas
# -----------------------------------------------------------------------
desc <- describe(prep[, todos])[, c("n", "mean", "sd", "skew", "kurtosis")]
round(desc, 2)                               # asimetría negativa; g06-g08 con piso (50% en 1)

# b14-b18 originales: 1 = "Totalmente cierto" ... 10 = "Totalmente falso" (mayor = más seguro).
# Las versiones *Recod* se invierten (mayor = más inseguridad). Con el signo de la
# correlación con las calificaciones (b11-b13) se ve cuál es cuál:
round(cor(prep[, c("b11", "b12", "b13")], prep[, c("b14", "b14Recod")], use = "pairwise"), 2)

# -----------------------------------------------------------------------
# Paso 6. AFE (como AFE.do, Lab 2 y EFA_Hogares.inp)
# -----------------------------------------------------------------------
# Casos completos del bloque, ML, varimax. KMO y Bartlett dicen si tiene sentido
# factorizar; el análisis paralelo, cuántos factores.
afe <- function(items, nf, nombre) {
  x <- prep[complete.cases(prep[, items]), items]
  cat("\n=====", nombre, "| N completos =", nrow(x), "\n")
  cat("KMO =", round(KMO(x)$MSA, 3), "\n")
  b <- cortest.bartlett(cor(x), n = nrow(x))
  cat("Bartlett: chi2 =", round(b$chisq), " gl =", b$df, " p =", signif(b$p.value, 2), "\n")
  ev <- eigen(cor(x))$values
  cat("Kaiser (eigenvalores > 1):", sum(ev > 1), "\n")
  # Análisis paralelo como en el Lab 2: eigenvalores de componentes principales
  # contra el percentil 95 de 100 matrices aleatorias
  set.seed(2013)
  ap <- parallel(subject = nrow(x), var = ncol(x), rep = 100, cent = .05)
  cat("Análisis paralelo (componentes):", sum(ev > ap$eigen$qevpea), "factores\n")
  # Variante con factores (ML): suele sugerir uno más
  pa <- fa.parallel(x, fm = "ml", fa = "fa", n.iter = 100, plot = FALSE)
  cat("Análisis paralelo (factores ML):", pa$nfact, "factores\n")
  f <- fa(x, nfactors = nf, fm = "ml", rotate = "varimax")
  cat("ML,", nf, "factores: RMSEA =", round(f$RMSEA[1], 3), " TLI =", round(f$TLI, 3), "\n")
  cargas <- cbind(round(unclass(f$loadings), 2), comunalidad = round(f$communality, 2))
  print(cargas)                              # cargas menores que .30 se ignoran al leer
  write.csv(cargas, file.path(dir_salida, paste0("cargas_AFE_", nombre, ".csv")))
  invisible(f)
}
afe(items_ep, 3, "EP")           # 3 factores: calificación, seguridad y actividades
afe(items_hog, 4, "Hogares")     # 4 factores (como AFE.do); con ML el paralelo sugiere 5
afe(items_g, 3, "G")             # 3 factores; g05 no carga en ninguno (comunalidad .03)

# -----------------------------------------------------------------------
# Paso 7. AFC (como CFA_Espacio_Publico.inp y CFA_Hogares.inp)
# -----------------------------------------------------------------------
# MLR + FIML, igual que Mplus. lavaan ignora a quien no tiene ningún ítem del
# modelo; aquí se quitan explícitamente para saber cuántos quedan.
con_info <- function(items) prep[rowSums(!is.na(prep[, items])) > 0, ]

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

d_ep <- con_info(items_ep); d_hog <- con_info(items_hog); d_g <- con_info(items_g)

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(fit, nombre) {
  m <- round(as.numeric(fitMeasures(fit, medidas)), 3)
  data.frame(modelo = nombre, N = lavInspect(fit, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}

fit_ep  <- cfa(m_ep,  data = d_ep,  estimator = "MLR", missing = "fiml")
fit_hog <- cfa(m_hog, data = d_hog, estimator = "MLR", missing = "fiml")   # ~1 min
fit_g   <- cfa(m_g,   data = d_g,   estimator = "MLR", missing = "fiml")
tabla_ajuste <- rbind(ajuste(fit_ep, "EP: EVEP/SEGEP/ACTEP"),
                      ajuste(fit_hog, "Hogares: IP/SG/CS/INF/SR"),
                      ajuste(fit_g, "G: PART/RECH/INTV"))
tabla_ajuste

# Cargas estandarizadas y correlaciones entre factores
fits <- list(EP = fit_ep, Hogares = fit_hog, G = fit_g)
for (nm in names(fits)) {
  s <- standardizedSolution(fits[[nm]])
  cat("\n", nm, "- rango de cargas:", round(range(s$est.std[s$op == "=~"]), 2), "\n")
  cor_f <- s[s$op == "~~" & s$lhs != s$rhs & s$lhs %in% lavNames(fits[[nm]], "lv"), c("lhs", "rhs", "est.std")]
  cor_f$est.std <- round(cor_f$est.std, 2)
  print(cor_f, row.names = FALSE)
}

# Los errores estándar suponen observaciones independientes y los respondientes
# están agrupados en espacios (ICC ~ .21): con cluster = "espacio" las cargas
# tienen errores estándar ~37% mayores y el ajuste casi no cambia.
fit_ep_cl <- cfa(m_ep, data = d_ep, estimator = "MLR", missing = "fiml", cluster = "espacio")
se_cargas <- function(f) { p <- parameterEstimates(f); mean(p$se[p$op == "=~" & p$se > 0]) }
se_cargas(fit_ep_cl) / se_cargas(fit_ep)
ajuste(fit_ep_cl, "EP con cluster = espacio")

# -----------------------------------------------------------------------
# Paso 8. AFC de segundo orden (técnica del Lab 3: G =~ f1 + f2 + f3)
# -----------------------------------------------------------------------
# EP: con 3 factores de primer orden el de segundo orden queda justo
# identificado (gl iguales, ajuste idéntico).
fit_ep2 <- cfa(paste(m_ep, "\n CALEP =~ EVEP + SEGEP + ACTEP"), data = d_ep,
               estimator = "MLR", missing = "fiml", std.lv = TRUE)
# Hogares: con 5 factores sí es contrastable. Con la carga marcadora por defecto
# NO converge; con std.lv = TRUE (varianza del factor = 1) sí.
fit_hog2 <- cfa(paste(m_hog, "\n ENT =~ IP + SG + CS + INF + SR"), data = d_hog,
                estimator = "MLR", missing = "fiml", std.lv = TRUE)
tabla_2o <- rbind(ajuste(fit_ep2, "EP 2do orden"), ajuste(fit_hog2, "Hogares 2do orden"))
tabla_2o
s <- standardizedSolution(fit_hog2); s[s$lhs == "ENT" & s$op == "=~", c("rhs", "est.std")]
# G: los 3 factores casi no se correlacionan (.05, .20, -.10), así que un factor
# de segundo orden no tiene sentido ahí.
round(lavInspect(fit_g, "cor.lv"), 2)
write.csv(rbind(tabla_ajuste, tabla_2o), file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 9. Confiabilidad y validez (Lab 2: alfa y confiabilidad compuesta)
# -----------------------------------------------------------------------
# Alfa con los datos (por pares). Confiabilidad compuesta de Dillon-Goldstein:
#   CR = (Σλ)² / [(Σλ)² + Σ(1 − λ²)]   con λ estandarizadas.
# AVE = promedio de λ². Fornell-Larcker: la AVE de cada factor debe superar el
# r² más alto con otro factor.
confiabilidad <- function(fit, nombre) {
  s <- standardizedSolution(fit)
  L <- s[s$op == "=~", ]
  res <- do.call(rbind, lapply(split(L, factor(L$lhs, levels = unique(L$lhs))), function(x)
    data.frame(bloque = nombre, factor = x$lhs[1], k = nrow(x),
               alfa = suppressMessages(psych::alpha(prep[, x$rhs], check.keys = FALSE,
                                                    warnings = FALSE))$total$raw_alpha,
               CR = sum(x$est.std)^2 / (sum(x$est.std)^2 + sum(1 - x$est.std^2)),
               AVE = mean(x$est.std^2))))
  phi <- lavInspect(fit, "cor.lv")
  res$r2_max <- sapply(res$factor, function(f) max(phi[f, rownames(phi) != f]^2))
  res
}
conf <- rbind(confiabilidad(fit_ep, "EP"), confiabilidad(fit_hog, "Hogares"), confiabilidad(fit_g, "G"))
rownames(conf) <- NULL
conf$discriminante <- conf$AVE > conf$r2_max
conf[, c("alfa", "CR", "AVE", "r2_max")] <- round(conf[, c("alfa", "CR", "AVE", "r2_max")], 3)
conf
write.csv(conf, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 10. Puntajes factoriales (SAVEDATA: SAVE = FS / Lab 2 y Lab 5)
# -----------------------------------------------------------------------
# Regresión = el método de Mplus. Cada respondiente con al menos un ítem recibe puntaje.
fs <- lavPredict(fit_ep, method = "regression")
nrow(fs); colSums(is.na(fs))
round(apply(fs, 2, function(x) c(media = mean(x), de = sd(x), min = min(x), max = max(x))), 2)

# Escala original (los [b11@0 ...] de los .inp): interceptos en 0 y medias de
# los factores libres; los marcadores son los de CFA_Espacio_Publico.inp.
m_ep_orig <- 'EVEP  =~ NA*b11 + 1*b12 + b13
              SEGEP =~ NA*b14 + b15 + b16 + b17 + 1*b18
              ACTEP =~ NA*b21 + 1*b22 + b26
              b11 ~ 0*1; b12 ~ 0*1; b13 ~ 0*1; b14 ~ 0*1; b15 ~ 0*1; b16 ~ 0*1
              b17 ~ 0*1; b18 ~ 0*1; b21 ~ 0*1; b22 ~ 0*1; b26 ~ 0*1
              EVEP ~ 1; SEGEP ~ 1; ACTEP ~ 1'
fit_orig <- cfa(m_ep_orig, data = d_ep, estimator = "MLR", missing = "fiml")
lavInspect(fit_orig, "converged")
pe <- parameterEstimates(fit_orig); pe[pe$op == "~1" & pe$lhs %in% c("EVEP", "SEGEP", "ACTEP"), c("lhs", "est")]
fs2 <- lavPredict(fit_orig, method = "regression")
round(apply(fs2, 2, function(x) c(media = mean(x), de = sd(x), min = min(x), max = max(x))), 2)

puntajes <- data.frame(id = d_ep$id, espacio = d_ep$espacio, fs, setNames(as.data.frame(fs2), paste0(colnames(fs2), "_orig")))
write.csv(round(puntajes, 3), file.path(dir_salida, "puntajes_EP.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 11. Invarianza factorial: ¿hay con qué agrupar?
# -----------------------------------------------------------------------
# La base NO trae sexo, edad ni nada del respondiente. Lo único que agrupa es
# el espacio y la clave del municipio (ID_MPIO), de la que sale el estado.
sort(table(prep$estado), decreasing = TRUE)[1:6]
# Ejemplo ilustrativo con los 3 estados más grandes que tienen 400+ respondientes
# (15 = México, 30 = Veracruz, 26 = Sonora). No es una hipótesis del estudio.
d_inv <- d_ep[d_ep$estado %in% c(15, 30, 26), ]
d_inv$estado <- factor(d_inv$estado)
inv <- function(...) cfa(m_ep, data = d_inv, group = "estado", estimator = "MLR", missing = "fiml", ...)
tabla_inv <- rbind(configural = fitMeasures(inv(), medidas),
                   metrica = fitMeasures(inv(group.equal = "loadings"), medidas),
                   escalar = fitMeasures(inv(group.equal = c("loadings", "intercepts")), medidas))
round(tabla_inv, 3)
round(diff(tabla_inv[, "cfi.robust"]), 3)    # criterio de Chen (2007): caída de CFI <= .01
write.csv(round(tabla_inv, 3), file.path(dir_salida, "invarianza_por_estado.csv"))

# -----------------------------------------------------------------------
# Paso 12. FIML frente a listwise
# -----------------------------------------------------------------------
fit_ep_lw <- cfa(m_ep, data = prep, estimator = "MLR", missing = "listwise")
tabla_fiml <- rbind(ajuste(fit_ep_lw, "EP listwise"), ajuste(fit_ep, "EP FIML"))
tabla_fiml                                   # 4,019 casos contra 7,814
a <- standardizedSolution(fit_ep_lw); b <- standardizedSolution(fit_ep)
max(abs(a$est.std[a$op == "=~"] - b$est.std[b$op == "=~"]))   # las cargas casi no cambian
write.csv(tabla_fiml, file.path(dir_salida, "fiml_vs_listwise.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 13. Extra: Laboratorios 4 y 5 (SEM y efectos indirectos) con esta base
# -----------------------------------------------------------------------
# Mismo modelo del Lab 5 / Lab 4 (IP, CS, IN y SR) con las variables de PREP.dta.
m_sem <- 'IP  =~ c01 + c02 + c03 + c04 + c05 + c06
          CS  =~ d01 + d02 + d03 + d04 + d05 + d06 + d07 + d08 + d09
          INF =~ e01 + e02 + e03 + e04 + e05
          SR  =~ f01 + f02
          CS ~ IP + a*INF
          SR ~ c*INF + b*CS
          IP ~~ INF
          ab := a*b
          total := c + (a*b)'
fit_sem <- sem(m_sem, data = d_hog, estimator = "MLR", missing = "fiml")
lavInspect(fit_sem, "converged")
round(fitMeasures(fit_sem, medidas), 3)
pe <- parameterEstimates(fit_sem); pe[pe$op %in% c("~", ":="), c("lhs", "op", "rhs", "est", "se", "pvalue")]
