# =============================================================================
# Libro SEM · EMOVI
# 00 - Instalación y carga de paquetes
# =============================================================================
# Referencias: tesis de Sánchez Flores (UNAM, 2019; Mplus) y diccionario de la
# ESRU-EMOVI 2023. Son los paquetes que usan el diagnóstico y los 7 ejercicios.

paquetes <- c(
  "readstata13", # leer las bases de Stata (.dta)
  "readxl",      # leer el diccionario de la ESRU-EMOVI 2023 (.xlsx)
  "psych",       # AFE (fa), KMO, tetracóricas, análisis paralelo, alfa de Cronbach
  "GPArotation", # rotación oblimin del AFE (la usa psych::fa)
  "lavaan"       # AFC, 2do orden, puntajes factoriales, invarianza
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("Paquetes listos para EMOVI:\n")
cat(paste("-", paquetes), sep = "\n")
