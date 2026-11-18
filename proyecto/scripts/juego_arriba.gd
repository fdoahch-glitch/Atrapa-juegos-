extends "res://scripts/juego.gd"
## Modo 2D «Vista desde arriba»: caminas en las cuatro direcciones por laberintos
## y aventuras. Las paredes frenan, los enemigos y los pinchos te quitan vidas.

const VEL := 230.0
const MEDIA := 0.28          # medio lado de la caja del héroe, en celdas

var _joy := Vector2.ZERO
var _joy_ini := Vector2.ZERO
var _joy_dedo := -1


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	tema = tema.duplicate()
	tema["arriba"] = true


func resetear() -> void:
	super.resetear()
	vel = Vector2.ZERO
	var pl := {"x": 1, "y": 6}
	for it in nivel["items"]:
		if it["t"] == "player":
			pl = it
	_poner_centro(Vector2((float(pl["x"]) + 0.5) * T, (float(pl["y"]) + 0.5) * T))
	inicio = pos
	for e in enemigos:
		e["y"] = float(e["it"]["y"])
		e["y0"] = e["y"]
		e["it"]["y"] = e["y"]


func _centro() -> Vector2:
	return pos + Vector2(PW * T / 2.0, PH * T / 2.0)


func _poner_centro(c: Vector2) -> void:
	pos = c - Vector2(PW * T / 2.0, PH * T / 2.0)


func _caja() -> Rect2:
	var c := _centro()
	return Rect2(c - Vector2(MEDIA, MEDIA) * T, Vector2(MEDIA, MEDIA) * 2.0 * T)


func _dir_entrada() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		d.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		d.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		d.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		d.y += 1.0
	if _joy.length() > 0.15:
		d += _joy
	return d.limit_length(1.0)


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_ESCAPE:
			if con_salir:
				salir.emit()
			elif not OS.has_feature("web") and not OS.has_feature("android"):
				get_tree().quit()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position - global_position
		if ev.pressed:
			if p.x < size.x * 0.6 and p.y > size.y * 0.2:
				_joy_dedo = 0
				_joy_ini = p
				_joy = Vector2.ZERO
		elif _joy_dedo == 0:
			_joy_dedo = -1
			_joy = Vector2.ZERO
	elif ev is InputEventMouseMotion and _joy_dedo == 0:
		_joy = (((ev.position - global_position) - _joy_ini) / 70.0).limit_length(1.0)


func _mover(delta: Vector2) -> void:
	_poner_centro(_centro() + delta)
	var h := MEDIA * T
	for p in plats:
		if _caja().intersects(p):
			var c := _centro()
			if delta.x > 0.0:
				c.x = p.position.x - h
			elif delta.x < 0.0:
				c.x = p.end.x + h
			elif delta.y > 0.0:
				c.y = p.position.y - h
			elif delta.y < 0.0:
				c.y = p.end.y + h
			_poner_centro(c)


func _enemigo_choca(x: float, y: float) -> bool:
	var r := Rect2(x * T + 10, y * T + 10, T - 20, T - 20)
	for p in plats:
		if r.intersects(p):
			return true
	return false


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	var ancho := float(nivel["cols"]) * T
	var alto := float(Datos.FILAS) * T
	var vista := size.x / escala
	var objetivo := (ancho - vista) / 2.0 if ancho <= vista else clampf(_centro().x - vista / 2.0, 0.0, ancho - vista)
	cam += (objetivo - cam) * minf(1.0, dt * 8.0)
	if estado != "jugar":
		return
	inv = maxf(0.0, inv - dt)
	var d := _dir_entrada()
	if absf(d.x) > 0.1:
		cara = signf(d.x)
	_mover(Vector2(d.x * VEL * dt, 0.0))
	_mover(Vector2(0.0, d.y * VEL * dt))
	var c := _centro()
	c.x = clampf(c.x, MEDIA * T, ancho - MEDIA * T)
	c.y = clampf(c.y, MEDIA * T, alto - MEDIA * T)
	_poner_centro(c)
	for s in pinchos:
		if _caja().intersects(Rect2(s["x"] * T + 10, s["y"] * T + 12, T - 20, T - 20)):
			_herir()
	for r in recogibles:
		if not r["got"] and _caja().intersects(Rect2(r["x"] * T + 8, r["y"] * T + 8, T - 16, T - 16).grow(_alcance())):
			r["got"] = true
			recogidos += 1
			puntos += _vale(r["t"])
			_sonido.tocar(880.0 if r["t"] == "coin" else 1200.0, 0.1)
	for e in enemigos:
		var vuela: bool = bool(e["it"].get("fly", false))
		var paso: float = e["dir"] * e["sp"] * _lento / T * dt
		if vuela:
			var ny: float = e["y"] + paso
			if _enemigo_choca(e["x"], ny):
				e["dir"] = -e["dir"]  # una pared: da la vuelta en vez de atravesarla
			else:
				e["y"] = ny
			if e["y"] > e["y0"] + e["r"]:
				e["dir"] = -1.0
			if e["y"] < e["y0"] - e["r"]:
				e["dir"] = 1.0
			e["it"]["y"] = e["y"]
		else:
			var nx: float = e["x"] + paso
			if _enemigo_choca(nx, e["y"]):
				e["dir"] = -e["dir"]
			else:
				e["x"] = nx
			if e["x"] > e["x0"] + e["r"]:
				e["dir"] = -1.0
			if e["x"] < e["x0"] - e["r"]:
				e["dir"] = 1.0
		if _caja().intersects(Rect2(e["x"] * T + 10, e["y"] * T + 10, T - 20, T - 20)):
			_herir()
	if meta != null and estado == "jugar" and _caja().intersects(Rect2(meta["x"] * T + 6, meta["y"] * T + 6, T - 12, T - 12)):
		if _faltan() > 0:
			_decir("Te faltan %d premios para abrir la meta" % _faltan())
		else:
			estado = "gano"
			_sonido.tocar(1000.0, 0.4, "triangulo")
			_mostrar_fin("🎉", "¡Llegaste a la meta!", "Puntos: %d · Recogiste %d de %d" % [puntos, recogidos, total])


func _dibujar_mundo(ci: CanvasItem) -> void:
	for d in decos:
		Dibujo.objeto(ci, d, tema, t)
	for s in pinchos:
		Dibujo.objeto(ci, s, tema, t)
	for r in recogibles:
		if not r["got"]:
			Dibujo.objeto(ci, r, tema, t)
	if meta != null:
		Dibujo.objeto(ci, meta, tema, t)
	for p in items_plat:
		Dibujo.objeto(ci, p, tema, t)
	for e in enemigos:
		Dibujo.objeto(ci, e["it"], tema, t, {"dir": e["dir"], "x": e["x"]})
	if not (inv > 0.0 and int(t * 14.0) % 2 == 1):
		var c2 := (_centro() - Vector2(T, T) / 2.0) / T
		_mascota_2d(ci, c2)
		Dibujo.objeto(ci, {"t": "player", "x": c2.x, "y": c2.y}, tema, t, {"e": nivel["hero"], "cara": cara})


func _dibujar_hud(ci: CanvasItem) -> void:
	_hud_extra(ci)
	var fuente := ThemeDB.fallback_font
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.45), 22), Rect2(12, 10, maxf(250.0, 126.0 + int(reglas["vidas"]) * 30.0), 40))
	Dibujo.emoji(ci, "⭐", Vector2(34, 30), 26.0)
	ci.draw_string(fuente, Vector2(52, 38), str(puntos), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	for i in maxi(0, vidas):
		Dibujo.emoji(ci, "❤", Vector2(130 + i * 30, 30), 26.0)
	if tactil:
		var base := Vector2(110.0, size.y - 110.0)
		ci.draw_circle(base, 70.0, Color(1, 1, 1, 0.18))
		ci.draw_arc(base, 70.0, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 3.0)
		ci.draw_circle(base + _joy * 50.0, 30.0, Color(1, 1, 1, 0.55))
	elif t < 6.0 and estado == "jugar":
		var txt := "Flechas o WASD para moverte"
		var w := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 18), Rect2((size.x - w) / 2.0 - 16, 70, w + 32, 40))
		ci.draw_string(fuente, Vector2((size.x - w) / 2.0, 98), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
