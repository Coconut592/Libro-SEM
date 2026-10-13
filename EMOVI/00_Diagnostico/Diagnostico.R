# =============================================================================
# Libro SEM · EMOVI
# 00 - Diagnóstico: ¿se pueden hacer los 7 ejercicios con lo que se tiene?
# =============================================================================
# Referencias: tesis de Sánchez Flores (UNAM, 2019) "La movilidad social en la
# Ciudad de México: una aproximación desde el modelado estructural" (ESRU-EMOVI
# 2017, CDMX, n = 3,117; Mplus) y su extracto Tesis_SEMOVI.pdf (caps. 5 y 6);
# diccionario de la ESRU-EMOVI 2023 (hojas Hogar y Entrevistado) y las bases
# hogar_2023.dta e ingreso_2017.dta. Este script no es parte del libro: revisa
# qué trae cada archivo, qué de lo que pide la tesis existe en el diccionario de
# 2023 y qué corre con lo que hay. Tarda unos 40 segundos.
#   source("EMOVI/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(readstata13)
library(readxl)
library(psych)
library(lavaan)

dir_datos  <- "EMOVI/data"
dir_salida <- "EMOVI/00_Diagnostico/output"

# -----------------------------------------------------------------------
# Paso 1. Leer las bases y el diccionario
# -----------------------------------------------------------------------
# convert.factors = FALSE evita que Stata convierta los códigos en factores.
hogar <- read.dta13(file.path(dir_datos, "hogar_2023.dta"), convert.factors = FALSE)
ing17 <- read.dta13(file.path(dir_datos, "ingreso_2017.dta"), convert.factors = FALSE)

# El diccionario trae la variable solo en la primera fila de sus valores: se
# rellena hacia abajo para tener una fila por (variable, valor).
leer_hoja <- function(hoja) {
  d <- as.data.frame(read_excel(file.path(dir_datos, "Diccionario_ESRU_EMOVI_2023.xlsx"),
                                sheet = hoja, col_types = "text"))[, 1:4]
  names(d) <- c("variable", "descripcion", "valor", "etiqueta")
  d <- d[!is.na(d$variable) | !is.na(d$valor) | !is.na(d$etiqueta), ]
  d$variable <- trimws(d$variable)
  inicio <- !is.na(d$variable)
  d$variable    <- d$variable[inicio][cumsum(inicio)]
  d$descripcion <- d$descripcion[inicio][cumsum(inicio)]
  d
}
dic_hogar <- leer_hoja("Hogar")
dic_ent   <- leer_hoja("Entrevistado")
vars_hogar_dic <- unique(dic_hogar$variable)
vars_ent_dic   <- unique(dic_ent$variable)
c(Hogar = length(vars_hogar_dic), Entrevistado = length(vars_ent_dic))   # 56 y 294

# -----------------------------------------------------------------------
# Paso 2. Qué archivos hay: ¿están las bases que describe el diccionario?
# -----------------------------------------------------------------------
# El diccionario describe DOS bases de la ESRU-EMOVI 2023: Hogar (una fila por
# integrante) y Entrevistado (una fila por persona entrevistada, 294 variables).
# De ellas solo se tiene la primera.
inventario <- data.frame(
  archivo = c("hogar_2023.dta", "ingreso_2017.dta"),
  unidad = c("integrante del hogar (2023)", "persona entrevistada (2017)"),
  filas = c(nrow(hogar), nrow(ing17)),
  columnas = c(ncol(hogar), ncol(ing17)),
  llave = c("index (+ integrante)", "folio (22 dígitos, texto)"))
inventario
# hogar_2023.dta coincide con la hoja Hogar del diccionario: mismas 56 variables
setequal(names(hogar), vars_hogar_dic)
# Del Entrevistado (294 variables) solo coinciden por nombre con el roster:
intersect(vars_ent_dic, names(hogar))        # index, edad, p8, p9, p10
# ingreso_2017.dta trae `ingc_pc` (2017) y `folio`; el Entrevistado 2023 tiene su
# PROPIA `ingc_pc` (última variable): mismo nombre, otro año.
ing_2023_en_dic <- "ingc_pc" %in% vars_ent_dic
ing_2023_en_dic

# -----------------------------------------------------------------------
# Paso 3. Estructura del roster (hogar_2023.dta)
# -----------------------------------------------------------------------
n_hogares <- length(unique(hogar$index))
n_hogares                                    # 17,843 hogares
summary(as.numeric(table(hogar$index)))      # 1 a 10 integrantes, media 3.1
anyDuplicated(hogar[, c("index", "integrante")])   # 0: (index, integrante) es la llave

# p5 == 1 marca al entrevistado ("El (la) mismo (a)"): una fila por hogar.
entrevistado <- hogar[hogar$p5 %in% 1, ]
nrow(entrevistado)                           # 17,843: uno por hogar
range(entrevistado$edad)                     # 25 a 64, la población objetivo de la EMOVI
table(sexo = entrevistado$p4)                # 1 = hombre, 2 = mujer

# Lo único del Entrevistado que el roster también trae: nivel y grado de estudios
# del entrevistado (p9, p10). El resto de las 294 variables NO está.
c(con_nivel = sum(!is.na(entrevistado$p9)),
  con_nivel_y_grado = sum(!is.na(entrevistado$p9) & !is.na(entrevistado$p10)))

# Padres del entrevistado que viven hoy en el hogar (p5 == 4): no sirven como
# origen social. Es el hogar ACTUAL, no el de los 14 años, y es un subconjunto
# selecto (padres vivos, que conviven con el entrevistado).
padres <- hogar[hogar$p5 %in% 4, ]
c(hogares_con_padre_o_madre = length(unique(padres$index)),
  pct_de_entrevistados = round(100 * length(unique(padres$index)) / n_hogares, 1))

# -----------------------------------------------------------------------
# Paso 4. ingreso_2017.dta: una sola variable, y de otro año
# -----------------------------------------------------------------------
dim(ing17)                                   # 17,665 filas (= N de la ESRU-EMOVI 2017) y 2 columnas
c(folios_unicos = length(unique(ing17$folio)), longitud = unique(nchar(ing17$folio)))
round(quantile(ing17$ingc_pc, c(0, .05, .25, .5, .75, .95, 1)), 0)
round(c(media = mean(ing17$ingc_pc), asimetria = psych::skew(ing17$ingc_pc)), 2)   # muy asimétrica
# No hay estructura factorial con una sola variable, y no se puede unir con el
# roster 2023: las dos EMOVI son muestras independientes (no un panel) y las
# llaves no tienen el mismo formato (index 2 a 28,647 contra folio de 22 dígitos).
c(rango_index_2023 = paste(range(hogar$index), collapse = " a "),
  folios_2017_que_son_index_2023 = sum(suppressWarnings(as.numeric(ing17$folio)) %in% hogar$index))

# -----------------------------------------------------------------------
# Paso 5. La tesis (EMOVI 2017) frente al diccionario 2023
# -----------------------------------------------------------------------
# El modelo de la tesis (Blau y Duncan adaptado): Origen social -> Educación ->
# Primera ocupación -> Logro ocupacional (ISEI actual). Cada fila es una variable
# manifiesta de la tesis (Tabla 1) y dónde está, si está, en el diccionario 2023.
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
lista <- function(...) paste(c(...), collapse = ", ")
mapeo <- data.frame(
  constructo = c(rep("Origen social", 5), rep("Educación", 3), rep("Primera ocupación", 2),
                 "Logro ocupacional", "Demográficas", "Muestra", "Diseño muestral"),
  variable_tesis = c("x1 pisei_oc", "x2 misei_oc", "x3 ind_or", "x4 pmax_edu", "x5 anesc_p",
                     "y6 Educ", "y7 Anesc", "y8 p64", "y9 p98", "y10 jisei_1o", "z4 jisei_oc",
                     "p05, p06", "CDMX", "-"),
  descripcion = c("ISEI de la ocupación del padre", "ISEI de la ocupación de la madre",
                  "Índice de riqueza del hogar de origen (CFA, Anexo 2)",
                  "Máximo nivel educativo de padre y madre (6 categorías)",
                  "Años de escolaridad promedio de los padres",
                  "Nivel educativo del entrevistado (6 categorías)", "Años de escolaridad del entrevistado",
                  "Edad a la que dejó de asistir a la escuela", "Edad a la que tuvo su primer empleo",
                  "ISEI de la primera ocupación", "ISEI de la ocupación actual",
                  "Edad y sexo", "Entidad donde vive", "Ponderador, UPM y estrato"),
  vars_2023 = c(lista("p48_SINCO", "cmop", "clasep"), lista("p54_SINCO", "cmom", "clasem"),
                lista("p25", rango("p26", "a", "e"), rango("p29", "a", "g"), "p30",
                      rango("p31", "a", "o"), rango("p32", "a", "o")),
                lista("p42a", "p42b", "p43a", "p43b"), lista("p42a", "p42b", "p43a", "p43b"),
                lista("p9", "p10"), lista("p9", "p10"), "",
                "p77", lista("p79_SINCO", "cmoe1", "clase1"), lista("p64_SINCO", "cmo", "clase", "ocup"),
                lista("edad", "sexo", "cohorte"), "entidad", lista("factor", "upm_muestra", "est")),
  estatus = c("Construir", "Construir", "Construir", "Construir", "Construir",
              "Construir", "Construir", "No existe", "Directo", "Construir", "Construir",
              "Directo", "Directo", "Directo"),
  nota = c("Hay SINCO, CMO y clase (6 categorías), no ISEI: falta la tabla SINCO -> CIUO-08 -> ISEI-08",
           "Igual que x1; en 2017 solo 1,149 de 3,117 tenían dato (FIML)",
           "Se reconstruye con CFA binario (tesis: 12 de 26 ítems, n = 17,665); los ítems 2023 no son idénticos",
           "Se reconstruye de p42 y p43; el archivo trae `educp` y `educm` con 4 categorías, no 6",
           "Falta la regla de conversión nivel + grado -> años",
           "Se reconstruye de p9 y p10 (también en el roster); `educ` trae 4 categorías",
           "Mismo par p9 y p10: no es un indicador independiente de y6",
           "No hay equivalente: p61 es la edad en que dejó de TRABAJAR; p8 es si asiste hoy",
           "Equivalente directo (en 2017 era p98)",
           "Igual que x1", "Solo ocupados (`ocup` = 1): en 2017, 1,911 de 3,117 (FIML)",
           "En el roster se llaman `edad` y `p4`", "CDMX = 9 en `entidad`; falta ver cuántos de la muestra son",
           "La tesis no lo menciona; hay que decidir si se usa"),
  stringsAsFactors = FALSE)

# ¿Existen en el diccionario 2023 las variables que se proponen?
verifica <- function(v) {
  if (v == "") return("-")
  vv <- strsplit(v, ", ")[[1]]
  ok <- vv %in% vars_ent_dic
  if (all(ok)) "todas" else paste("faltan:", paste(vv[!ok], collapse = ", "))
}
mapeo$en_diccionario <- sapply(mapeo$vars_2023, verifica)
# Cuántas de esas variables trae también el roster (hogar_2023.dta)
mapeo$en_roster <- sapply(mapeo$vars_2023, function(v) {
  if (v == "") return("-")
  vv <- strsplit(v, ", ")[[1]]
  paste(sum(vv %in% names(hogar)), "de", length(vv))
})
mapeo[, c("variable_tesis", "estatus", "en_diccionario", "en_roster")]
table(mapeo$estatus)    # 9 se construyen (4 con ISEI), 4 directas (con 3 filas de apoyo), 1 no existe
# Entidad: ¿cuál es el código de la Ciudad de México?
dic_ent[dic_ent$variable == "entidad" & grepl("Ciudad|Distrito", dic_ent$etiqueta), c("valor", "etiqueta")]
write.csv(mapeo, file.path(dir_salida, "mapeo_tesis_2023.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. Bloques de ítems del Entrevistado 2023 para AFE, AFC, 2.º orden e invarianza
# -----------------------------------------------------------------------
# Según el diccionario (la base no está: no se sabe N, faltantes ni prevalencias).
bloques <- list(
  "Riqueza del hogar de origen (14 años): vivienda"   = rango("p26", "a", "e"),
  "Riqueza del hogar de origen (14 años): casa"       = rango("p29", "a", "g"),
  "Riqueza del hogar de origen (14 años): bienes"     = rango("p31", "a", "o"),
  "Riqueza del hogar de origen (14 años): activos"    = rango("p32", "a", "o"),
  "Colonia a los 14 años"                             = rango("p33", "a", "i"),
  "Riqueza del hogar actual: casa"                    = rango("p94", "a", "g"),
  "Riqueza del hogar actual: vivienda"                = rango("p95", "a", "e"),
  "Riqueza del hogar actual: bienes"                  = rango("p96", "a", "r"),
  "Riqueza del hogar actual: activos"                 = rango("p97", "a", "n"),
  "Colonia actual"                                    = rango("p98", "a", "i"),
  "Carencias: qué es indispensable"                   = rango("p105", "a", "o"),
  "Carencias: qué tiene el hogar"                     = rango("p106", "a", "o"),
  "Depresión (7 ítems)"                               = rango("p107", "a", "g"),
  "Ansiedad (2 ítems)"                                = rango("p108", "a", "b"))
tabla_bloques <- do.call(rbind, lapply(names(bloques), function(b) {
  v <- bloques[[b]]
  etq <- dic_ent$etiqueta[dic_ent$variable == v[1] & !is.na(dic_ent$etiqueta)]
  data.frame(bloque = b, n_items = length(v), todos_en_diccionario = all(v %in% vars_ent_dic),
             primer_item = v[1], respuestas = paste(trimws(etq), collapse = " / "))
}))
tabla_bloques[, c("bloque", "n_items", "todos_en_diccionario", "primer_item")]
write.csv(tabla_bloques, file.path(dir_salida, "bloques_items_2023.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 7. Lo único medible que trae el roster: 11 dificultades funcionales (p12_1 a p12_11)
# -----------------------------------------------------------------------
# Sí/No por cada integrante del hogar. Es lo único que hay para probar AFE, AFC,
# 2.º orden, confiabilidad, puntajes e invarianza con lo que se subió. NO es
# movilidad social.
it <- paste0("p12_", 1:11)
x <- hogar[, it]
prev <- round(100 * colMeans(x), 2)
prev                                         # de 0.13% a 4.61%
sum(prev < 10)                               # 11 de 11 caen bajo el criterio 90-10 de la tesis (Anexo 2)
sum(is.na(x))                                # 0: no hay faltantes (el FIML no aplica)
mean(rowSums(x) == 0)                        # 90.5% no tiene ninguna dificultad

# Personas con las DOS dificultades de cada pareja de ítems: de ahí salen las
# correlaciones tetracóricas
n11 <- combn(it, 2, function(p) sum(x[[p[1]]] == 1 & x[[p[2]]] == 1))
c(minimo = min(n11), mediana = median(n11), parejas_con_menos_de_10 = sum(n11 < 10), parejas = length(n11))

# AFE sobre la matriz tetracórica
rho <- suppressWarnings(suppressMessages(tetrachoric(x)$rho))
kmo <- round(KMO(rho)$MSA, 2)
set.seed(2023)
ap <- suppressWarnings(suppressMessages(fa.parallel(x, cor = "tet", fa = "fa", fm = "minres", n.iter = 20, plot = FALSE)))
afe <- lapply(1:3, function(k) suppressWarnings(suppressMessages(
  fa(rho, nfactors = k, n.obs = nrow(x), fm = "minres", rotate = if (k > 1) "oblimin" else "none"))))
afe_tabla <- data.frame(factores = 1:3, RMSEA = sapply(afe, function(f) round(f$RMSEA[1], 3)),
                        TLI = sapply(afe, function(f) round(f$TLI, 3)))
c(KMO = kmo, paralelo = ap$nfact)
afe_tabla                                    # RMSEA de .22 a .25: ningún AFE ajusta

# AFC con ítems ordinales (WLSMV)
medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
d <- hogar[, c(it, "p4")]
d[it] <- lapply(d[it], ordered)
ajusta <- function(modelo, nombre, datos = d, ...) {
  f <- suppressWarnings(cfa(modelo, data = datos, ordered = it, estimator = "WLSMV", ...))
  m <- as.numeric(round(suppressWarnings(fitMeasures(f, medidas)), 3))
  list(fit = f, fila = data.frame(modelo = nombre, converge = lavInspect(f, "converged"),
       chisq = m[1], gl = m[2], CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6]))
}
m1 <- paste("F =~", paste(it, collapse = " + "))
m3 <- "SENS =~ p12_1 + p12_2 + p12_3
       COG  =~ p12_4 + p12_5 + p12_6 + p12_8
       SOC  =~ p12_7 + p12_9 + p12_10 + p12_11"
r1  <- ajusta(m1, "1 factor")
r3  <- ajusta(m3, "3 factores (sensorial, cognitivo, social; supuesto)")
r3b <- ajusta(paste(m3, "\n G =~ SENS + COG + SOC"), "3 factores + 2.º orden (justo identificado)")
tabla_ajuste <- rbind(r1$fila, r3$fila, r3b$fila)
tabla_ajuste
# En el de 2.º orden, lavaan avisa de una varianza negativa: la varianza residual del
# factor COG sale negativa y su carga estandarizada en G pasa de 1 (caso Heywood).
round(diag(suppressWarnings(lavInspect(r3b$fit, "est"))$psi), 3)
s <- suppressWarnings(standardizedSolution(r3b$fit)); round(s$est.std[s$op == "=~" & s$lhs == "G"], 2)
round(suppressWarnings(lavInspect(r3$fit, "cor.lv")), 2)       # COG y SOC correlacionan .88

# Confiabilidad: alfa ordinal (sobre tetracóricas) y AVE/CR del modelo de 1 factor
alfa_ord <- round(suppressWarnings(psych::alpha(rho, n.obs = nrow(x)))$total$raw_alpha, 3)
l <- standardizedSolution(r1$fit); l <- l$est.std[l$op == "=~"]
c(alfa_ordinal = alfa_ord, CR = round(sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), 3), AVE = round(mean(l^2), 3))

# Puntajes factoriales (EBM, el de los ítems ordinales). Predecir los 55,477 casos
# tarda más de 2 minutos; como solo hay unos cientos de patrones de respuesta
# distintos, se predice por patrón y se cuenta a cuántas personas toca cada uno.
patron <- apply(x, 1, paste, collapse = "")
unicos <- d[!duplicated(patron), it]
pf <- as.numeric(suppressWarnings(lavPredict(r1$fit, newdata = unicos, method = "EBM")))
n_patron <- as.numeric(table(patron)[patron[!duplicated(patron)]])
c(n = nrow(x), patrones_de_respuesta = nrow(unicos),
  pct_con_el_puntaje_modal = round(100 * max(n_patron) / nrow(x), 1))   # 90.5%: todos "no"

# Invarianza por sexo (p4: 1 = hombre, 2 = mujer; se descartan 19 con "otro")
dd <- d[d$p4 %in% 1:2, ]
conf <- ajusta(m3, "configural", dd, group = "p4")
metr <- ajusta(m3, "umbrales + cargas", dd, group = "p4", group.equal = c("thresholds", "loadings"))
tabla_inv <- rbind(conf$fila, metr$fila)
tabla_inv
write.csv(rbind(cbind(tipo = "AFC", tabla_ajuste), cbind(tipo = "Invarianza por sexo", tabla_inv)),
          file.path(dir_salida, "bateria_dificultades_ajuste.csv"), row.names = FALSE)

# Los miembros de un hogar no son independientes (3.1 por hogar): sin una variable
# de agrupación real, los errores estándar de esta batería serían demasiado optimistas.
write.csv(data.frame(item = it, prevalencia_pct = prev, bajo_90_10 = prev < 10),
          file.path(dir_salida, "bateria_dificultades_prevalencia.csv"), row.names = FALSE)
