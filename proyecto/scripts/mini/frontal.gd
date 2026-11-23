extends "res://scripts/juego_mini.gd"
## Carrera 2D frontal: carretera en perspectiva con curvas y tráfico.

var pos_m := 0.0
var vel_m := 0.0
var lx := 0.0
var trafico: Array = []
var _curvas: Array = []
var _dedo := 0.0
var _inv := 0.0


func mini_usa_vidas() -> bool:
	return true


func _empezar() -> void:
	pos_m = 0.0
	vel_m = 0.0
	lx = 0.0
	_inv = 0.0
	_dedo = 0.0
	_curvas = []
	for tok in str(cfg.get("curvas", "0")).split(" ", false):
		_curvas.append(clampf(float(tok), -1.0, 1.0))
	if _curvas.is_empty():
		_curvas = [0.0]
	trafico = []
	var n := int(cfg.get("trafico", 14))
	var largo := float(cfg.get("largo", 1400))
	for i in n:
		trafico.append({"z": 90.0 + (largo - 150.0) * float(i) / maxf(1.0, n), "l": [-0.7, 0.0, 0.7][(i * 7 + 3) % 3], "e": ["🚙", "🚕", "🚌", "🚓"][i % 4]})


func _curva(d: float) -> float:
	return _curvas[int(maxf(d, 0.0) / 80.0) % _curvas.size()]


func _paso(dt: float) -> void:
	_inv = maxf(0.0, _inv - dt)
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	dir += _dedo
	var tope := 75.0 if absf(lx) < 1.1 else 30.0
	vel_m = move_toward(vel_m, tope, 22.0 * dt)
	lx += dir * 1.6 * dt - _curva(pos_m + 20.0) * vel_m * 0.012 * dt * 10.0
	lx = clampf(lx, -1.4, 1.4)
	pos_m += vel_m * dt
	for a in trafico:
		if absf(a["z"] - pos_m) < 5.0 and absf(a["l"] - lx) < 0.38 and _inv <= 0.0:
			vidas -= 1
			vel_m *= 0.35
			_inv = 1.6
			_sonido.tocar(150.0, 0.25, "sierra")
			if vidas <= 0:
				_perder("Chocaste demasiado")
				return
	puntos = int(pos_m / 10.0)
	if pos_m >= float(cfg.get("largo", 1400)):
		_ganar("Llegaste a la meta")


func _x_en(s: float, d: float) -> Array:
	var u := s * s
	var ancho := lerpf(size.x * 0.05, size.x * 0.95, u)
	var curva := _curva(pos_m + d * 0.5) * pow(1.0 - s, 2.0) * size.x * 0.55
	return [size.x / 2.0 - lx * ancho * 0.4 + curva, ancho]


func _dibujar(ci: CanvasItem) -> void:
	var yh := size.y * 0.42
	var th: Dictionary = tema
	var pasto: Array = [(th["cerca"] as Color), (th["cerca"] as Color).darkened(0.12)]
	ci.draw_rect(Rect2(0, yh, size.x, size.y - yh), pasto[0])
	var lejos := 220.0
	var N := 56
	var prev_y := yh
	var prev: Array = _x_en(0.0, lejos)
	for k in range(1, N + 1):
		var s := float(k) / N
		var d := lejos * (1.0 - s)
		var y := yh + (size.y - yh) * s * s
		var cur: Array = _x_en(s, d)
		var banda := int((pos_m + d) / 12.0) % 2
		ci.draw_rect(Rect2(0, prev_y, size.x, y - prev_y + 1.0), pasto[banda])
		var pts := PackedVector2Array([Vector2(prev[0] - prev[1] * 0.5, prev_y), Vector2(prev[0] + prev[1] * 0.5, prev_y), Vector2(cur[0] + cur[1] * 0.5, y), Vector2(cur[0] - cur[1] * 0.5, y)])
		ci.draw_colored_polygon(pts, Color(0.26, 0.26, 0.3) if banda == 0 else Color(0.3, 0.3, 0.34))
		var borde := Color.WHITE if banda == 0 else Color("ef4444")
		ci.draw_line(Vector2(cur[0] - cur[1] * 0.5, y), Vector2(prev[0] - prev[1] * 0.5, prev_y), borde, maxf(2.0, cur[1] * 0.02))
		ci.draw_line(Vector2(cur[0] + cur[1] * 0.5, y), Vector2(prev[0] + prev[1] * 0.5, prev_y), borde, maxf(2.0, cur[1] * 0.02))
		if banda == 0:
			ci.draw_line(Vector2(cur[0], y), Vector2(prev[0], prev_y), Color(1, 1, 1, 0.7), maxf(1.0, cur[1] * 0.012))
		prev = cur
		prev_y = y
	# tráfico de lejos a cerca
	var vis: Array = trafico.filter(func(a): return a["z"] > pos_m + 2.0 and a["z"] < pos_m + lejos)
	vis.sort_custom(func(a, b): return a["z"] > b["z"])
	for a in vis:
		var d: float = a["z"] - pos_m
		var s := 1.0 - d / lejos
		var c: Array = _x_en(s, d)
		var y := yh + (size.y - yh) * s * s
		Dibujo.emoji(ci, a["e"], Vector2(c[0] + a["l"] * c[1] * 0.4, y - c[1] * 0.04), maxf(8.0, c[1] * 0.16))
	if not (_inv > 0.0 and int(t * 14.0) % 2 == 1):
		Dibujo.emoji(ci, str(cfg.get("auto", "🚗")), Vector2(size.x / 2.0, size.y * 0.86), minf(size.x * 0.17, 130.0))
	_txt(ci, "%d km/h" % int(vel_m * 3.6), Vector2(20, 36), 26)
	var largo := float(cfg.get("largo", 1400))
	ci.draw_rect(Rect2(20, 52, 220, 10), Color(0, 0, 0, 0.4))
	ci.draw_rect(Rect2(20, 52, 220.0 * clampf(pos_m / largo, 0.0, 1.0), 10), Color("22c55e"))


func _input(ev: InputEvent) -> void:
	super._input(ev)
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dedo = -1.0 if (ev.position.x - global_position.x) < size.x / 2.0 else 1.0
		else:
			_dedo = 0.0
