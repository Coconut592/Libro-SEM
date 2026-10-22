# =============================================================================
# Libro SEM · ENCO
# 00 - Instalación y carga de paquetes
# =============================================================================
# Referencia: INEGI, "Encuesta Nacional sobre Confianza del Consumidor (ENCO).
# Estructura de la base de datos" (2025). Son los paquetes que usan el
# diagnóstico y los 7 ejercicios.

paquetes <- c(
  "foreign",     # leer las bases de INEGI (.DBF) con read.dbf
  "psych",       # AFE (fa), KMO, policóricas, análisis paralelo, alfa y omega
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa y psych::omega)
  "lavaan"       # AFC, 2do orden, puntajes factoriales, invarianza, FIML
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para ENCO:\n")
cat(paste("-", paquetes), sep = "\n")
