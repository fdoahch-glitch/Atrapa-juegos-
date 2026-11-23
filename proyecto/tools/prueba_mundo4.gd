extends Node
var fallos := 0
func chk(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_inicial())
	n["items"] = n["items"].filter(func(i): return not ["spike", "enemy", "platmov"].has(str(i["t"])))
	# puente largo justo delante del inicio y un péndulo
	var pl: Dictionary = n["items"].filter(func(i): return i["t"] == "player")[0]
	n["items"].append({"t": "puente", "x": int(pl["x"]) + 3, "y": int(pl["y"]), "w": 4, "h": 1, "id": Datos.nuevo_id()})
	n["items"].append({"t": "pendulo", "x": int(pl["x"]) + 12, "y": int(pl["y"]) - 5, "r": 4, "sp": 60, "id": Datos.nuevo_id()})
	n = Datos.normalizar(n)
	chk(n["items"].any(func(i): return i["t"] == "puente"), "puente sobrevive a normalizar")
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"cam_zoom": 160})})
	chk(Datos.reglas["cam_zoom"] == 160, "zoom guardado")
	var J = load("res://scripts/juego.gd").new()
	add_child(J)
	J.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var nn: Dictionary = n.duplicate(true)
	nn["reglas"] = Datos.reglas
	J.iniciar(nn, false, false)
	await get_tree().create_timer(0.3).timeout
	chk(J.puentes.size() == 1 and J.pendulos.size() == 1, "puente y péndulo cargados")
	chk(J.escala > 1.5 * maxf(0.1, J.size.y / (Datos.FILAS * J.T)) * 0.99, "zoom aplicado (escala %.2f)" % J.escala)
	# poner al héroe sobre el puente
	var pu: Dictionary = J.puentes[0]
	var r0: Rect2 = pu["r0"]
	J.pos = Vector2(r0.position.x + 20, r0.position.y - J.PH * J.T)
	J.vel = Vector2.ZERO
	await get_tree().create_timer(0.35).timeout
	chk(int(pu["est"]) >= 1, "pisar el puente lo activa (estado %d)" % int(pu["est"]))
	await get_tree().create_timer(1.0).timeout
	chk(int(pu["est"]) == 2, "el puente se cae")
	chk(J.pos.y > r0.position.y - J.PH * J.T + 5.0 or not J.suelo, "el héroe cae con él")
	# péndulo hiere
	var pe: Dictionary = J.pendulos[0]
	var v0: int = J.vidas
	J.inv = 0.0
	J.pos = Vector2(float(pe["bx"]) - J.PW * J.T / 2.0, float(pe["by"]) - J.PH * J.T / 2.0)
	await get_tree().create_timer(0.1).timeout
	chk(J.vidas < v0 or J.estado != "jugar", "el péndulo hace daño")
	get_viewport().get_texture().get_image().save_png("/tmp/asis/mundo4.png")
	print("FALLOS: ", fallos)
	get_tree().quit(1 if fallos > 0 else 0)
