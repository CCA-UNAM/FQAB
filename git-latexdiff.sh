#!/bin/bash
# Script: git-latexdiff.sh
# Descripción: Compara dos versiones de un archivo LaTeX usando git y latexdiff,
#              con soporte mejorado para tags.
# Uso: ./git-latexdiff.sh <commit1> <commit2> <ruta-del-archivo>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mostrar_ayuda() {
    cat <<EOF
Uso: $0 <referencia1> <referencia2> <archivo>

Compara dos versiones de un archivo LaTeX almacenado en git usando latexdiff.
Las referencias pueden ser:
  - Tags: v1.0, v2.0, etc.
  - Ramas: main, develop, feature/nueva
  - Commits: HEAD~3, 1a2b3c4, etc.

Ejemplos:
  $0 v1.0 HEAD tesis.tex
  $0 v1.0 v2.0 capitulos/intro.tex
  $0 main feature-branch articulo.tex
EOF
    exit 1
}

# Función para validar que una referencia existe en git
validar_referencia() {
    local ref=$1
    local tipo=$2
    
    if git rev-parse --verify "$ref" >/dev/null 2>&1; then
        # Determinar el tipo de referencia
        if git show-ref --tags | grep -q "refs/tags/$ref$"; then
            echo -e "${GREEN}✓ $tipo: Tag '$ref' encontrado${NC}"
        elif git show-ref --heads | grep -q "refs/heads/$ref$"; then
            echo -e "${GREEN}✓ $tipo: Rama '$ref' encontrada${NC}"
        else
            echo -e "${GREEN}✓ $tipo: Commit '$ref' encontrado${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Error: La referencia '$ref' no existe en el repositorio${NC}"
        return 1
    fi
}

# Función para obtener información detallada de una referencia
info_referencia() {
    local ref=$1
    local commit_hash=$(git rev-parse --short "$ref")
    local commit_msg=$(git log -1 --pretty=%s "$ref" 2>/dev/null | cut -c1-50)
    
    if git describe --exact-match "$ref" 2>/dev/null; then
        echo -e "${YELLOW}  Tag: $(git describe --exact-match "$ref")${NC}"
    fi
    echo -e "${YELLOW}  Hash: $commit_hash${NC}"
    echo -e "${YELLOW}  Mensaje: $commit_msg${NC}"
}

# Verificar argumentos
if [ $# -ne 3 ]; then
    mostrar_ayuda
fi

REF1="$1"
REF2="$2"
FILE="$3"

# Verificar que estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: No estás dentro de un repositorio git.${NC}"
    exit 1
fi

# Validar referencias
echo "Validando referencias..."
validar_referencia "$REF1" "Primera referencia" || exit 1
validar_referencia "$REF2" "Segunda referencia" || exit 1

# Verificar que el archivo existe en ambas referencias
echo -e "\n${YELLOW}Verificando archivo...${NC}"
for ref in "$REF1" "$REF2"; do
    if ! git show "$ref":"$FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: El archivo '$FILE' no existe en la referencia $ref${NC}"
        echo "Archivos disponibles en esa referencia:"
        git ls-tree --name-only "$ref" | grep -i "\.tex$" | head -5
        exit 1
    fi
done

# Mostrar información de las referencias
echo -e "\n${YELLOW}Información de las referencias:${NC}"
echo "Primera referencia ($REF1):"
info_referencia "$REF1"
echo "Segunda referencia ($REF2):"
info_referencia "$REF2"

# Verificar herramientas necesarias
echo -e "\n${YELLOW}Verificando herramientas...${NC}"
for cmd in latexdiff pdflatex; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo -e "${RED}Error: No se encuentra el comando '$cmd'${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $cmd encontrado${NC}"
    fi
done

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Obtener los archivos de las referencias
OLD_TEX="$TEMP_DIR/old.tex"
NEW_TEX="$TEMP_DIR/new.tex"
DIFF_TEX="$TEMP_DIR/diff.tex"
DIFF_PDF="$TEMP_DIR/diff.pdf"

echo -e "\n${YELLOW}Extrayendo archivos...${NC}"
git show "$REF1":"$FILE" > "$OLD_TEX"
git show "$REF2":"$FILE" > "$NEW_TEX"
echo -e "${GREEN}✓ Archivos extraídos correctamente${NC}"

# Generar diff
echo -e "\n${YELLOW}Generando diferencias con latexdiff...${NC}"
latexdiff "$OLD_TEX" "$NEW_TEX" > "$DIFF_TEX"
echo -e "${GREEN}✓ Diff generado${NC}"

# Compilar PDF (hasta 3 pasadas para referencias cruzadas)
echo -e "\n${YELLOW}Compilando PDF...${NC}"
for i in 1 2 3; do
    echo "  Pasada $i de 3..."
    pdflatex -interaction=nonstopmode -output-directory="$TEMP_DIR" "$DIFF_TEX" > /dev/null 2>&1 || {
        echo -e "${RED}Error en la compilación. Revisa el archivo .log${NC}"
        exit 1
    }
done

# Verificar que el PDF se generó
if [ ! -f "$DIFF_PDF" ]; then
    echo -e "${RED}Error: No se pudo generar el PDF${NC}"
    exit 1
fi

# Generar nombre para el PDF con información de los tags
OUTPUT_NAME="diff_${REF1}_to_${REF2}.pdf"
mv "$DIFF_PDF" "./$OUTPUT_NAME"
echo -e "\n${GREEN}✓ PDF generado: ./$OUTPUT_NAME${NC}"

# Mostrar resumen
echo -e "\n${YELLOW}Resumen:${NC}"
echo "  Comparación: $REF1 -> $REF2"
echo "  Archivo: $FILE"
echo "  Tamaño del PDF: $(du -h "./$OUTPUT_NAME" | cut -f1)"

# Abrir el PDF si es posible
if [ -f "./$OUTPUT_NAME" ]; then
    if command -v xdg-open > /dev/null; then
        xdg-open "./$OUTPUT_NAME"
    elif command -v open > /dev/null; then
        open "./$OUTPUT_NAME"
    else
        echo -e "\n${YELLOW}Puedes abrir el PDF manualmente: ./$OUTPUT_NAME${NC}"
    fi
fi

echo -e "\n${GREEN}Proceso completado exitosamente.${NC}"
