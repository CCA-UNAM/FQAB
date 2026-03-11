#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import pathlib

bibfile = "fqba.bib"
outtex = "glossary_entries.tex"

# -----------------------------
# Leer archivo bib
# -----------------------------
with open(bibfile, encoding="utf-8") as f:
    content = f.read()

entries = re.findall(r'@GLOSSDEF\s*{([^,]+),(.*?)}\s*', content, re.S)

gloss_entries = []

for key, body in entries:

    word = re.search(r'word\s*=\s*["{](.*?)["}]', body)
    definition = re.search(r'definition\s*=\s*[{"](.*?)[}"]', body, re.S)
    sort = re.search(r'sort-word\s*=\s*[{"](.*?)[}"]', body)

    word = word.group(1) if word else key
    definition = definition.group(1).replace("\n", " ") if definition else ""
    sort = sort.group(1) if sort else key

    entry = f"""\\newglossaryentry{{{key}}}{{
    name={{{word}}},
    description={{{definition}}},
    sort={{{sort}}}
}}
"""
    gloss_entries.append(entry)

# -----------------------------
# Guardar archivo tex
# -----------------------------
with open(outtex, "w", encoding="utf-8") as f:
    f.write("% Archivo generado automáticamente\n")
    f.write("\\makeglossaries\n\n")
    for e in gloss_entries:
        f.write(e + "\n")

print(f"{len(gloss_entries)} entradas convertidas a {outtex}")

# -----------------------------
# Actualizar archivos tex
# -----------------------------
for texfile in pathlib.Path(".").rglob("*.tex"):

    text = texfile.read_text(encoding="utf-8")

    text = re.sub(r'\\gloss\[nocite\]\{(.*?)\}', r'\\gls{\1}', text)
    text = re.sub(r'\\gloss\[Word\]\{(.*?)\}', r'\\gls{\1}', text)
    text = re.sub(r'\\gloss\[word\]\{(.*?)\}', r'\\gls{\1}', text)
    text = re.sub(r'\\gloss\[short\]\{(.*?)\}', r'\\gls{\1}', text)
    text = re.sub(r'\\gloss\{(.*?)\}', r'\\gls{\1}', text)

    texfile.write_text(text, encoding="utf-8")

    print(f"Actualizado: {texfile}")
