find . -name "*.tex" -exec bash -c 'mv $1 $1.WXY; iconv -f macintosh  -t UTF-8 $1.WXY > $1; rm $1.WXY' sh {} \;

