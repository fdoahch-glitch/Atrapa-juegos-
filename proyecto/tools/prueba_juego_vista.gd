extends Node
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_trio())
	n["items"].append({"t": "llave", "x": 4, "y": 11, "id": "k1"})
	n["items"].append({"t": "puerta", "x": 8, "y": 10, "id": "k2"})
	n["items"].append({"t": "caja", "x": 11, "y": 11, "id": "k3"})
	n["items"].append({"t": "platmov", "x": 16, "y": 9, "w": 3, "h": 1, "r": 2, "sp": 50, "id": "k4"})
	n["items"].append({"t": "deco", "x": 2, "y": 11, "e": "🔥", "s": 40, "fx": "fuego", "id": "k5"})
	n["oscuridad"] = 0.8
	n["filtro"] = "vineta"
	n = Datos.normalizar(n)
	var J = load("res://scripts/juego.gd").new()
	add_child(J)
	J.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n["reglas"] = Datos.reglas_completas({"mec": {"dash": true, "disparar": true}})
	J.iniciar(n, true, false)
	for i in 100:
		J._actualizar(1.0 / 60.0)
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/vista_juego.png")
	var E = load("res://scripts/panel_efectos.gd").new()
	add_child(E)
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/vista_efectos.png")
	E.queue_free()
	var Ev = load("res://scripts/panel_eventos.gd").new()
	Datos.nivel["eventos"] = [{"si": "monedas", "n": 10, "haz": "puertas", "txt": "", "v": 1}, {"si": "tiempo", "n": 30, "haz": "mensaje", "txt": "¡Apúrate!", "v": 1}]
	add_child(Ev)
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/vista_eventos.png")
	get_tree().quit()
