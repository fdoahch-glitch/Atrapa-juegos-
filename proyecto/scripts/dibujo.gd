extends RefCounted
## Dibujo compartido por el editor y el juego: fondos animados y objetos.

const T := 48


static func _rnd(i: float) -> float:
	var s := sin(i * 127.1 + 311.7) * 43758.5453
	return s - floor(s)


static func emoji(ci: CanvasItem, e: String, c: Vector2, tam: float, voltear: bool = false, esc_y: float = 1.0) -> void:
	var tex: Texture2D = Datos.textura(e)
	if tex == null:
		return
	ci.draw_set_transform(c, 0.0, Vector2(-1.0 if voltear else 1.0, esc_y))
	ci.draw_texture_rect(tex, Rect2(Vector2(-tam / 2.0, -tam / 2.0), Vector2(tam, tam)), false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ fondo
static func _colinas(ci: CanvasItem, tam: Vector2, color: Color, base: float, amp: float, onda: float, desfase: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, tam.y))
	var x := 0.0
	while x <= tam.x + 12.0:
		var y := tam.y * base + sin((x + desfase) / onda) * amp * tam.y + sin((x + desfase) / (onda * 0.37) + 2.0) * amp * tam.y * 0.35
		pts.append(Vector2(x, y))
		x += 12.0
	pts.append(Vector2(tam.x + 12.0, tam.y))
	ci.draw_colored_polygon(pts, color)


## Fondo del nivel: la imagen propia (si eligió una) o el del tema.
static func fondo_de(ci: CanvasItem, n: Dictionary, th: Dictionary, tam: Vector2, cam: float, t: float) -> void:
	var id := str(n.get("fondo", ""))
	var tex: Texture2D = Datos.textura(id) if id != "" else null
	if tex == null:
		if th.get("arriba", false):
			_suelo_arriba(ci, th, tam, cam)
		else:
			fondo(ci, th, tam, cam, t)
		return
	var w := tex.get_width() * tam.y / tex.get_height()
	var s := cam * 0.25
	var j := int(floor(s / w))
	var x := -(s - j * w)
	while x < tam.x:
		# cada tarjeta se voltea para que no se note la unión
		if j % 2 != 0:
			ci.draw_texture_rect(tex, Rect2(x + w, 0, -w, tam.y), false)
		else:
			ci.draw_texture_rect(tex, Rect2(x, 0, w, tam.y), false)
		x += w
		j += 1


## Suelo de cuadros para los juegos vistos desde arriba.
static func _suelo_arriba(ci: CanvasItem, th: Dictionary, tam: Vector2, cam: float) -> void:
	var base: Color = (th["cerca"] as Color).lightened(0.18)
	ci.draw_rect(Rect2(Vector2.ZERO, tam), base)
	var s := tam.y / 14.0
	var k := int(floor(cam / s))
	var x := -(cam - k * s)
	while x < tam.x:
		for fila in range(0, 14):
			if (k + fila) % 2 == 0:
				ci.draw_rect(Rect2(x, fila * s, s, s), Color(0, 0, 0, 0.06))
		x += s
		k += 1


static func fondo(ci: CanvasItem, th: Dictionary, tam: Vector2, cam: float, t: float) -> void:
	var c0: Color = th["cielo"][0]
	var c1: Color = th["cielo"][1]
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(tam.x, 0), tam, Vector2(0, tam.y)]), PackedColorArray([c0, c0, c1, c1]))
	var deco: String = th["deco"]
	if deco == "estrellas":
		for i in 80:
			var x := fposmod(_rnd(i) * tam.x * 1.6 - cam * 0.04, tam.x)
			var y := _rnd(i + 99.0) * tam.y * 0.75
			var s := 1.5 + _rnd(i + 5.0) * 2.5
			ci.draw_rect(Rect2(x, y, s, s), Color(1, 1, 1, 0.35 + 0.65 * absf(sin(t * 1.4 + i))))
	if deco == "sol" or deco == "sol2":
		var cx := tam.x * 0.82
		var cy := tam.y * (0.17 if deco == "sol" else 0.42)
		var r := tam.y * 0.085
		ci.draw_circle(Vector2(cx, cy), r * 2.6, Color(1, 0.94, 0.67, 0.18))
		ci.draw_circle(Vector2(cx, cy), r * 1.8, Color(1, 0.94, 0.67, 0.28))
		ci.draw_circle(Vector2(cx, cy), r * 1.25, Color(1, 0.94, 0.67, 0.5))
		ci.draw_circle(Vector2(cx, cy), r, Color("fff3b0"))
	_colinas(ci, tam, th["lejos"], 0.62, 0.07, tam.y * 0.32, cam * 0.18)
	if deco == "arboles":
		var sp := tam.y * 0.22
		for i in range(-1, int(tam.x / sp) + 2):
			var x := i * sp - fmod(cam * 0.3, sp)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, tam.y * 0.8), Vector2(x + sp * 0.28, tam.y * 0.45), Vector2(x + sp * 0.56, tam.y * 0.8)]), Color(0.12, 0.39, 0.24, 0.55))
	_colinas(ci, tam, th["cerca"], 0.8, 0.05, tam.y * 0.22, cam * 0.4)
	if deco == "burbujas":
		for i in 22:
			var x := _rnd(i) * tam.x + sin(t + i) * 6.0
			var y := tam.y - fmod(t * (18.0 + _rnd(i + 3.0) * 30.0) + _rnd(i + 7.0) * tam.y, tam.y)
			ci.draw_arc(Vector2(x, y), 3.0 + _rnd(i + 9.0) * 7.0, 0.0, TAU, 14, Color(1, 1, 1, 0.55), 1.5)
	if deco == "nieve":
		for i in 50:
			var x := fposmod(_rnd(i) * tam.x + sin(t * 0.8 + i) * 14.0, tam.x)
			var y := fmod(t * (24.0 + _rnd(i + 3.0) * 30.0) + _rnd(i + 7.0) * tam.y, tam.y)
			ci.draw_circle(Vector2(x, y), 1.5 + _rnd(i + 1.0) * 2.0, Color.WHITE)


# ---------------------------------------------------------------- objetos
## Dibuja un objeto en coordenadas del mundo (1 celda = 48 px).
## Animación elegida para un objeto (panel de propiedades): mueve el objeto un poquito.
static func _con_anim(it: Dictionary, t: float) -> Dictionary:
	var a := str(it["anim"])
	var c := it.duplicate()
	var f := float(it["x"]) * 0.7
	match a:
		"flotar":
			c["y"] = float(it["y"]) + sin(t * 2.0 + f) * 0.12
		"rebotar":
			c["y"] = float(it["y"]) - absf(sin(t * 4.0 + f)) * 0.35
		"balancear":
			c["x"] = float(it["x"]) + sin(t * 2.5 + f) * 0.12
		"latir":
			c["y"] = float(it["y"]) + sin(t * 9.0 + f) * 0.05
			c["x"] = float(it["x"]) + cos(t * 9.0 + f) * 0.05
		"temblar":
			c["x"] = float(it["x"]) + sin(t * 40.0 + f) * 0.03
	return c


static func objeto(ci: CanvasItem, it0: Dictionary, th: Dictionary, t: float, extra: Dictionary = {}) -> void:
	var it: Dictionary = it0
	if it0.has("anim") and str(it0["anim"]) != "ninguna" and it0["t"] != "plat":
		it = _con_anim(it0, t)
	var x: float = float(it["x"]) * T
	var y: float = float(it["y"]) * T
	match it["t"]:
		"plat":
			var w: float = float(it["w"]) * T
			var h: float = float(it["h"]) * T
			var pl: Array = th["plat"]
			if th.get("arriba", false):
				# pared vista desde arriba: sombra, lado y tapa clara
				ci.draw_rect(Rect2(x + 3, y + 7, w, h), Color(0, 0, 0, 0.22))
				ci.draw_rect(Rect2(x, y, w, h), pl[1])
				ci.draw_rect(Rect2(x + 2, y + 2, w - 4, h - 9), pl[0])
				for i in range(1, int(it["w"])):
					ci.draw_rect(Rect2(x + i * T - 1, y + 2, 2, h - 9), Color(0, 0, 0, 0.13))
				for i in range(1, int(it["h"])):
					ci.draw_rect(Rect2(x + 2, y + i * T - 5, w - 4, 2), Color(0, 0, 0, 0.13))
				return
			ci.draw_rect(Rect2(x, y, w, h), pl[0])
			for i in range(1, int(it["h"])):
				ci.draw_rect(Rect2(x, y + i * T - 1, w, 2), Color(0, 0, 0, 0.13))
			for i in range(1, int(it["w"])):
				ci.draw_rect(Rect2(x + i * T - 1, y, 2, h), Color(0, 0, 0, 0.13))
			ci.draw_rect(Rect2(x, y, w, 12), pl[1])
			ci.draw_rect(Rect2(x, y, w, 3), Color(1, 1, 1, 0.28))
			ci.draw_rect(Rect2(x + 1, y + 1, w - 2, h - 2), Color(0, 0, 0, 0.25), false, 2.0)
		"coin":
			var c := Vector2(x + T / 2.0, y + T / 2.0 + sin(t * 4.0 + it["x"]) * 3.0)
			var sx := absf(cos(t * 3.0 + it["x"])) * 0.7 + 0.3
			ci.draw_set_transform(c, 0.0, Vector2(sx, 1.0))
			ci.draw_circle(Vector2.ZERO, 15.0, Color("c98a00"))
			ci.draw_circle(Vector2.ZERO, 12.0, Color("ffc61a"))
			ci.draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 20, Color("ffe27a"), 2.5)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"star":
			emoji(ci, "⭐", Vector2(x + T / 2.0, y + T / 2.0 + sin(t * 3.0 + it["x"]) * 4.0), 38.0)
		"gem":
			emoji(ci, "💎", Vector2(x + T / 2.0, y + T / 2.0 + sin(t * 3.0 + it["x"]) * 3.0), 34.0)
		"spike":
			for i in 3:
				var a := Vector2(x + i * T / 3.0 + 1.0, y + T)
				var b := Vector2(x + (i + 0.5) * T / 3.0, y + T * 0.45)
				var d := Vector2(x + (i + 1) * T / 3.0 - 1.0, y + T)
				ci.draw_colored_polygon(PackedVector2Array([a, b, d]), Color("d4d8e0"))
				ci.draw_polyline(PackedVector2Array([a, b, d, a]), Color("5b6270"), 2.0)
		"spring":
			var sq: float = float(extra.get("sq", 0.0)) * 12.0
			var top := y + T * 0.5 + sq
			ci.draw_rect(Rect2(x + 8, y + T - 8, T - 16, 8), Color("6b7280"))
			var alto := (y + T - 8.0) - (top + 6.0)
			ci.draw_polyline(PackedVector2Array([Vector2(x + 14, y + T - 8), Vector2(x + T - 14, y + T - 8 - alto * 0.33), Vector2(x + 14, y + T - 8 - alto * 0.66), Vector2(x + T / 2.0, top + 6.0)]), Color("9aa1ad"), 4.0)
			ci.draw_rect(Rect2(x + 5, top - 3, T - 10, 9), Color("ef4444"))
			ci.draw_rect(Rect2(x + 5, top - 3, T - 10, 3), Color("fca5a5"))
		"valla":
			# baja: hay que SALTAR
			for px_ in [x + 7.0, x + T - 11.0]:
				ci.draw_rect(Rect2(px_, y + 14, 4, T - 18), Color("6b7280"))
			for k in 4:
				ci.draw_rect(Rect2(x + 5 + k * 9.5, y + 14, 9.5, 12), Color("ef4444") if k % 2 == 0 else Color("fff7f7"))
			ci.draw_rect(Rect2(x + 5, y + 14, T - 10, 12), Color(0, 0, 0, 0.35), false, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + T / 2.0, y + 2), Vector2(x + T / 2.0 - 7, y + 12), Vector2(x + T / 2.0 + 7, y + 12)]), Color("22c55e"))
		"pared":
			# bloque grande: hay que ESQUIVAR (cambiar de carril)
			ci.draw_rect(Rect2(x + 4, y + 3, T - 8, T - 6), Color("8b8f9c"))
			for k in 3:
				ci.draw_rect(Rect2(x + 4, y + 3 + (k + 1) * (T - 6) / 4.0 - 1, T - 8, 2), Color(0, 0, 0, 0.25))
			ci.draw_rect(Rect2(x + 4, y + 3, T - 8, T - 6), Color("3f4350"), false, 2.5)
			ci.draw_line(Vector2(x + 12, y + 12), Vector2(x + T - 12, y + T - 12), Color("ef4444"), 4.0)
			ci.draw_line(Vector2(x + T - 12, y + 12), Vector2(x + 12, y + T - 12), Color("ef4444"), 4.0)
		"viga":
			# alta: hay que AGACHARSE
			for px_ in [x + 5.0, x + T - 9.0]:
				ci.draw_rect(Rect2(px_, y + 4, 4, T - 8), Color("6b7280"))
			for k in 4:
				ci.draw_rect(Rect2(x + 5 + k * 9.5, y + 4, 9.5, 13), Color("f59e0b") if k % 2 == 0 else Color("1f2937"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + T / 2.0, y + T - 6), Vector2(x + T / 2.0 - 7, y + 24), Vector2(x + T / 2.0 + 7, y + 24)]), Color("22c55e"))
		"goal":
			emoji(ci, "🏁", Vector2(x + T / 2.0 + 4.0, y + T / 2.0 - 2.0), 50.0 + sin(t * 5.0) * 1.5)
		"enemy":
			var dir: float = float(extra.get("dir", 1))
			var ex: float = float(extra.get("x", it["x"])) * T
			var vuela: bool = bool(it.get("fly", false))
			var dy: float = sin(t * 3.0 + it["x"]) * 7.0 if vuela else 0.0
			var aplastado: bool = bool(extra.get("sq", false))
			emoji(ci, str(it["e"]), Vector2(ex + T / 2.0, y + T / 2.0 + dy + (10.0 if aplastado else 0.0)), 40.0 * (1.2 if aplastado else 1.0), dir >= 0.0, 0.5 if aplastado else 1.0)
		"deco":
			var s: float = float(it.get("s", 56))
			var e := str(it["e"])
			if Datos.es_nube(e):
				emoji(ci, e, Vector2(x + T / 2.0 + sin(t * 0.3 + it["x"]) * 8.0, y + T / 2.0), s)
			else:
				emoji(ci, e, Vector2(x + T / 2.0, y + T - s / 2.0 + 3.0), s)
		"player":
			var cara: float = float(extra.get("cara", 1))
			emoji(ci, str(extra.get("e", "🐱")), Vector2(x + T / 2.0, y + T / 2.0), 42.0, cara < 0.0)


## Dibuja una lista de objetos respetando las capas (decoración al fondo).
static func objetos(ci: CanvasItem, items: Array, th: Dictionary, t: float, hero: String) -> void:
	var orden: Array = items.duplicate()
	orden.sort_custom(func(a, b): return Datos.capa(a) < Datos.capa(b))
	for it in orden:
		var extra := {}
		if it["t"] == "player":
			extra = {"e": hero, "cara": 1}
		elif it["t"] == "enemy":
			extra = {"dir": 1}
		objeto(ci, it, th, t, extra)
