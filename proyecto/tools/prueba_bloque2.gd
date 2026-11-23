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
	var n := Datos.normalizar(Datos.nivel_inicial())
	var it := func(t: String, x: int, y: int, extra: Dictionary = {}) -> Dictionary:
		var d := {"t": t, "x": x, "y": y, "id": Datos.nuevo_id()}
		d.merge(extra)
		return d
	n["items"].append(it.call("llave", 3, 11))
	n["items"].append(it.call("puerta", 5, 10))
	n["items"].append(it.call("boton", 9, 11))
	n["items"].append(it.call("platmov", 11, 8, {"w": 3, "h": 1, "r": 2, "sp": 60}))
	n["items"].append(it.call("caja", 12, 11))
	n["items"].append(it.call("deco", 2, 11, {"e": "🔥", "s": 40, "fx": "fuego"}))
	n["eventos"] = [{"si": "monedas", "n": 1, "haz": "meta", "txt": "", "v": 1}, {"si": "tiempo", "n": 1, "haz": "mensaje", "txt": "hola", "v": 1}, {"si": "x", "haz": "y"}]
	n["oscuridad"] = 0.6
	n["filtro"] = "sepia"
	n = Datos.normalizar(n)
	chk(n["eventos"].size() == 2, "eventos normalizados")
	var reglas := Datos.reglas_completas({"sonidos": {"saltar": "m:x.ogg", "ganar": "no_existe"}, "fx": {"recoger": "fuego"}})
	chk(reglas["sonidos"]["ganar"] == "victoria", "sonido invalido vuelve a normal")
	chk(reglas["sonidos"]["saltar"] == "m:x.ogg", "sonido propio")
	chk(reglas["fx"]["recoger"] == "fuego", "fx ok")
	var J = load("res://scripts/juego.gd").new()
	add_child(J)
	J.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var nn: Dictionary = n.duplicate(true)
	nn["reglas"] = reglas
	J.iniciar(nn, false, false)
	await get_tree().create_timer(0.3).timeout
	chk(J.llaves.size() == 1 and J.puertas.size() == 1 and J.botones.size() == 1 and J.moviles.size() == 1 and J.cajas.size() == 1, "objetos creados")
	chk(J._meta_oculta, "meta oculta por evento")
	chk(J._filtro != null, "filtro creado")
	# la caja cae al suelo y el movil se mueve
	var x0: float = J.moviles[0]["px"]
	for i in 240:
		J._actualizar(1.0 / 120.0)
	chk(absf(J.moviles[0]["px"] - x0) > 1.0, "movil se mueve")
	chk(J._parts.size() > 0, "particulas del deco")
	# llave + puerta
	J.pos = Vector2(3 * 48 + 8, 11 * 48 + 8)
	J._objetos_vivos(0.01)
	chk(J._llaves_disp == 1, "recoge llave")
	J.pos = Vector2(4.6 * 48, 10 * 48 + 20)
	J._objetos_vivos(0.01)
	chk(J.puertas[0]["abierta"], "puerta se abre con llave")
	# boton abre puertas
	J.puertas[0]["abierta"] = false
	J.pos = Vector2(9 * 48 + 10, 11 * 48 + 10)
	J._objetos_vivos(0.01)
	chk(J.botones[0]["on"] and J.puertas[0]["abierta"], "boton abre puertas")
	# evento monedas -> meta visible
	J._n_mon = 1
	J._eventos_tick()
	chk(not J._meta_oculta, "evento muestra meta")
	# sfx/emitir no fallan
	J._sfx("saltar")
	J._emitir("explosion", Vector2(100, 100), 10)
	await get_tree().create_timer(0.2).timeout
	# paneles
	var E = load("res://scripts/panel_eventos.gd").new()
	add_child(E)
	var F = load("res://scripts/panel_efectos.gd").new()
	add_child(F)
	await get_tree().create_timer(0.3).timeout
	print("FALLOS ", fallos)
	get_tree().quit()
