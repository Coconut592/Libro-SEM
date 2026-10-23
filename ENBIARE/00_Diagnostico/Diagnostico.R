# =============================================================================
# Libro SEM · ENBIARE
# 00 - Diagnóstico: ¿se pueden hacer los 7 ejercicios con lo que se tiene?
# =============================================================================
# Referencias: base `conjunto_de_datos_tenbiare_enbiare_2021.csv` y su
# diccionario `diccionario_datos_tenbiare_enbiare_2021.csv` (Encuesta Nacional
# de Bienestar Autorreportado, ENBIARE 2021, INEGI: Cuestionario de Bienestar
# Autorreportado). No hay documento de referencia (tesis, capítulo, .inp), así
# que los modelos salen del contenido de los ítems y de un AFE previo.
# Este script no es parte del libro: revisa qué trae la base, qué bloques de
# ítems sirven para cada ejercicio y prueba cada ejercicio con la base real.
# Tarda unos 4 minutos (casi todo, los puntajes por patrón y la invarianza ordinal).
#   source("ENBIARE/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(psych)
library(GPArotation)
library(lavaan)

dir_datos  <- "ENBIARE/data"
dir_salida <- "ENBIARE/00_Diagnostico/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Leer la base y el diccionario
# -----------------------------------------------------------------------
# La base viene en latin1 y con los nombres en MAYÚSCULAS; el diccionario, en
# UTF-8 con BOM y con los nombres en minúsculas. Hay que fijar quote = "\"":
# los textos libres (pf14_*_esp) traen apóstrofos y con el quote por defecto
# R deja de leer en el primer renglón.
enb <- read.csv(file.path(dir_datos, "conjunto_de_datos_tenbiare_enbiare_2021.csv"),
                fileEncoding = "latin1", na.strings = c("", " "), quote = "\"",
                comment.char = "", stringsAsFactors = FALSE)
names(enb) <- tolower(names(enb))
dic <- read.csv(file.path(dir_datos, "diccionario_datos_tenbiare_enbiare_2021.csv"),
                fileEncoding = "UTF-8-BOM", quote = "\"", stringsAsFactors = FALSE)
names(dic) <- c("campo", "longitud", "tipo", "variable", "catalogo", "rango")
dim(enb)                                     # 31,166 personas y 284 variables
dim(dic)                                     # 284 variables descritas

# -----------------------------------------------------------------------
# Paso 2. ¿La base y el diccionario dicen lo mismo?
# -----------------------------------------------------------------------
setequal(names(enb), dic$variable)           # TRUE: las mismas 284 variables
table(dic$tipo)                              # todas "C" (carácter) aunque casi todas son numéricas
# El diccionario NO trae etiquetas de valor: la columna `catalogo` solo repite el
# nombre de la variable (273) o está vacía (11). No se sabe qué dice cada código.
c(repite_nombre = sum(dic$catalogo == dic$variable), vacio = sum(dic$catalogo == ""))

# Los rangos de `rango_claves` (p. ej. "00…10", "1,2", "1…4,9") contra lo observado
permitidos <- function(r) {
  unlist(lapply(strsplit(r, ",")[[1]], function(p) {
    m <- regmatches(p, regexec("^([0-9]+)(…|\\.\\.\\.)([0-9]+)$", trimws(p)))[[1]]
    if (length(m) == 4) seq(as.numeric(m[2]), as.numeric(m[4])) else suppressWarnings(as.numeric(p))
  }))
}
numericas <- dic[!grepl("[A-Za-z@]", dic$rango) & dic$variable != "pf2", ]   # pf2 es un monto de 7 dígitos
revision <- do.call(rbind, lapply(seq_len(nrow(numericas)), function(i) {
  v <- numericas$variable[i]; ok <- permitidos(numericas$rango[i]); obs <- sort(unique(na.omit(enb[[v]])))
  data.frame(variable = v, rango = numericas$rango[i], fuera_de_rango = paste(setdiff(obs, ok), collapse = ","),
             sin_observar = paste(setdiff(ok, obs), collapse = ","))
}))
sum(revision$fuera_de_rango != "")           # 0: ningún valor fuera del rango del diccionario
# Categorías declaradas que nadie contestó. Las que importan para los ítems de bienestar:
# `pd1_1`, `pd1_2` y `pd1_6` (la 4.ª), `pb2_2` (la 3.ª) y `ph1_*`/`ph2_*` (la 3.ª; solo salen 1, 2 y 9).
subset(revision, sin_observar != "" & grepl("^(pb|pd|ph)", variable))[, c("variable", "rango", "sin_observar")]

# -----------------------------------------------------------------------
# Paso 3. Estructura de la base y diseño muestral
# -----------------------------------------------------------------------
# Una fila por PERSONA SELECCIONADA (no por hogar ni por integrante). La llave es
# (folio, hogar): `folio` identifica la vivienda y se repite cuando hay varios hogares.
nrow(unique(enb[, c("folio", "hogar")]))     # 31,166: la llave no se repite
length(unique(enb$folio))                    # 30,822 folios (viviendas)
table(table(enb$folio))                      # 30,522 con una persona; 300 folios con 2 a 5 (dependencia mínima)
# NO hay sexo, edad, escolaridad ni ningún dato del encuestado. Los únicos grupos
# disponibles son `ent` (32 entidades, de 906 a 1,037 personas) y `tloc` (4 tamaños de
# localidad; sin etiquetas: se supone 1 = 100 mil o más ... 4 = menos de 2,500).
range(table(enb$ent)); table(enb$tloc)

# Diseño muestral: estrato (`est_dis`), UPM (`upm_dis`) y ponderador (`fac_ele`)
c(estratos = length(unique(enb$est_dis)), UPM = length(unique(enb$upm_dis)),
  personas_por_UPM = round(nrow(enb) / length(unique(enb$upm_dis)), 1))   # 472, 4,704 y 6.6
summary(enb$fac_ele)                         # de 122 a 45,955; suma 84.4 millones
w <- enb$fac_ele
deff_pesos <- length(w) * sum(w^2) / sum(w)^2        # efecto de pesos desiguales (Kish)
round(deff_pesos, 2)                         # 2.23

# Correlación intraclase por UPM (ANOVA de un factor, fórmula directa)
icc1 <- function(v, g) {
  g <- factor(g); n <- length(v); k <- nlevels(g); ng <- tabulate(g)
  mg <- tapply(v, g, mean); ssb <- sum(ng * (mg - mean(v))^2); ssw <- sum((v - mg[g])^2)
  msb <- ssb / (k - 1); msw <- ssw / (n - k); n0 <- (n - sum(ng^2) / n) / (k - 1)
  (msb - msw) / (msb + (n0 - 1) * msw)
}
it_icc <- c(sprintf("pa3_%02d", 1:17), sprintf("pa4_%02d", 1:10), sprintf("pb1_%02d", 1:12))
icc <- sapply(it_icc, function(v) icc1(enb[[v]], enb$upm_dis))
round(c(mediana = median(icc), min = min(icc), max = max(icc)), 3)   # .025 (de .005 a .102)
round(1 + (nrow(enb) / length(unique(enb$upm_dis)) - 1) * median(icc), 2)   # efecto de diseño ~1.14

# ¿Cambia el AFC si se toma en cuenta el diseño? (PA3, 5 factores, MLR)
m_pa3 <- '
  NIV =~ pa3_01 + pa3_02 + pa3_03 + pa3_08
  REL =~ pa3_04 + pa3_05 + pa3_06 + pa3_07
  AUT =~ pa3_09 + pa3_10 + pa3_12
  BAR =~ pa3_13 + pa3_14
  CIU =~ pa3_11 + pa3_15 + pa3_16 + pa3_17'
f_sin <- cfa(m_pa3, enb, estimator = "MLR")
f_upm <- cfa(m_pa3, enb, estimator = "MLR", cluster = "upm_dis")
f_pes <- cfa(m_pa3, enb, estimator = "MLR", sampling.weights = "fac_ele")
ep <- function(f) { p <- parameterEstimates(f); p$se[p$op == "=~" & p$se > 0] }
cl <- function(f) standardizedSolution(f)$est.std[standardizedSolution(f)$op == "=~"]
diseno <- data.frame(
  razon_EE_UPM    = round(mean(ep(f_upm) / ep(f_sin)), 2),
  razon_EE_pesos  = round(mean(ep(f_pes) / ep(f_sin)), 2),
  dif_max_cargas_pesos = round(max(abs(cl(f_pes) - cl(f_sin))), 3),
  CFI_sin = round(as.numeric(fitMeasures(f_sin, "cfi.robust")), 3),
  CFI_UPM = round(as.numeric(fitMeasures(f_upm, "cfi.robust")), 3),
  CFI_pesos = round(as.numeric(fitMeasures(f_pes, "cfi.robust")), 3))
diseno
# El cluster por UPM no mueve los errores estándar (x1.01); ponderar los sube x1.45, pero cambia
# las cargas estandarizadas en .014 como máximo y el CFI en .002 (.952 contra .950): para la
# ESTRUCTURA factorial el diseño casi no importa; para medias poblacionales sí (por eso los
# ejercicios se hacen sin ponderador, como EMOVI, y el ponderador queda para estimar niveles).
write.csv(diseno, file.path(dir_salida, "efecto_diseno.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Faltantes y códigos especiales
# -----------------------------------------------------------------------
na <- colSums(is.na(enb))
c(sin_faltantes = sum(na == 0), con_faltantes = sum(na > 0))   # 214 y 70
# Los bloques de bienestar (pa, pb, pc1 a pc3, pd) no tienen NINGÚN faltante. Los
# faltantes de las demás son saltos de pregunta (sólo a quien trabaja, quien tiene
# pareja, quien contestó "sí" en pf7...), no no-respuesta:
resumen_na <- data.frame(variable = names(na), n_na = as.numeric(na), pct = round(100 * na / nrow(enb), 1))
resumen_na <- resumen_na[resumen_na$n_na > 0, ]
resumen_na$pregunta <- sub("_[0-9]+$", "", resumen_na$variable)       # pf8_01 ... pf8_16 -> pf8
aggregate(pct ~ pregunta, resumen_na, function(x) c(vars = length(x), min = min(x), max = max(x)))
write.csv(resumen_na[order(-resumen_na$n_na), ], file.path(dir_salida, "faltantes_por_variable.csv"), row.names = FALSE)
# Los saltos se comprueban en la base:
table(faltan_de_los_8 = rowSums(is.na(enb[, paste0("pe10_", 1:8)])))   # 0 u 8: el bloque falta junto (17,589)
all(is.na(enb[, sprintf("pf8_%02d", 1:16)]) == (enb[, sprintf("pf7_%02d", 1:16)] != 1))   # pf8 solo si pf7 = sí
all(is.na(enb$ph1_4) == is.na(enb$ph2_4))    # ph1_4 y ph2_4 comparten los mismos 4,302 blancos
# Códigos especiales: el diccionario declara 9 ("no sabe") en pf3, pe16 y los 8 ítems
# ph1_* / ph2_*, y 99 en pe18_*. NO hay 99 en las escalas 0-10: no hay "Ns/Nc" que recodificar.
dic$variable[grepl(",9$|,99$", dic$rango)]
# Los ítems Sí/No son 1 y 2 (1 = sí, por las frecuencias: p. ej. pf7, discriminación, 1 = 0.8%-9.2%).
# Se recodifican a 1/0 y el 9 pasa a NA en las pruebas de abajo.

# -----------------------------------------------------------------------
# Paso 5. Bloques candidatos para los ejercicios
# -----------------------------------------------------------------------
# Se pasan a 1/0 los ítems Sí/No y a NA los códigos 9 ("no sabe").
sino <- c(paste0("pc1_", 1:7), sprintf("pf7_%02d", 1:16), paste0("pe10_", 1:8), paste0("pf1_", 1:6),
          paste0("pf4_", 1:9), sprintf("pj6_%02d", 1:13), paste0("pg1_", 1:8), paste0("ph1_", 1:4), paste0("ph2_", 1:4))
for (v in sino) { enb[[v]][enb[[v]] == 9] <- NA; enb[[v]] <- ifelse(enb[[v]] == 1, 1, 0) }
enb$pd2_6r <- 3 - enb$pd2_6                  # "disfrutó de la vida" es positivo: se invierte (0-3)
enb$tloc_g <- factor(enb$tloc)

b <- function(nombre, items, escala, tipo, nota) list(nombre = nombre, items = items, escala = escala, tipo = tipo, nota = nota)
bloques <- list(
  PA3 = b("Satisfacción con 17 aspectos de la vida", sprintf("pa3_%02d", 1:17), "0-10", "cont", "Candidato principal"),
  PA4 = b("Afecto del día de ayer (5 positivos y 5 negativos)", sprintf("pa4_%02d", 1:10), "0-10", "cont", "Candidato"),
  PA1 = b("Evaluación de la vida (pa1, pa2, pa5, pa6)", c("pa1", "pa2", "pa5", "pa6"), "0-10", "cont", "Débil por sí sola: 4 ítems heterogéneos"),
  PB1 = b("Confianza en personas e instituciones", sprintf("pb1_%02d", 1:12), "0-10", "cont", "Candidato"),
  PD2 = b("Depresión (CESD-7) y ansiedad (GAD-2)", c(paste0("pd2_", c(1:5, 7)), "pd2_6r", paste0("pd3_", 1:2)), "0-3", "ord", "Candidato (ordinal)"),
  PC3 = b("Reuniones sociales con 8 grupos", paste0("pc3_", 1:8), "1-5", "ord", "Candidato (ordinal)"),
  PC2 = b("Uso de 5 redes sociales", paste0("pc2_", 1:5), "1-5", "ord", "Candidato (ordinal)"),
  PD1 = b("Dificultades funcionales", paste0("pd1_", 1:6), "1-4", "ord", "Ítems casi constantes (90-96% en la 1.ª categoría)"),
  PH  = b("Dificultades y alegrías por etapa de vida", c(paste0("ph1_", 1:4), paste0("ph2_", 1:4)), "Sí/No", "bin", "Único con faltantes reales (FIML)"),
  PC1 = b("Actividades de la semana", paste0("pc1_", 1:7), "Sí/No", "bin", "Sin estructura (KMO .60)"),
  PF7 = b("Discriminación alguna vez (16 motivos)", sprintf("pf7_%02d", 1:16), "Sí/No", "bin", "Los 16 ítems con < 10%"),
  PE10 = b("Prestaciones laborales (solo ocupados)", paste0("pe10_", 1:8), "Sí/No", "bin", "Un solo factor; 56% faltante por diseño"),
  PF1 = b("Pidió prestado para 6 gastos", paste0("pf1_", 1:6), "Sí/No", "bin", "Un factor; ítems 6%-29%"),
  PF4 = b("Eventos negativos propios (9)", paste0("pf4_", 1:9), "Sí/No", "bin", "Lista de eventos: no es reflectivo"),
  PJ6 = b("Gustos musicales (13 géneros)", sprintf("pj6_%02d", 1:13), "Sí/No", "bin", "No es bienestar; ajuste pobre"),
  PG1 = b("Pertenencia a 8 tipos de organización", paste0("pg1_", 1:8), "Sí/No", "bin", "Prevalencias de 0.3% a 5.8%"))

matriz_cor <- function(x, tipo) suppressWarnings(suppressMessages(switch(tipo,
  cont = cor(x, use = "pairwise.complete.obs"), ord = polychoric(x)$rho, bin = tetrachoric(x)$rho)))
RNGkind("L'Ecuyer-CMRG")                     # fa.parallel simula en varios núcleos: así la semilla es reproducible
set.seed(2021)
tabla_bloques <- do.call(rbind, lapply(names(bloques), function(n) {
  bl <- bloques[[n]]; x <- enb[, bl$items]; r <- matriz_cor(x, bl$tipo)
  modal <- sapply(x, function(v) 100 * max(table(v)) / sum(!is.na(v)))
  ev <- eigen(r)$values
  f1 <- suppressWarnings(fa(r, nfactors = 1, n.obs = nrow(x), fm = if (bl$tipo == "cont") "ml" else "minres"))
  ap <- invisible(capture.output(pa <- suppressWarnings(fa.parallel(r, n.obs = sum(complete.cases(x)), fa = "fa",
        fm = if (bl$tipo == "cont") "ml" else "minres", n.iter = 100, plot = FALSE))))
  data.frame(bloque = n, descripcion = bl$nombre, k = length(bl$items), escala = bl$escala, tipo = bl$tipo,
             n_completos = sum(complete.cases(x)), pct_faltante = round(100 * mean(is.na(as.matrix(x))), 1),
             pct_modal_medio = round(mean(modal), 1), items_mas_90 = sum(modal > 90),
             asimetria_max = round(max(abs(sapply(x, psych::skew, na.rm = TRUE))), 1),
             KMO = round(KMO(r)$MSA, 2), Kaiser = sum(ev > 1), paralelo = pa$nfact,
             RMSEA_1f = round(as.numeric(f1$RMSEA[1]), 3), TLI_1f = round(f1$TLI, 3), nota = bl$nota)
}))
rownames(tabla_bloques) <- NULL
tabla_bloques[, c("bloque", "k", "escala", "n_completos", "pct_faltante", "pct_modal_medio", "items_mas_90",
                  "asimetria_max", "KMO", "Kaiser", "paralelo", "RMSEA_1f", "TLI_1f")]
# Los bloques 0-10 (PA3, PA4, PB1) y PD2 y PC3 tienen respuestas repartidas (categoría modal de
# 20% a 59%) y KMO >= .86; los Sí/No casi todos están por arriba de 70% en una categoría y PF7,
# PG1 y PF4 tienen ítems con más de 90% en una (el criterio 90-10 de la tesis de EMOVI los saca).
write.csv(tabla_bloques, file.path(dir_salida, "bloques_candidatos.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. Prueba de cada ejercicio en los bloques candidatos
# -----------------------------------------------------------------------
# Estimador: los bloques 0-10 son casi continuos (11 categorías) y se tratan como tales
# con MLR (como PREP, que usó escalas 1-10); los de 3 a 5 categorías, ordinales con WLSMV.
# Estructuras: las propone el AFE de cada bloque (cargas en output/); se verifican con AFC.
estructuras <- list(
  PA3 = list(
    modelo = m_pa3, segundo = "SAT =~ NIV + REL + AUT + BAR + CIU", ord = FALSE),
  PA4 = list(
    modelo = 'AP =~ pa4_01 + pa4_02 + pa4_03 + pa4_04 + pa4_05
              AN =~ pa4_06 + pa4_07 + pa4_08 + pa4_09 + pa4_10', segundo = NULL, ord = FALSE),
  PB1 = list(
    modelo = 'INT =~ pb1_01 + pb1_02
              POL =~ pb1_04 + pb1_05
              MIL =~ pb1_06 + pb1_07
              JUS =~ pb1_08 + pb1_09
              PLT =~ pb1_10 + pb1_11 + pb1_12', segundo = "CONF =~ POL + MIL + JUS + PLT", ord = FALSE),
  BS  = list(
    modelo = 'EVA =~ pa1 + pa2 + pa5 + pa6
              AP  =~ pa4_01 + pa4_02 + pa4_03 + pa4_04 + pa4_05
              AN  =~ pa4_06 + pa4_07 + pa4_08 + pa4_09 + pa4_10', segundo = "BS =~ EVA + AP + AN", ord = FALSE),
  PD2 = list(
    modelo = 'DEP =~ pd2_1 + pd2_2 + pd2_3 + pd2_4 + pd2_5 + pd2_6r + pd2_7
              ANS =~ pd3_1 + pd3_2', segundo = NULL, ord = TRUE),
  PC3 = list(
    modelo = 'COM =~ pc3_1 + pc3_2
              ESC =~ pc3_3 + pc3_4 + pc3_5
              FAM =~ pc3_6 + pc3_7 + pc3_8', segundo = "SOC =~ COM + ESC + FAM", ord = TRUE),
  PC2 = list(
    modelo = 'MSG =~ pc2_1 + pc2_4
              RED =~ pc2_2 + pc2_3 + pc2_5', segundo = NULL, ord = TRUE))
# BS combina pa1, pa2, pa5 y pa6 con los ítems de afecto: Bienestar subjetivo en tres componentes.
# pb1_03 (medios de comunicación) se deja fuera de PB1: carga en dos factores del AFE.

items_de <- function(modelo) unique(unlist(regmatches(modelo, gregexpr("(pa|pb|pc|pd)[0-9]+(_[0-9]+r?)?", modelo))))
medidas <- function(f, ord) {
  m <- fitMeasures(f, if (ord) c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
                       else c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr"))
  setNames(round(as.numeric(m), 3), c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR"))
}
ajusta <- function(modelo, ord, datos = enb, ...) {
  it <- items_de(modelo)
  if (ord) { datos[it] <- lapply(datos[it], ordered)
    suppressWarnings(cfa(modelo, datos, ordered = it, estimator = "WLSMV", std.lv = TRUE, ...))
  } else suppressWarnings(cfa(modelo, datos, estimator = "MLR", std.lv = TRUE, ...))
}

# 6a. AFE: KMO, número de factores y ajuste con k elegido (oblimin) ------------
k_afe <- c(PA3 = 5, PA4 = 2, PB1 = 5, PD2 = 2, PC3 = 3, PC2 = 2)
afe <- do.call(rbind, lapply(names(k_afe), function(n) {
  bl <- bloques[[n]]; r <- matriz_cor(enb[, bl$items], bl$tipo); fm <- if (bl$tipo == "cont") "ml" else "minres"
  p <- length(bl$items); kmax <- max(Filter(function(k) (p - k)^2 >= p + k, 1:(k_afe[n] + 1)))   # k con gl >= 0
  do.call(rbind, lapply(1:kmax, function(k) {
    f <- suppressWarnings(fa(r, nfactors = k, n.obs = nrow(enb), fm = fm, rotate = if (k > 1) "oblimin" else "none"))
    data.frame(bloque = n, factores = k, RMSEA = round(f$RMSEA[1], 3), TLI = round(f$TLI, 3), SRMR = round(f$rms, 3))
  }))
}))
rownames(afe) <- NULL
afe
# El primer k con RMSEA <= .06 y TLI >= .95 es el elegido: PA3 5 (.035; el AFE de 4 factores
# da .048 pero mezcla vivienda y vecindario con el resto), PB1 5 (.021), PD2 2 (.071), PC3 3 (.056)
# y PC2 2 (.066). PA4 se deja en 2 (afecto positivo y negativo): con 3 el RMSEA baja a .067, pero el
# tercer factor no define nada (cargas de -.23 a .29, parte del ítem 'buen humor' y 'calma').
write.csv(afe, file.path(dir_salida, "afe_ajuste.csv"), row.names = FALSE)
for (n in names(k_afe)) {                    # cargas de la solución elegida
  bl <- bloques[[n]]; r <- matriz_cor(enb[, bl$items], bl$tipo)
  f <- suppressWarnings(fa(r, nfactors = k_afe[n], n.obs = nrow(enb), fm = if (bl$tipo == "cont") "ml" else "minres", rotate = "oblimin"))
  write.csv(round(unclass(f$loadings), 3), file.path(dir_salida, paste0("afe_cargas_", n, ".csv")))
}

# 6b. AFC de primer orden y de segundo orden ----------------------------------
fits <- list(); fits2 <- list(); cargas <- list()
tabla_afc <- do.call(rbind, lapply(names(estructuras), function(n) {
  e <- estructuras[[n]]
  fits[[n]] <<- ajusta(e$modelo, e$ord)
  s <- standardizedSolution(fits[[n]]); l <- s$est.std[s$op == "=~"]
  cargas[[n]] <<- s[s$op == "=~", c("lhs", "rhs", "est.std")]
  fila <- data.frame(bloque = n, orden = "1.º", t(medidas(fits[[n]], e$ord)), converge = lavInspect(fits[[n]], "converged"),
                     admisible = suppressWarnings(lavInspect(fits[[n]], "post.check")),
                     carga_min = round(min(l), 2), carga_max = round(max(l), 2))
  if (!is.null(e$segundo)) {
    fits2[[n]] <<- ajusta(paste(e$modelo, e$segundo, sep = "\n"), e$ord)
    s2 <- standardizedSolution(fits2[[n]])
    fila2 <- data.frame(bloque = n, orden = "2.º", t(medidas(fits2[[n]], e$ord)), converge = lavInspect(fits2[[n]], "converged"),
                        admisible = suppressWarnings(lavInspect(fits2[[n]], "post.check")),
                        carga_min = round(min(s2$est.std[s2$op == "=~" & s2$lhs == sub(" =~.*", "", e$segundo)]), 2),
                        carga_max = round(max(s2$est.std[s2$op == "=~" & s2$lhs == sub(" =~.*", "", e$segundo)]), 2))
    rbind(fila, fila2)
  } else fila
}))
tabla_afc
# PA3 5F: CFI .952, RMSEA .047. PB1 5F: .968 / .088. PA4 2F: .943 / .085. BS: .934 / .069.
# PD2 (WLSMV): CFI .995 / .051. PC3: .987 / .047. PC2: .998 / .033.
# `admisible` = ninguna varianza negativa ni matriz no positiva definida (post.check de lavaan).
# 2.º orden: PB1 casi igual que el 1.º (.962; cargas de .81 a .93), PA3 pierde .014 de CFI (.938;
# cargas de .60 a .91). BS y PC3 tienen 3 factores: el 2.º orden es justo identificado (mismo
# ajuste). PA4, PD2 y PC2 tienen sólo 2 factores: no hay 2.º orden sin restringir cargas.
write.csv(tabla_afc, file.path(dir_salida, "afc_ajuste.csv"), row.names = FALSE)

# Sensibilidad: PA3 con los 11 puntos tratados como ordinales (WLSMV) en vez de continuos (MLR)
f_pa3_ord <- ajusta(m_pa3, TRUE)
c(medidas(f_pa3_ord, TRUE)[c("CFI", "TLI", "RMSEA", "SRMR")],
  carga_media_MLR = round(mean(cl(fits$PA3)), 2), carga_media_WLSMV = round(mean(cl(f_pa3_ord)), 2))
# Con WLSMV el ajuste es mejor (CFI .966, TLI .957, RMSEA .062) y las cargas, más altas (media .71
# contra .65): las policóricas corrigen el techo de las respuestas. Mismos cinco factores y mismo
# orden de ítems; cambia el nivel de las cargas y con él la AVE: con WLSMV queda en .49-.54
# (con MLR, .41-.45). Es decir, el "AVE < .50" de PA3 depende en parte del estimador.
write.csv(do.call(rbind, lapply(names(cargas), function(n) cbind(bloque = n, cargas[[n]]))),
          file.path(dir_salida, "afc_cargas.csv"), row.names = FALSE)

# 6c. Confiabilidad y validez --------------------------------------------------
# CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)]; AVE = media de λ²; Fornell-Larcker: AVE > r² máx. con otro
# factor; HTMT con las correlaciones de los ítems (Pearson o policóricas) y valor absoluto.
confiab <- do.call(rbind, lapply(names(estructuras), function(n) {
  e <- estructuras[[n]]; f <- fits[[n]]; s <- standardizedSolution(f); fi <- lavInspect(f, "cor.lv")
  fac <- unique(s$lhs[s$op == "=~"]); its <- items_de(e$modelo)
  R <- abs(matriz_cor(enb[, its], if (e$ord) "ord" else "cont"))
  est <- lapply(fac, function(g) s$rhs[s$op == "=~" & s$lhs == g]); names(est) <- fac
  do.call(rbind, lapply(fac, function(g) {
    l <- s$est.std[s$op == "=~" & s$lhs == g]; it_g <- est[[g]]
    dentro <- function(v) mean(R[v, v][lower.tri(R[v, v])])
    htmt <- sapply(setdiff(fac, g), function(h) mean(R[it_g, est[[h]]]) / sqrt(dentro(it_g) * dentro(est[[h]])))
    x <- enb[, it_g]
    alfa <- tryCatch(suppressWarnings(suppressMessages(psych::alpha(if (e$ord) matriz_cor(x, "ord") else x, n.obs = nrow(x), check.keys = FALSE)))$total$raw_alpha, error = function(e) NA)
    data.frame(bloque = n, factor = g, k = length(l), alfa = round(alfa, 3), CR = round(sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), 3),
               AVE = round(mean(l^2), 3), r2_max = round(max(fi[g, setdiff(fac, g)]^2), 3),
               HTMT_max = round(max(htmt, 0), 2))
  }))
}))
confiab$FL <- confiab$AVE > confiab$r2_max
confiab
# PB1, PA4, PC2 y BS: CR .70-.90 y Fornell-Larcker cumplido (PB1: HTMT máx .84, JUS-PLT).
# PA3: CR .61-.77 y AVE .41-.45: NINGÚN factor llega a .50 ni pasa Fornell-Larcker (cargas de .55 a .76),
# aunque HTMT queda bajo .85. PD2: DEP rozando (AVE .607 contra r² .628). PC3: ESC y FAM no pasan
# (HTMT .83). Los factores de 2 ítems (BAR, COM, INT, MIL...) dan alfas poco informativas.
write.csv(confiab, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)

# Validez de criterio: SÍ hay criterios dentro de la propia base. pa1 (satisfacción con la vida) y
# pa5 (escalón actual) para la satisfacción y el afecto positivo; la depresión (CESD-7) y la ansiedad
# (GAD-2) para el afecto negativo. Se usan medias de ítems (Spearman) para no depender de un modelo.
medias <- data.frame(
  SAT  = rowMeans(enb[, sprintf("pa3_%02d", 1:17)]),
  AP   = rowMeans(enb[, sprintf("pa4_%02d", 1:5)]), AN = rowMeans(enb[, sprintf("pa4_%02d", 6:10)]),
  CONF = rowMeans(enb[, sprintf("pb1_%02d", 4:12)]),
  DEP  = rowMeans(enb[, c(paste0("pd2_", c(1:5, 7)), "pd2_6r")]), ANS = rowMeans(enb[, paste0("pd3_", 1:2)]),
  pa1  = enb$pa1, pa5 = enb$pa5)
criterio <- round(cor(medias, method = "spearman"), 2)
criterio
# SAT: pa1 .56, pa5 .54, AP .49, DEP -.33. AN: DEP .48, ANS .42 (mismo constructo) y pa1 -.25.
# CONF (instituciones): SAT .37 pero pa1 .13, pa5 .18, DEP -.05: distinta del bienestar (validez discriminante).
write.csv(criterio, file.path(dir_salida, "validez_criterio.csv"))

# 6d. Puntajes factoriales -----------------------------------------------------
# Determinación: ρ = sqrt(diag(Φ Λ' Σ⁻¹ Λ Φ) / diag(Φ)) (como en PREP); >= .90 = confiable.
# MLR: puntajes por regresión; WLSMV: EBM por patrón de respuesta distinto.
determinacion <- function(f) {
  est <- lavInspect(f, "est"); Sigma <- lavInspect(f, "implied")$cov
  sqrt(diag(est$psi %*% t(est$lambda) %*% solve(Sigma) %*% est$lambda %*% est$psi) / diag(est$psi))
}
puntajes <- do.call(rbind, lapply(names(estructuras), function(n) {
  e <- estructuras[[n]]; f <- fits[[n]]; its <- items_de(e$modelo)
  if (e$ord) {
    patron <- apply(enb[, its], 1, paste, collapse = "-"); u <- !duplicated(patron)
    d_u <- enb[u, its, drop = FALSE]; d_u[] <- lapply(d_u, ordered)
    pu <- suppressWarnings(lavPredict(f, newdata = d_u, method = "EBM"))
    fs <- pu[match(patron, patron[u]), , drop = FALSE]; patrones <- sum(u)
  } else { fs <- lavPredict(f, method = "regression"); patrones <- NA }
  fac <- colnames(fs); det <- determinacion(f)
  s <- standardizedSolution(f)
  do.call(rbind, lapply(fac, function(g) {
    it_g <- s$rhs[s$op == "=~" & s$lhs == g]
    media <- rowMeans(enb[, it_g, drop = FALSE])
    data.frame(bloque = n, factor = g, n_puntajes = sum(!is.na(fs[, g])), patrones_distintos = patrones,
               determinacion = round(det[g], 3), r_con_media_simple = round(abs(cor(fs[, g], media)), 3))
  }))
}))
rownames(puntajes) <- NULL
puntajes
# Determinación de .86 a .97 (la más baja, BAR con 2 ítems); >= .90 en 15 de 22 factores.
# Los 31,166 reciben puntaje (no hay faltantes) y el puntaje correlaciona .80-.99 con la media simple.
write.csv(puntajes, file.path(dir_salida, "puntajes_resumen.csv"), row.names = FALSE)

# 6e. Invarianza factorial por tamaño de localidad (tloc, 4 grupos) ------------
# No hay sexo ni edad en la base. MLR: configural, métrica (cargas) y escalar (+ interceptos).
# WLSMV: configural y umbrales + cargas (Millsap y Tein, 2004). Criterio de Chen (2007):
# ΔCFI >= -.010 y ΔRMSEA <= .015.
invarianza <- function(n, grupo = "tloc_g") {
  e <- estructuras[[n]]
  pasos <- if (e$ord) list(Configural = NULL, "Umbrales + cargas" = c("thresholds", "loadings"))
           else list(Configural = NULL, "Métrica" = "loadings", "Escalar" = c("loadings", "intercepts"))
  ajustes <- lapply(pasos, function(ge) if (is.null(ge)) ajusta(e$modelo, e$ord, group = grupo)
                                          else ajusta(e$modelo, e$ord, group = grupo, group.equal = ge))
  tb <- data.frame(bloque = n, modelo = names(pasos), do.call(rbind, lapply(ajustes, medidas, ord = e$ord)), row.names = NULL)
  # los cambios se calculan con los índices sin redondear
  cfi <- sapply(ajustes, function(f) fitMeasures(f, if (e$ord) "cfi.scaled" else "cfi.robust"))
  rmsea <- sapply(ajustes, function(f) fitMeasures(f, if (e$ord) "rmsea.scaled" else "rmsea.robust"))
  tb$dCFI <- round(c(NA, diff(cfi)), 3); tb$dRMSEA <- round(c(NA, diff(rmsea)), 3)
  tb$criterio_Chen <- c(NA, tb$dCFI[-1] >= -.010 & tb$dRMSEA[-1] <= .015)
  tb
}
inv <- do.call(rbind, lapply(names(estructuras), function(n)
  tryCatch(invarianza(n), error = function(err) { message(n, ": ", conditionMessage(err)); NULL })))
inv
# PB1, PA4 y BS: pasan hasta la escalar (ΔCFI >= -.002). PA3: métrica -.001; escalar -.010, pasa justo en el límite.
# PD2, PC3 y PC2 (ordinales): umbrales + cargas pasan (ΔCFI -.006 a +.001).
write.csv(inv, file.path(dir_salida, "invarianza_tloc.csv"), row.names = FALSE)
table(tloc = enb$tloc)                       # 14,095 / 4,793 / 4,925 / 7,353: grupos grandes

# 6f. FIML: ¿hay faltantes reales? ----------------------------------------------
# En los bloques de bienestar no hay ninguno. Los faltantes de la base son SALTOS de pregunta
# (todo el bloque falta junto: p. ej. pe10_* para quien no trabaja; un FIML ahí no agrega
# casos: los renglones sin ningún ítem no aportan). La única excepción con faltantes
# PARCIALES son ph1_4 y ph2_4 (14%: no se pregunta "a partir de los 25 años" a quien tiene
# menos), más los códigos 9 (0.1%) de ph1_* y ph2_*.
colSums(is.na(enb[, c(paste0("ph1_", 1:4), paste0("ph2_", 1:4))]))
m_ph <- 'DIF =~ ph1_1 + ph1_2 + ph1_3 + ph1_4
         ALE =~ ph2_1 + ph2_2 + ph2_3 + ph2_4'
# lavaan NO tiene FIML con ítems ordinales (missing = "fiml" + ordered da error): se trata
# a los Sí/No como continuos con MLR. Con WLSMV se usa missing = "pairwise" como alternativa.
f_fiml <- suppressWarnings(cfa(m_ph, enb, estimator = "MLR", missing = "fiml", std.lv = TRUE))
f_list <- suppressWarnings(cfa(m_ph, enb, estimator = "MLR", missing = "listwise", std.lv = TRUE))
it_ph <- items_de(m_ph); d_ph <- enb; d_ph[it_ph] <- lapply(d_ph[it_ph], ordered)
f_ord <- suppressWarnings(cfa(m_ph, d_ph, ordered = it_ph, estimator = "WLSMV", missing = "pairwise", std.lv = TRUE))
se_l <- parameterEstimates(f_list); se_f <- parameterEstimates(f_fiml)
fiml <- data.frame(
  metodo = c("Listwise (MLR)", "FIML (MLR, ítems como continuos)", "Pairwise (WLSMV, ítems ordinales)"),
  N = c(lavInspect(f_list, "nobs"), lavInspect(f_fiml, "nobs"), lavInspect(f_ord, "nobs")),
  rbind(medidas(f_list, FALSE), medidas(f_fiml, FALSE), medidas(f_ord, TRUE))[, c("CFI", "TLI", "RMSEA", "SRMR")])
fiml$razon_EE <- c(1, round(mean(se_f$se[se_f$op == "=~" & se_f$se > 0] / se_l$se[se_l$op == "=~" & se_l$se > 0]), 2), NA)
fiml
# FIML recupera 4,380 personas (de 26,784 a 31,164) y reduce 7% los errores estándar; pero el ajuste
# de dos factores con Sí/No como continuos es mediocre (CFI .90, RMSEA .127; con WLSMV y pairwise,
# CFI .94 y RMSEA .055). Los dos factores (dificultades y alegrías) casi no se relacionan (-.07).
write.csv(fiml, file.path(dir_salida, "fiml_ph.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 7. Resumen: qué ejercicio corre en qué bloque
# -----------------------------------------------------------------------
resumen <- data.frame(
  bloque = names(estructuras),
  AFE_factores = c(k_afe["PA3"], k_afe["PA4"], k_afe["PB1"], NA, k_afe["PD2"], k_afe["PC3"], k_afe["PC2"]),
  CFI_1er_orden = tabla_afc$CFI[tabla_afc$orden == "1.º"],
  CFI_2do_orden = sapply(names(estructuras), function(n) if (n %in% tabla_afc$bloque[tabla_afc$orden == "2.º"])
                  tabla_afc$CFI[tabla_afc$bloque == n & tabla_afc$orden == "2.º"] else NA),
  CR_min = sapply(names(estructuras), function(n) min(confiab$CR[confiab$bloque == n])),
  AVE_min = sapply(names(estructuras), function(n) min(confiab$AVE[confiab$bloque == n])),
  HTMT_max = sapply(names(estructuras), function(n) max(confiab$HTMT_max[confiab$bloque == n])),
  determinacion_min = sapply(names(estructuras), function(n) min(puntajes$determinacion[puntajes$bloque == n])),
  invarianza_hasta = sapply(names(estructuras), function(n) { t <- inv[inv$bloque == n, ]
    if (nrow(t) == 0) return(NA_character_)
    ok <- c(TRUE, as.logical(t$criterio_Chen[-1])); ok[is.na(ok)] <- FALSE
    t$modelo[max(which(cumsum(!ok) == 0))] }),
  row.names = NULL)
resumen
write.csv(resumen, file.path(dir_salida, "resumen_ejercicios.csv"), row.names = FALSE)
