extends "res://scripts/juego.gd"
## Base de los minijuegos: dibujan todo en pantalla (sin mundo con cámara) y se manejan con toques o clics.
## Cada minijuego define _empezar(), _paso(dt), _dibujar(ci), _al_pulsar(id), _al_suelo(pos) y _tecla(k).

var cfg: Dictionary = {}
var _zonas: Array = []


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	cfg = n.get("mini_cfg", {}) if n.get("mini_cfg", {}) is Dictionary else {}
	super.iniciar(n, forzar_tactil, mostrar_salir)


func resetear() -> void:
	if _fin:
		_fin.queue_free()
		_fin = null
	t = 0.0
	recogidos = 0
	total = 0
	estado = "jugar"
	inv = 0.0
	plats = []
	items_plat = []
	pinchos = []
	resortes = []
	recogibles = []
	meta = null
	enemigos = []
	decos = []
	_aplicar_reglas()
	_zonas = []
	_empezar()


func _empezar() -> void:
	pass


func _paso(_dt: float) -> void:
	pass


func _dibujar(_ci: CanvasItem) -> void:
	pass


func _al_pulsar(_id: Variant) -> void:
	pass


func _al_suelo(_p: Vector2) -> void:
	pass


func _tecla(_k: int) -> void:
	pass


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	if estado == "jugar":
		_paso(dt)


func _dibujar_mundo(_ci: CanvasItem) -> void:
	pass


func _dibujar_hud(ci: CanvasItem) -> void:
	_zonas = []
	_dibujar(ci)
	_hud_extra(ci)
	_txt(ci, "Puntos: %d" % puntos, Vector2(size.x - 18.0, 34.0), 24, Color.WHITE, 2)
	if int(reglas["vidas"]) > 0 and mini_usa_vidas():
		for i in maxi(0, vidas):
			Dibujo.emoji(ci, "❤", Vector2(size.x - 30.0 - i * 30.0, 66.0), 26.0)


func mini_usa_vidas() -> bool:
	return false


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_ESCAPE:
			if con_salir:
				salir.emit()
			elif not OS.has_feature("web") and not OS.has_feature("android"):
				get_tree().quit()
		elif estado == "jugar":
			_tecla(ev.keycode)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and estado == "jugar":
		pulsar(ev.position - global_position)


func pulsar(p: Vector2) -> void:
	for z in _zonas:
		if (z[0] as Rect2).has_point(p):
			_al_pulsar(z[1])
			return
	_al_suelo(p)


func _ganar(txt: String) -> void:
	if estado != "jugar":
		return
	estado = "gano"
	_sonido.tocar(1000.0, 0.4, "triangulo")
	_mostrar_fin("🎉", "¡Ganaste!", txt)


func _perder(txt: String) -> void:
	if estado != "jugar":
		return
	estado = "perdio"
	_sonido.tocar(150.0, 0.3, "sierra")
	_mostrar_fin("😵", "¡Casi!", txt)


# ------------------------------------------------------------------ ayudas de dibujo
func _txt(ci: CanvasItem, s: String, pos: Vector2, tam: int = 22, col: Color = Color.WHITE, alin: int = 0) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var x := pos.x
	if alin == 0 and x < 70.0 and pos.y > 50.0 and pos.y < 120.0:
		x = 70.0   # no tapar el botón de sonido
	if alin == 1:
		x -= w / 2.0
	elif alin == 2:
		x -= w
	ci.draw_string(f, Vector2(x + 1.0, pos.y + 1.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(0, 0, 0, 0.35))
	ci.draw_string(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)


## Dibuja un botón y lo registra como zona pulsable con ese id.
func _boton(ci: CanvasItem, r: Rect2, s: String, col: Color, id: Variant, tam: int = 22, txt_col: Color = Color.WHITE) -> void:
	ci.draw_style_box(Estilo.caja(col, 16), r)
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, tam).x
	ci.draw_string(f, Vector2(r.position.x + maxf(8.0, (r.size.x - w) / 2.0), r.position.y + r.size.y / 2.0 + tam * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, tam, txt_col)
	_zonas.append([r, id])


## Escribe texto en varias líneas dentro de un ancho. Devuelve el y final.
func _parrafo(ci: CanvasItem, s: String, pos: Vector2, ancho: float, tam: int = 22, col: Color = Color.WHITE) -> float:
	var f := ThemeDB.fallback_font
	var linea := ""
	var y := pos.y
	for palabra in s.split(" "):
		var prueba := (linea + " " + palabra).strip_edges()
		if f.get_string_size(prueba, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho and linea != "":
			ci.draw_string(f, Vector2(pos.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
			y += tam * 1.35
			linea = palabra
		else:
			linea = prueba
	ci.draw_string(f, Vector2(pos.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
	return y + tam * 1.35


## Líneas no vacías de un texto de configuración.
func _lineas(clave: String) -> Array:
	var r: Array = []
	for l in str(cfg.get(clave, "")).split("\n"):
		if l.strip_edges() != "":
			r.append(l.strip_edges())
	return r


func _num(clave: String, def: float) -> float:
	return float(cfg.get(clave, def))
