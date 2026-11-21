extends Node
const Partida := preload("res://scripts/partida.gd")
func _ready() -> void:
	var txt := FileAccess.get_file_as_string("/home/claude/dino-run-motor-/dino-run.atrapa.json")
	var pr: Dictionary = Datos.proyecto_desde(JSON.parse_string(txt))
	var r: Dictionary = pr["reglas"]
	print("coleccion ", r["coleccion"].size(), " skins ", r["skins"].size(), " acc ", r["accesorios"].size(), " rev ", r["revivir"], " dif ", r["dificultad"])
	for n in pr["niveles"]:
		print(n["name"], " clima=", n.get("clima"), " hora=", n.get("hora"), " perse=", n.get("perseguidor"))
	get_tree().quit()
