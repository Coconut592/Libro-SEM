# =============================================================================
# Libro SEM · Datos Violencia Veracruz
# 01 - Análisis exploratorio de la base BASE_ACLnew.dta
# =============================================================================
#
# Base de Stata (versión 13, 3 nov 2018) con 1,089 mujeres y 37 variables:
#   - Sociodemográficas: p1 (indígena), p2 (edad, grupos), p3 (lee y
#     escribe), p4 (escolaridad), p5 (ocupación), p7 (recibe dinero de
#     persona/programa), p9 (estado civil), p13 (edad al primer embarazo),
#     p62 (ha escuchado de los derechos de las mujeres).
#   - 24 indicadores dicotómicos (0 = No, 1 = Sí) de violencia en 6 ámbitos:
#     niñez (p141-p144), familia (p161, p162, p165), pareja (p171-p176),
#     trabajo (p183-p186), comunidad/calle (p191-p194) y escuela (p201-p204).
#     Son los indicadores candidatos para el modelo de clases latentes.
#   - c / c_r: variable de agrupación de 3 categorías SIN etiquetas de valor
#     (c_r es c recodificada al revés: 1<->3). Confirmar con el profesor qué
#     representa (¿ciudad, región, estrato?).
#   - _merge: residuo de un merge de Stata; solo 1 caso es "using only" y no
#     tiene respuestas, así que se elimina.
#
# Pensado para correrse en VSCode (extensión "R" + paquete languageserver)
# o RStudio, con el directorio de trabajo en la raíz del repositorio:
#   setwd("ruta/a/Libro-SEM")
#   source("Datos_Violencia_Veracruz/scripts/01_analisis_exploratorio.R")
# En VSCode también puedes ir corriendo sección por sección con Ctrl+Enter.
# Las tablas y gráficas se guardan en Datos_Violencia_Veracruz/output/.
# =============================================================================

library(tidyverse)
library(haven)
library(labelled)
library(naniar)
library(psych)

ruta_dta   <- "Datos_Violencia_Veracruz/data/BASE_ACLnew.dta"
dir_salida <- "Datos_Violencia_Veracruz/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# 1. Lectura y limpieza mínima
# -----------------------------------------------------------------------
# Es un .dta de Stata 13 (anterior a Unicode), los acentos vienen en latin1
base_raw <- read_dta(ruta_dta, encoding = "latin1")

dim(base_raw)                     # 1089 x 37
anyDuplicated(base_raw$id) == 0   # id es identificador único
count(base_raw, `_merge`)         # 1088 "matched (3)", 1 "using only (2)"

base <- base_raw |>
  filter(`_merge` == 3) |>
  select(-`_merge`)

# Versión numérica (sin etiquetas) para cálculos, y versión con factores
# (etiquetas de Stata como niveles) para tablas y gráficas
base_num <- base |> zap_labels() |> zap_label() |> zap_formats()
base_fct <- as_factor(base, levels = "labels")

# -----------------------------------------------------------------------
# 2. Diccionario de variables (nombre, pregunta y etiquetas de valor)
# -----------------------------------------------------------------------
look_for(base)   # vista rápida en consola (también sirve look_for(base, "pareja"))

diccionario <- tibble(
  variable  = names(base),
  pregunta  = map_chr(base, \(x) var_label(x) %||% NA_character_),
  etiquetas = map_chr(base, \(x) {
    et <- val_labels(x)
    if (is.null(et)) NA_character_ else paste(et, names(et), sep = " = ", collapse = "; ")
  }),
  n_validos = map_int(base, \(x) sum(!is.na(x)))
)
print(diccionario, n = Inf)
write_csv(diccionario, file.path(dir_salida, "diccionario_variables.csv"))

# Indicadores de violencia agrupados por ámbito
ambitos <- list(
  ninez     = c("p141", "p142", "p143", "p144"),
  familia   = c("p161", "p162", "p165"),
  pareja    = c("p171", "p172", "p173", "p175", "p176"),
  trabajo   = c("p183", "p184", "p185", "p186"),
  comunidad = c("p191", "p192", "p193", "p194"),
  escuela   = c("p201", "p202", "p203", "p204")
)
items <- unlist(ambitos, use.names = FALSE)

info_items <- tibble(
  item   = items,
  ambito = rep(names(ambitos), lengths(ambitos)),
  texto  = map_chr(items, \(v) var_label(base[[v]]) %||% v)
)

sociodem <- c("p1", "p2", "p3", "p4", "p5", "p7", "p9", "p13", "p62")

# -----------------------------------------------------------------------
# 3. Variable de agrupación c
# -----------------------------------------------------------------------
count(base_num, c, c_r)   # c = 1 -> c_r = 3, c = 2 -> 2, c = 3 -> 1
count(base_num, c) |> mutate(pct = round(100 * n / sum(n), 1))

# -----------------------------------------------------------------------
# 4. Perfil sociodemográfico
# -----------------------------------------------------------------------
tabla_frecuencias <- function(datos, var) {
  datos |>
    count(categoria = .data[[var]]) |>
    mutate(
      variable = var,
      pregunta = var_label(base[[var]]) %||% var,
      pct      = round(100 * n / sum(n), 1),
      pct_validos = if_else(is.na(categoria), NA_real_,
                            round(100 * n / sum(n[!is.na(categoria)]), 1)),
      categoria = as.character(categoria)
    ) |>
    relocate(variable, pregunta)
}

frec_sociodem <- map(c(sociodem, "c"), \(v) tabla_frecuencias(base_fct, v)) |>
  list_rbind()
print(frec_sociodem, n = Inf)
write_csv(frec_sociodem, file.path(dir_salida, "frecuencias_sociodemograficas.csv"))

g_sociodem <- frec_sociodem |>
  filter(!is.na(categoria)) |>
  mutate(categoria = fct_inorder(categoria)) |>
  ggplot(aes(x = pct_validos, y = fct_rev(categoria))) +
  geom_col(fill = "#3B6FB6") +
  geom_text(aes(label = pct_validos), hjust = -0.15, size = 3) +
  facet_wrap(~ variable, scales = "free_y", ncol = 3) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Perfil sociodemográfico (% sobre respuestas válidas)",
       x = "%", y = NULL) +
  theme_minimal(base_size = 10)
g_sociodem
ggsave(file.path(dir_salida, "01_perfil_sociodemografico.png"), g_sociodem,
       width = 11, height = 9, dpi = 150)

# -----------------------------------------------------------------------
# 5. Datos faltantes: ¿al azar o por salto de pregunta?
# -----------------------------------------------------------------------
faltantes <- miss_var_summary(base_num)
print(faltantes, n = Inf)
write_csv(faltantes, file.path(dir_salida, "datos_faltantes.csv"))

g_faltantes <- gg_miss_var(base_num, show_pct = TRUE) +
  labs(title = "% de datos faltantes por variable")
g_faltantes
ggsave(file.path(dir_salida, "02_datos_faltantes.png"), g_faltantes,
       width = 7, height = 8, dpi = 150)

# Los huecos grandes NO son no-respuesta al azar, son saltos del
# cuestionario (la pregunta no aplica):
#   - Pareja (p171-p176, ~29% NA): casi todas son solteras, separadas,
#     divorciadas o viudas (p9 = 1-4). Casadas/unión libre casi no tienen NA.
base_fct |>
  count(p9, falta_pareja = is.na(p171)) |>
  pivot_wider(names_from = falta_pareja, values_from = n,
              names_prefix = "p171_NA_", values_fill = 0)

#   - Trabajo (p183-p186, ~23% NA): se concentran en amas de casa (p5 = 2),
#     es decir, mujeres que no han tenido un trabajo remunerado.
base_fct |>
  count(p5, falta_trabajo = is.na(p183)) |>
  pivot_wider(names_from = falta_trabajo, values_from = n,
              names_prefix = "p183_NA_", values_fill = 0)

#   - Primer embarazo (p13, ~20% NA): presumiblemente no ha estado embarazada.
#   - Escuela (p201-p204, ~6% NA): revisar contra escolaridad (p4 = Ninguna).
base_fct |>
  count(p4, falta_escuela = is.na(p201)) |>
  pivot_wider(names_from = falta_escuela, values_from = n,
              names_prefix = "p201_NA_", values_fill = 0)

# Mapa de faltantes en los indicadores de violencia (filas = mujeres):
# los bloques de pareja y trabajo faltan juntos, confirmando el salto
vis_miss(base_num[items])

# -----------------------------------------------------------------------
# 6. Prevalencia de cada tipo de violencia
# -----------------------------------------------------------------------
prevalencias <- base_num |>
  select(all_of(items)) |>
  pivot_longer(everything(), names_to = "item", values_to = "resp") |>
  group_by(item) |>
  summarise(
    n_validos   = sum(!is.na(resp)),
    n_si        = sum(resp == 1, na.rm = TRUE),
    prevalencia = round(100 * mean(resp, na.rm = TRUE), 1),
    pct_na      = round(100 * mean(is.na(resp)), 1),
    .groups = "drop"
  ) |>
  left_join(info_items, by = "item") |>
  mutate(item = factor(item, levels = items)) |>
  arrange(item) |>
  relocate(ambito, item, texto)
print(prevalencias, n = Inf)
write_csv(prevalencias, file.path(dir_salida, "prevalencias_violencia.csv"))

g_prev <- prevalencias |>
  mutate(ambito = factor(ambito, levels = names(ambitos))) |>
  ggplot(aes(x = prevalencia, y = fct_rev(item), fill = ambito)) +
  geom_col() +
  geom_text(aes(label = prevalencia), hjust = -0.15, size = 3) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Prevalencia de cada indicador de violencia",
       subtitle = "% de 'Sí' sobre respuestas válidas",
       x = "%", y = NULL, fill = "Ámbito") +
  theme_minimal(base_size = 10)
g_prev
ggsave(file.path(dir_salida, "03_prevalencias_violencia.png"), g_prev,
       width = 8, height = 7, dpi = 150)

# Indicadores muy raros (< 5%) aportan poca información a un LCA y pueden
# producir probabilidades condicionales en la frontera (0 o 1)
prevalencias |> filter(prevalencia < 5) |> select(ambito, item, prevalencia)

# -----------------------------------------------------------------------
# 7. Conteo de violencias por ámbito
# -----------------------------------------------------------------------
# Para cada ámbito: número de indicadores con "Sí" (NA si el ámbito no
# aplica, es decir, si todos sus indicadores son NA) y si hubo al menos uno
conteos <- imap(ambitos, \(vars, nombre) {
  x <- base_num[vars]
  todos_na <- rowSums(!is.na(x)) == 0
  tibble(
    !!paste0("n_", nombre)   := if_else(todos_na, NA_real_, rowSums(x, na.rm = TRUE)),
    !!paste0("alg_", nombre) := if_else(todos_na, NA_real_, as.numeric(rowSums(x, na.rm = TRUE) > 0))
  )
}) |> list_cbind()

base_num <- bind_cols(base_num, conteos)

# % de mujeres con al menos una violencia en cada ámbito
base_num |>
  summarise(across(starts_with("alg_"), \(x) round(100 * mean(x, na.rm = TRUE), 1)))

# Distribución del número total de violencias (sobre los ámbitos que aplican)
base_num <- base_num |>
  mutate(total_violencias = rowSums(across(all_of(items)), na.rm = TRUE))
count(base_num, total_violencias)

g_total <- ggplot(base_num, aes(x = total_violencias)) +
  geom_bar(fill = "#3B6FB6") +
  labs(title = "Número de indicadores de violencia reportados por mujer",
       x = "Total de 'Sí' (de 24 indicadores)", y = "Mujeres") +
  theme_minimal()
g_total
ggsave(file.path(dir_salida, "04_total_violencias.png"), g_total,
       width = 7, height = 4, dpi = 150)

# -----------------------------------------------------------------------
# 8. Asociación entre indicadores: correlaciones tetracóricas y KR-20
# -----------------------------------------------------------------------
# Para variables dicotómicas la correlación de Pearson subestima la
# asociación; la tetracórica supone una variable continua latente detrás
# de cada indicador. (Advertencias en pares con celdas vacías son normales
# en los indicadores muy raros.)
tetra <- tetrachoric(as.data.frame(base_num[items]), na.rm = TRUE)
rho   <- tetra$rho

g_tetra <- rho |>
  as_tibble(rownames = "item1") |>
  pivot_longer(-item1, names_to = "item2", values_to = "rho") |>
  mutate(item1 = factor(item1, levels = items),
         item2 = factor(item2, levels = rev(items))) |>
  ggplot(aes(item1, item2, fill = rho)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.1f", rho)), size = 2) +
  scale_fill_gradient2(low = "#B2182B", mid = "white", high = "#2166AC",
                       limits = c(-1, 1)) +
  labs(title = "Correlaciones tetracóricas entre indicadores de violencia",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 9) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
g_tetra
ggsave(file.path(dir_salida, "05_correlaciones_tetracoricas.png"), g_tetra,
       width = 9, height = 8, dpi = 150)

# Consistencia interna por ámbito (alfa de Cronbach = KR-20 en dicotómicas)
fiabilidad <- imap(ambitos, \(vars, nombre) {
  a <- psych::alpha(as.data.frame(base_num[vars]), warnings = FALSE,
                    check.keys = FALSE)
  tibble(ambito = nombre, n_items = length(vars),
         alfa_KR20 = round(a$total$raw_alpha, 2))
}) |> list_rbind()
fiabilidad

# -----------------------------------------------------------------------
# 9. Violencia según características de las mujeres
# -----------------------------------------------------------------------
prevalencia_por <- function(var_grupo) {
  base_num |>
    mutate(grupo = base_fct[[var_grupo]]) |>
    filter(!is.na(grupo)) |>
    group_by(grupo) |>
    summarise(n = n(),
              across(starts_with("alg_"),
                     \(x) round(100 * mean(x, na.rm = TRUE), 1)),
              .groups = "drop") |>
    mutate(variable = var_grupo, grupo = as.character(grupo)) |>
    relocate(variable)
}

por_grupo <- map(c("c", "p1", "p2", "p4", "p9"), prevalencia_por) |>
  list_rbind()
print(por_grupo, n = Inf, width = Inf)
write_csv(por_grupo, file.path(dir_salida, "violencia_por_grupo.csv"))

# Pruebas chi-cuadrada: ¿la violencia en cada ámbito difiere entre los
# grupos de c y entre indígenas / no indígenas?
chi_por <- function(var_grupo) {
  map(names(ambitos), \(amb) {
    tab <- table(base_num[[var_grupo]], base_num[[paste0("alg_", amb)]])
    p   <- suppressWarnings(chisq.test(tab)$p.value)
    tibble(grupo = var_grupo, ambito = amb, p_valor = round(p, 4))
  }) |> list_rbind()
}
bind_rows(chi_por("c"), chi_por("p1"))

# -----------------------------------------------------------------------
# 10. Implicaciones para el Análisis de Clases Latentes
# -----------------------------------------------------------------------
# a) Casos completos: si se usan los 24 indicadores, el listwise deja
#    ~505 casos (se pierden sobre todo las mujeres sin pareja o sin
#    trabajo). Sin pareja y trabajo quedan ~986.
sum(complete.cases(base_num[items]))
items_sin_pareja_trabajo <- setdiff(items, c(ambitos$pareja, ambitos$trabajo))
sum(complete.cases(base_num[items_sin_pareja_trabajo]))

# b) poLCA maneja NA con máxima verosimilitud (na.rm = FALSE), pero como
#    aquí los NA son saltos de cuestionario, hay que decidir si esos
#    ámbitos entran al modelo, si se modela solo la submuestra a la que
#    aplican, o si se usan los indicadores resumen por ámbito (alg_*).
# c) Número de patrones de respuesta distintos frente a los 2^k posibles:
#    muchos patrones vacíos = tabla dispersa, y el estadístico G² / chi²
#    del LCA pierde validez (usar BIC / bootstrap LRT para elegir clases).
patrones <- base_num |>
  filter(complete.cases(across(all_of(items_sin_pareja_trabajo)))) |>
  count(across(all_of(items_sin_pareja_trabajo)), sort = TRUE)
nrow(patrones)                             # patrones observados
2^length(items_sin_pareja_trabajo)         # patrones posibles
head(patrones, 10)

# d) Recodificación para poLCA: exige categorías 1, 2, ... (no 0/1)
base_lca <- base_num |>
  mutate(across(all_of(items), \(x) x + 1))   # 1 = No, 2 = Sí

cat("\nAnálisis exploratorio terminado. Resultados en", dir_salida, "\n")
