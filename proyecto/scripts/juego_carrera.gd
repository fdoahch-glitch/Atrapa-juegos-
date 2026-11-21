extends "res://scripts/juego_arriba.gd"
## Carreras vistas desde arriba: pista (agarre firme) y go-karts (derrapes y turbo).
## Las paredes son los bordes de la pista, la meta es la línea de llegada,
## los resortes son turbos y los enemigos son los corredores rivales.

const VMAX := 330.0
const ACEL := 430.0
const FRENO := 720.0

var kart := false
var vueltas := 2
var ang := 0.0
var vl := Vector2.ZERO
var rivales: Array = []

var _libre := {}
var _campo_cp := {}
var _campo_meta := {}
var _max_cp := 1
var _max_meta := 1
var _cel_meta := {}
var _cel_cp := {}
var _lin_meta: Array = []
var _lin_cp: Array = []
var _lap := 0
var _cp := false
var _cuenta := 3.4
var _turbo := 0.0
var _deriva := 0.0
var _choque_cd := 0.0
var _tras_ganador := 0.0
var _posicion := 1
var _terminado := false
var _tex_auto: Texture2D


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	kart = str(n.get("estilo", "carrera")) == "kart"
	vueltas = clampi(int(n.get("vueltas", 3 if kart else 2)), 1, 9)
	_tex_auto = Datos.textura("🏎")
	super.iniciar(n, forzar_tactil, mostrar_salir)


# ------------------------------------------------------------------ preparación
func _es_libre(c: Vector2i) -> bool:
	return _libre.has(c)


func _bfs(objetivo: Array, bloqueo: Dictionary) -> Dictionary:
	var d := {}
	var cola: Array = []
	for c in objetivo:
		if _libre.has(c):
			d[c] = 0
			cola.append(c)
	var i := 0
	while i < cola.size():
		var c: Vector2i = cola[i]
		i += 1
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + v
			if _libre.has(n) and not d.has(n) and not bloqueo.has(n):
				d[n] = d[c] + 1
				cola.append(n)
	return d


## Línea de cruce: la tira de casillas libres más corta (atraviesa la pista).
func _linea(c: Vector2i) -> Array:
	var h: Array = [c]
	var x := c.x - 1
	while _libre.has(Vector2i(x, c.y)):
		h.append(Vector2i(x, c.y))
		x -= 1
	x = c.x + 1
	while _libre.has(Vector2i(x, c.y)):
		h.append(Vector2i(x, c.y))
		x += 1
	var v: Array = [c]
	var y := c.y - 1
	while _libre.has(Vector2i(c.x, y)):
		v.append(Vector2i(c.x, y))
		y -= 1
	y = c.y + 1
	while _libre.has(Vector2i(c.x, y)):
		v.append(Vector2i(c.x, y))
		y += 1
	return h if h.size() <= v.size() else v


func resetear() -> void:
	super.resetear()
	_libre = {}
	var cols := int(nivel["cols"])
	for x in cols:
		for y in Datos.FILAS:
			var r := Rect2(x * T + 10, y * T + 10, T - 20, T - 20)
			var ok := true
			for p in plats:
				if r.intersects(p):
					ok = false
					break
			if ok:
				_libre[Vector2i(x, y)] = true
	_lap = 0
	_cp = false
	_cuenta = 3.4
	_turbo = 0.0
	_deriva = 0.0
	_tras_ganador = 0.0
	_terminado = false
	vl = Vector2.ZERO
	_lin_meta = []
	_lin_cp = []
	_campo_cp = {}
	_campo_meta = {}
	if meta != null:
		var mc := Vector2i(int(meta["x"]), int(meta["y"]))
		_libre[mc] = true
		_lin_meta = _linea(mc)
		var lejos := mc
		var dd := _bfs([mc], {})
		var mejor := -1
		for k in dd:
			if dd[k] > mejor:
				mejor = dd[k]
				lejos = k
		_lin_cp = _linea(lejos)
		_cel_meta = {}
		for c in _lin_meta:
			_cel_meta[c] = true
		_cel_cp = {}
		for c in _lin_cp:
			_cel_cp[c] = true
		_campo_cp = _bfs(_lin_cp, _cel_meta)
		_campo_meta = _bfs(_lin_meta, _cel_cp)
		_max_cp = maxi(1, _campo_cp.values().max() if not _campo_cp.is_empty() else 1)
		_max_meta = maxi(1, _campo_meta.values().max() if not _campo_meta.is_empty() else 1)
	# dirección inicial: hacia donde baja el campo del punto de control
	ang = _rumbo_de(_celda(_centro()), _campo_cp)
	# los rivales son los «enemigos» que puso el creador
	rivales = []
	var k := 0
	for e in enemigos:
		var it: Dictionary = e["it"]
		var c := Vector2((float(it["x"]) + 0.5) * T, (float(it["y"]) + 0.5) * T)
		rivales.append({"p": c, "e": str(it.get("e", "🐌")), "v": 255.0 + 17.0 * (k % 4), "ang": ang, "lap": 0, "cp": false, "hecho": false, "t_fin": 0.0, "col": [Color("ff5252"), Color("4dabf7"), Color("69db7c"), Color("ffd43b")][k % 4]})
		k += 1
	enemigos = []   # el motor base no los mueve


func _celda(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / T)), int(floor(p.y / T)))


func _rumbo_de(c: Vector2i, campo: Dictionary) -> float:
	# sigue el camino de la ruta unos pasos y apunta hacia allí
	var cur := c
	for i in 5:
		var mejor: int = int(campo.get(cur, 1 << 30))
		var sig := cur
		for v in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if campo.has(cur + v) and campo[cur + v] < mejor:
				mejor = campo[cur + v]
				sig = cur + v
		if sig == cur:
			break
		cur = sig
	if cur == c:
		return 0.0
	return Vector2(cur - c).angle()


# ------------------------------------------------------------------ vida del juego
func _herir() -> void:
	# En carrera no se pierden vidas: un charco o un choque te frena y te hace girar.
	if inv > 0.0 or estado != "jugar":
		return
	vl *= 0.25
	inv = 0.9
	_deriva = 0.0
	_sonido.tocar(150.0, 0.25, "sierra")


func _progreso(cp: bool, lap: int, c: Vector2i) -> float:
	var campo := _campo_meta if cp else _campo_cp
	var mx := _max_meta if cp else _max_cp
	var d: float = float(campo.get(c, mx))
	return float(lap) + (0.5 if cp else 0.0) + (1.0 - d / float(mx)) * 0.5


func _calcular_puesto() -> void:
	var mio := _progreso(_cp, _lap, _celda(_centro()))
	var n := 1
	for r in rivales:
		var pr := float(vueltas) + 1.0 if r["hecho"] else _progreso(r["cp"], r["lap"], _celda(r["p"]))
		if pr > mio:
			n += 1
	_posicion = n


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
	if _cuenta > 0.0:
		var antes := int(ceil(_cuenta))
		_cuenta -= dt
		if int(ceil(_cuenta)) != antes:
			_sonido.tocar(520.0 if _cuenta > 0.0 else 880.0, 0.15)
		return
	inv = maxf(0.0, inv - dt)
	_turbo = maxf(0.0, _turbo - dt)
	_choque_cd = maxf(0.0, _choque_cd - dt)
	_mover_auto(dt, ancho, alto)
	_mover_rivales(dt)
	_calcular_puesto()
	_revisar_pista()
	if _tras_ganador > 0.0:
		_tras_ganador -= dt
		if _tras_ganador <= 0.0 and estado == "jugar":
			estado = "perdio"
			_mostrar_fin("🏁", "¡Un rival ganó la carrera!", "Puesto %d de %d · Inténtalo otra vez" % [_posicion, rivales.size() + 1])


func _mover_auto(dt: float, ancho: float, alto: float) -> void:
	var d := _dir_entrada()
	var acel := 0.0
	var dir_giro := d.x
	if tactil and _joy.length() > 0.15:
		acel = -0.8 if d.y > 0.55 else 1.0
	else:
		if d.y < -0.3:
			acel = 1.0
		elif d.y > 0.3:
			acel = -1.0
	var deriva := kart and (Input.is_key_pressed(KEY_SPACE) or (tactil and _joy.length() > 0.85 and absf(d.x) > 0.8))
	var vmax := VMAX * (1.45 if _turbo > 0.0 else 1.0)
	var fwd := Vector2.from_angle(ang)
	var vf := vl.dot(fwd)
	# giro (mejor mientras más rápido vas)
	var fv := clampf(absf(vf) / 110.0, 0.0, 1.0) * signf(vf)
	var giro := (3.0 if kart else 2.5) * (1.35 if deriva else 1.0)
	ang += dir_giro * giro * fv * dt
	fwd = Vector2.from_angle(ang)
	var rgt := Vector2(-fwd.y, fwd.x)
	vf = vl.dot(fwd)
	var vs := vl.dot(rgt)
	if acel > 0.0:
		vf = move_toward(vf, vmax, ACEL * dt)
	elif acel < 0.0:
		vf = move_toward(vf, -vmax * 0.35, FRENO * dt)
	else:
		vf = move_toward(vf, 0.0, 230.0 * dt)
	if vf > vmax:
		vf = move_toward(vf, vmax, 500.0 * dt)
	var agarre := 9.0
	if kart:
		agarre = 1.5 if deriva and absf(vf) > 140.0 else 5.5
	if kart and deriva and absf(vf) > 140.0:
		_deriva += dt
	else:
		if _deriva > 0.8:
			_turbo = 0.9
			_sonido.tocar(700.0, 0.2, "triangulo")
		_deriva = 0.0
	vs *= exp(-agarre * dt)
	vl = fwd * vf + rgt * vs
	var c0 := _centro()
	_mover(Vector2(vl.x * dt, 0.0))
	_mover(Vector2(0.0, vl.y * dt))
	var real := _centro() - c0
	var quiere := vl * dt
	if quiere.length() > 0.6 and real.length() < quiere.length() * 0.55:
		vl *= 0.55
		if _choque_cd <= 0.0:
			_sonido.tocar(120.0, 0.08, "sierra")
			_choque_cd = 0.25
	var c := _centro()
	c.x = clampf(c.x, MEDIA * T, ancho - MEDIA * T)
	c.y = clampf(c.y, MEDIA * T, alto - MEDIA * T)
	_poner_centro(c)
	if absf(vl.x) > 8.0:
		cara = signf(vl.x)


func _mover_rivales(dt: float) -> void:
	for r in rivales:
		if r["hecho"]:
			continue
		var campo := _campo_meta if r["cp"] else _campo_cp
		var c := _celda(r["p"])
		var mejor: int = int(campo.get(c, 1 << 30))
		var destino: Vector2 = r["p"]
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + v
			if campo.has(n) and campo[n] < mejor:
				mejor = campo[n]
				destino = (Vector2(n) + Vector2(0.5, 0.5)) * T
		var a: Vector2 = destino - r["p"]
		# se acerca al centro de la casilla actual para no cortar esquinas
		if a.length() > 1.0:
			var paso: float = minf(a.length(), float(r["v"]) * dt)
			r["p"] += a.normalized() * paso
			r["ang"] = lerp_angle(float(r["ang"]), a.angle(), minf(1.0, dt * 9.0))
		var cc := _celda(r["p"])
		if not r["cp"] and _cel_cp.has(cc):
			r["cp"] = true
		elif r["cp"] and _cel_meta.has(cc):
			r["cp"] = false
			r["lap"] += 1
			if int(r["lap"]) >= vueltas:
				r["hecho"] = true
				r["t_fin"] = t
				if _tras_ganador <= 0.0 and not _terminado:
					_tras_ganador = 20.0


func _revisar_pista() -> void:
	var c := _celda(_centro())
	for r in resortes:
		if _caja().intersects(Rect2(r["x"] * T, r["y"] * T, T, T)):
			if _turbo < 0.6:
				_sonido.tocar(980.0, 0.15, "triangulo")
			_turbo = 1.3
			vl += Vector2.from_angle(ang) * 40.0
	for s in pinchos:
		if _caja().intersects(Rect2(s["x"] * T + 8, s["y"] * T + 8, T - 16, T - 16)):
			_herir()
	for r in recogibles:
		if not r["got"] and _caja().intersects(Rect2(r["x"] * T + 6, r["y"] * T + 6, T - 12, T - 12)):
			r["got"] = true
			recogidos += 1
			puntos += _vale(r["t"])
			_sonido.tocar(880.0 if r["t"] == "coin" else 1200.0, 0.1)
	if meta == null:
		return
	if not _cp and _cel_cp.has(c):
		_cp = true
	elif _cp and _cel_meta.has(c):
		_cp = false
		_lap += 1
		if _lap >= vueltas:
			_terminar()
		else:
			_sonido.tocar(1000.0, 0.2, "triangulo")
			_decir("Vuelta %d de %d" % [_lap + 1, vueltas])


func _terminar() -> void:
	_terminado = true
	var puesto := 1
	for r in rivales:
		if r["hecho"]:
			puesto += 1
	var n := rivales.size() + 1
	if puesto == 1:
		estado = "gano"
		_sonido.tocar(1000.0, 0.4, "triangulo")
		_mostrar_fin("🏆", "¡Ganaste la carrera!", "Tiempo %.1f s · Puntos: %d" % [t - 3.4, puntos])
	else:
		estado = "perdio"
		_mostrar_fin("🏁", "¡Llegaste en el puesto %d de %d!" % [puesto, n], "Tiempo %.1f s · Intenta ser el primero" % [t - 3.4])


# ------------------------------------------------------------------ dibujo
func _dibujar_mundo(ci: CanvasItem) -> void:
	for d in decos:
		Dibujo.objeto(ci, d, tema, t)
	# línea de llegada
	for c in _lin_meta:
		var par: bool = (c.x + c.y) % 2 == 0
		ci.draw_rect(Rect2(c.x * T, c.y * T, T, T), Color(1, 1, 1, 0.85) if par else Color(0.1, 0.1, 0.12, 0.85))
	# turbos
	for r in resortes:
		var o := Vector2(r["x"] * T, r["y"] * T)
		ci.draw_rect(Rect2(o + Vector2(4, 4), Vector2(T - 8, T - 8)), Color(1.0, 0.65, 0.1, 0.85))
		for k in 2:
			var y := o.y + 12.0 + k * 14.0 + fmod(t * 30.0, 14.0) * 0.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(o.x + 10, y + 10), Vector2(o.x + T / 2.0, y), Vector2(o.x + T - 10, y + 10)]), Color.WHITE)
	for s in pinchos:
		var o2 := Vector2(s["x"] * T, s["y"] * T)
		ci.draw_circle(o2 + Vector2(T, T) / 2.0, T * 0.42, Color(0.1, 0.1, 0.14, 0.8))
		ci.draw_circle(o2 + Vector2(T, T) / 2.0 + Vector2(-6, -6), T * 0.1, Color(1, 1, 1, 0.35))
	for r in recogibles:
		if not r["got"]:
			Dibujo.objeto(ci, r, tema, t)
	for p in items_plat:
		Dibujo.objeto(ci, p, tema, t)
	for r in rivales:
		_dibujar_auto(ci, r["p"], float(r["ang"]), r["e"], r["col"], 1.0, false)
	if not (inv > 0.0 and int(t * 14.0) % 2 == 1):
		_dibujar_auto(ci, _centro(), ang, str(nivel["hero"]), Color.WHITE, 1.0, _turbo > 0.0)


func _dibujar_auto(ci: CanvasItem, c: Vector2, a: float, piloto: String, col: Color, esc: float, fuego: bool) -> void:
	if fuego:
		ci.draw_circle(c - Vector2.from_angle(a) * T * 0.55, T * 0.22 + sin(t * 40.0) * 3.0, Color(1.0, 0.6, 0.1, 0.85))
	ci.draw_set_transform(c, a, Vector2.ONE * esc)
	var L := T * 0.62
	var W := T * 0.36
	for sx in [-0.55, 0.5]:
		for sy in [-1.0, 1.0]:
			ci.draw_rect(Rect2(Vector2(L * sx - 7.0, W * sy * 0.98 - 3.5 + (3.0 if sy > 0 else -3.0) * 0.0), Vector2(14, 7)), Color(0.08, 0.08, 0.1))
	ci.draw_rect(Rect2(Vector2(-L, -W), Vector2(L * 2.0, W * 2.0)), col.darkened(0.15) if col != Color.WHITE else Color("ff6b3d"))
	ci.draw_rect(Rect2(Vector2(-L, -W), Vector2(L * 2.0, W * 2.0)), Color(0, 0, 0, 0.55), false, 2.0)
	ci.draw_rect(Rect2(Vector2(L * 0.35, -W * 0.8), Vector2(L * 0.3, W * 1.6)), Color(0.75, 0.9, 1.0, 0.9))
	ci.draw_rect(Rect2(Vector2(-L * 0.95, -W * 0.25), Vector2(L * 0.5, W * 0.5)), Color(1, 1, 1, 0.55))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Dibujo.emoji(ci, piloto, c + Vector2(0, -T * 0.1), T * 0.62)


func _dibujar_hud(ci: CanvasItem) -> void:
	_hud_extra(ci)
	var fuente := ThemeDB.fallback_font
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 22), Rect2(12, 10, 350, 40))
	ci.draw_string(fuente, Vector2(24, 38), "Vuelta %d/%d" % [mini(_lap + 1, vueltas), vueltas], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	ci.draw_string(fuente, Vector2(160, 38), "Puesto %d/%d" % [_posicion, rivales.size() + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Estilo.AMARILLO)
	Dibujo.emoji(ci, "⭐", Vector2(322, 30), 22.0)
	ci.draw_string(fuente, Vector2(338, 38), str(puntos), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	# velocímetro
	var v := clampf(vl.length() / (VMAX * 1.45), 0.0, 1.0)
	var ancho := 220.0
	var y := size.y - 34.0
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 10), Rect2(size.x - ancho - 22, y, ancho + 12, 22))
	ci.draw_rect(Rect2(size.x - ancho - 16, y + 5, ancho * v, 12), Color(1.0, 0.6, 0.1) if _turbo > 0.0 else Color("69db7c"))
	if _cuenta > 0.0:
		var txt := str(int(ceil(_cuenta))) if _cuenta > 0.4 else "¡YA!"
		var tam := 120 if _cuenta > 0.4 else 90
		var w := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		ci.draw_string_outline(fuente, Vector2((size.x - w) / 2.0, size.y * 0.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 14, Color(0.1, 0.08, 0.3))
		ci.draw_string(fuente, Vector2((size.x - w) / 2.0, size.y * 0.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)
	if tactil:
		var base := Vector2(110.0, size.y - 110.0)
		ci.draw_circle(base, 70.0, Color(1, 1, 1, 0.18))
		ci.draw_arc(base, 70.0, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 3.0)
		ci.draw_circle(base + _joy * 50.0, 30.0, Color(1, 1, 1, 0.55))
	elif t < 7.0 and _cuenta <= 0.0:
		var txt2 := "↑ acelera · ← → giran · ↓ frena" + ("  ·  Espacio = derrapar" if kart else "")
		var w2 := fuente.get_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 18), Rect2((size.x - w2) / 2.0 - 16, 70, w2 + 32, 40))
		ci.draw_string(fuente, Vector2((size.x - w2) / 2.0, 98), txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
