#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
YELLOW='\033[1;33m'

# Configuración de directorios
EXERCISE="ft_popen"
GRADEME_DIR="$(cd "$(dirname "$0")" && pwd)"
STUDENT_DIR="../../../../rendu/$EXERCISE"

echo -e "${BLUE}🧪 FT_POPEN COMPREHENSIVE TESTER${NC}"
echo -e "${BLUE}===================================${NC}"

# Verificar que existe el directorio del estudiante
if [ ! -d "$STUDENT_DIR" ]; then
    echo -e "${RED}❌ Error: No se encuentra el directorio $STUDENT_DIR${NC}"
    echo -e "${YELLOW}💡 Crea tu solución: mkdir -p rendu/ft_popen && cp your_ft_popen.c rendu/ft_popen/ft_popen.c${NC}"
    exit 1
fi

# Verificar que existe el archivo del estudiante
if [ ! -f "$STUDENT_DIR/ft_popen.c" ]; then
    echo -e "${RED}❌ Error: No se encuentra ft_popen.c en $STUDENT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Testing solution at: $STUDENT_DIR/ft_popen.c${NC}"
echo ""

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copiar archivos necesarios
cp "$STUDENT_DIR"/* "$TEMP_DIR"
cp test_main.c "$TEMP_DIR"

# Ir al directorio temporal
cd "$TEMP_DIR"

# Smart compilation with compiler-based main conflict detection
echo -e "${BLUE}📦 Compilando...${NC}"
if gcc -Wall -Wextra -Werror ft_popen.c test_main.c -o test_program 2>compile_error.txt; then
    echo -e "${GREEN}✅ Compilación exitosa${NC}"
else
    # Check if the error is specifically about multiple main functions
    if grep -q -E "(multiple definition.*main|duplicate symbol.*main)" compile_error.txt; then
        echo -e "${YELLOW}⚠️  Conflicto de función main detectado - limpiando...${NC}"
        
        # Remove main function from student file
        sed '/^[[:space:]]*int[[:space:]]*main[[:space:]]*(/,$d' ft_popen.c > ft_popen_clean.c
        mv ft_popen_clean.c ft_popen.c
        
        # Try to compile again
        echo -e "${BLUE}📦 Recompilando sin función main...${NC}"
        if gcc -Wall -Wextra -Werror ft_popen.c test_main.c -o test_program 2>/dev/null; then
            echo -e "${GREEN}✅ Conflicto de main resuelto${NC}"
        else
            echo -e "${RED}❌ Error de compilación persiste después de limpiar main${NC}"
            echo -e "${YELLOW}💡 Revisa tu implementación de ft_popen${NC}"
            rm -f compile_error.txt
            exit 1
        fi
    else
        echo -e "${RED}❌ Error de compilación (no relacionado con main)${NC}"
        echo -e "${YELLOW}Detalles del error:${NC}"
        cat compile_error.txt
        echo -e "${YELLOW}💡 Revisa que tu función ft_popen esté correctamente implementada${NC}"
        echo -e "${YELLOW}💡 Asegúrate de que compile con -Wall -Wextra -Werror${NC}"
        rm -f compile_error.txt
        exit 1
    fi
fi

# Clean up error file
rm -f compile_error.txt
echo ""

# Ejecutar tests
echo -e "${BLUE}🚀 Ejecutando tests...${NC}"
echo ""

# Ejecutar el programa de test con timeout
timeout 10 ./test_program
test_result=$?

echo ""
if [ $test_result -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON!${NC}"
    echo -e "${GREEN}Tu implementación de ft_popen funciona correctamente.${NC}"
    exit 0
elif [ $test_result -eq 124 ]; then
    echo -e "${RED}⏰ Tests timeout - posible bucle infinito o deadlock${NC}"
    exit 1
else
    echo -e "${RED}❌ Algunos tests fallaron.${NC}"
    echo -e "${YELLOW}💡 Revisa tu implementación y vuelve a intentar.${NC}"
    exit 1
fi