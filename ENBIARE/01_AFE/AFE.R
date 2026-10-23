# =============================================================================
# Libro SEM · ENBIARE
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Sin referencia: no hay tesis, capítulo ni script que traiga un modelo factorial
# de la ENBIARE 2021. Aquí se explora cuántas dimensiones tienen las dos escalas
# de los ejercicios: satisfacción con 17 aspectos de la vida (pa3_01 a pa3_17;
# principal) y confianza en personas e instituciones (pb1_01 a pb1_12; segunda).
#   source("ENBIARE/01_AFE/AFE.R")
# =============================================================================

library(psych)
library(GPArotation)
library(ggplot2)

dir_salida <- "ENBIARE/01_AFE/output"
# fa.parallel simula en varios núcleos; con este generador la semilla sí da el mismo resultado
RNGkind("L'Ecuyer-CMRG")
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos
# -----------------------------------------------------------------------
# La base viene en latin1 y con los nombres en MAYÚSCULAS. quote = "\"" es
# necesario: los textos libres (pf14_*_esp) traen apóstrofos. Las escalas 0-10
# no tienen faltantes ni "no sabe": no hay nada que recodificar.
enb <- read.csv("ENBIARE/data/conjunto_de_datos_tenbiare_enbiare_2021.csv",
                fileEncoding = "latin1", na.strings = c("", " "), quote = "\"",
                comment.char = "", stringsAsFactors = FALSE)
names(enb) <- tolower(names(enb))
dim(enb)                                     # 31,166 personas

items_sat  <- sprintf("pa3_%02d", 1:17)      # satisfacción con 17 aspectos (0-10)
items_conf <- sprintf("pb1_%02d", 1:12)      # confianza en 12 personas e instituciones (0-10)
colSums(is.na(enb[, c(items_sat, items_conf)]))   # 0: sin faltantes

# -----------------------------------------------------------------------
# Paso 2. Un AFE por escala, con las 31,166 personas
# -----------------------------------------------------------------------
# KMO y Bartlett: ¿tiene sentido factorizar? Kaiser (eigenvalores > 1) y análisis
# paralelo: ¿cuántos factores? fa(): máxima verosimilitud con rotación oblimin (los
# factores se esperan correlacionados, de .4 a .8). Las escalas de 11 puntos se
# tratan como continuas (como PREP, con escalas 1-10).
afe <- function(items, nombre, k_max = 6) {
  x <- enb[, items]
  r <- cor(x)
  cat("\n=====", nombre, "| N =", nrow(x), "\n")
  cat("KMO =", round(KMO(r)$MSA, 3), " (por ítem de", round(min(KMO(r)$MSAi), 2), "a", round(max(KMO(r)$MSAi), 2), ")\n")
  b <- cortest.bartlett(r, n = nrow(x))
  cat("Bartlett: chi2 =", round(b$chisq), " gl =", b$df, " p =", signif(b$p.value, 2), "\n")
  ev <- eigen(r)$values
  cat("Eigenvalores:", round(ev[1:8], 2), "\n")
  cat("Kaiser (eigenvalores > 1):", sum(ev > 1), "\n")
  set.seed(2021)
  ap <- fa.parallel(x, fm = "ml", fa = "both", n.iter = 100, plot = FALSE)
  cat("Análisis paralelo: componentes =", ap$ncomp, " factores ML =", ap$nfact, "\n")
  # El número de factores del paralelo con ML depende de la semilla cuando el último
  # eigenvalor casi iguala al simulado; se repite con 8 semillas para ver qué tan estable es.
  nf <- sapply(1:8, function(s) { set.seed(s); invisible(capture.output(
    n <- fa.parallel(x, fm = "ml", fa = "fa", n.iter = 50, plot = FALSE)$nfact)); n })
  cat("Paralelo (ML) con 8 semillas:", nf, "\n")

  # Gráfica de codo con la línea del análisis paralelo
  datos <- data.frame(componente = seq_along(ev), eigenvalor = ev, paralelo = ap$pc.sim)
  g <- ggplot(datos, aes(componente, eigenvalor)) + geom_line(col = "red") + geom_point() +
    geom_line(aes(y = paralelo), col = "blue", linetype = 2) + geom_hline(yintercept = 1) +
    labs(title = paste("Gráfica de codo:", nombre))
  ggsave(file.path(dir_salida, paste0("grafica_codo_", nombre, ".png")), g, width = 7, height = 4.5)

  # Ajuste del AFE de 1 a k_max factores
  ajuste <- do.call(rbind, lapply(1:k_max, function(k) {
    f <- suppressWarnings(fa(r, nfactors = k, n.obs = nrow(x), fm = "ml", rotate = if (k > 1) "oblimin" else "none"))
    data.frame(escala = nombre, factores = k, RMSEA = round(f$RMSEA[1], 3), TLI = round(f$TLI, 3),
               SRMR = round(f$rms, 3), BIC = round(f$BIC),
               residual_min = round(min(1 - f$communality), 3))   # < 0: caso Heywood
  }))
  print(ajuste, row.names = FALSE)
  invisible(ajuste)
}

ajuste_sat  <- afe(items_sat, "SAT")
# KMO .92 (por ítem de .88 a .95); Kaiser pide 2 factores y el análisis paralelo 5 con la semilla
# 2021, pero con 8 semillas distintas sale 5 cuatro veces y 6 otras cuatro: es un caso límite (el
# 6.º eigenvalor, .018, casi iguala al simulado, .015).
# Ajuste: 4 factores RMSEA .048 y TLI .939; 5 factores .035 y .968; 6 factores .031 y .975.
# Se elige 5: es el primero con RMSEA <= .06 y TLI >= .95 y los 5 factores se pueden nombrar;
# el 6.º solo parte a pa3_04 (relaciones personales) en un factor de un solo ítem (carga .99,
# comunalidad 1.00: caso Heywood en el límite).
write.csv(ajuste_sat, file.path(dir_salida, "ajuste_AFE_SAT.csv"), row.names = FALSE)

ajuste_conf <- afe(items_conf, "CONF")
# KMO .90 (por ítem de .80 a .97); Kaiser pide 2 factores y el análisis paralelo 5 con las 8
# semillas. Ajuste: 4 factores RMSEA .127 y
# TLI .880; 5 factores .021 y .997 (un salto enorme); 6 factores .012 y .999.
write.csv(ajuste_conf, file.path(dir_salida, "ajuste_AFE_CONF.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Satisfacción: cinco factores, cargas de patrón (oblimin)
# -----------------------------------------------------------------------
cargas_tabla <- function(items, k) {
  f <- suppressWarnings(fa(cor(enb[, items]), nfactors = k, n.obs = nrow(enb), fm = "ml", rotate = "oblimin"))
  L <- unclass(f$loadings)
  orden <- order(apply(abs(L), 1, which.max), -apply(abs(L), 1, max))     # ítems agrupados por factor
  list(fa = f, cargas = cbind(round(L[orden, , drop = FALSE], 2), comunalidad = round(f$communality[orden], 2)))
}
sat5 <- cargas_tabla(items_sat, 5)
sat5$cargas
# Factor A · Nivel de vida y logros: pa3_01 (.67), pa3_02 (.49), pa3_03 (.46); pa3_08 (futuro) carga .26 y .25 en dos más.
# Factor B · Relaciones: pa3_04 (.71), pa3_07 (.57), pa3_05 (.56), pa3_06 (.55).
# Factor C · Autonomía y actividad: pa3_10 (.66), pa3_09 (.57), pa3_12 (.45).
# Factor D · Hogar y vecindario: pa3_14 (.58), pa3_13 (.54, y .24 en nivel de vida).
# Factor E · Ciudad y país: pa3_17 (.72), pa3_15 (.68), pa3_16 (.62), pa3_11 (.53).
# El ítem menos limpio es pa3_08 (futuro): tres cargas de .22 a .26. La comunalidad más baja es
# la de pa3_07 (vida afectiva, .32); todas las demás pasan de .37.
round(sat5$fa$Phi, 2)                        # los factores correlacionan de .33 a .63
write.csv(sat5$cargas, file.path(dir_salida, "cargas_AFE_SAT_5_factores.csv"))
# Cargas cruzadas (>= .30 en un factor que no es el principal)
cruzadas <- function(L, corte = .30) {
  L <- L[, 1:(ncol(L) - 1), drop = FALSE]
  do.call(rbind, lapply(rownames(L), function(i) {
    o <- order(-abs(L[i, ])); if (abs(L[i, o[2]]) >= corte) data.frame(item = i, principal = round(L[i, o[1]], 2), segundo = round(L[i, o[2]], 2))
  }))
}
cruzadas(sat5$cargas)                        # ninguna con .30 o más

# ¿Qué pasa con 4 y con 6 factores?
sat4 <- cargas_tabla(items_sat, 4); sat4$cargas   # 4: pa3_14 (vecindario) se une a ciudad y país (.45) y pa3_13 (vivienda) queda sin factor (.26 y .22)
sat6 <- cargas_tabla(items_sat, 6); sat6$cargas   # 6: pa3_04 forma un factor de un solo ítem (carga .99)

# -----------------------------------------------------------------------
# Paso 4. Confianza: cinco factores
# -----------------------------------------------------------------------
conf5 <- cargas_tabla(items_conf, 5)
conf5$cargas
# F1 · Interpersonal: pb1_02 (.76) y pb1_01 (.75) — la gente que conoce y la mayoría de la gente.
# F2 · Policías: pb1_04 (.91) y pb1_05 (.78) — municipal y estatal.
# F3 · Fuerzas armadas: pb1_06 (.92, Guardia Nacional) y pb1_07 (.84, Ejército y Marina).
# F4 · Justicia: pb1_09 (.93, juzgados) y pb1_08 (.58, ministerio público).
# F5 · Política: pb1_11 (.95, partidos), pb1_12 (.78, funcionarios) y pb1_10 (.51, cámaras; carga además .38 en justicia).
# pb1_03 (medios de comunicación) no pertenece a ningún factor: cargas de .19, .30 y .25 y la comunalidad
# más baja. Se deja fuera del modelo.
sort(round(conf5$fa$communality, 2))         # pb1_03 la más baja (.41); las demás, de .55 a .92
round(conf5$fa$Phi, 2)                       # entre los cuatro factores institucionales: .58 a .69; con el interpersonal: .33 a .46
write.csv(conf5$cargas, file.path(dir_salida, "cargas_AFE_CONF_5_factores.csv"))

# Verificación sin pb1_03: los mismos cinco factores, con mejor ajuste
items_conf11 <- setdiff(items_conf, "pb1_03")
f11 <- suppressWarnings(fa(cor(enb[, items_conf11]), nfactors = 5, n.obs = nrow(enb), fm = "ml", rotate = "oblimin"))
c(RMSEA = round(as.numeric(f11$RMSEA[1]), 3), TLI = round(f11$TLI, 3), SRMR = round(f11$rms, 3))   # .019, .998 y .002
cargas11 <- cargas_tabla(items_conf11, 5)$cargas
cargas11
write.csv(cargas11, file.path(dir_salida, "cargas_AFE_CONF_11_items.csv"))

# -----------------------------------------------------------------------
# Paso 5. ¿Se sostiene la estructura en dos mitades al azar?
# -----------------------------------------------------------------------
# Con 31 mil casos se puede partir la muestra. El coeficiente de congruencia de
# Tucker compara los factores de cada mitad con los de la muestra completa (arriba
# de .95, el mismo factor; hay que emparejar los factores porque su orden cambia).
set.seed(2021)
mitad <- sample(c(1, 2), nrow(enb), replace = TRUE)
congruencia <- function(items, k) {
  completa <- suppressWarnings(fa(cor(enb[, items]), nfactors = k, fm = "ml", rotate = "oblimin"))
  sapply(1:2, function(m) {
    f <- suppressWarnings(fa(cor(enb[mitad == m, items]), nfactors = k, fm = "ml", rotate = "oblimin"))
    cong <- abs(factor.congruence(unclass(completa$loadings), unclass(f$loadings)))
    round(min(apply(cong, 1, max)), 3)       # el peor factor de la mitad
  })
}
table(mitad)                                 # 15,513 y 15,653
cong <- rbind(SAT = congruencia(items_sat, 5), CONF = congruencia(items_conf11, 5))
colnames(cong) <- c("mitad_1", "mitad_2")
cong
# Congruencia mínima de .99 a 1.00 en las dos mitades de las dos escalas: la estructura es estable.
write.csv(cong, file.path(dir_salida, "congruencia_mitades.csv"))
