extends Control
## Punto de entrada.
## - Si existe res://nivel.json  -> es un juego exportado: se juega directo.
## - Si no                       -> se abre el creador (editor).

const Juego := preload("res://scripts/juego.gd")
const Juego25 := preload("res://scripts/juego25.gd")
const Juego3D := preload("res://scripts/juego3d.gd")
const JuegoAventura := preload("res://scripts/juego_aventura.gd")
const Partida := preload("res://scripts/partida.gd")
const Inicio := preload("res://scripts/inicio.gd")


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
		_mostrar_inicio()


func _limpiar() -> void:
	for c in get_children():
		c.queue_free()


func _mostrar_inicio() -> void:
	_limpiar()
	var ini := Inicio.new()
	add_child(ini)
	ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ini.crear_juego.connect(func(cfg: Dictionary):
		var modo := str(cfg.get("modo", "2d"))
		var tipo := str(cfg.get("tipo", "plataformas"))
		var n: Dictionary
		var est := str(cfg.get("estilo", ""))
		if est in ["carrera", "kart"]:
			n = Datos.nivel_carrera(est == "kart")
			if bool(cfg.get("vista3d", false)):
				n["vista3d"] = true
		elif est == "disparos":
			n = Datos.nivel_arriba()
			n["estilo"] = "disparos"
		elif est == "corredor2d":
			n = Datos.nivel_corredor2d()
		elif est == "pelea":
			n = Datos.nivel_pelea(str(cfg.get("theme", "dia")))
		elif modo == "3d" and tipo == "aventura":
			n = Datos.nivel_aventura()
		elif modo == "3d":
			n = Datos.nivel_corredor()
		elif tipo == "arriba":
			n = Datos.nivel_arriba()
		else:
			n = Datos.nivel_inicial()
		n["modo"] = str(n.get("modo", modo)) if est != "" else modo
		n["tipo"] = str(n.get("tipo", tipo)) if est != "" else tipo
		if est == "disparos":
			n["tipo"] = "arriba"
		n["theme"] = str(cfg.get("theme", n.get("theme", "dia")))
		n["hero"] = str(cfg.get("hero", n.get("hero", "🐱")))
		n["name"] = "Mundo 1"
		n["disp"] = str(cfg.get("disp", "pc"))
		n["orient"] = str(cfg.get("orient", "horizontal"))
		var reglas := Datos.reglas_completas({})
		reglas["plataforma"] = str(cfg.get("plataforma", "windows"))
		reglas["categoria"] = str(cfg.get("categoria", ""))
		reglas["subtipo"] = str(cfg.get("subtipo", ""))
		reglas["portada"] = Datos.portada_nueva(str(cfg.get("nombre", "Mi juego")))
		Datos.establecer_proyecto({"niveles": [Datos.normalizar(n)], "reglas": reglas})
		_abrir_editor())
	ini.continuar.connect(func():
		Datos.cargar_guardado()
		_abrir_editor())
	ini.abierto.connect(func(): _abrir_editor())
	ini.ayuda.connect(func():
		var n := Datos.nivel_inicial()
		Datos.establecer(Datos.normalizar(n))
		_abrir_editor(true))


func _abrir_editor(con_tutorial: bool = false) -> void:
	_limpiar()
	var Editor = load("res://scripts/editor.gd")
	var e: Control = Editor.new()
	add_child(e)
	e.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	e.volver.connect(_mostrar_inicio)
	e.reabrir.connect(_abrir_editor)
	if con_tutorial:
		e.call_deferred("_iniciar_tutorial")
