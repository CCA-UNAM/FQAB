#!/bin/bash
#
# Codigo para convertir archivos codificados en Roman a UTF-8
# Busca todos lo archivos en tex y los transforma a de macintosh a UTF-8
## Busca todos lo archivos en tex y los transforma a de iUTF-8 a macintosh 
#find . -name "*.tex" -exec bash -c 'mv $1 $1.WXY; iconv -f UTF-8  -t macintosh $1.WXY > $1; rm $1.WXY' sh {} \;
# Busca todos lo archivos en tex y los transforma a de macintosh a UTF-8
#find . -name "*.tex" -exec bash -c 'mv $1 $1.WXY; iconv  -f MACROMAN -t UTF-8 $1.WXY > $1; rm $1.WXY' sh {} \;
lista=$(ls *tex)
for FILE in $lista
do
mv $FILE ${FILE}.WXY
iconv -f MACROMAN -t UTF-8 ${FILE}.WXY > $FILE
done