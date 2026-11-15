extends Control
# Muestra un modo de juego para sacar capturas. Variables: MODO (25d|3d|av), TEMA.
func _ready() -> void:
	theme = load("res://scripts/estilo.gd").tema()
	var modo := OS.get_environment("MODO")
	var n: Dictionary = Datos.nivel_inicial()
	var j: Control
	if modo == "3d":
		n = Datos.nivel_corredor()
		n["hero"] = "a:caballero"
		j = load("res://scripts/juego3d.gd").new()
	elif modo == "av":
		n = Datos.nivel_aventura()
		j = load("res://scripts/juego_aventura.gd").new()
	else:
		j = load("res://scripts/juego25.gd").new()
		n["hero"] = "a:explorador"
	n["theme"] = OS.get_environment("TEMA") if OS.get_environment("TEMA") != "" else "dia"
	add_child(j)
	j.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	j.iniciar(n, OS.get_environment("TACTIL") != "", false)
