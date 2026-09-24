# =============================================================================
# Libro SEM · Datos Violencia Veracruz
# 00 - Instalación y carga de paquetes
# =============================================================================

paquetes <- c(
  "tidyverse",  # manejo de datos y gráficos
  "haven",      # leer bases de Stata (.dta) con sus etiquetas
  "labelled",   # diccionario de variables a partir de las etiquetas
  "naniar",     # exploración de datos faltantes
  "psych",      # correlaciones tetracóricas, alfa de Cronbach
  "poLCA"       # modelos de clases latentes (se usa en los scripts siguientes)
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))
invisible(lapply(paquetes, library, character.only = TRUE))

cat("Paquetes listos para Datos Violencia Veracruz:\n")
cat(paste("-", paquetes), sep = "\n")
