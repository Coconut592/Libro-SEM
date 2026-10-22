# =============================================================================
# Libro SEM · Violencia Veracruz
# 04 - Confiabilidad y validez: los seis ámbitos de violencia
# =============================================================================
# Sin referencia: Scripts.do no calcula confiabilidad ni validez. Se sigue el
# esquema de EMOVI (ítems 0/1): KR-20, confiabilidad compuesta (CR), AVE,
# Fornell-Larcker y HTMT, más el omega del factor general. Como criterio externo
# solo hay dos cosas: la clase latente c_r (que sale de estos mismos ítems, así
# que no es independiente) y las variables sociodemográficas del cuestionario.
#   source("Violencia_Veracruz/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)

dir_salida <- "Violencia_Veracruz/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo (igual que en 02_AFC y 03_AFC_2do_Orden)
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
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # 1,088 mujeres
modelo <- paste(sapply(names(factores), function(f) paste(f, "=~", paste(factores[[f]], collapse = " + "))),
                collapse = "\n")
fit <- cfa(modelo, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")

# =======================================================================
# CONFIABILIDAD
# =======================================================================

# -----------------------------------------------------------------------
# Paso 2. KR-20, confiabilidad compuesta (CR) y AVE
# -----------------------------------------------------------------------
# KR-20 = alfa de Cronbach con ítems 0/1 (las mujeres que contestan el bloque).
# CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)], con las cargas estandarizadas ordinales.
# AVE = promedio de λ²; se pide > .50.
s <- standardizedSolution(fit)
fi <- lavInspect(fit, "cor.lv")
conf <- do.call(rbind, lapply(names(factores), function(f) {
  l <- s$est.std[s$op == "=~" & s$lhs == f]
  data.frame(factor = f, k = length(l),
             n = sum(rowSums(!is.na(vera[, factores[[f]]])) == length(factores[[f]])),
             KR20 = suppressWarnings(psych::alpha(vera[, factores[[f]]], check.keys = FALSE))$total$raw_alpha,
             CR = sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), AVE = mean(l^2),
             r2_max = max(fi[f, rownames(fi) != f]^2))
}))
conf$AVE_supera_r2 <- conf$AVE > conf$r2_max
conf[, c("KR20", "CR", "AVE", "r2_max")] <- round(conf[, c("KR20", "CR", "AVE", "r2_max")], 3)
conf
# CR de .78 (COM) a .94 (INF): confiabilidad compuesta alta. El KR-20 es mucho más bajo
# en los ámbitos heterogéneos o con eventos raros: TRA .52 y COM .49 (menos de .60), FAM .65;
# INF .80, PAR .77 y ESC .72 están bien. El KR-20 supone que todos los ítems pesan igual, y
# aquí no (p193 y p194 cargan .47 mientras p191 y p192 cargan .86-.88), y con eventos raros
# las correlaciones entre ítems 0/1 están muy limitadas por sus frecuencias distintas.
# AVE: todos superan .50 salvo COM (.487, por p193 y p194). Fornell-Larcker: la AVE de
# cada factor supera su r² más alto con otro (de .20 a .36): se cumple en los seis.
write.csv(conf, file.path(dir_salida, "confiabilidad.csv"), row.names = FALSE)

# KR-20 por ítem: ¿algún ítem resta a su escala? (alfa si se elimina)
por_item <- do.call(rbind, lapply(names(factores), function(f) {
  a <- suppressWarnings(psych::alpha(vera[, factores[[f]]], check.keys = FALSE))
  data.frame(factor = f, item = factores[[f]], item_resto = a$item.stats$r.drop,
             KR20_sin_item = a$alpha.drop$raw_alpha, KR20_escala = a$total$raw_alpha)
}))
por_item[, 3:5] <- round(por_item[, 3:5], 3)
por_item[por_item$KR20_sin_item > por_item$KR20_escala, ]   # p144 (.80 -> .86), p165 (.65 -> .68) y p203 (.72 -> .74)
# Son tres ítems raros de infancia, familia y escuela (4.6%, 2.5% y 4.0%): en 0/1 se asocian poco
# con los demás de su bloque (r ítem-resto de .32 a .37), aunque en el AFC cargan fuerte (.77, .92
# y .79) porque la carga ordinal corrige por la baja frecuencia del evento.
write.csv(por_item, file.path(dir_salida, "kr20_por_item.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Confiabilidad del factor general (segundo orden)
# -----------------------------------------------------------------------
# a) CR de VIO con las cargas de segundo orden
# b) Omega total y omega jerárquico de la escala de 24 ítems (como en Habilidades Políticas):
#    cada ítem tiene una parte debida a VIO (carga del ítem x carga de su ámbito), otra
#    propia de su ámbito y un error. Con ítems ordinales son omegas "ordinales": se calculan
#    sobre las respuestas latentes (correlaciones policóricas implicadas por el modelo).
fit2 <- cfa(paste(modelo, "\n VIO =~ INF + FAM + PAR + TRA + COM + ESC"), data = vera, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
s2 <- standardizedSolution(fit2)
gamma <- setNames(s2$est.std[s2$lhs == "VIO" & s2$op == "=~"], s2$rhs[s2$lhs == "VIO" & s2$op == "=~"])
cr_VIO <- sum(gamma)^2 / (sum(gamma)^2 + sum(1 - gamma^2))
lambda <- setNames(s2$est.std[s2$op == "=~" & s2$rhs %in% items], s2$rhs[s2$op == "=~" & s2$rhs %in% items])[items]
ambito <- setNames(s2$lhs[s2$op == "=~" & s2$rhs %in% items], s2$rhs[s2$op == "=~" & s2$rhs %in% items])[items]
Sigma <- cov2cor(lavInspect(fit2, "implied")$cov)[items, items]
omega_total <- 1 - sum(1 - lambda^2) / sum(Sigma)
omega_jerarquico <- sum(lambda * gamma[ambito])^2 / sum(Sigma)
omegas <- round(c(CR_VIO = cr_VIO, omega_total = omega_total, omega_jerarquico = omega_jerarquico,
                  proporcion_por_VIO = omega_jerarquico / omega_total), 3)
omegas
# CR del factor general .83. Omega total .97 y omega jerárquico .79: el 82% de la confiabilidad
# de la escala de 24 ítems se debe al factor general (en Habilidades Políticas fue el 92%). Ojo:
# son omegas sobre las respuestas latentes (ordinales) y son optimistas; la confiabilidad de una
# suma simple de ítems 0/1 con eventos raros es mucho menor (ver el KR-20 de cada ámbito).
write.csv(data.frame(indicador = names(omegas), valor = as.numeric(omegas)),
          file.path(dir_salida, "omega_factor_general.csv"), row.names = FALSE)

# =======================================================================
# VALIDEZ
# =======================================================================

# -----------------------------------------------------------------------
# Paso 4. Validez de contenido (cualitativa)
# -----------------------------------------------------------------------
# No se calcula: se argumenta. Los 24 ítems cubren seis ámbitos de violencia contra las mujeres
# (infancia, familia, pareja, trabajo, comunidad, escuela) y, dentro de ellos, formas distintas
# (emocional, física, sexual, económica). Pero la base trae una SELECCIÓN de los reactivos
# del cuestionario (faltan p163, p164, p174, p181 y p182) y las etiquetas de Stata están cortadas
# a 80 caracteres: la cobertura real solo se puede juzgar con el cuestionario.

# -----------------------------------------------------------------------
# Paso 5. Validez discriminante: HTMT (correlaciones policóricas)
# -----------------------------------------------------------------------
# HTMT = promedio de las correlaciones entre ítems de dos factores / raíz del producto de los
# promedios de las correlaciones dentro de cada factor. Se pide < .85 (estricto) o < .90.
R <- lavCor(vera[, items], ordered = items, missing = "pairwise")
dentro <- function(v) mean(R[v, v][lower.tri(R[v, v])])
htmt <- function(a, b) mean(R[factores[[a]], factores[[b]]]) / sqrt(dentro(factores[[a]]) * dentro(factores[[b]]))
parejas <- t(combn(names(factores), 2))
tabla_htmt <- data.frame(par = paste(parejas[, 1], parejas[, 2], sep = " - "),
                         r_factores = round(mapply(function(a, b) fi[a, b], parejas[, 1], parejas[, 2]), 2),
                         HTMT = round(mapply(htmt, parejas[, 1], parejas[, 2]), 2))
tabla_htmt[order(-tabla_htmt$HTMT), ][1:5, ]
max(tabla_htmt$HTMT)
# HTMT máximo .61 (FAM-TRA; INF-FAM .60): muy por debajo de .85. Los seis ámbitos se distinguen
# con claridad, con las dos pruebas (HTMT y Fornell-Larcker).
write.csv(tabla_htmt, file.path(dir_salida, "htmt.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. Validez convergente con la clase latente c_r
# -----------------------------------------------------------------------
# c_r (1 = poca violencia, 2 = violencia sobre todo en la infancia, 3 = violencia en varios
# ámbitos) sale del análisis de clases latentes de estos mismos 24 ítems (Mplus). Entonces
# NO es un criterio independiente: sirve para ver que los puntajes factoriales y las clases
# cuentan la misma historia, no para probar que la escala mide violencia.
puntajes <- as.data.frame(lavPredict(fit2, method = "EBM"))
puntajes <- puntajes[, c("INF", "FAM", "PAR", "TRA", "COM", "ESC", "VIO")]
sin_datos <- sapply(factores, function(it) rowSums(!is.na(vera[, it])) == 0)
for (f in names(factores)) puntajes[sin_datos[, f], f] <- NA   # sin ítems del ámbito, sin puntaje propio
medias_clase <- round(sapply(puntajes, function(p) tapply(p, vera$c_r, mean, na.rm = TRUE)), 2)
medias_clase
# VIO sube con la clase: -0.05, 0.43 y 0.82. INF es la excepción esperada: es MÁS alta en la clase 2
# (infancia) que en la 3 (.91 contra .74). PAR, FAM, TRA, COM y ESC suben de la clase 1 a la 3
# (PAR: -.03, .23 y 1.13).
eta2 <- sapply(puntajes, function(p) { a <- anova(lm(p ~ factor(vera$c_r))); a$"Sum Sq"[1] / sum(a$"Sum Sq") })
round(eta2, 2)                               # VIO .66, INF .74, PAR .62, TRA .50, FAM .48, COM .35, ESC .31
write.csv(medias_clase, file.path(dir_salida, "puntajes_por_clase.csv"))

# -----------------------------------------------------------------------
# Paso 7. Correlatos sociodemográficos (exploratorio)
# -----------------------------------------------------------------------
# Scripts.do los corre contra c_r (ologit). Aquí contra el puntaje general VIO. Sin hipótesis
# previas fijas, se espera lo habitual en la literatura: más violencia con menos escolaridad y
# con menos alfabetización. Es una revisión de signos, no una prueba de criterio.
criterios <- data.frame(
  escolaridad = ifelse(vera$p4 == 6, NA, vera$p4),   # 1 ninguna ... 5 universidad ("otro" fuera)
  lee_y_escribe = vera$p3, indigena = vera$p1, edad_grupo = vera$p2,
  recibe_dinero = vera$p7, conoce_derechos = vera$p62, edad_primer_embarazo = vera$p13)
validez <- data.frame(criterio = names(criterios),
  spearman = round(sapply(criterios, function(y) cor(puntajes$VIO, y, use = "pairwise.complete.obs", method = "spearman")), 2),
  p = round(sapply(criterios, function(y) cor.test(puntajes$VIO, y, method = "spearman", exact = FALSE)$p.value), 3),
  n = sapply(criterios, function(y) sum(!is.na(y) & !is.na(puntajes$VIO))))
rownames(validez) <- NULL
validez
# Edad al primer embarazo -.21 y escolaridad -.20 (menos violencia con más estudios y con un
# primer embarazo más tardío), leer y escribir -.11, conocer los derechos de las mujeres -.07,
# recibir dinero de alguien +.07, indígena +.06 (p = .06) y edad +.04 (n.s.). Las direcciones
# coinciden con las razones de momios de Scripts.do (00_Diagnostico). Las correlaciones son bajas
# (|rho| ≤ .21): son asociaciones débiles, no una prueba de criterio.
write.csv(validez, file.path(dir_salida, "correlatos_sociodemograficos.csv"), row.names = FALSE)
