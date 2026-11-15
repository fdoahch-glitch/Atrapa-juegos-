extends Node
const JA := preload("res://scripts/juego_arriba.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _crear() -> Control:
	var j: Control = JA.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.normalizar(Datos.nivel_arriba()), false, false)
	return j
func _correr(j, n: int) -> void:
	for i in n:
		j._actualizar(1.0 / 60.0)
func _ready() -> void:
	var j := _crear()
	var c0: Vector2 = j._centro()
	ok(absf(c0.x - 2.5 * 48.0) < 1.0 and absf(c0.y - 2.5 * 48.0) < 1.0, "empieza en la celda de inicio")
	# pared izquierda: caminar a la izquierda no la atraviesa
	j._joy = Vector2(-1, 0)
	_correr(j, 120)
	ok(j._centro().x >= 48.0 + 0.28 * 48.0 - 0.5, "la pared frena (x=%.1f)" % j._centro().x)
	# pared interior x=5: caminar a la derecha desde (2,2) choca en x=5
	j = _crear()
	j._joy = Vector2(1, 0)
	_correr(j, 200)
	ok(j._centro().x < 5.0 * 48.0 and j._centro().x > 4.0 * 48.0, "pared interior frena (x=%.1f)" % j._centro().x)
	# moverse hacia abajo funciona
	j = _crear()
	j._joy = Vector2(0, 1)
	_correr(j, 30)
	ok(j._centro().y > c0.y + 50.0, "se mueve hacia abajo (y=%.1f)" % j._centro().y)
	# moneda
	j = _crear()
	var m: Dictionary = j.recogibles[0]
	j._poner_centro(Vector2((m["x"] + 0.5) * 48.0, (m["y"] + 0.5) * 48.0))
	_correr(j, 2)
	ok(j.recogidos == 1, "recoge moneda")
	# pinchos
	j = _crear()
	var s: Dictionary = j.pinchos[0]
	j._poner_centro(Vector2((s["x"] + 0.5) * 48.0, (s["y"] + 0.5) * 48.0))
	_correr(j, 2)
	ok(j.vidas == 2, "pinchos quitan vida")
	# enemigo volador patrulla en vertical
	j = _crear()
	var vol = null
	for e in j.enemigos:
		if e["it"].get("fly", false): vol = e
	var y0: float = vol["y"]
	_correr(j, 60)
	ok(absf(vol["y"] - y0) > 0.3 and absf(vol["x"] - vol["x0"]) < 0.01, "el enemigo volador se mueve en vertical")
	# enemigo terrestre contacto
	j = _crear()
	var te = null
	for e in j.enemigos:
		if not e["it"].get("fly", false): te = e
	j._poner_centro(Vector2((te["x"] + 0.5) * 48.0, (te["y"] + 0.5) * 48.0))
	_correr(j, 2)
	ok(j.vidas == 2, "enemigo hiere al tocarlo")
	# meta
	j = _crear()
	j._poner_centro(Vector2((j.meta["x"] + 0.5) * 48.0, (j.meta["y"] + 0.5) * 48.0))
	_correr(j, 2)
	ok(j.estado == "gano", "llega a la meta")
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
