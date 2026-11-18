#!/usr/bin/env python3
"""Copia el motor (sin el editor) a plantilla_juego/, el proyecto mínimo que usa
el botón mágico para exportar. Ejecutar cada vez que cambie el motor:
    python3 tools/sincronizar_plantilla.py
"""
import os, shutil
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DEST = os.path.join(RAIZ, "plantilla_juego")
ARCHIVOS = ["project.godot", "icon.svg", "arranque.tscn", "arranque.gd",
            "scripts/datos.gd", "scripts/dibujo.gd", "scripts/capa.gd",
            "scripts/sonido.gd", "scripts/juego.gd", "scripts/estilo.gd",
            "scripts/juego25.gd", "scripts/juego3d.gd", "scripts/mundo3d.gd",
            "scripts/assets3d.gd", "scripts/hornear.gd", "scripts/importar.gd", "scripts/juego_aventura.gd", "scripts/juego_arriba.gd", "scripts/partida.gd", "scripts/tienda.gd"]
shutil.rmtree(DEST, ignore_errors=True)
for a in ARCHIVOS:
    d = os.path.join(DEST, a)
    os.makedirs(os.path.dirname(d), exist_ok=True)
    shutil.copy(os.path.join(RAIZ, a), d)
shutil.copytree(os.path.join(RAIZ, "assets", "emoji"), os.path.join(DEST, "assets", "emoji"),
                ignore=shutil.ignore_patterns("*.import"))
shutil.copytree(os.path.join(RAIZ, "assets", "modelos2d"), os.path.join(DEST, "assets", "modelos2d"), ignore=shutil.ignore_patterns("*.import"))
shutil.copy(os.path.join(RAIZ, "tools", "arranque_plantilla.gd"), os.path.join(DEST, "arranque.gd"))
shutil.copy(os.path.join(RAIZ, "tools", "export_presets_plantilla.cfg"), os.path.join(DEST, "export_presets.cfg"))
print("plantilla_juego lista:", sum(len(f) for _, _, f in os.walk(DEST)), "archivos")
