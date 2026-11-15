extends Node
# Prueba el botón mágico: exporta el nivel de ejemplo a web y a Windows.
const ExportadorScript := preload("res://scripts/exportador.gd")
func _ready() -> void:
	var ex := ExportadorScript.new()
	add_child(ex)
	print("godot: ", ex.godot_ruta, " | plantilla: ", ex.plantilla_dir(), " | disponible: ", ex.disponible())
	for plat in ["web", "windows"]:
		ex.exportar(plat, "Mi Juego Ñandú", Datos.a_json())
		var r = await ex.terminado
		print("[", plat, "] ok=", r[0], " | ", r[1], " | carpeta=", r[2])
	get_tree().quit(0)
