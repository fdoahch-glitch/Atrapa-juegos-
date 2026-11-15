extends Control
## Punto de entrada.
## - Si existe res://nivel.json  -> es un juego exportado: se juega directo.
## - Si no                       -> se abre el creador (editor).

const Juego := preload("res://scripts/juego.gd")
const Juego25 := preload("res://scripts/juego25.gd")
const Juego3D := preload("res://scripts/juego3d.gd")
const JuegoAventura := preload("res://scripts/juego_aventura.gd")
const Partida := preload("res://scripts/partida.gd")


func _ready() -> void:
	var estilo := load("res://scripts/estilo.gd")
	theme = estilo.tema()
	# En celulares y tablets los botones se agrandan para tocarlos fácil.
	var movil := OS.has_feature("android") or OS.has_feature("ios") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
	if movil:
		get_window().content_scale_factor = 1.3
	# Motor propio: el nivel puede venir junto al ejecutable (sin Godot instalado)
	var ruta_nivel := "res://nivel.json"
	var junto := OS.get_executable_path().get_base_dir().path_join("nivel.json")
	if OS.has_feature("web"):
		if FileAccess.file_exists("/nivel.json"):
			ruta_nivel = "/nivel.json"
	elif FileAccess.file_exists(junto):
		ruta_nivel = junto
	if FileAccess.file_exists(ruta_nivel):
		var proy: Dictionary = Datos.leer_proyecto(ruta_nivel)
		if proy.is_empty():
			proy = {"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})}
		var primero: Dictionary = proy["niveles"][0]
		var partida: Control = Partida.new()
		add_child(partida)
		partida.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		Datos.aplicar_pantalla(primero)
		partida.iniciar(proy, 0, true, str(primero.get("disp", "pc")) == "movil", false)
	else:
		var Editor = load("res://scripts/editor.gd")
		var e: Control = Editor.new()
		add_child(e)
		e.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
