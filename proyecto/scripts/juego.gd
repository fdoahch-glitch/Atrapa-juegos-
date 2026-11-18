extends Control
## Motor del juego de plataformas. Se usa tanto para "Probar" dentro del
## creador como en el juego exportado (Windows, Android, web).

signal salir
signal nivel_terminado(gano: bool, icono: String, titulo: String, sub: String)

const Dibujo := preload("res://scripts/dibujo.gd")
const Capa := preload("res://scripts/capa.gd")
const Sonido := preload("res://scripts/sonido.gd")
const Estilo := preload("res://scripts/estilo.gd")

const T := 48
const PW := 0.62
const PH := 0.88
const MOVER := 300.0
const GRAV := 2300.0
const SALTO := 860.0
const RESORTE := 1300.0

var nivel: Dictionary = {}
var tema: Dictionary = {}
var escala := 1.0
var con_salir := false
var tactil := false

var _mundo: Node2D
var _hud: Node2D
var _sonido: Node
var _fin: Control
var _btn_sonido: Button

# estado de la partida
var t := 0.0
var puntos := 0
var recogidos := 0
var total := 0
var vidas := 3
var estado := "jugar"      # jugar | gano | perdio
var inv := 0.0
var cam := 0.0
var inicio := Vector2.ZERO
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var cara := 1.0
var suelo := false
var coyote := 0.0
var buffer := 0.0
var salto_pulsado := false
var plats: Array[Rect2] = []
var items_plat: Array = []
var pinchos: Array = []
var resortes: Array = []
var recogibles: Array = []
var meta: Variant = null
var enemigos: Array = []
var decos: Array = []
var dedos := {}            # índice de dedo -> "izq" | "der" | "salto"
# reglas del juego y campaña (varios niveles)
var reglas: Dictionary = {}
var campana := false          # si es true, el fin de nivel lo maneja Partida
var puntos_base := 0          # puntos que traes de niveles anteriores
var etiqueta_nivel := ""      # «Nivel 2 de 3»
var tiempo_rest := -1.0       # segundos que quedan (-1 = sin límite)
var _msg := ""
var _msg_t := 0.0


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	nivel = n.duplicate(true)
	reglas = Datos.reglas_completas(nivel.get("reglas", {}) if nivel.get("reglas", {}) is Dictionary else {})
	tema = Datos.temas.get(str(nivel.get("theme", "dia")), Datos.temas["dia"])
	tactil = forzar_tactil or DisplayServer.is_touchscreen_available()
	con_salir = mostrar_salir
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sonido = Sonido.new()
	add_child(_sonido)
	_mundo = Capa.new()
	_mundo.al_dibujar = _dibujar_mundo
	add_child(_mundo)
	_hud = Capa.new()
	_hud.al_dibujar = _dibujar_hud
	add_child(_hud)
	_btn_sonido = Button.new()
	_btn_sonido.icon = Datos.textura("🔊")
	_btn_sonido.custom_minimum_size = Vector2(52, 44)
	_btn_sonido.expand_icon = true
	_btn_sonido.add_theme_constant_override("icon_max_width", 28)
	_btn_sonido.position = Vector2(12, 58)
	_btn_sonido.focus_mode = Control.FOCUS_NONE
	_btn_sonido.pressed.connect(_alternar_sonido)
	add_child(_btn_sonido)
	if mostrar_salir:
		var b := Button.new()
		b.text = "  Editar"
		b.icon = Datos.textura("↩")
		b.focus_mode = Control.FOCUS_NONE
		b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		b.offset_left = -140.0
		b.offset_right = -15.0
		b.offset_top = 10.0
		b.offset_bottom = 56.0
		b.pressed.connect(func(): salir.emit())
		add_child(b)
	resetear()


func _alternar_sonido() -> void:
	_sonido.silencio = not _sonido.silencio
	_btn_sonido.icon = Datos.textura("🔇" if _sonido.silencio else "🔊")


## Aplica vidas, tiempo y puntos de arranque según las reglas.
func _aplicar_reglas() -> void:
	vidas = int(reglas["vidas"])
	_poner_poder()
	puntos = puntos_base
	tiempo_rest = float(reglas["tiempo"]) if int(reglas["tiempo"]) > 0 else -1.0
	_msg = ""
	_msg_t = 0.0


# ------------------------------------------------------------------ mascota y personaje con poder
const Tienda_ := preload("res://scripts/tienda.gd")
const PODERES := [["", "Ninguno"], ["salto", "Salto alto"], ["escudo", "Escudo"], ["escudo2", "Doble escudo"], ["vida", "Vida extra"], ["iman", "Imán"], ["bono", "Más puntos"]]
var _escudos := 0
var _iman := false
var _iman_s := 0.0
var _doble_s := 0.0
var _bono := 1.0
var _k_salto := 1.0
var _lento := 1.0
var _inv_golpe := 1.6
var _mult := {}
var _m3: Node3D


func _tiene_mascota() -> bool:
	return str(reglas.get("mascota", "")) != ""


## Activa los poderes del personaje jugable y de la mascota al empezar el nivel.
func _poner_poder() -> void:
	_escudos = 0
	_iman = false
	_iman_s = 0.0
	_doble_s = 0.0
	_bono = 1.0
	_k_salto = 1.0
	_lento = 1.0
	_inv_golpe = 1.6
	_mult = {}
	var ids: Array = []
	if _tiene_mascota():
		ids.append(str(reglas.get("poder", "")))
	var ph := str(reglas.get("poder_heroe", ""))
	if ph != "":
		ids.append(ph)
	for id in ids:
		var e: Dictionary = Tienda_.EFECTOS.get(id, {})
		_escudos += int(e.get("esc", 0))
		vidas = mini(12, vidas + int(e.get("vida", 0)))
		_iman = _iman or bool(e.get("iman", false))
		_iman_s = maxf(_iman_s, float(e.get("iman_s", 0.0)))
		_doble_s = maxf(_doble_s, float(e.get("doble", 0.0)))
		_bono *= float(e.get("todo", 1.0))
		_k_salto *= float(e.get("salto", 1.0))
		_lento *= float(e.get("lento", 1.0))
		_inv_golpe = maxf(_inv_golpe, float(e.get("inv", 0.0)))
		for k in ["coin", "gem", "star", "enemy"]:
			if e.has(k):
				_mult[k] = float(_mult.get(k, 1.0)) * float(e[k])


func _iman_act() -> bool:
	return _iman or t < _iman_s


func _vale(tipo: String) -> int:
	var m := _bono * float(_mult.get(tipo, 1.0))
	if t < _doble_s:
		m *= 2.0
	return int(round(int(reglas.get("pts_" + tipo, 1)) * m))


## El escudo de la mascota se come un golpe. Devuelve true si el golpe se absorbió.
func _absorber() -> bool:
	if _escudos <= 0:
		return false
	_escudos -= 1
	inv = 1.0
	_sonido.tocar(520.0, 0.2, "triangulo")
	_decir("¡Tu mascota te protegió!")
	return true


## Ayuda del imán: cuánto se agranda el alcance para recoger (en píxeles).
func _alcance() -> float:
	return 70.0 if _iman_act() else 0.0


## Pone a la mascota 3D junto al héroe.
func _mascota_3d(mundo: Node3D, p: Vector3, desf: Vector3) -> void:
	if not _tiene_mascota():
		return
	if _m3 == null or not is_instance_valid(_m3):
		_m3 = preload("res://scripts/mundo3d.gd").objeto(str(reglas["mascota"]), 0.75)
		if _m3 is Sprite3D:
			(_m3 as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		else:
			_m3.rotation_degrees.y = 180.0
		mundo.add_child(_m3)
	var vuelo := 0.8 if str(reglas["mascota"]).contains("pterodactylus") else 0.0
	_m3.position = p + desf + Vector3(0, vuelo + sin(t * 5.0) * 0.07, 0)
	_m3.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1) or _escudos > 0


## Dibuja a la mascota 2D junto al héroe (c2 = celda del héroe).
func _mascota_2d(ci: CanvasItem, c2: Vector2) -> void:
	if not _tiene_mascota():
		return
	var tx: Texture2D = Datos.textura(str(reglas["mascota"]))
	if tx == null:
		return
	var o := Vector2((c2.x - 0.85 * cara) * T, (c2.y + 0.35) * T + sin(t * 5.0) * 3.0)
	ci.draw_texture_rect(tx, Rect2(o, Vector2(T * 0.6, T * 0.6)), false)
	if _escudos > 0:
		ci.draw_arc(o + Vector2(T * 0.3, T * 0.3), T * 0.42, 0, TAU, 24, Color(0.4, 0.8, 1.0, 0.9), 3.0)


## Cuántos premios faltan para poder ganar (0 = ya puedes llegar a la meta).
func _faltan() -> int:
	var need := 0
	match str(reglas.get("meta", "meta")):
		"mitad":
			need = ceili(total * 0.5)
		"todo":
			need = total
	return maxi(0, need - recogidos)


func _decir(txt: String) -> void:
	_msg = txt
	_msg_t = 2.5


## Se llama en cada cuadro: reloj de cuenta regresiva y mensajes.
func _reglas_tick(dt: float) -> void:
	_msg_t = maxf(0.0, _msg_t - dt)
	if estado != "jugar" or tiempo_rest < 0.0:
		return
	tiempo_rest -= dt
	if tiempo_rest <= 0.0:
		tiempo_rest = 0.0
		estado = "perdio"
		_sonido.tocar(150.0, 0.3, "sierra")
		_mostrar_fin("⏰", "¡Se acabó el tiempo!", "Recogiste %d de %d premios" % [recogidos, total])


## Reloj, mensaje y nivel, dibujados sobre la pantalla del juego.
func _hud_extra(ci: CanvasItem) -> void:
	var f := ThemeDB.fallback_font
	if tiempo_rest >= 0.0:
		var seg := int(ceil(tiempo_rest))
		var txt := "%d:%02d" % [seg / 60, seg % 60]
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var rojo := tiempo_rest < 10.0 and int(t * 3.0) % 2 == 0
		ci.draw_style_box(Estilo.caja(Color(0.7, 0.1, 0.1, 0.75) if rojo else Color(0, 0, 0, 0.45), 20), Rect2(size.x / 2.0 - w / 2.0 - 40, 10, w + 62, 40))
		Dibujo.emoji(ci, "⏰", Vector2(size.x / 2.0 - w / 2.0 - 18, 30), 24.0)
		ci.draw_string(f, Vector2(size.x / 2.0 - w / 2.0 + 4, 38), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	if etiqueta_nivel != "":
		var w2 := f.get_string_size(etiqueta_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		ci.draw_string(f, Vector2(size.x - w2 - 16, size.y - 14) if tactil else Vector2(size.x - w2 - 16, 100), etiqueta_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	if _msg_t > 0.0:
		var w3 := f.get_string_size(_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.6), 20), Rect2((size.x - w3) / 2.0 - 18, size.y * 0.25, w3 + 36, 46))
		ci.draw_string(f, Vector2((size.x - w3) / 2.0, size.y * 0.25 + 32), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


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
	var pl: Dictionary = {"x": 1, "y": Datos.FILAS - 3}
	for it in nivel["items"]:
		var c: Dictionary = it.duplicate()
		match it["t"]:
			"plat":
				plats.append(Rect2(it["x"] * T, it["y"] * T, it["w"] * T, it["h"] * T))
				items_plat.append(c)
			"spike":
				pinchos.append(c)
			"spring":
				c["sq"] = 0.0
				resortes.append(c)
			"coin", "star", "gem":
				c["got"] = false
				recogibles.append(c)
				total += 1
			"goal":
				meta = c
			"enemy":
				enemigos.append({"it": c, "x": float(it["x"]), "x0": float(it["x"]), "dir": 1.0, "muerto": false, "sqt": 0.0,
					"r": float(it.get("r", 3)), "sp": float(it.get("sp", 60))})
			"deco":
				decos.append(c)
			"player":
				pl = it
	var pw := PW * T
	var ph := PH * T
	inicio = Vector2(float(pl["x"]) * T + (T - pw) / 2.0, float(pl["y"] + 1) * T - ph)
	pos = inicio
	vel = Vector2.ZERO
	cara = 1.0
	suelo = false
	coyote = 0.0
	buffer = 0.0
	escala = maxf(0.1, size.y / (Datos.FILAS * T))
	cam = maxf(0.0, inicio.x - size.x / escala / 2.0)


# ------------------------------------------------------------------ entrada
func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_UP, KEY_W, KEY_SPACE]:
			salto_pulsado = true
		elif ev.keycode == KEY_ESCAPE:
			if con_salir:
				salir.emit()
			elif not OS.has_feature("web") and not OS.has_feature("android"):
				get_tree().quit()
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			var z := _zona(ev.position - global_position)
			if z != "":
				dedos[ev.index] = z
				if z == "salto":
					salto_pulsado = true
		else:
			dedos.erase(ev.index)
	elif ev is InputEventScreenDrag:
		var z2 := _zona(ev.position - global_position)
		if z2 == "":
			dedos.erase(ev.index)
		else:
			if z2 == "salto" and dedos.get(ev.index, "") != "salto":
				salto_pulsado = true
			dedos[ev.index] = z2


func _zona(p: Vector2) -> String:
	if not tactil:
		return ""
	for z in ["izq", "der", "salto"]:
		if _rect_zona(z).grow(18.0).has_point(p):
			return z
	return ""


func _rect_zona(z: String) -> Rect2:
	match z:
		"izq":
			return Rect2(24, size.y - 130, 100, 100)
		"der":
			return Rect2(144, size.y - 130, 100, 100)
	return Rect2(size.x - 150, size.y - 150, 120, 120)


func _pulsado(z: String) -> bool:
	return dedos.values().has(z)


# ------------------------------------------------------------------ lógica
func _process(delta: float) -> void:
	_actualizar(minf(delta, 0.033))
	escala = maxf(0.1, size.y / (Datos.FILAS * T))
	_mundo.scale = Vector2(escala, escala)
	_mundo.position = Vector2(-cam * escala, 0.0)
	queue_redraw()
	_mundo.queue_redraw()
	_hud.queue_redraw()


func _caja() -> Rect2:
	return Rect2(pos, Vector2(PW * T, PH * T))


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	var pw := PW * T
	var ph := PH * T
	var ancho := float(nivel["cols"]) * T
	var vista := size.x / escala
	var objetivo := (ancho - vista) / 2.0 if ancho <= vista else clampf(pos.x + pw / 2.0 - vista / 2.0, 0.0, ancho - vista)
	cam += (objetivo - cam) * minf(1.0, dt * 8.0)
	for r in resortes:
		r["sq"] = maxf(0.0, float(r["sq"]) - dt * 4.0)
	if estado != "jugar":
		return
	inv = maxf(0.0, inv - dt)
	var izq := Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or _pulsado("izq")
	var der := Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or _pulsado("der")
	var sost := Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE) or _pulsado("salto")
	var dir := (1.0 if der else 0.0) - (1.0 if izq else 0.0)
	vel.x += (dir * MOVER - vel.x) * minf(1.0, dt * (16.0 if suelo else 9.0))
	if dir != 0.0:
		cara = dir
	if salto_pulsado:
		buffer = 0.12
		salto_pulsado = false
	buffer -= dt
	coyote -= dt
	if suelo:
		coyote = 0.1
	if buffer > 0.0 and coyote > 0.0:
		vel.y = -SALTO * _k_salto
		buffer = 0.0
		coyote = 0.0
		suelo = false
		_sonido.tocar(520.0, 0.12)
	if not sost and vel.y < -280.0:
		vel.y += GRAV * 1.2 * dt
	vel.y = minf(vel.y + GRAV * dt, 1100.0)
	# --- movimiento horizontal
	pos.x += vel.x * dt
	for p in plats:
		if _caja().intersects(p):
			if vel.x > 0.0:
				pos.x = p.position.x - pw
			elif vel.x < 0.0:
				pos.x = p.end.x
			else:
				pos.x = (p.position.x - pw) if pos.x + pw / 2.0 < p.position.x + p.size.x / 2.0 else p.end.x
			vel.x = 0.0
	pos.x = clampf(pos.x, 0.0, ancho - pw)
	# --- movimiento vertical
	pos.y += vel.y * dt
	suelo = false
	for p in plats:
		if _caja().intersects(p):
			if vel.y >= 0.0:
				pos.y = p.position.y - ph
				suelo = true
			else:
				pos.y = p.end.y
			vel.y = 0.0
	# --- resortes, pinchos, premios
	for r in resortes:
		if vel.y >= 0.0 and _caja().intersects(Rect2(r["x"] * T, r["y"] * T + T * 0.5, T, T * 0.5)):
			vel.y = -RESORTE
			r["sq"] = 1.0
			suelo = false
			_sonido.tocar(700.0, 0.2, "triangulo")
	for s in pinchos:
		if _caja().intersects(Rect2(s["x"] * T + 8, s["y"] * T + T * 0.5, T - 16, T * 0.5)):
			_herir()
	for c in recogibles:
		if not c["got"] and _caja().intersects(Rect2(c["x"] * T + 8, c["y"] * T + 8, T - 16, T - 16).grow(_alcance())):
			c["got"] = true
			recogidos += 1
			puntos += _vale(c["t"])
			_sonido.tocar(880.0 if c["t"] == "coin" else 1200.0, 0.1)
	# --- enemigos
	for e in enemigos:
		if e["muerto"]:
			e["sqt"] += dt
			continue
		e["x"] += e["dir"] * e["sp"] * _lento / T * dt
		if e["x"] > e["x0"] + e["r"]:
			e["dir"] = -1.0
		if e["x"] < e["x0"] - e["r"]:
			e["dir"] = 1.0
		var ey: float = float(e["it"]["y"]) * T
		if e["it"].get("fly", false):
			ey += sin(t * 3.0 + e["x0"]) * 7.0
		if _caja().intersects(Rect2(e["x"] * T + 8, ey + 10, T - 16, T - 14)):
			if vel.y > 0.0 and pos.y + ph < ey + T * 0.55:
				e["muerto"] = true
				vel.y = -540.0
				puntos += _vale("enemy")
				_sonido.tocar(300.0, 0.15)
			else:
				_herir()
	# --- meta y caída
	if meta != null and estado == "jugar" and _caja().intersects(Rect2(meta["x"] * T + 4, meta["y"] * T, T - 8, T)):
		if _faltan() > 0:
			_decir("Te faltan %d premios para abrir la meta" % _faltan())
		else:
			estado = "gano"
			_sonido.tocar(1000.0, 0.4, "triangulo")
			_mostrar_fin("🎉", "¡Nivel completado!", "Puntos: %d · Recogiste %d de %d" % [puntos, recogidos, total])
	if pos.y > Datos.FILAS * T + T * 2:
		_caida()


## Caer al vacío: si hay protección (inmunidad o escudo) no se pierde vida, pero vuelve al inicio.
func _caida() -> void:
	if estado != "jugar":
		return
	if inv > 0.0 or _absorber():
		pos = inicio
		vel = Vector2.ZERO
		return
	_herir()


func _herir() -> void:
	if inv > 0.0 or estado != "jugar":
		return
	if _absorber():
		return
	vidas -= 1
	_sonido.tocar(150.0, 0.3, "sierra")
	if vidas <= 0:
		estado = "perdio"
		_mostrar_fin("😵", "¡Ups! Se acabaron las vidas", "Recogiste %d de %d premios" % [recogidos, total])
	else:
		inv = _inv_golpe
		pos = inicio
		vel = Vector2.ZERO


func _mostrar_fin(icono: String, titulo: String, sub: String) -> void:
	if campana:
		nivel_terminado.emit(estado == "gano", icono, titulo, sub)
		return
	_fin = ColorRect.new()
	_fin.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(_fin)
	_fin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	_fin.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	centro.add_child(caja)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(icono)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(110, 110)
	caja.add_child(tr)
	var l1 := Label.new()
	l1.text = titulo
	l1.add_theme_font_size_override("font_size", 38)
	l1.add_theme_color_override("font_color", Color.WHITE)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l1)
	var l2 := Label.new()
	l2.text = sub
	l2.add_theme_font_size_override("font_size", 22)
	l2.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l2)
	var b := Button.new()
	b.text = "Jugar de nuevo"
	b.custom_minimum_size = Vector2(260, 58)
	b.add_theme_font_size_override("font_size", 24)
	Estilo.pintar(b, Estilo.AMARILLO, Color("4a3300"))
	b.pressed.connect(resetear)
	caja.add_child(b)


# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	if tema.is_empty():
		return
	Dibujo.fondo_de(self, nivel, tema, size, cam * escala, t)


func _dibujar_mundo(ci: CanvasItem) -> void:
	for d in decos:
		Dibujo.objeto(ci, d, tema, t)
	for p in items_plat:
		Dibujo.objeto(ci, p, tema, t)
	for s in pinchos:
		Dibujo.objeto(ci, s, tema, t)
	for r in resortes:
		Dibujo.objeto(ci, r, tema, t, {"sq": r["sq"]})
	for c in recogibles:
		if not c["got"]:
			Dibujo.objeto(ci, c, tema, t)
	if meta != null:
		Dibujo.objeto(ci, meta, tema, t)
	for e in enemigos:
		if not e["muerto"] or e["sqt"] < 0.5:
			Dibujo.objeto(ci, e["it"], tema, t, {"dir": e["dir"], "x": e["x"], "sq": e["muerto"]})
	if not (inv > 0.0 and int(t * 14.0) % 2 == 1):
		var c2 := Vector2(pos.x + PW * T / 2.0 - T / 2.0, pos.y + PH * T / 2.0 - T / 2.0) / T
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
	if _escudos > 0:
		Dibujo.emoji(ci, "🛡", Vector2(130 + maxi(0, vidas) * 30 + 6, 30), 24.0)
	if tactil:
		for z in ["izq", "der", "salto"]:
			var r := _rect_zona(z)
			var c := r.get_center()
			var activo := _pulsado(z)
			ci.draw_circle(c, r.size.x / 2.0, Color(1, 1, 1, 0.5 if activo else 0.28))
			ci.draw_arc(c, r.size.x / 2.0, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0)
			var k := r.size.x * 0.22
			var tri: PackedVector2Array
			match z:
				"izq":
					tri = PackedVector2Array([c + Vector2(-k, 0), c + Vector2(k * 0.7, -k), c + Vector2(k * 0.7, k)])
				"der":
					tri = PackedVector2Array([c + Vector2(k, 0), c + Vector2(-k * 0.7, -k), c + Vector2(-k * 0.7, k)])
				_:
					tri = PackedVector2Array([c + Vector2(0, -k), c + Vector2(-k, k * 0.7), c + Vector2(k, k * 0.7)])
			ci.draw_colored_polygon(tri, Color.WHITE)
