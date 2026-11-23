extends "res://scripts/juego_disparos.gd"
## Supervivencia: llegan enemigos sin parar y te persiguen. Dispara y aguanta el tiempo que pide el mundo
## (campo «aguantar» del mundo, 45 segundos por defecto).

var _sale := 0.0


func resetear() -> void:
	super.resetear()
	_sale = 2.0
	enemigos = enemigos.filter(func(e): return false)


func _meta_s() -> float:
	return float(nivel.get("aguantar", 45))


func _actualizar(dt: float) -> void:
	super._actualizar(dt)
	if estado != "jugar":
		return
	_sale -= dt
	if _sale <= 0.0:
		_sale = maxf(0.7, 2.0 - t * 0.02)
		_nuevo_enemigo()
	var c := _centro() / T
	for e in enemigos:
		if not e.get("chase", false):
			continue
		var d := (c - Vector2(float(e["x"]) + 0.5, float(e["y"]) + 0.5))
		if d.length() < 0.05:
			continue
		d = d.normalized() * (1.5 + t * 0.012) * dt
		if not _enemigo_choca(float(e["x"]) + d.x, float(e["y"])):
			e["x"] += d.x
		if not _enemigo_choca(float(e["x"]), float(e["y"]) + d.y):
			e["y"] += d.y
		e["it"]["x"] = e["x"]
		e["it"]["y"] = e["y"]
		e["dir"] = 1.0 if d.x >= 0.0 else -1.0
	if t >= _meta_s():
		puntos += 100
		estado = "gano"
		_mostrar_fin("🎉", "¡Sobreviviste!", "Aguantaste %d segundos · %d puntos" % [int(_meta_s()), puntos])


func _nuevo_enemigo() -> void:
	var c := _centro() / T
	for intento in 20:
		var x := float(randi_range(1, int(nivel["cols"]) - 2))
		var y := float(randi_range(1, Datos.FILAS - 2))
		if Vector2(x, y).distance_to(c) < 6.0 or _enemigo_choca(x, y):
			continue
		var it := {"t": "enemy", "e": ["👾", "🐝", "👻"][randi() % 3], "x": x, "y": y, "fly": false, "r": 0, "sp": 0}
		enemigos.append({"it": it, "x": x, "x0": x, "y": y, "y0": y, "dir": 1.0, "muerto": false, "sqt": 0.0, "r": 0.0, "sp": 0.0, "chase": true})
		return


func _dibujar_hud(ci: CanvasItem) -> void:
	super._dibujar_hud(ci)
	var f := ThemeDB.fallback_font
	var txt := "Aguanta %d s" % maxi(0, int(ceil(_meta_s() - t)))
	ci.draw_string(f, Vector2(size.x / 2.0 - 70.0, 40.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
