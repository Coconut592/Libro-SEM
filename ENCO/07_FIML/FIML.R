# =============================================================================
# Libro SEM · ENCO
# 07 - FIML: Confianza del consumidor con datos faltantes
# =============================================================================
# Sin referencia: el documento de INEGI no trae tratamiento de faltantes. Los únicos
# faltantes REALES son los "No sabe" (115 personas, 5.6 %). Se hace el AFC de cuatro
# factores y se compara listwise contra FIML. No se simulan faltantes.
#   source("ENCO/07_FIML/FIML.R")
# =============================================================================

library(foreign)
library(lavaan)

dir_salida <- "ENCO/07_FIML/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos (igual que en 02_AFC) y modelo
# -----------------------------------------------------------------------
# merge() reordena las filas por llave: de aquí en adelante TODO sale de `enco`.
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
cs <- read.dbf("ENCO/data/encocs_0826.DBF", as.is = TRUE)
llave <- c("FOL", "CVE_ENT", "CON", "V_SEL", "N_HOG", "H_MUD", "N_REN")
enco <- merge(cb, cs[, c(llave, "SEX", "EDA")], by = llave)
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

modelo <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15'

# -----------------------------------------------------------------------
# Paso 2. Cuántos datos faltan, y quién no sabe
# -----------------------------------------------------------------------
faltantes <- data.frame(item = items, n_NA = colSums(is.na(x)), pct_NA = round(100 * colMeans(is.na(x)), 1),
                        row.names = NULL)
faltantes                                    # de 1 caso (P1, P3, P7, P14, P15) a 34 (P13, 1.7 %)
c(completos = sum(complete.cases(x)), con_algun_NS = sum(!complete.cases(x)),
  pct = round(100 * mean(!complete.cases(x)), 1))
table(faltantes_por_persona = rowSums(is.na(x)))   # 96 tienen 1 ítem sin respuesta, 14 tienen 2 y el máximo es 9
write.csv(faltantes, file.path(dir_salida, "faltantes.csv"), row.names = FALSE)

# ¿Es al azar? Quien no sabe es mayor (+.022 en logit por año, p < .001) y, algo más, mujer
# (+.41, p = .046): el faltante depende de variables que sí se observan, que es el supuesto
# de FIML (MAR); no se puede comprobar que no dependa también de lo que no se contestó. Los 115
# puntúan algo más bajo en lo que sí contestaron (.54 contra .58 en el promedio de 0 a 1),
# coherente con que sean mayores.
no_sabe <- as.integer(!complete.cases(x))
edad <- as.numeric(enco$EDA)
mujer <- as.integer(enco$SEX == "2")
round(summary(glm(no_sabe ~ edad + mujer, family = binomial))$coefficients, 3)
round(tapply(rowMeans(x / matrix(maximo, nrow(x), 15, byrow = TRUE), na.rm = TRUE), no_sabe, mean), 3)

# -----------------------------------------------------------------------
# Paso 3. AFC de cuatro factores: listwise contra FIML
# -----------------------------------------------------------------------
# lavaan no ofrece FIML con ítems ordinales (probado: `missing = "fiml" not available
# in the categorical setting`), solo con indicadores continuos. Así que aquí los ítems
# se tratan como NUMÉRICOS, con MLR (errores estándar robustos) y std.lv = TRUE
# (varianza del factor = 1). No es lo ideal con ítems de 2 o 3 categorías (P7-P10, P14,
# P15): por eso el ajuste es peor que en el AFC ordinal (02).
try(cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "fiml"), silent = FALSE)
xn <- x
xn[] <- lapply(xn, as.numeric)
fit_lw   <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE)                       # listwise
fit_fiml <- cfa(modelo, data = xn, estimator = "MLR", std.lv = TRUE, missing = "fiml")    # FIML

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit_lw, "Listwise"), ajuste(fit_fiml, "FIML"))
tabla_ajuste
# N: 1,935 contra 2,050 (+6 %). El ajuste es el mismo: CFI .935 y .936, RMSEA .068 y .067.
# (Con ítems continuos el ajuste es peor que con ordinales: CFI .936 contra .975 en 02.)
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_listwise_vs_fiml.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y errores estándar
# -----------------------------------------------------------------------
carga <- function(f) { s <- standardizedSolution(f); s[s$op == "=~", "est.std"] }
ee <- function(f) { p <- parameterEstimates(f); p[p$op == "=~", "se"] }
fo <- parameterEstimates(fit_fiml)
comparacion <- data.frame(factor = fo$lhs[fo$op == "=~"], item = fo$rhs[fo$op == "=~"],
                          carga_listwise = round(carga(fit_lw), 3), carga_FIML = round(carga(fit_fiml), 3),
                          ee_listwise = round(ee(fit_lw), 3), ee_FIML = round(ee(fit_fiml), 3))
comparacion$razon_ee <- round(comparacion$ee_FIML / comparacion$ee_listwise, 2)
comparacion
c(max_dif_cargas = round(max(abs(comparacion$carga_FIML - comparacion$carga_listwise)), 3),
  razon_ee_promedio = round(mean(comparacion$razon_ee), 3))
# Las cargas cambian hasta .007 y los errores estándar de FIML son 98 % de los de listwise: con
# 5.6 % de casos incompletos y casi todos con un solo ítem faltante, el FIML casi no aporta;
# da el mismo resultado y conserva a las 115 personas. Las correlaciones entre factores
# cambian hasta .01.
write.csv(comparacion, file.path(dir_salida, "cargas_listwise_vs_fiml.csv"), row.names = FALSE)

# Correlaciones entre factores: listwise contra FIML
round(cbind(listwise = lavInspect(fit_lw, "cor.lv")[lower.tri(diag(4))],
            FIML = lavInspect(fit_fiml, "cor.lv")[lower.tri(diag(4))]), 2)

# -----------------------------------------------------------------------
# Paso 5. Contra el AFC ordinal (02): ¿cambia la estructura al tratar los ítems como continuos?
# -----------------------------------------------------------------------
fit_ord <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")
cargas_ord <- standardizedSolution(fit_ord); cargas_ord <- cargas_ord[cargas_ord$op == "=~", "est.std"]
data.frame(item = comparacion$item, ordinal = round(cargas_ord, 2), continuo_FIML = round(comparacion$carga_FIML, 2))
round(cor(cargas_ord, comparacion$carga_FIML), 3)
# Las cargas continuas son más bajas (de .43 a .86 contra .48 a .91), sobre todo en los
# ítems de 2 y 3 categorías (P9, P10, P14, P15: de .13 a .19 menos), pero el orden es el mismo
# (r = .93): tratar los ítems como continuos para el FIML no cambia la estructura.
