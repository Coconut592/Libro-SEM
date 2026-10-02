# =============================================================================
# Libro SEM · Violencia Guerrero
# 07 - Datos faltantes: FIML
# =============================================================================
# Sin referencia propia. En el Tren se explicó FIML con missing = "fiml" y MLR
# (Mplus lo usa por defecto). Aquí el problema es mayor: solo 160 de 294
# personas contestan los 46 ítems. Se compara el AFC con eliminación por lista
# (listwise) y con FIML, se prueba si los faltantes son al azar (MCAR) y se
# revisa el supuesto que más pesa: los 71 faltantes de pareja son estructurales.
#   source("Violencia_Guerrero/07_FIML/FIML.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Guerrero/07_FIML/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. ¿Cuántos datos faltan y dónde?
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
items <- setdiff(names(guerrero), "folio")

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

round(100 * mean(is.na(guerrero[, items])), 1)    # % de celdas faltantes
sort(colSums(is.na(guerrero[, items])), decreasing = TRUE)[1:8]
sum(complete.cases(guerrero[, items]))            # solo 160 de 294 están completos
# Con eliminación por lista (listwise) se pierde el 46% de la muestra, y
# TODAS las personas sin pareja.

# Patrones de faltantes por bloque de contenido: casi todo es "pareja"
falta_bloque <- sapply(factores, function(it) rowSums(is.na(guerrero[, it])) > 0)
patron_bloque <- apply(falta_bloque, 1, function(r)
  if (any(r)) paste(names(factores)[r], collapse = " + ") else "ninguno")
sort(table(patron_bloque), decreasing = TRUE)[1:6]
# Patrones distintos a nivel de ítem
length(unique(apply(is.na(guerrero[, items]), 1, paste, collapse = "")))

# -----------------------------------------------------------------------
# Paso 2. ¿Son faltantes completamente al azar (MCAR)?
# -----------------------------------------------------------------------
# FIML es insesgado si los datos son MCAR o MAR (la probabilidad de faltar
# depende solo de variables observadas). Eliminar por lista exige MCAR.
# a) Como en el Tren: si faltar fuera independiente de lo observado, quienes
#    dejan en blanco un ítem no deberían diferir en los demás. Se cuentan
#    las pruebas t con p < .05 (por azar se esperan ~5%).
probar <- function(falta) {
  otros <- setdiff(items, paste0("a", 1:4))
  otros <- otros[sapply(otros, function(v) sum(!is.na(guerrero[[v]][falta])) >= 5)]
  p <- sapply(otros, function(v) t.test(guerrero[[v]] ~ falta)$p.value)
  c(n_falta = sum(falta), items_comparados = length(p),
    p_menor_05 = sum(p < .05), esperados_azar = round(.05 * length(p), 1))
}
sin_pareja <- rowSums(!is.na(guerrero[, factores$pareja])) == 0
t(sapply(list(`sin pareja (a1-a4)` = sin_pareja,
              `falta c6` = is.na(guerrero$c6), `falta c8` = is.na(guerrero$c8),
              `falta c13` = is.na(guerrero$c13),
              `sin familia (a5-a8)` = rowSums(!is.na(guerrero[, factores$familia])) == 0),
         probar))
# Casi no hay diferencias univariadas: de 0 a 3 pruebas significativas de ~40.

# b) Prueba de Little (1988): compara la media de cada patrón de faltantes
#    con la media estimada con FIML; H0 = los datos son MCAR. Se necesitan las
#    medias y covarianzas ML (EM) del modelo saturado, que lavCor() da con FIML.
#    gl = suma de las variables observadas en cada patrón menos el total.
little_mcar <- function(x) {
  est <- lavCor(x, missing = "fiml", output = "sampstat")
  x <- as.matrix(x)
  patron <- apply(is.na(x), 1, paste, collapse = "")
  d2 <- 0; gl <- 0
  for (pt in unique(patron)) {
    filas <- which(patron == pt)
    obs <- !is.na(x[filas[1], ])
    if (!any(obs)) next
    dif <- colMeans(x[filas, obs, drop = FALSE]) - est$mean[obs]
    d2 <- d2 + length(filas) * drop(t(dif) %*% solve(est$cov[obs, obs]) %*% dif)
    gl <- gl + sum(obs)
  }
  gl <- gl - ncol(x)
  c(chi2 = d2, gl = gl, p = pchisq(d2, gl, lower.tail = FALSE),
    patrones = length(unique(patron)))
}
# Con los 46 ítems y sin los de pareja (para saber si el rechazo es solo
# por los faltantes estructurales de pareja)
little <- rbind(`46 ítems` = little_mcar(guerrero[, items]),
                `42 ítems (sin a1-a4)` = little_mcar(guerrero[, setdiff(items, factores$pareja)]))
print(little, digits = 4)
write.csv(little, file.path(dir_salida, "prueba_little_MCAR.csv"))
# Se rechaza MCAR en los dos casos (p < .001): no es solo el bloque de pareja.
# El listwise puede sesgar. FIML supone MAR, que es más débil; Little no
# puede distinguir MAR de "no al azar" (MNAR), así que MAR es un supuesto.

# -----------------------------------------------------------------------
# Paso 3. Eliminación por lista contra FIML
# -----------------------------------------------------------------------
modelo <- '
  pareja      =~ a1 + a2 + a3 + a4
  familia     =~ a5 + a6 + a7 + a8
  economia    =~ a9 + a10 + a11 + a12
  social      =~ a13 + a14 + a15 + a16
  personal    =~ a17 + a18 + a19 + a20
  trabajo     =~ a21 + a22 + a23 + a24
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'
modelo_sat <- '
  pareja   =~ a1 + a2 + a3 + a4
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24'
modelo_vio <- '
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'
modelos <- list(`12 factores` = modelo, `Satisfacción (6)` = modelo_sat,
                `Violencia y clima (6)` = modelo_vio)

# a) Listwise: solo quienes contestaron todos los ítems del modelo
# b) FIML: las 294 personas. Cada una aporta a la verosimilitud con los ítems
#    que sí contestó (missing = "fiml"), igual que Mplus con MLR.
# Tarda unos 4 minutos (las medidas robustas del modelo de 12 factores con FIML
# tardan más de 2).
ajustes <- lapply(modelos, function(m) {
  vars <- lavNames(cfa(m, data = guerrero, do.fit = FALSE), "ov")
  completos <- guerrero[complete.cases(guerrero[, vars]), ]
  list(listwise = cfa(m, data = completos, estimator = "MLR"),
       fiml = cfa(m, data = guerrero, estimator = "MLR", missing = "fiml"))
})
sapply(ajustes, function(a) sapply(a, lavInspect, "ntotal"))

# -----------------------------------------------------------------------
# Paso 4. Comparar ajuste y estimaciones
# -----------------------------------------------------------------------
medidas <- c("ntotal", "chisq.scaled", "df", "cfi.robust", "tli.robust",
             "rmsea.robust", "srmr")
ajuste <- do.call(rbind, lapply(names(ajustes), function(nm) {
  lw <- fitMeasures(ajustes[[nm]]$listwise, medidas)
  fi <- fitMeasures(ajustes[[nm]]$fiml, medidas)
  data.frame(modelo = nm, metodo = c("Listwise", "FIML"), rbind(unclass(lw), unclass(fi)))
}))
ajuste[, -(1:2)] <- round(ajuste[, -(1:2)], 3)
ajuste

# Diferencias en las cargas y correlaciones entre factores (estandarizadas) y
# cociente de errores estándar (FIML / listwise): menor que 1 = FIML más preciso
comparar_est <- function(a) {
  s1 <- standardizedSolution(a$listwise); s2 <- standardizedSolution(a$fiml)
  l1 <- s1[s1$op == "=~", ]; l2 <- s2[s2$op == "=~", ]
  c1 <- s1[s1$op == "~~" & s1$lhs != s1$rhs, ]; c2 <- s2[s2$op == "~~" & s2$lhs != s2$rhs, ]
  c(carga_media_listwise = mean(l1$est.std), carga_media_FIML = mean(l2$est.std),
    dif_max_cargas = max(abs(l1$est.std - l2$est.std)),
    cociente_EE_cargas = mean(l2$se / l1$se),
    dif_max_correlaciones = max(abs(c1$est.std - c2$est.std)))
}
estimaciones <- round(t(sapply(ajustes, comparar_est)), 3)
estimaciones
# Con FIML el ajuste es mejor y los errores estándar son menores (15% en el
# modelo de 12 factores): se usa a las 294 personas y no solo a las 160 que
# contestaron todo (que además no incluyen a nadie sin pareja).

# Cargas y errores estándar del modelo de 12 factores, lado a lado
solucion <- function(fit) {
  std <- standardizedSolution(fit)
  std <- std[std$op == "=~", ]
  data.frame(parametro = paste(std$lhs, std$op, std$rhs), est = std$est.std, ee = std$se)
}
cargas <- merge(solucion(ajustes[["12 factores"]]$listwise), solucion(ajustes[["12 factores"]]$fiml),
                by = "parametro", suffixes = c("_listwise", "_FIML"), sort = FALSE)
cargas[, -1] <- round(cargas[, -1], 3)
head(cargas, 8)

write.csv(ajuste, file.path(dir_salida, "ajuste_listwise_vs_FIML.csv"), row.names = FALSE)
write.csv(estimaciones, file.path(dir_salida, "estimaciones_listwise_vs_FIML.csv"))
write.csv(cargas, file.path(dir_salida, "cargas_listwise_vs_FIML.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Cobertura
# -----------------------------------------------------------------------
# Proporción de personas con información para cada par de ítems. Mplus pide
# al menos 0.10.
cobertura <- lavInspect(ajustes[["12 factores"]]$fiml, "coverage")
round(c(minima = min(cobertura), media = mean(cobertura[lower.tri(cobertura)])), 3)
sum(cobertura[lower.tri(cobertura)] < .70)      # pares con cobertura menor que .70
par_minimo <- which(cobertura == min(cobertura), arr.ind = TRUE)[1, ]
rownames(cobertura)[par_minimo]                 # el par con menos cobertura

# -----------------------------------------------------------------------
# Paso 6. Los faltantes de pareja son estructurales: ¿qué tanto importan?
# -----------------------------------------------------------------------
# Las 71 personas sin pareja no tienen satisfacción con la pareja: FIML (MAR)
# la trata como un dato faltante que podría haber existido. Si esas personas
# influyeran en el modelo, el modelo de satisfacción cambiaría al quitarlas.
# Se compara FIML con las 294 y FIML solo con las 223 con pareja.
fit_todos <- ajustes[["Satisfacción (6)"]]$fiml
fit_con <- cfa(modelo_sat, data = guerrero[!sin_pareja, ], estimator = "MLR", missing = "fiml")
s1 <- standardizedSolution(fit_todos); s2 <- standardizedSolution(fit_con)
l1 <- s1[s1$op == "=~", ]; l2 <- s2[s2$op == "=~", ]
c1 <- s1[s1$op == "~~" & s1$lhs != s1$rhs, ]; c2 <- s2[s2$op == "~~" & s2$lhs != s2$rhs, ]
con_pareja <- c1$lhs == "pareja" | c1$rhs == "pareja"
round(c(dif_max_cargas = max(abs(l1$est.std - l2$est.std)),
        dif_max_correlaciones = max(abs(c1$est.std - c2$est.std)),
        dif_max_correlaciones_con_pareja = max(abs(c1$est.std[con_pareja] - c2$est.std[con_pareja]))), 3)
round(c(cfi_294 = fitMeasures(fit_todos, "cfi.robust"),
        cfi_223 = fitMeasures(fit_con, "cfi.robust")), 3)
# Las diferencias son pequeñas (cargas hasta .05, correlaciones hasta .04):
# los 71 faltantes estructurales casi no mueven el modelo de medida.
