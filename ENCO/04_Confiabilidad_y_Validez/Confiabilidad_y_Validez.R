# =============================================================================
# Libro SEM · ENCO
# 04 - Confiabilidad y validez: Confianza del consumidor
# =============================================================================
# Sin referencia: el documento de INEGI no trae confiabilidad ni validez. Se
# calculan aquí: alfa ordinal, confiabilidad compuesta (CR) y AVE de cada factor,
# validez discriminante (Fornell-Larcker y HTMT), omega y validez de criterio con
# variables del cuestionario sociodemográfico que no entraron al modelo.
#   source("ENCO/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(foreign)
library(lavaan)
library(psych)

dir_salida <- "ENCO/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo (igual que en 02_AFC), más el sociodemográfico
# -----------------------------------------------------------------------
# merge() reordena las filas por llave: de aquí en adelante TODO sale de `enco`.
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
cs <- read.dbf("ENCO/data/encocs_0826.DBF", as.is = TRUE)
llave <- c("FOL", "CVE_ENT", "CON", "V_SEL", "N_HOG", "H_MUD", "N_REN")
enco <- merge(cb, cs[, c(llave, "EDA", "I_NIV", "C_ACT", "I_PER", "ING")], by = llave)
items <- paste0("P", 1:15)
codigo_NS <- c(P1 = 6, P2 = 6, P3 = 6, P4 = 6, P5 = 6, P6 = 6, P7 = 4, P8 = 4, P9 = 3, P10 = 3,
               P11 = 6, P12 = 7, P13 = 6, P14 = 4, P15 = 4)
maximo    <- c(P1 = 5, P2 = 5, P3 = 5, P4 = 5, P5 = 5, P6 = 5, P7 = 3, P8 = 3, P9 = 2, P10 = 2,
               P11 = 5, P12 = 6, P13 = 5, P14 = 3, P15 = 3)
x <- enco[, items]
x[] <- lapply(x, as.integer)
for (v in items) x[[v]][x[[v]] == codigo_NS[[v]]] <- NA
x$P10[enco$P10 == "4"] <- NA
for (v in items) x[[v]] <- maximo[[v]] + 1L - x[[v]]

factores <- list(
  HOGA = c("P1", "P3"),
  HOGE = c("P2", "P4"),
  PAIS = c("P5", "P6", "P12", "P13"),
  CONS = c("P7", "P8", "P9", "P10", "P11", "P14", "P15"))
modelo <- paste(sapply(names(factores), function(f) paste(f, "=~", paste(factores[[f]], collapse = " + "))), collapse = "\n")
fit <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")

# -----------------------------------------------------------------------
# Paso 2. Confiabilidad: alfa ordinal, confiabilidad compuesta (CR) y AVE
# -----------------------------------------------------------------------
# Alfa ordinal = alfa de Cronbach sobre la matriz policórica (los ítems son ordinales).
# CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)], con las cargas estandarizadas.
# AVE = promedio de λ²; se pide > .50.
R <- lavCor(x, ordered = items, missing = "pairwise")      # policóricas
s <- standardizedSolution(fit)
fi <- lavInspect(fit, "cor.lv")
conf <- do.call(rbind, lapply(names(factores), function(f) {
  v <- factores[[f]]; l <- s$est.std[s$op == "=~" & s$lhs == f]
  data.frame(factor = f, k = length(v),
             alfa_ordinal = psych::alpha(R[v, v], n.obs = nrow(x))$total$raw_alpha,
             CR = sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), AVE = mean(l^2),
             r2_max = max(fi[f, rownames(fi) != f]^2))
}))
conf$AVE_supera_r2 <- conf$AVE > conf$r2_max
conf[, c("alfa_ordinal", "CR", "AVE", "r2_max")] <- round(conf[, c("alfa_ordinal", "CR", "AVE", "r2_max")], 3)
conf
# α ordinal y CR de .90 en HOGA, HOGE y CONS (.91); PAIS es el débil: α .73, CR .74 y AVE .43
# (por P12, que carga .48): no llega a .50. Fornell-Larcker: la AVE de cada factor debe superar
# su r² más alto con otro factor. HOGA, HOGE y PAIS cumplen (el r² de PAIS es bajo, .38); CONS
# apenas no (AVE .597 contra r² = .62 con HOGA): ver HTMT.
write.csv(conf, file.path(dir_salida, "confiabilidad.csv"), row.names = FALSE)

# Omega con la matriz policórica: jerárquico (lo que aporta el factor general) y total
om <- suppressWarnings(psych::omega(R, nfactors = 4, n.obs = nrow(x), plot = FALSE))
c(omega_jerarquico = round(om$omega_h, 2), omega_total = round(om$omega.tot, 2))   # .76 y .95

# -----------------------------------------------------------------------
# Paso 3. Validez discriminante: HTMT (correlaciones policóricas)
# -----------------------------------------------------------------------
# HTMT = promedio de las correlaciones entre ítems de dos factores / raíz del
# producto de los promedios de las correlaciones dentro de cada factor.
# Se pide < .85 (estricto) o < .90.
dentro <- function(v) mean(R[v, v][lower.tri(R[v, v])])
htmt <- function(a, b) mean(R[factores[[a]], factores[[b]]]) / sqrt(dentro(factores[[a]]) * dentro(factores[[b]]))
parejas <- t(combn(names(factores), 2))
tabla_htmt <- data.frame(par = paste(parejas[, 1], parejas[, 2], sep = " - "),
                         r_factores = round(mapply(function(a, b) fi[a, b], parejas[, 1], parejas[, 2]), 2),
                         HTMT = round(mapply(htmt, parejas[, 1], parejas[, 2]), 2))
tabla_htmt
# HTMT de .55 (HOGA-PAIS) a .77 (HOGA-CONS): los seis bajo .85. Por HTMT los factores se
# distinguen; por Fornell-Larcker, CONS y HOGA no del todo. Comparten mucho (r de .54 a .79),
# que es lo que justifica el segundo orden (ver 03).
write.csv(tabla_htmt, file.path(dir_salida, "htmt.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Validez de criterio: el puntaje contra variables externas
# -----------------------------------------------------------------------
# Puntaje de confianza (segundo orden, EBM). Criterios del sociodemográfico (no
# entraron al modelo): la confianza suele bajar con la edad y subir con más
# estudios, más ingreso y estar ocupado. No hay un criterio "oro" en estos archivos.
fit2 <- cfa(paste(modelo, "\n CONF =~ HOGA + HOGE + PAIS + CONS"), data = x, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
conf_pf <- as.numeric(lavPredict(fit2, method = "EBM")[, "CONF"])
edad <- as.numeric(enco$EDA)
estudios <- suppressWarnings(as.integer(enco$I_NIV)); estudios[estudios == 99] <- NA   # 0 ninguno ... 9 doctorado
ingreso <- suppressWarnings(as.numeric(trimws(enco$ING))); ingreso[ingreso == 999999] <- NA   # 999999 = no especificado
a_mes <- c("1" = 52 / 12, "2" = 2, "3" = 1, "4" = 1 / 12)    # semanal, quincenal, mensual, anual -> por mes
ln_ingreso_mensual <- log(ingreso * a_mes[as.character(enco$I_PER)])
criterios <- data.frame(edad = edad, estudios = estudios, ln_ingreso_mensual = ln_ingreso_mensual,
                        ocupado = as.integer(enco$C_ACT == "01"))
validez <- data.frame(criterio = names(criterios),
  spearman = round(sapply(criterios, function(y) cor(conf_pf, y, use = "pairwise.complete.obs", method = "spearman")), 2),
  n = sapply(criterios, function(y) sum(!is.na(y))))
rownames(validez) <- NULL
validez
# Edad -.33 (los jóvenes confían más), estudios .16, ingreso mensual .20 (solo 810 personas
# con ingreso válido) y estar ocupado .17: los signos esperados, con correlaciones de
# moderadas a bajas. El ingreso falta en 1,240: no trabajan (762) o no lo especificaron (478).
write.csv(validez, file.path(dir_salida, "validez_criterio.csv"), row.names = FALSE)
