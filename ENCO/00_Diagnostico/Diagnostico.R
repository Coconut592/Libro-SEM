# =============================================================================
# Libro SEM · ENCO
# 00 - Diagnóstico: ¿se pueden hacer los 7 ejercicios con lo que se tiene?
# =============================================================================
# Referencias: INEGI, "Encuesta Nacional sobre Confianza del Consumidor (ENCO).
# Estructura de la base de datos" (fd_enco_v7.pdf, 06/10/2025) y las tres tablas
# de agosto de 2026 (periodo 0826): ENCOVIV (viviendas), ENCOCS (cuestionario
# sociodemográfico) y ENCOCB (cuestionario básico). Este script no es parte del
# libro: revisa qué trae cada archivo, cómo se unen y qué corre con lo que hay.
# Tarda unos 3 minutos.
#   source("ENCO/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(foreign)
library(psych)
library(lavaan)

dir_datos  <- "ENCO/data"
dir_salida <- "ENCO/00_Diagnostico/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Leer las tres tablas (.DBF) y ver qué trae cada una
# -----------------------------------------------------------------------
# as.is = TRUE deja los campos de texto como texto (los códigos del diccionario
# son caracteres: "01", "1"...). Solo FACTOR y FAC_P18 vienen numéricos.
viv <- read.dbf(file.path(dir_datos, "encoviv_0826.DBF"), as.is = TRUE)
cs  <- read.dbf(file.path(dir_datos, "encocs_0826.DBF"),  as.is = TRUE)
cb  <- read.dbf(file.path(dir_datos, "encocb_0826.DBF"),  as.is = TRUE)

inventario <- data.frame(
  archivo = c("encoviv_0826.DBF", "encocs_0826.DBF", "encocb_0826.DBF"),
  unidad = c("vivienda", "integrante del hogar", "persona de 18+ elegida"),
  filas = c(nrow(viv), nrow(cs), nrow(cb)),
  columnas = c(ncol(viv), ncol(cs), ncol(cb)))
inventario                                   # 2,336 x 33; 6,670 x 32; 2,050 x 28
write.csv(inventario, file.path(dir_salida, "inventario_archivos.csv"), row.names = FALSE)

# El PDF (diccionario) describe las mismas 33, 32 y 28 variables. En el
# sociodemográfico, NOM (nombre del integrante) viene enmascarado con "-": no hay
# datos personales.
unique(cs$NOM)                               # "-"

# -----------------------------------------------------------------------
# Paso 2. Llaves y uniones: ¿se pueden juntar las tres tablas?
# -----------------------------------------------------------------------
# Según el PDF, ENCOVIV se identifica con FOL, CVE_ENT, CON y V_SEL, y ENCOCS y
# ENCOCB con esas más N_HOG, H_MUD y N_REN. Aquí se usan los siete campos.
llave_viv <- c("FOL", "CVE_ENT", "CON", "V_SEL", "N_HOG", "H_MUD")
llave_per <- c(llave_viv, "N_REN")
c(dup_viv = anyDuplicated(viv[, llave_viv]), dup_cs = anyDuplicated(cs[, llave_per]),
  dup_cb = anyDuplicated(cb[, llave_per]))   # 0, 0, 0: son llaves

# ¿Cuántas viviendas terminaron en entrevista? R_DEF = 00 es "entrevista completa".
table(viv$R_DEF)                             # 2,050 completas; 266 sin hogar o sin entrevista; 20 sin el elegido
sum(viv$R_DEF == "00")                       # 2,050 = filas de ENCOCB
# De cada hogar con sociodemográfico (2,070) se elige UNA persona de 18+ (ELEGIDO = 1)
# para el cuestionario básico. Los 20 hogares sin cuestionario son R_DEF 14, 15 y 16
# (13 elegido no encontrado, 6 se negó y 1 incapacitado).
# (ELEGIDO viene en blanco, con un byte nulo, para los no elegidos: R lo lee como NA, de ahí el %in%.)
c(hogares_cs = nrow(unique(cs[, llave_viv])), elegidos = sum(cs$ELEGIDO %in% "1"),
  r_def_14_15_16 = sum(viv$R_DEF %in% c("14", "15", "16")))

# Unión del cuestionario básico con el sociodemográfico y con la vivienda: ninguna
# fila se pierde ni se duplica.
extra_cs <- c("SEX", "EDA", "I_NIV", "A_ESC", "C_ACT", "OCU", "I_PER", "ING", "UPM")
enco <- merge(cb, cs[, c(llave_per, extra_cs)], by = llave_per, all.x = TRUE)
nrow(enco)                                   # 2,050
sum(is.na(enco$SEX))                         # 0: todas las personas encontraron su registro
# OJO: merge() reordena las filas por llave. De aquí en adelante TODO (ítems, sexo,
# edad, UPM, ponderador) sale de `enco`, no de `cb`, para que las filas coincidan.
nrow(merge(cb[, llave_viv], viv[, llave_viv]))   # 2,050
# El ponderador del cuestionario básico es el FAC_P18 (población de 18+) del
# sociodemográfico, el mismo número.
elegidos <- cs[cs$ELEGIDO %in% "1", ]
all(cb$FACTOR == elegidos$FAC_P18[match(do.call(paste, cb[, llave_per]),
    do.call(paste, elegidos[, llave_per]))])    # TRUE

enco$edad <- as.numeric(enco$EDA)
c(n = nrow(enco), mujeres = sum(enco$SEX == "2"), hombres = sum(enco$SEX == "1"))   # 2,050: 1,188 y 862
range(enco$edad)                             # 18 a 97
table(enco$CD)[c("01", "02", "03")]          # CDMX 323, Guadalajara 218, Monterrey 225; las otras 29 ciudades, de 34 a 74
table(enco$CVE_ENT)                          # 32 entidades, de 34 a 225 entrevistas

# -----------------------------------------------------------------------
# Paso 3. Los 15 ítems del cuestionario básico (P1 a P15)
# -----------------------------------------------------------------------
# Todos son de opinión sobre la situación económica. Codificación según el PDF:
# la ESCALA y el código de "No sabe" cambian de una pregunta a otra.
items <- paste0("P", 1:15)
tabla_items <- data.frame(
  item = items,
  contenido = c("Su situación económica hoy, frente a hace 12 meses",
                "Su situación económica dentro de 12 meses",
                "Situación del hogar hoy, frente a hace 12 meses",
                "Situación del hogar dentro de 12 meses",
                "Situación económica del país hoy, frente a hace 12 meses",
                "Situación económica del país dentro de 12 meses",
                "Mayores posibilidades hoy de comprar ropa, zapatos, alimentos que hace un año",
                "Posibilidades hoy de comprar muebles, TV, lavadora (bienes durables), frente a hace un año",
                "Posibilidades de salir de vacaciones en los próximos 12 meses",
                "Posibilidades hoy de ahorrar parte de sus ingresos",
                "Condiciones para ahorrar dentro de 12 meses, frente a las actuales",
                "Precios en el país en los siguientes 12 meses",
                "Empleo en el país en los próximos 12 meses",
                "Planes de comprar un automóvil en los próximos 2 años",
                "Planes de comprar, construir o remodelar una casa en los próximos 2 años"),
  categorias = c(rep("5: mucho mejor ... mucho peor", 6), "3: sí / igual / no", "3: mayores / iguales / menores",
                 "2: sí / no", "2: sí / no", "5: muy buenas ... muy malas",
                 "6: disminuirán mucho ... aumentarán mucho", "5: aumentará mucho ... disminuirá mucho",
                 "3: sí / probablemente / no", "3: sí / probablemente / no"),
  codigo_NS = c(rep(6, 6), 4, 4, 3, 3, 6, 7, 6, 4, 4),
  stringsAsFactors = FALSE)
tabla_items$n_categorias <- c(rep(5, 6), 3, 3, 2, 2, 5, 6, 5, 3, 3)
# P12: el código 5 es "Aumentarán igual" (así dice el PDF): queda entre "poco" y
# "mucho" por orden de código, pero su significado no es claro.
# P10: además del NS (3) existe el código 4 "No tiene ingresos".

# Frecuencias de cada ítem tal como vienen
frec <- do.call(rbind, lapply(items, function(v) {
  t <- table(factor(cb[[v]], levels = 1:7))
  data.frame(item = v, t(as.matrix(t)), row.names = NULL)
}))
names(frec)[-1] <- paste0("cod", 1:7)
frec
write.csv(merge(tabla_items, frec, by = "item", sort = FALSE),
          file.path(dir_salida, "items_enco.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Limpieza: NS a faltante, colas raras y dirección de las escalas
# -----------------------------------------------------------------------
x <- enco[, items]
x[] <- lapply(x, as.integer)
for (i in seq_along(items)) x[[items[i]]][x[[items[i]]] == tabla_items$codigo_NS[i]] <- NA   # "No sabe" -> NA
x$P10[enco$P10 == "4"] <- NA                 # "No tiene ingresos": no contesta la pregunta de ahorro

# Faltantes: pocos. Todos son "No sabe" (el único otro faltante posible es P10 = 4).
faltantes <- data.frame(item = items, n_NA = colSums(is.na(x)), pct_NA = round(100 * colMeans(is.na(x)), 1),
                        row.names = NULL)
faltantes                                    # de 1 (P1, P3, P7, P14, P15) a 34 (P13: 1.7 %)
c(completos = sum(complete.cases(x)), con_algun_NS = sum(!complete.cases(x)),
  pct = round(100 * mean(!complete.cases(x)), 1))   # 1,935 completos; 115 (5.6 %) con algún NS
write.csv(faltantes, file.path(dir_salida, "faltantes_por_item.csv"), row.names = FALSE)

# ¿Quién no sabe? Más edad y más mujeres: el faltante NO es completamente al azar
# (se parece a MAR: depende de variables que sí se observan).
no_sabe <- as.integer(!complete.cases(x))
round(summary(glm(no_sabe ~ enco$edad + I(enco$SEX == "2"), family = binomial))$coefficients, 3)
# edad +.022 por año (p < .001), mujer +.41 (p = .046)

# Colas raras: P12 "Disminuirán mucho" tiene 5 casos y "poco" 26. Con subgrupos
# (invarianza) esa categoría queda vacía y lavaan se detiene; aquí se funden las dos.
# (El diagnóstico las funde; los ejercicios 01 a 07 NO: decisión del proyecto, ver el README.)
table(x$P12)                                 # 1: 5, 2: 26, 3: 217, 4: 606, 5: 332, 6: 859
x$P12[x$P12 == 1] <- 2; x$P12 <- x$P12 - 1   # ahora 1 a 5

# Dirección: en el cuestionario el código 1 es SIEMPRE la respuesta más optimista
# (mucho mejor, sí, mayores, aumentará mucho el empleo, disminuirán mucho los
# precios), así que todas las correlaciones son positivas. Se invierten todas para
# que MAYOR = MÁS CONFIANZA (cargas positivas y puntajes fáciles de leer).
maximo <- c(P1 = 5, P2 = 5, P3 = 5, P4 = 5, P5 = 5, P6 = 5, P7 = 3, P8 = 3, P9 = 2, P10 = 2,
            P11 = 5, P12 = 5, P13 = 5, P14 = 3, P15 = 3)
for (v in items) x[[v]] <- maximo[[v]] + 1L - x[[v]]
round(min(cor(x, use = "pairwise.complete.obs", method = "spearman")), 2)   # .12 (P12-P14): ninguna negativa

# -----------------------------------------------------------------------
# Paso 5. Diseño muestral: ponderador y conglomerados
# -----------------------------------------------------------------------
w <- as.numeric(enco$FACTOR)
c(min = min(w), max = max(w), razon = round(max(w) / min(w), 1))     # 4,812 a 88,119 (18 a 1)
round(length(w) * sum(w^2) / sum(w)^2, 2)    # efecto de diseño por pesos (Kish): 1.26
upm <- table(enco$UPM)
c(UPM = length(upm), max_por_UPM = max(upm))  # 583 UPM, máximo 4 entrevistados por UPM
# Con tan pocos entrevistados por UPM el efecto de conglomerado es pequeño (ver el
# Paso 12). Decisión propuesta: sin ponderador para los modelos, como EMOVI, y
# revisar la sensibilidad.

# -----------------------------------------------------------------------
# Paso 6. AFE: casos completos, ítems ordinales
# -----------------------------------------------------------------------
completos <- x[complete.cases(x), ]
rho <- suppressWarnings(polychoric(completos)$rho)
c(KMO = round(KMO(rho)$MSA, 2), eigenvalor_minimo = round(min(eigen(rho)$values), 2))   # KMO .91; matriz definida positiva
cortest.bartlett(rho, n = nrow(completos))$p.value      # ~0
ev <- eigen(rho)$values
round(ev[1:6], 2)                            # 7.35 1.48 0.98 0.92 0.72 0.66
sum(ev > 1)                                  # Kaiser: 2
set.seed(2026)
ap <- suppressWarnings(fa.parallel(completos, cor = "poly", fa = "fa", fm = "minres", n.iter = 50, plot = FALSE))
ap$nfact                                     # paralelo: 5

ordinales <- as.data.frame(lapply(completos, ordered))
afe <- lapply(1:5, function(k) suppressWarnings(efa(ordinales, nfactors = k, ordered = items,
                                   estimator = "WLSMV", rotation = "oblimin")))
medidas <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
tabla_afe <- data.frame(factores = 1:5, t(sapply(afe, function(e) round(fitMeasures(e[[1]], medidas), 3))))
tabla_afe$residual_min <- sapply(afe, function(e) {
  L <- lavInspect(e[[1]], "est")$lambda; Phi <- lavInspect(e[[1]], "est")$psi
  round(min(1 - rowSums((L %*% Phi) * L)), 3) })
tabla_afe
# 1 factor: CFI .888, RMSEA .147; 2: .931 y .125; 3: .962 y .102; 4: .992 y .053;
# 5: .996 y .044. Con 4 el ajuste ya es bueno y no hay varianzas negativas.
write.csv(tabla_afe, file.path(dir_salida, "ajuste_AFE.csv"), row.names = FALSE)

e4 <- afe[[4]][[1]]
cargas_afe <- round(unclass(lavInspect(e4, "est")$lambda), 2)
cargas_afe <- cargas_afe[order(apply(abs(cargas_afe), 1, which.max), -apply(abs(cargas_afe), 1, max)), ]
colnames(cargas_afe) <- paste0("F", 1:4)
cargas_afe
# F1: P1, P3 (situación del hogar HOY frente a hace 12 meses; .82 y .78)
# F2: P2, P4 (situación del hogar DENTRO de 12 meses; .81 y .78)
# F3: P5, P6 (país hoy y en 12 meses; .76 y .79) con P12 y P13 (precios y empleo; .41 y .44)
# F4: P7 a P10, P14 y P15 (compras, vacaciones, ahorro, auto y casa; de .57 a .78)
# P11 (condiciones para ahorrar) carga .41 en F4, .24 en F2 y .21 en F3: el ítem menos limpio.
# P7 y P8 también cargan algo en F1 (.37 y .27). Con 5 factores, P14 y P15 (auto y casa)
# se separan en un factor propio (.73 y .83).
round(lavInspect(e4, "est")$psi, 2)          # los factores correlacionan de .41 a .60
write.csv(cargas_afe, file.path(dir_salida, "cargas_AFE_4_factores.csv"))

# -----------------------------------------------------------------------
# Paso 7. AFC de primer orden (WLSMV, ordinal, pairwise)
# -----------------------------------------------------------------------
# Cada ítem en el factor donde más carga en el AFE. HOGA = hogar hoy, HOGE = hogar
# esperado, PAIS = economía del país, CONS = consumo, ahorro y planes de compra.
modelo <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15'
fit <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
lavInspect(fit, "converged")                 # TRUE
lavInspect(fit, "nobs")                      # 2,050: pairwise conserva a los 115 con algún NS

medidas_cfa <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas_cfa), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
# Alternativas: sin P11 (el ítem menos limpio), 5 factores (auto y casa aparte) y un
# solo factor con los 15 ítems.
fit_sin11 <- cfa(sub(" \\+ P11", "", modelo), data = x, ordered = setdiff(items, "P11"),
                 estimator = "WLSMV", missing = "pairwise")
modelo5 <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11
  PLAN =~ P14 + P15'
fit5 <- cfa(modelo5, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
fit1 <- cfa(paste("G =~", paste(items, collapse = " + ")), data = x, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
tabla_afc <- rbind(ajuste(fit, "4 factores (HOGA, HOGE, PAIS, CONS)"), ajuste(fit_sin11, "4 factores sin P11"),
                   ajuste(fit5, "5 factores (PLAN aparte)"), ajuste(fit1, "1 factor con los 15 ítems"))
tabla_afc
# 4 factores: CFI .975, TLI .969, RMSEA .071, SRMR .048 (el RMSEA es el punto flojo);
# sin P11: .981, .976, .065, .045; 1 factor: .889 y RMSEA .146: la estructura de varias
# dimensiones es real.
write.csv(tabla_afc, file.path(dir_salida, "ajuste_AFC.csv"), row.names = FALSE)

s <- standardizedSolution(fit)
cargas <- s[s$op == "=~", c("lhs", "rhs", "est.std", "se")]
names(cargas) <- c("factor", "item", "carga", "ee")
cargas[, 3:4] <- round(cargas[, 3:4], 3)
cargas                                       # de .48 (P12) a .91 (P2, P4, P1)
round(lavInspect(fit, "cor.lv"), 2)          # HOGA-CONS .79 es la mayor; PAIS con los demás, de .54 a .62
write.csv(cargas, file.path(dir_salida, "cargas_AFC.csv"), row.names = FALSE)

# Índices de modificación (solo para ver): P11 con HOGE (123) y con PAIS (99); P14 con
# P15 (103), P5 con P6 (69) y P9 con P10 (68): parejas de preguntas muy parecidas.
mi <- modindices(fit, sort. = TRUE, maximum.number = 6)
mi[, c("lhs", "op", "rhs", "mi")]

# Los cinco ítems del ICC oficial (P3, P4, P5, P6 y P8) no bastan para una estructura
# factorial: caen en los cuatro factores (P3 en HOGA, P4 en HOGE, P5-P6 en PAIS, P8 en CONS)
# y juntos no son unidimensionales.
icc5 <- c("P3", "P4", "P5", "P6", "P8")
f_icc <- cfa(paste("ICC =~", paste(icc5, collapse = " + ")), data = x, ordered = icc5,
             estimator = "WLSMV", missing = "pairwise")
ajuste(f_icc, "1 factor con los 5 ítems del ICC")    # CFI .883, RMSEA .228: no ajusta
round(standardizedSolution(f_icc)$est.std[1:5], 2)   # .72 .67 .67 .64 .68

# -----------------------------------------------------------------------
# Paso 8. AFC de segundo orden: CONF =~ HOGA + HOGE + PAIS + CONS
# -----------------------------------------------------------------------
fit2 <- cfa(paste(modelo, "\n  CONF =~ HOGA + HOGE + PAIS + CONS"), data = x, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
lavInspect(fit2, "converged")                # TRUE
tabla_2o <- rbind(ajuste(fit, "1.er orden (4 factores)"), ajuste(fit2, "2.º orden (CONF)"))
tabla_2o
# Con 4 factores el segundo orden NO queda justo identificado: 6 correlaciones se
# reemplazan por 4 cargas, así que quedan 2 gl más (86 contra 84) y se puede contrastar.
# El ajuste casi no cambia (CFI .975, RMSEA .070).
s2 <- standardizedSolution(fit2)
g <- s2[s2$lhs == "CONF" & s2$op == "=~", c("rhs", "est.std", "se")]
g$R2 <- g$est.std^2
g[, 2:4] <- round(g[, 2:4], 3)
g                                            # HOGA .85, HOGE .79, PAIS .68, CONS .92
round(diag(lavInspect(fit2, "est")$psi), 3)  # varianzas residuales de los factores: todas positivas
# CONS (R2 = .84) es el que más se parece al factor general; PAIS el que menos (.47).
suppressMessages(lavTestLRT(fit, fit2))      # la χ2 rechaza (p < .001), el CFI no cambia
write.csv(tabla_2o, file.path(dir_salida, "ajuste_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 9. Confiabilidad y validez
# -----------------------------------------------------------------------
factores <- list(HOGA = c("P1", "P3"), HOGE = c("P2", "P4"), PAIS = c("P5", "P6", "P12", "P13"),
                 CONS = c("P7", "P8", "P9", "P10", "P11", "P14", "P15"))
fi <- lavInspect(fit, "cor.lv")
R <- lavCor(x, ordered = items, missing = "pairwise")      # policóricas
conf <- do.call(rbind, lapply(names(factores), function(f) {
  v <- factores[[f]]; l <- s$est.std[s$op == "=~" & s$lhs == f]
  data.frame(factor = f, k = length(v),
             alfa_ordinal = psych::alpha(R[v, v], n.obs = nrow(x))$total$raw_alpha,
             CR = sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), AVE = mean(l^2),
             r2_max = max(fi[f, rownames(fi) != f]^2))
}))
conf$AVE_supera_r2 <- conf$AVE > conf$r2_max
conf[, 3:6] <- round(conf[, 3:6], 3)
conf
# α ordinal y CR de .90 en HOGA, HOGE y CONS; PAIS es el débil: α .73, CR .74 y AVE .43
# (por P12, que carga .48): no llega a .50. Fornell-Larcker: HOGA, HOGE y PAIS pasan (la AVE
# supera su r² más alto; el de PAIS es bajo, .38); CONS apenas no (AVE .597 contra r² = .62
# con HOGA).
write.csv(conf, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)

dentro <- function(v) mean(R[v, v][lower.tri(R[v, v])])
htmt <- function(a, b) mean(R[factores[[a]], factores[[b]]]) / sqrt(dentro(factores[[a]]) * dentro(factores[[b]]))
pp <- t(combn(names(factores), 2))
tabla_htmt <- data.frame(par = paste(pp[, 1], pp[, 2], sep = " - "),
                         r_factores = round(mapply(function(a, b) fi[a, b], pp[, 1], pp[, 2]), 2),
                         HTMT = round(mapply(htmt, pp[, 1], pp[, 2]), 2))
tabla_htmt                                   # HTMT de .55 a .77: todos bajo .85
write.csv(tabla_htmt, file.path(dir_salida, "htmt.csv"), row.names = FALSE)

om <- suppressWarnings(psych::omega(R, nfactors = 4, n.obs = nrow(x), plot = FALSE))
c(omega_jerarquico = round(om$omega_h, 2), omega_total = round(om$omega.tot, 2))   # .76 y .95

# -----------------------------------------------------------------------
# Paso 10. Puntajes factoriales (EBM) y validez de criterio
# -----------------------------------------------------------------------
# EBM es el método de lavaan para ítems ordinales. Con missing = "pairwise" cada
# persona recibe puntaje aunque tenga algún NS. Tarda unos 40 segundos.
pf <- as.data.frame(lavPredict(fit2, method = "EBM"))
dim(pf)                                      # 2,050 x 5 (HOGA, HOGE, PAIS, CONS, CONF)
sum(is.na(pf))                               # 0
round(sapply(pf, function(z) c(media = mean(z), de = sd(z), min = min(z), max = max(z))), 2)
# media 0 y desviación de .63 a .83 (el puntaje se encoge hacia la media)

# Contra un promedio simple (ítems reescalados a 0-1): el del ICC (P3, P4, P5, P6, P8,
# como el indicador oficial, pero NO su fórmula) y el de los 15.
re <- function(v) x[[v]] / maximo[[v]]
simple15 <- rowMeans(sapply(items, re), na.rm = TRUE)
simple5  <- rowMeans(sapply(icc5, re), na.rm = TRUE)
c(r_con_promedio_15 = round(cor(pf$CONF, simple15), 3), r_con_promedio_ICC5 = round(cor(pf$CONF, simple5), 3))   # .970 y .904

# Criterios externos del sociodemográfico (que no entraron al modelo): con mayor edad
# menos confianza; con más estudios, más ingreso y estar ocupado, más.
niv <- suppressWarnings(as.integer(enco$I_NIV)); niv[niv == 99] <- NA
ing <- suppressWarnings(as.numeric(trimws(enco$ING))); ing[ing == 999999] <- NA   # 999999 = no especificado
a_mes <- c("1" = 52 / 12, "2" = 2, "3" = 1, "4" = 1 / 12)                          # a pesos por mes
ing_mes <- ing * a_mes[as.character(enco$I_PER)]
criterios <- data.frame(edad = enco$edad, estudios = niv, ln_ingreso_mensual = log(ing_mes),
                        ocupado = as.integer(enco$C_ACT == "01"))
validez <- data.frame(criterio = names(criterios),
  spearman = round(sapply(criterios, function(y) cor(pf$CONF, y, use = "pairwise.complete.obs", method = "spearman")), 2),
  n = sapply(criterios, function(y) sum(!is.na(y))))
rownames(validez) <- NULL
validez                                      # edad -.33; estudios .16; ingreso .20 (n = 810); ocupado .17
round(tapply(pf$CONF, cut(enco$edad, c(17, 29, 44, 59, Inf)), mean), 2)   # .35 .13 -.13 -.25
write.csv(validez, file.path(dir_salida, "validez_criterio.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 11. Invarianza factorial: sexo, edad, escolaridad y ciudad
# -----------------------------------------------------------------------
# Umbrales y cargas juntos (Millsap y Tein, 2004): P9 y P10 son binarios. Criterio
# de Chen (2007): ΔCFI de -.010 o menos y ΔRMSEA de .015 o menos.
d <- x
d$sexo     <- factor(enco$SEX, levels = c("1", "2"), labels = c("Hombre", "Mujer"))
d$edad_g   <- cut(enco$edad, c(17, 39, 59, Inf), labels = c("18-39", "40-59", "60+"))
d$estudios <- cut(niv, c(-1, 2, 3, 6, 9), labels = c("Primaria o menos", "Secundaria", "Medio superior", "Superior"))
d$ciudad   <- factor(ifelse(enco$CD %in% c("01", "02", "03"), "Gran ciudad", "Resto"))
lapply(d[c("sexo", "edad_g", "estudios", "ciudad")], table)
# Sexo 862 / 1,188; edad 773 / 747 / 530; estudios 316 / 453 / 559 / 720 (2 sin dato);
# ciudad (CDMX, Guadalajara y Monterrey) 766 contra 1,284.

invarianza <- function(grupo) {
  dd <- d[!is.na(d[[grupo]]), ]
  conf <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise")
  rest <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise",
              group.equal = c("thresholds", "loadings"))
  m <- rbind(round(fitMeasures(conf, medidas_cfa), 3), round(fitMeasures(rest, medidas_cfa), 3))
  lrt <- suppressMessages(lavTestLRT(conf, rest))
  tabla <- data.frame(grupo = grupo, modelo = c("Configural", "Umbrales + cargas"), m, row.names = NULL)
  names(tabla)[3:8] <- c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR")
  tabla$dCFI <- c(NA, round(tabla$CFI[2] - tabla$CFI[1], 3))
  tabla$dRMSEA <- c(NA, round(tabla$RMSEA[2] - tabla$RMSEA[1], 3))
  tabla$p_LRT <- c(NA, round(lrt$`Pr(>Chisq)`[2], 3))
  tabla
}
tabla_inv <- do.call(rbind, lapply(c("sexo", "edad_g", "estudios", "ciudad"), invarianza))
tabla_inv
# Los cuatro grupos convergen y cumplen el criterio de Chen (ΔCFI de +.002 a +.004, que
# no empeora; ΔRMSEA de -.010 a -.013), pero la χ2 rechaza (p de .00 a .02) con tantos casos.
write.csv(tabla_inv, file.path(dir_salida, "invarianza.csv"), row.names = FALSE)

# Ajuste del modelo en cada grupo por separado, y la categoría más rara de cualquier
# ítem en cada uno (con 1 a 3 casos las colas de las escalas de 5 puntos son frágiles).
por_grupo <- function(variable, nivel) {
  dd <- d[which(d[[variable]] == nivel), ]
  f <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", missing = "pairwise")
  m <- round(fitMeasures(f, c("cfi.scaled", "rmsea.scaled", "srmr")), 3)
  minimo <- min(sapply(items, function(v) min(table(factor(dd[[v]], levels = 1:maximo[[v]])))))
  data.frame(variable = variable, grupo = nivel, N = nrow(dd), CFI = m[1], RMSEA = m[2], SRMR = m[3],
             min_casos_por_categoria = minimo, row.names = NULL)
}
ajuste_grupos <- do.call(rbind, lapply(c("sexo", "edad_g", "estudios", "ciudad"), function(v)
  do.call(rbind, lapply(levels(d[[v]]), function(n) por_grupo(v, n)))))
ajuste_grupos                                # CFI de .962 a .984; categoría más rara de 1 a 14 casos
write.csv(ajuste_grupos, file.path(dir_salida, "ajuste_por_grupo.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 12. FIML, ponderador y conglomerados
# -----------------------------------------------------------------------
# lavaan no ofrece FIML con ítems ordinales:
try(cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "fiml"), silent = FALSE)
# ERROR: missing = "fiml" not available in the categorical setting
# Se puede con los ítems tratados como continuos (MLR). No es lo ideal con ítems de 2 o
# 3 categorías (P7-P10, P14, P15), pero sirve para ver cuánto cambia.
xn <- x[, items]; xn[] <- lapply(xn, as.numeric)
f_lw   <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE)                       # listwise
f_fiml <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE, missing = "fiml")     # FIML
med_mlr <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
tabla_fiml <- do.call(rbind, lapply(list(Listwise = f_lw, FIML = f_fiml), function(f) {
  m <- as.numeric(round(fitMeasures(f, med_mlr), 3))
  data.frame(N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2], CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}))
tabla_fiml
# N: 1,935 contra 2,050 (+6 %). CFI .935 y .936, RMSEA .068 y .067: el ajuste es el mismo.
cl <- function(f) { z <- standardizedSolution(f); z$est.std[z$op == "=~"] }
ee <- function(f) { z <- parameterEstimates(f); z$se[z$op == "=~"] }
c(max_dif_cargas = round(max(abs(cl(f_lw) - cl(f_fiml))), 3),
  razon_ee_FIML_listwise = round(mean(ee(f_fiml) / ee(f_lw)), 3))      # .007 y .975
# Con 5.6 % de casos incompletos el FIML casi no aporta: el resultado es el mismo que
# con listwise. El FIML sería más útil si se quiere decir algo del mecanismo (MAR por
# edad y sexo) o con faltantes simulados.
write.csv(tabla_fiml, file.path(dir_salida, "fiml_vs_listwise.csv"))

# Sensibilidad al diseño (MLR continuo, FIML): ponderador FACTOR y conglomerado UPM
xn$w <- w; xn$upm <- enco$UPM
f_w <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE, missing = "fiml", sampling.weights = "w")
f_c <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE, missing = "fiml", cluster = "upm")
c(max_dif_cargas_con_ponderador = round(max(abs(cl(f_w) - cl(f_fiml))), 3),   # .028
  razon_ee_con_cluster_UPM = round(mean(ee(f_c) / ee(f_fiml)), 3))            # 1.036
