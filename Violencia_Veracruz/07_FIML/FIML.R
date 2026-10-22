# =============================================================================
# Libro SEM · Violencia Veracruz
# 07 - FIML: los seis ámbitos con datos faltantes
# =============================================================================
# Sin referencia propia. Siguiendo EMOVI (indicadores 0/1) y Violencia Guerrero (faltantes
# por bloques), se compara el AFC de seis ámbitos con eliminación por lista (listwise)
# y con FIML. Aquí solo 505 de 1,088 mujeres contestan los 24 ítems, y los faltantes
# no son esporádicos: son SALTOS de pregunta (pareja, trabajo, escuela). lavaan no ofrece
# FIML con ítems ordinales (probado: `missing = "fiml" not available in the categorical
# setting`), así que aquí los 0/1 se tratan como continuos (MLR + FIML), como en EMOVI.
#   source("Violencia_Veracruz/07_FIML/FIML.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Veracruz/07_FIML/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. ¿Cuántos datos faltan y dónde?
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
factores <- list(
  INF = c("p141", "p142", "p143", "p144"),
  FAM = c("p161", "p162", "p165"),
  PAR = c("p171", "p172", "p173", "p175", "p176"),
  TRA = c("p183", "p184", "p185", "p186"),
  COM = c("p191", "p192", "p193", "p194"),
  ESC = c("p201", "p202", "p203", "p204"))
items <- unlist(factores, use.names = FALSE)
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # 1,088 mujeres (id 907 no tiene ítems)
datos <- vera[, items]

round(100 * mean(is.na(datos)), 1)           # 11.1% de las celdas
sum(complete.cases(datos))                   # solo 505 de 1,088 (46%) contestan los 24 ítems
sin_bloque <- sapply(factores, function(it) rowSums(!is.na(vera[, it])) == 0)
faltantes <- data.frame(ambito = names(factores), n_sin_ningun_item = colSums(sin_bloque),
                        pct = round(100 * colMeans(sin_bloque), 1), row.names = NULL)
faltantes                                    # pareja 313 (28.8%), trabajo 249 (22.9%), escuela 57 (5.2%); el resto, < 1%
write.csv(faltantes, file.path(dir_salida, "faltantes.csv"), row.names = FALSE)

# Patrones de faltantes por bloque de contenido
patron <- apply(sin_bloque, 1, function(r) if (any(r)) paste(names(factores)[r], collapse = " + ") else "ninguno")
sort(table(patron), decreasing = TRUE)[1:6]  # ninguno 536, pareja 272, trabajo 195, trabajo + escuela 25, pareja + trabajo 20, escuela 14
# Con listwise se pierde el 54% de la muestra: y con ella, todas las mujeres sin pareja, sin trabajo
# o sin estudios (justo las que no pueden contestar esos bloques).

# -----------------------------------------------------------------------
# Paso 2. ¿Son faltantes al azar?
# -----------------------------------------------------------------------
# FIML es insesgado si los datos son MCAR o MAR (la probabilidad de faltar depende solo de lo
# observado); listwise exige MCAR. La prueba de Little (1988) supone normalidad multivariada y
# NO es válida con ítems 0/1, así que no se usa (en Violencia Guerrero sí, con escalas de 1 a 10).
# a) Si faltar fuera independiente de lo observado, quien se salta un bloque no debería responder
#    distinto en los demás ítems (chi2 por ítem; por azar ~5% con p < .05).
probar <- function(falta, otros) {
  p <- sapply(otros, function(v) {
    ok <- !is.na(vera[[v]]); tt <- table(falta[ok], vera[[v]][ok])
    if (any(dim(tt) < 2)) NA else suppressWarnings(chisq.test(tt)$p.value) })
  c(n_falta = sum(falta), items_comparados = sum(!is.na(p)), p_menor_05 = sum(p < .05, na.rm = TRUE),
    esperados_azar = round(.05 * sum(!is.na(p)), 1))
}
prueba_azar <- t(sapply(c("PAR", "TRA", "ESC"), function(b) probar(sin_bloque[, b], setdiff(items, factores[[b]]))))
prueba_azar
# Sin pareja: 1 de 19 (lo esperado). Sin trabajo: 8 de 20. Sin escuela: 4 de 20. Quien nunca trabajó
# reporta MÁS violencia (infancia: p142 .35 contra .24; pareja: p172 .14 contra .06; p173 .10 contra
# .03): no es MCAR, y eliminar por lista subestimaría la violencia.
write.csv(prueba_azar, file.path(dir_salida, "faltantes_vs_resto.csv"))

# b) Qué explica los saltos: son de cuestionario, así que dependen de variables OBSERVADAS.
#    % que se salta el bloque según la condición que lo explica:
#    pareja: p9 (estado civil; con pareja = 5 unión libre o 6 casada); trabajo: p5 (2 = ama de casa);
#    escuela: p4 (1 = sin estudios).
pct_salta <- function(falta, condicion)
  round(100 * c(si = mean(falta[which(condicion)]), no = mean(falta[which(!condicion)])), 1)
rbind(`pareja: sin pareja actual / con pareja` = pct_salta(sin_bloque[, "PAR"], vera$p9 %in% 1:4),
      `trabajo: ama de casa / otra ocupación`   = pct_salta(sin_bloque[, "TRA"], vera$p5 == 2),
      `escuela: sin estudios / con estudios`     = pct_salta(sin_bloque[, "ESC"], vera$p4 == 1))
# Pareja: la salta el 87.2% de las que no tienen pareja actual y el 0.8% de las que sí. Escuela: el
# 29% de las que no tienen estudios contra el 1% de las demás. Trabajo: el 40% de las amas de casa
# contra el 7% de las demás (varias amas de casa sí trabajaron alguna vez, y viceversa).
# Eso es MAR, no MNAR: depende de lo observado. FIML es defendible, pero p9, p5 y p4 NO están en el
# modelo (podrían entrar como variables auxiliares) y, sobre todo, el salto significa que el
# constructo no aplica (ver el paso 6).

# -----------------------------------------------------------------------
# Paso 3. Listwise contra FIML (MLR; ítems 0/1 como continuos)
# -----------------------------------------------------------------------
modelo <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  TRA =~ p183 + p184 + p185 + p186
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'
completos <- vera[complete.cases(datos), ]
fit_lw   <- cfa(modelo, data = completos, estimator = "MLR", std.lv = TRUE)                      # listwise
# Con FIML lavaan avisa que la matriz de varianzas de los parámetros es casi singular: con ítems 0/1 la
# varianza de un ítem es función de su media (p(1-p)), así que hay dependencia exacta entre momentos. Las
# estimaciones y el ajuste no cambian; los errores estándar son aproximados (ver el paso 4).
fit_fiml <- suppressWarnings(cfa(modelo, data = vera, estimator = "MLR", std.lv = TRUE, missing = "fiml"))
# Referencia: el AFC ordinal de 02_AFC (WLSMV, pairwise)
fit_ord  <- cfa(modelo, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit_fiml, "converged")            # TRUE

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit_lw, "Listwise (MLR)"), ajuste(fit_fiml, "FIML (MLR)"))
tabla_ajuste
# N: 505 contra 1,088 (2.2 veces más casos). El ajuste de FIML es MEJOR: CFI .949 contra .903, RMSEA
# .034 contra .045 (con 0/1 como continuos, ninguno llega al .987 del AFC ordinal; es otra métrica).
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_listwise_vs_fiml.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y errores estándar
# -----------------------------------------------------------------------
carga <- function(f) { s <- standardizedSolution(f); s[s$op == "=~", "est.std"] }
ee <- function(f) { p <- parameterEstimates(f); p[p$op == "=~", "se"] }
comparacion <- data.frame(item = items, factor = rep(names(factores), lengths(factores)),
                          carga_listwise = round(carga(fit_lw), 2), carga_FIML = round(carga(fit_fiml), 2),
                          carga_ordinal = round(carga(fit_ord), 2),
                          ee_listwise = round(ee(fit_lw), 3), ee_FIML = round(ee(fit_fiml), 3))
comparacion$razon_ee <- round(comparacion$ee_FIML / comparacion$ee_listwise, 2)
comparacion
# Las cargas cambian poco en infancia, pareja y escuela (hasta .06) y más en los ítems raros
# (p165 .36 contra .48, p192 .47 contra .60, p193 .38 contra .24, p185 .64 contra .53: hasta .15).
# Los errores estándar de FIML son ~.68 de los de listwise (de .34 en p193 a .90 en p186): se gana
# precisión. Con otra matriz de información
# (expected, h1 sin estructura) el cociente es .73: la ganancia no depende de ese detalle.
# La carga ordinal (WLSMV) es mayor (.47-.96): las correlaciones 0/1 de Pearson están acotadas por
# las frecuencias de los ítems. No son comparables entre métricas, solo entre listwise y FIML.
round(mean(comparacion$razon_ee), 2)
write.csv(comparacion, file.path(dir_salida, "cargas_listwise_vs_fiml.csv"), row.names = FALSE)

# Correlaciones entre factores: listwise y FIML
cor_fiml <- round(lavInspect(fit_fiml, "cor.lv"), 2)
cor_lw <- round(lavInspect(fit_lw, "cor.lv"), 2)
round(max(abs(cor_fiml - cor_lw)), 2)        # hasta .14
cor_fiml                                     # de .18 a .46 (más bajas que las ordinales: con 0/1 como continuos se atenúan)

# -----------------------------------------------------------------------
# Paso 5. Cobertura
# -----------------------------------------------------------------------
# Proporción de mujeres con información para cada par de ítems (Mplus pide al menos .10).
cobertura <- lavInspect(fit_fiml, "coverage")
round(c(minima = min(cobertura), media = mean(cobertura[lower.tri(cobertura)])), 3)   # .505 y .801
sum(cobertura[lower.tri(cobertura)] < .70)   # 41 de 276 parejas con cobertura menor que .70 (pareja con trabajo)
par_minimo <- which(cobertura == min(cobertura), arr.ind = TRUE)[1, ]
rownames(cobertura)[par_minimo]              # p183 y p173: trabajo con pareja

# -----------------------------------------------------------------------
# Paso 6. Los faltantes de pareja son estructurales: ¿qué tanto importan?
# -----------------------------------------------------------------------
# A las 313 mujeres sin pareja FIML (MAR) les trata el bloque de pareja como un dato que PODRÍA
# haber existido. Si pesaran en el modelo, los resultados cambiarían al quitarlas. Se compara FIML
# con las 1,088 y FIML solo con las 775 con pareja.
con_pareja <- vera[!sin_bloque[, "PAR"], ]
fit_con <- suppressWarnings(cfa(modelo, data = con_pareja, estimator = "MLR", std.lv = TRUE, missing = "fiml"))
s1 <- standardizedSolution(fit_fiml); s2 <- standardizedSolution(fit_con)
l1 <- s1[s1$op == "=~", ]; l2 <- s2[s2$op == "=~", ]
c1 <- s1[s1$op == "~~" & s1$lhs != s1$rhs, ]; c2 <- s2[s2$op == "~~" & s2$lhs != s2$rhs, ]
con_PAR <- c1$lhs == "PAR" | c1$rhs == "PAR"
sensibilidad <- c(N_todas = lavInspect(fit_fiml, "nobs"), N_con_pareja = lavInspect(fit_con, "nobs"),
                  dif_max_cargas = max(abs(l1$est.std - l2$est.std)),
                  dif_max_correlaciones = max(abs(c1$est.std - c2$est.std)),
                  dif_max_correlaciones_con_PAR = max(abs(c1$est.std - c2$est.std)[con_PAR]),
                  cfi_todas = unname(fitMeasures(fit_fiml, "cfi.robust")), cfi_con_pareja = unname(fitMeasures(fit_con, "cfi.robust")))
round(sensibilidad, 3)
dif_cargas <- setNames(abs(l1$est.std - l2$est.std), l1$rhs)
round(sort(dif_cargas, decreasing = TRUE)[1:3], 3)   # los ítems que más se mueven
# Las cargas cambian hasta .12 (p185; luego p194 .085 y p184 .062: ítems raros) y las correlaciones entre
# factores hasta .12 (hasta .04 las de PAR); el CFI baja de .949 a .930. El modelo de medida se mueve poco.
# Es un resultado sobre el MODELO DE MEDIDA, no sobre la prevalencia de violencia de pareja:
# FIML nunca debe leerse como "la violencia de pareja de las mujeres sin pareja".
write.csv(data.frame(indicador = names(sensibilidad), valor = round(as.numeric(sensibilidad), 3)),
          file.path(dir_salida, "sensibilidad_con_pareja.csv"), row.names = FALSE)
