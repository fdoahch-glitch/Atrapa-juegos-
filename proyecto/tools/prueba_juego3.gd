extends Node
var fallos := 0
func chk(c: bool, m: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", m)
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_trio())
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"categoria": "plataformas", "mec": {"doble_salto": true, "disparar": true}, "fis": {"grav": 0.5, "rebote": 0.5}})})
	chk(Datos.reglas["fis"]["grav"] == 0.5, "fis guardada")
	chk(Datos.reglas["mec"]["doble_salto"], "mec guardada")
	chk(Datos.reglas["mec"]["pisar"], "pisar por defecto")
	# juego
	var J = load("res://scripts/juego.gd").new()
	add_child(J)
	J.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var nn: Dictionary = n.duplicate(true)
	nn["reglas"] = Datos.reglas
	J.iniciar(nn, false, false)
	await get_tree().create_timer(0.3).timeout
	chk(J._trio, "trio activo")
	chk(J._hero_i == 0 and J.nivel["hero"] == "a:caballero", "heroe 0")
	J._cambiar_heroe(1)
	chk(J.nivel["hero"] == "a:mago" and J._mecanica("conjurar"), "mago conjura")
	J._cambiar_heroe(2)
	chk(J._mecanica("doble_salto") and J._mecanica("disparar"), "ladron")
	# disparar
	J.bolas.append({"x": J.pos.x, "y": J.pos.y, "d": 1.0})
	J._acciones(0.1)
	chk(J.bolas.size() == 1, "bala viva")
	# enemigos con ia
	var ias := []
	for e in J.enemigos:
		ias.append(e["it"].get("ia"))
	chk("persigue" in ias and "dispara" in ias, "ia en enemigos: " + str(ias))
	# conjurar
	J._cambiar_heroe(1)
	J._conj_cd = 0.0
	Input.action_press("ui_accept")
	J._bloques.append({"r": Rect2(0, 0, 48, 48), "it": {"t": "plat", "x": 0, "y": 0, "w": 1, "h": 1}})
	chk(J._todas_plats().size() == J.plats.size() + 1, "bloques cuentan como suelo")
	# correr unos cuadros
	for i in 90:
		J._actualizar(1.0 / 60.0)
	chk(J.estado == "jugar" or J.estado == "perdio", "sigue corriendo")
	# anim item
	var it := {"t": "coin", "x": 3, "y": 3, "anim": "flotar", "id": "x"}
	var c: Dictionary = load("res://scripts/dibujo.gd")._con_anim(it, 1.0)
	chk(c["y"] != 3.0, "anim mueve")
	# normalizar ia/anim invalidos
	var m := Datos.normalizar({"items": [{"t": "enemy", "x": 1, "y": 1, "ia": "xx", "anim": "yy"}], "name": "q"})
	chk(not m["items"][0].has("ia") and not m["items"][0].has("anim"), "normaliza ia/anim")
	# creador
	var Cr = load("res://scripts/panel_creador.gd").new()
	add_child(Cr)
	await get_tree().create_timer(0.3).timeout
	Cr._acc = "👑"
	var img: Image = Cr._armar()
	chk(img != null and img.get_width() > 8, "creador arma imagen")
	var id: String = load("res://scripts/importar.gd").guardar_imagen(img, "prueba_trio")
	chk(id.begins_with("u:"), "guarda personaje " + id)
	chk(Datos.textura(id) != null, "personaje usable")
	load("res://scripts/importar.gd").quitar(id)
	print("FALLOS ", fallos)
	get_tree().quit()
