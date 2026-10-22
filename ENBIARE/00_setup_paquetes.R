# =============================================================================
# Libro SEM · ENBIARE
# 00 - Instalación y carga de paquetes
# =============================================================================
# Referencias: base y diccionario de la ENBIARE 2021 (INEGI). Son los paquetes
# que usa el diagnóstico (y con los que se harán los 7 ejercicios).

paquetes <- c(
  "psych",       # AFE (fa), KMO, policóricas, análisis paralelo, alfa de Cronbach
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa)
  "lavaan"       # AFC, 2do orden, puntajes factoriales, invarianza, FIML
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para ENBIARE:\n")
cat(paste("-", paquetes), sep = "\n")
