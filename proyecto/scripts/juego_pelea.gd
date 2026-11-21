extends "res://scripts/juego.gd"
## Lucha 2D: tu luchador contra un rival (el primer «enemigo» del nivel).
## Mejor de 3 rondas. Puñetazo, patada, salto y bloqueo.

const VEL_L := 280.0
const SALTO_L := 760.0
const GRAV_L := 2200.0
const VIDA := 100.0

var yo: Dictionary = {}
var rival: Dictionary = {}
var suelo_y := 12.0 * T
var ronda := 1
var _estado := "cuenta"     # cuenta | pelea | ronda_fin
var _t_est := 2.2
var _tiempo_ronda := 60.0
var _titulo_ronda := ""
var _ia_cd := 0.8
var _teclas := {}
var _toques := {}
var _hit_fx: Array = []
var dos := false
var _msg_combo := ""
var _msg_combo_t := 0.0


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	dos = int(reglas.get("jugadores", 1)) == 2
	if dos:
		var e2 := str(reglas.get("heroe2", ""))
		if e2 != "":
			rival["emoji"] = e2


func _nuevo_luchador(x: float, emoji: String, cara: float) -> Dictionary:
	return {"x": x, "y": suelo_y, "vx": 0.0, "vy": 0.0, "hp": VIDA, "cara": cara, "emoji": emoji, "atk": "", "atk_t": 0.0, "dado": false, "bloq": false, "aturd": 0.0, "gana": 0, "suelo": true, "cadena": 0, "cad_t": 0.0}


func resetear() -> void:
	super.resetear()
	enemigos_a_rival()
	ronda = 1
	_empezar_ronda()


func enemigos_a_rival() -> void:
	suelo_y = 12.0 * T
	for p in plats:
		if p.size.x >= float(nivel["cols"]) * T * 0.7:
			suelo_y = p.position.y
	var anchura := float(nivel["cols"]) * T
	var emo_rival := "🥊"
	for e in enemigos:
		emo_rival = str(e["it"].get("e", "🥊"))
		break
	yo = _nuevo_luchador(anchura * 0.3, str(nivel["hero"]), 1.0)
	rival = _nuevo_luchador(anchura * 0.7, emo_rival, -1.0)
	enemigos = []


func _empezar_ronda() -> void:
	var anchura := float(nivel["cols"]) * T
	for f in [yo, rival]:
		f["hp"] = VIDA
		f["vx"] = 0.0
		f["vy"] = 0.0
		f["y"] = suelo_y
		f["atk"] = ""
		f["atk_t"] = 0.0
		f["aturd"] = 0.0
		f["bloq"] = false
	yo["x"] = anchura * 0.3
	rival["x"] = anchura * 0.7
	yo["cara"] = 1.0
	rival["cara"] = -1.0
	_estado = "cuenta"
	_t_est = 2.2
	_tiempo_ronda = 60.0
	_titulo_ronda = "Ronda %d" % ronda
	estado = "jugar"


# ------------------------------------------------------------------ entrada
func _input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		if ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
			if con_salir:
				salir.emit()
			elif not OS.has_feature("web") and not OS.has_feature("android"):
				get_tree().quit()
		if not ev.echo:
			_teclas[ev.keycode] = ev.pressed
			if ev.pressed and _estado == "pelea" and estado == "jugar":
				if dos:
					if ev.keycode == KEY_F:
						_atacar(yo, "puno")
					elif ev.keycode == KEY_G:
						_atacar(yo, "patada")
					elif ev.keycode == KEY_K:
						_atacar(rival, "puno")
					elif ev.keycode == KEY_L:
						_atacar(rival, "patada")
				elif ev.keycode in [KEY_Z, KEY_J, KEY_SPACE]:
					_atacar(yo, "puno")
				elif ev.keycode in [KEY_X, KEY_K]:
					_atacar(yo, "patada")
	elif ev is InputEventScreenTouch or ev is InputEventScreenDrag:
		_tocar(ev.index, ev.position - global_position, ev is InputEventScreenDrag or ev.pressed)
		if ev is InputEventScreenTouch and not ev.pressed:
			_toques.erase(ev.index)
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and tactil and not DisplayServer.is_touchscreen_available():
		_tocar(0, ev.position - global_position, ev.pressed)
		if not ev.pressed:
			_toques.erase(0)
	elif ev is InputEventMouseMotion and tactil and _toques.has(0) and not DisplayServer.is_touchscreen_available():
		_tocar(0, ev.position - global_position, true)


func _botones_tactiles() -> Dictionary:
	var s := 78.0
	return {
		"izq": Rect2(20, size.y - 110, s, s), "der": Rect2(110, size.y - 110, s, s),
		"salto": Rect2(size.x - 330, size.y - 110, s, s), "puno": Rect2(size.x - 240, size.y - 110, s, s),
		"patada": Rect2(size.x - 150, size.y - 110, s, s), "bloq": Rect2(size.x - 330, size.y - 200, s, s)}


func _tocar(id: int, p: Vector2, activo: bool) -> void:
	if not activo:
		_toques.erase(id)
		return
	var antes: String = _toques.get(id, "")
	for k in _botones_tactiles():
		if _botones_tactiles()[k].grow(14).has_point(p):
			_toques[id] = k
			if antes != k and _estado == "pelea" and estado == "jugar":
				if k == "puno":
					_atacar(yo, "puno")
				elif k == "patada":
					_atacar(yo, "patada")
			return
	_toques.erase(id)


func _pulsa(k: String) -> bool:
	return _toques.values().has(k)


# ------------------------------------------------------------------ combate
func _atacar(f: Dictionary, tipo: String) -> void:
	if f["atk"] != "" or f["aturd"] > 0.0 or f["bloq"]:
		return
	f["atk"] = tipo
	f["atk_t"] = 0.34 if tipo == "puno" else 0.5
	f["dado"] = false
	_sonido.tocar(300.0 if tipo == "puno" else 220.0, 0.06, "sierra")


func _alc_golpe(f: Dictionary) -> float:
	return (1.05 if f["atk"] == "puno" else 1.45) * T


func _en_golpe(f: Dictionary) -> bool:
	if f["atk"] == "":
		return false
	var total := 0.34 if f["atk"] == "puno" else 0.5
	var p: float = total - float(f["atk_t"])
	return p > total * 0.25 and p < total * 0.65


func _golpear(a: Dictionary, b: Dictionary) -> void:
	if a["dado"] or not _en_golpe(a):
		return
	var dx: float = b["x"] - a["x"]
	if signf(dx) != a["cara"] and absf(dx) > 8.0:
		return
	if absf(dx) > _alc_golpe(a) + 0.35 * T or absf(float(b["y"]) - float(a["y"])) > 1.2 * T:
		return
	a["dado"] = true
	var dano := 8.0 if a["atk"] == "puno" else 13.0
	var bloqueado_antes: bool = b["bloq"] and signf(a["x"] - b["x"]) == b["cara"]
	if not bloqueado_antes:
		a["cadena"] += 1
		a["cad_t"] = 0.9
		if a["cadena"] >= 3:
			dano += 10.0 + 4.0 * (a["cadena"] - 3)
			_msg_combo = "¡COMBO x%d!" % a["cadena"]
			_msg_combo_t = 1.0
			_sonido.tocar(880.0, 0.15, "triangulo")
	else:
		a["cadena"] = 0
	var bloqueado: bool = b["bloq"] and signf(a["x"] - b["x"]) == b["cara"]
	if bloqueado:
		dano *= 0.15
		_sonido.tocar(500.0, 0.05, "cuadrada")
	else:
		b["aturd"] = 0.28
		b["atk"] = ""
		_sonido.tocar(110.0, 0.1, "sierra")
	b["hp"] = maxf(0.0, float(b["hp"]) - dano)
	b["vx"] = a["cara"] * (260.0 if not bloqueado else 90.0)
	_hit_fx.append({"p": Vector2(b["x"], float(b["y"]) - 0.9 * T), "t": 0.0})
	if b == rival:
		puntos += 1 if bloqueado else 3


func _mover_f(f: Dictionary, dt: float, dir: float, saltar: bool, bloq: bool) -> void:
	f["atk_t"] = maxf(0.0, f["atk_t"] - dt)
	if f["atk_t"] <= 0.0:
		f["atk"] = ""
	f["aturd"] = maxf(0.0, f["aturd"] - dt)
	f["bloq"] = bloq and f["suelo"] and f["atk"] == "" and f["aturd"] <= 0.0
	var quieto: bool = f["aturd"] > 0.0 or f["bloq"] or (f["atk"] != "" and f["suelo"])
	if not quieto:
		f["vx"] = dir * VEL_L
		if dir != 0.0:
			f["cara"] = signf(dir)
		if saltar and f["suelo"]:
			f["vy"] = -SALTO_L
			f["suelo"] = false
	else:
		f["vx"] = move_toward(f["vx"], 0.0, 900.0 * dt)
	f["vy"] += GRAV_L * dt
	f["x"] += f["vx"] * dt
	f["y"] += f["vy"] * dt
	if f["y"] >= suelo_y:
		f["y"] = suelo_y
		f["vy"] = 0.0
		f["suelo"] = true
	f["x"] = clampf(f["x"], 0.6 * T, float(nivel["cols"]) * T - 0.6 * T)


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	var ancho := float(nivel["cols"]) * T
	var vista := size.x / escala
	var medio := (float(yo["x"]) + float(rival["x"])) / 2.0
	var objetivo := (ancho - vista) / 2.0 if ancho <= vista else clampf(medio - vista / 2.0, 0.0, ancho - vista)
	cam += (objetivo - cam) * minf(1.0, dt * 6.0)
	for fx in _hit_fx:
		fx["t"] += dt
	_hit_fx = _hit_fx.filter(func(f): return f["t"] < 0.3)
	if estado != "jugar":
		return
	_t_est -= dt
	if _estado == "cuenta":
		if _t_est <= 0.0:
			_estado = "pelea"
		return
	if _estado == "ronda_fin":
		if _t_est <= 0.0:
			if yo["gana"] >= 2 or rival["gana"] >= 2:
				_terminar_partido()
			else:
				ronda += 1
				_empezar_ronda()
		return
	_tiempo_ronda -= dt
	var d := 0.0
	var a_izq: bool = _teclas.get(KEY_A, false) or _pulsa("izq") or (not dos and _teclas.get(KEY_LEFT, false))
	var a_der: bool = _teclas.get(KEY_D, false) or _pulsa("der") or (not dos and _teclas.get(KEY_RIGHT, false))
	if a_izq:
		d -= 1.0
	if a_der:
		d += 1.0
	var salta: bool = _teclas.get(KEY_W, false) or _pulsa("salto") or (not dos and _teclas.get(KEY_UP, false))
	var bloq: bool = _teclas.get(KEY_S, false) or _pulsa("bloq") or (not dos and _teclas.get(KEY_DOWN, false))
	_mover_f(yo, dt, d, salta, bloq)
	if dos:
		var d2 := 0.0
		if _teclas.get(KEY_LEFT, false):
			d2 -= 1.0
		if _teclas.get(KEY_RIGHT, false):
			d2 += 1.0
		_mover_f(rival, dt, d2, _teclas.get(KEY_UP, false), _teclas.get(KEY_DOWN, false))
		if rival["atk"] == "" and rival["aturd"] <= 0.0 and d2 == 0.0 and rival["suelo"]:
			rival["cara"] = signf(float(yo["x"]) - float(rival["x"])) if yo["x"] != rival["x"] else rival["cara"]
	else:
		_ia(dt)
	_msg_combo_t = maxf(0.0, _msg_combo_t - dt)
	yo["cad_t"] = maxf(0.0, yo["cad_t"] - dt)
	rival["cad_t"] = maxf(0.0, rival["cad_t"] - dt)
	if yo["cad_t"] <= 0.0:
		yo["cadena"] = 0
	if rival["cad_t"] <= 0.0:
		rival["cadena"] = 0
	_golpear(yo, rival)
	_golpear(rival, yo)
	# no se atraviesan
	var sep: float = absf(float(yo["x"]) - float(rival["x"]))
	if sep < 0.7 * T and absf(float(yo["y"]) - float(rival["y"])) < 1.0 * T:
		var empuje := (0.7 * T - sep) / 2.0
		var s := signf(float(yo["x"]) - float(rival["x"]))
		if s == 0.0:
			s = 1.0
		yo["x"] += s * empuje
		rival["x"] -= s * empuje
	if yo["atk"] == "" and yo["aturd"] <= 0.0 and sep > 8.0:
		yo["cara"] = signf(float(rival["x"]) - float(yo["x"])) if yo["suelo"] and d == 0.0 else yo["cara"]
	if yo["hp"] <= 0.0 or rival["hp"] <= 0.0 or _tiempo_ronda <= 0.0:
		_fin_ronda()


func _ia(dt: float) -> void:
	var dx: float = float(yo["x"]) - float(rival["x"])
	var dist := absf(dx)
	_ia_cd -= dt
	var dir := 0.0
	var bloq := false
	var saltar := false
	var rango: float = 1.0 * T
	if dist > rango:
		dir = signf(dx)
	elif dist < 0.6 * T and rival["suelo"]:
		dir = -signf(dx) * 0.6
	# se defiende si lo van a golpear
	if _en_golpe_cercano() and randf() < 0.55 and rival["suelo"]:
		bloq = true
	if _ia_cd <= 0.0 and dist < rango + 0.5 * T and rival["atk"] == "" and rival["aturd"] <= 0.0:
		_atacar(rival, "puno" if randf() < 0.6 else "patada")
		_ia_cd = randf_range(0.55, 1.2)
	elif _ia_cd <= 0.0 and dist > 3.0 * T and randf() < 0.012:
		saltar = true
	if dx != 0.0 and rival["atk"] == "":
		rival["cara"] = signf(dx)
	_mover_f(rival, dt, dir, saltar, bloq)


func _en_golpe_cercano() -> bool:
	return yo["atk"] != "" and absf(float(yo["x"]) - float(rival["x"])) < _alc_golpe(yo) + 0.8 * T


func _fin_ronda() -> void:
	var ganador := ""
	if yo["hp"] > rival["hp"]:
		ganador = "yo"
	elif rival["hp"] > yo["hp"]:
		ganador = "rival"
	if ganador == "yo":
		yo["gana"] += 1
		_titulo_ronda = "¡Ganaste la ronda!"
		puntos += 10
	elif ganador == "rival":
		rival["gana"] += 1
		_titulo_ronda = "El rival ganó la ronda"
	else:
		_titulo_ronda = "¡Empate!"
	_estado = "ronda_fin"
	_t_est = 2.0
	_sonido.tocar(600.0 if ganador == "yo" else 200.0, 0.3, "triangulo")


func _terminar_partido() -> void:
	if dos:
		estado = "gano"
		var g := "1" if yo["gana"] >= 2 else "2"
		_mostrar_fin("🏆", "¡Ganó el jugador %s!" % g, "Rondas %d - %d" % [yo["gana"], rival["gana"]])
		return
	if yo["gana"] >= 2:
		estado = "gano"
		_mostrar_fin("🏆", "¡Eres el campeón!", "Rondas %d - %d · Puntos: %d" % [yo["gana"], rival["gana"], puntos])
	else:
		estado = "perdio"
		_mostrar_fin("😵", "¡Perdiste el combate!", "Rondas %d - %d · ¡Revancha!" % [yo["gana"], rival["gana"]])


# ------------------------------------------------------------------ dibujo
func _dibujar_mundo(ci: CanvasItem) -> void:
	for d in decos:
		Dibujo.objeto(ci, d, tema, t)
	for p in items_plat:
		Dibujo.objeto(ci, p, tema, t)
	_dibujar_f(ci, rival, Color(1, 0.85, 0.85))
	_dibujar_f(ci, yo, Color.WHITE)
	for fx in _hit_fx:
		Dibujo.emoji(ci, "💥", fx["p"], T * (0.7 + fx["t"] * 2.0))


func _dibujar_f(ci: CanvasItem, f: Dictionary, col: Color) -> void:
	var tam := T * 1.7
	var lunge := 0.0
	if f["atk"] != "":
		var total := 0.34 if f["atk"] == "puno" else 0.5
		lunge = sin((1.0 - float(f["atk_t"]) / total) * PI) * 0.45 * T * float(f["cara"])
	var base := Vector2(float(f["x"]) + lunge, float(f["y"]))
	ci.draw_circle(Vector2(float(f["x"]), suelo_y + 3.0), T * 0.35, Color(0, 0, 0, 0.18))
	var c := base + Vector2(0, -tam / 2.0 + 4.0)
	var esc_y := 0.85 if f["bloq"] else 1.0
	if f["aturd"] > 0.0 and int(t * 20.0) % 2 == 0:
		c.x += 4.0
	var tex: Texture2D = Datos.textura(str(f["emoji"]))
	if tex != null:
		var flip := -1.0 if float(f["cara"]) < 0.0 else 1.0
		ci.draw_set_transform(c + Vector2(0, tam * (1.0 - esc_y) / 2.0), 0.0, Vector2(flip, esc_y))
		ci.draw_texture_rect(tex, Rect2(Vector2(-tam / 2.0, -tam / 2.0), Vector2(tam, tam)), false, col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if f["bloq"]:
		ci.draw_arc(c, tam * 0.55, -PI / 2.0 - 0.9 * float(f["cara"]) , -PI / 2.0 + 0.9 * float(f["cara"]), 12, Color(0.4, 0.8, 1.0, 0.9), 5.0)
	if f["atk"] == "patada":
		Dibujo.emoji(ci, "💥", c + Vector2(float(f["cara"]) * tam * 0.55, tam * 0.25), T * 0.5)


func _barra(ci: CanvasItem, r: Rect2, v: float, col: Color, derecha: bool) -> void:
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.55), 10), r.grow(4))
	var w := r.size.x * clampf(v / VIDA, 0.0, 1.0)
	var rr := Rect2(r.position.x + (r.size.x - w if derecha else 0.0), r.position.y, w, r.size.y)
	ci.draw_rect(rr, col)


func _dibujar_hud(ci: CanvasItem) -> void:
	var fuente := ThemeDB.fallback_font
	var ancho := minf(size.x * 0.38, 420.0)
	_barra(ci, Rect2(size.x / 2.0 - 60.0 - ancho, 24, ancho, 22), yo["hp"], Color("69db7c"), true)
	_barra(ci, Rect2(size.x / 2.0 + 60.0, 24, ancho, 22), rival["hp"], Color("ff6b6b"), false)
	Dibujo.emoji(ci, str(yo["emoji"]), Vector2(size.x / 2.0 - 60.0 - ancho - 30.0, 35), 38.0)
	Dibujo.emoji(ci, str(rival["emoji"]), Vector2(size.x / 2.0 + 60.0 + ancho + 30.0, 35), 38.0, true)
	var seg := str(maxi(0, int(ceil(_tiempo_ronda))))
	var w := fuente.get_string_size(seg, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	ci.draw_string_outline(fuente, Vector2((size.x - w) / 2.0, 46), seg, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 8, Color(0.1, 0.08, 0.3))
	ci.draw_string(fuente, Vector2((size.x - w) / 2.0, 46), seg, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
	for i in 2:
		ci.draw_circle(Vector2(size.x / 2.0 - 70.0 - i * 22.0, 64), 7.0, Estilo.AMARILLO if i < yo["gana"] else Color(1, 1, 1, 0.25))
		ci.draw_circle(Vector2(size.x / 2.0 + 70.0 + i * 22.0, 64), 7.0, Estilo.AMARILLO if i < rival["gana"] else Color(1, 1, 1, 0.25))
	var centro := ""
	if _estado == "cuenta":
		centro = _titulo_ronda if _t_est > 0.8 else "¡PELEA!"
	elif _estado == "ronda_fin":
		centro = _titulo_ronda
	if centro != "":
		var tam := 76
		var w2 := fuente.get_string_size(centro, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		ci.draw_string_outline(fuente, Vector2((size.x - w2) / 2.0, size.y * 0.42), centro, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 14, Color(0.1, 0.08, 0.3))
		ci.draw_string(fuente, Vector2((size.x - w2) / 2.0, size.y * 0.42), centro, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)
	if _msg_combo_t > 0.0:
		var wc := fuente.get_string_size(_msg_combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 56).x
		ci.draw_string_outline(fuente, Vector2((size.x - wc) / 2.0, size.y * 0.3), _msg_combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 56, 12, Color(0.1, 0.08, 0.3))
		ci.draw_string(fuente, Vector2((size.x - wc) / 2.0, size.y * 0.3), _msg_combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Estilo.AMARILLO)
	if tactil:
		var nombres := {"izq": "◀", "der": "▶", "salto": "⤒", "puno": "👊", "patada": "🦵", "bloq": "🛡"}
		for k in _botones_tactiles():
			var r: Rect2 = _botones_tactiles()[k]
			ci.draw_circle(r.get_center(), r.size.x / 2.0, Color(1, 1, 1, 0.3 if _pulsa(k) else 0.16))
			ci.draw_arc(r.get_center(), r.size.x / 2.0, 0, TAU, 28, Color(1, 1, 1, 0.6), 2.0)
			var e: String = {"puno": "👊", "bloq": "🛡"}.get(k, "")
			if e != "":
				Dibujo.emoji(ci, e, r.get_center(), 36.0)
			else:
				var tx: String = {"izq": "◀", "der": "▶", "salto": "▲", "patada": "K"}[k]
				ci.draw_string(fuente, r.get_center() + Vector2(-10, 10), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	elif t < 8.0 and _estado != "ronda_fin":
		var txt := "← → mover · ↑ saltar · ↓ bloquear · Z puñetazo · X patada · ¡3 golpes seguidos = combo!"
		if dos:
			txt = "Jugador 1: A D W S + F puño, G patada   ·   Jugador 2: flechas + K puño, L patada"
		var w3 := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 18), Rect2((size.x - w3) / 2.0 - 16, 92, w3 + 32, 38))
		ci.draw_string(fuente, Vector2((size.x - w3) / 2.0, 118), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	_hud_extra(ci)
