extends "res://scripts/juego.gd"
## Modo 3D «Aventura»: caminas libremente por un mundo 3D visto desde atrás y desde
## arriba. Recoge monedas, salta sobre bloques, pisa enemigos y llega a la meta.
## En el editor el mundo se ve desde arriba; 1 celda = 2 metros.

const Mundo3D := preload("res://scripts/mundo3d.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const C := 2.0              # metros por celda
const RADIO := 0.38         # radio del héroe
const VEL3 := 6.5
const G3 := 26.0
const SALTO3 := 10.0   # llega a ~1,9 de alto: se sube a bloques de altura 2 (los más altos, con escalones)

var _raiz: Node3D
var _mundo3: Node3D
var _cam3: Camera3D
var _jug: Node3D
var _sombra: MeshInstance3D
var p3 := Vector3.ZERO      # x, y (altura), z
var vy := 0.0
var enelsuelo := true
var giro := 0.0
var bloques: Array = []     # {r: Rect2 (x,z), top}
var solidos: Array = []     # {c: Vector2, r}
var premios: Array = []
var peligros: Array = []
var bichos: Array = []      # {it, x, z, x0, dir, muerto, sqt, nodo}
var meta_pos: Variant = null
var _salto := false
var _joy_ini := Vector2.ZERO
var _joy := Vector2.ZERO
var _joy_dedo := -1
var _mundo_ancho := 60.0
var _mundo_fondo := 28.0


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	var v := Mundo3D.visor(self)
	_raiz = v[1]
	_raiz.add_child(Mundo3D.entorno(tema, str(nivel.get("fondo", ""))))
	_raiz.add_child(Mundo3D.sol())
	_cam3 = Camera3D.new()
	_cam3.fov = 55.0
	_cam3.far = 300.0
	_raiz.add_child(_cam3)
	_reconstruir()


func resetear() -> void:
	if _fin:
		_fin.queue_free()
		_fin = null
	t = 0.0
	puntos = 0
	recogidos = 0
	total = 0
	_aplicar_reglas()
	estado = "jugar"
	inv = 0.0
	bloques = []
	solidos = []
	premios = []
	peligros = []
	bichos = []
	meta_pos = null
	_mundo_ancho = float(nivel["cols"]) * C
	_mundo_fondo = float(Datos.FILAS) * C
	var inicio3 := Vector2(2.0 * C, 6.0 * C)
	for it in nivel["items"]:
		var cx := (float(it["x"]) + 0.5) * C
		var cz := (float(it["y"]) + 0.5) * C
		match str(it["t"]):
			"player":
				inicio3 = Vector2(cx, cz)
			"plat":
				bloques.append({"r": Rect2(float(it["x"]) * C, float(it["y"]) * C, float(it["w"]) * C, float(it["h"]) * C), "top": float(it.get("alt", 1)), "it": it})
			"coin", "star", "gem":
				premios.append({"t": str(it["t"]), "x": cx, "z": cz, "got": false, "nodo": null})
				total += 1
			"spike":
				peligros.append({"x": cx, "z": cz})
			"goal":
				meta_pos = Vector2(cx, cz)
			"enemy":
				bichos.append({"it": it, "x": cx, "z": cz, "x0": cx, "dir": 1.0, "muerto": false, "sqt": 0.0,
					"r": float(it.get("r", 3)) * C, "sp": float(it.get("sp", 60)) / 48.0 * C * 0.8, "nodo": null})
			"deco":
				var e := str(it["e"])
				if not Datos.es_nube(e):
					var ancho_m := float(it.get("s", 56)) / 48.0 * C
					solidos.append({"c": Vector2(cx, cz), "r": maxf(0.2, ancho_m * 0.22)})
	p3 = Vector3(inicio3.x, 0, inicio3.y)
	vy = 0.0
	enelsuelo = true
	giro = 0.0
	_p3_construir()
	if _raiz:
		_reconstruir()


func _draw() -> void:
	pass


func _dibujar_mundo(_ci: CanvasItem) -> void:
	pass


# ------------------------------------------------------------------ mundo
func _reconstruir() -> void:
	if _mundo3:
		_mundo3.queue_free()
	_mundo3 = Node3D.new()
	_raiz.add_child(_mundo3)
	var pl: Array = tema["plat"]
	var borde := 40.0
	_mundo3.add_child(Mundo3D.suelo((tema["cerca"] as Color).darkened(0.15), _mundo_ancho + borde * 2.0, _mundo_fondo + borde * 2.0, C, _mundo_ancho / 2.0, _mundo_fondo / 2.0))
	# borde del mundo
	for r in [Rect2(-0.3, -0.3, _mundo_ancho + 0.6, 0.3), Rect2(-0.3, _mundo_fondo, _mundo_ancho + 0.6, 0.3), Rect2(-0.3, 0, 0.3, _mundo_fondo), Rect2(_mundo_ancho, 0, 0.3, _mundo_fondo)]:
		_mundo3.add_child(Mundo3D.caja(Vector3(r.size.x, 0.5, r.size.y), pl[1], Vector3(r.position.x + r.size.x / 2.0, 0.25, r.position.y + r.size.y / 2.0)))
	_mundo3.add_child(Mundo3D.colinas(tema["lejos"], -50.0, 8.0, 14.0, 40.0, -150.0, _mundo_ancho + 150.0))
	for b in bloques:
		var r2: Rect2 = b["r"]
		var top: float = b["top"]
		_mundo3.add_child(Mundo3D.caja(Vector3(r2.size.x, top, r2.size.y), pl[0], Vector3(r2.position.x + r2.size.x / 2.0, top / 2.0, r2.position.y + r2.size.y / 2.0)))
		_mundo3.add_child(Mundo3D.caja(Vector3(r2.size.x + 0.04, 0.2, r2.size.y + 0.04), pl[1], Vector3(r2.position.x + r2.size.x / 2.0, top - 0.1, r2.position.y + r2.size.y / 2.0)))
	var i := 0
	for it in nivel["items"]:
		if str(it["t"]) != "deco":
			i += 1
			continue
		var e := str(it["e"])
		var px := float(it.get("s", 56))
		var cx := (float(it["x"]) + 0.5) * C
		var cz := (float(it["y"]) + 0.5) * C
		var nodo: Node3D
		if Mundo3D.es_modelo(e):
			Datos.pal_item = str(it.get("pal", ""))
			nodo = Mundo3D.objeto(e, px / 48.0 * C, px * C)
			Datos.pal_item = ""
		else:
			nodo = Mundo3D.sprite(e, px / 48.0 * C)
			(nodo as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			nodo.position.y = px / 48.0 * C / 2.0
		var alto_nube := 7.0 if Datos.es_nube(e) else 0.0
		nodo.position = Vector3(cx, nodo.position.y + alto_nube, cz)
		nodo.rotation_degrees.y = float((i * 47) % 40) - 20.0
		_mundo3.add_child(nodo)
		i += 1
	for pe in peligros:
		for k in 4:
			var cono := Mundo3D.cono(0.22, 0.8, Color("d4d8e0"))
			cono.position = Vector3(pe["x"] + (k % 2 - 0.5) * 0.7, 0.4, pe["z"] + (k / 2 - 0.5) * 0.7)
			_mundo3.add_child(cono)
	for pr in premios:
		var nodo2: Node3D
		match pr["t"]:
			"coin":
				nodo2 = Mundo3D.moneda()
				nodo2.scale = Vector3.ONE * 1.4
			"star":
				nodo2 = Mundo3D.sprite("⭐", 1.2)
			_:
				nodo2 = Mundo3D.sprite("💎", 1.1)
		nodo2.position = Vector3(pr["x"], 1.0, pr["z"])
		_mundo3.add_child(nodo2)
		pr["nodo"] = nodo2
	if meta_pos != null:
		var mp: Vector2 = meta_pos
		_mundo3.add_child(Mundo3D.caja(Vector3(0.12, 3.6, 0.12), Color("e5e7eb"), Vector3(mp.x, 1.8, mp.y)))
		var bandera := Mundo3D.caja(Vector3(1.4, 0.8, 0.06), Color("22c55e"), Vector3(mp.x + 0.7, 3.2, mp.y))
		_mundo3.add_child(bandera)
		var aro := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0
		tm.outer_radius = 1.25
		aro.mesh = tm
		aro.material_override = Mundo3D.mat(Color("22c55e"), 0.8)
		aro.position = Vector3(mp.x, 0.1, mp.y)
		_mundo3.add_child(aro)
	for b2 in bichos:
		var nb := Mundo3D.objeto(str(b2["it"]["e"]), 1.5)
		_mundo3.add_child(nb)
		b2["nodo"] = nb
	_sombra = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.45
	cm.height = 0.02
	_sombra.mesh = cm
	_sombra.material_override = Mundo3D.mat(Color(0, 0, 0, 0.35), 0.0, true)
	_sombra.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mundo3.add_child(_sombra)
	_jug = Mundo3D.objeto(str(nivel["hero"]), 1.7)
	if _jug is Sprite3D:
		(_jug as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_mundo3.add_child(_jug)


# ------------------------------------------------------------------ entrada
func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_SPACE, KEY_UP] and false:
			pass
		if ev.keycode == KEY_SPACE:
			_salto = true
		elif ev.keycode == KEY_ESCAPE:
			if con_salir:
				salir.emit()
			elif not OS.has_feature("web") and not OS.has_feature("android"):
				get_tree().quit()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position - global_position
		if ev.pressed:
			if tactil or true:
				if p.x > size.x * 0.62 and p.y > size.y * 0.45:
					_salto = true
				elif p.x < size.x * 0.5 and p.y > size.y * 0.2:
					_joy_dedo = 0
					_joy_ini = p
					_joy = Vector2.ZERO
		elif _joy_dedo == 0:
			_joy_dedo = -1
			_joy = Vector2.ZERO
	elif ev is InputEventMouseMotion and _joy_dedo == 0:
		var d: Vector2 = (ev.position - global_position) - _joy_ini
		_joy = (d / 70.0).limit_length(1.0)


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


# ------------------------------------------------------------------ lógica
func _process(delta: float) -> void:
	_avanzar(delta)
	if _raiz and _mundo3:
		_sincronizar()
	_hud.queue_redraw()


func _techo(x: float, z: float) -> float:
	## altura del suelo bajo (x,z): 0 o la parte de arriba de un bloque
	var m := 0.0
	for b in bloques:
		if (b["r"] as Rect2).grow(RADIO * 0.6).has_point(Vector2(x, z)) and b["top"] > m and p3.y >= b["top"] - 0.45:
			m = b["top"]
	return m


func _bicho_choca(x: float, z: float) -> bool:
	for b in bloques:
		if (b["r"] as Rect2).grow(0.4).has_point(Vector2(x, z)):
			return true
	return false


func _choca(x: float, z: float) -> bool:
	for b in bloques:
		if (b["r"] as Rect2).grow(RADIO).has_point(Vector2(x, z)) and p3.y < b["top"] - 0.3:
			return true
	for s in solidos:
		if Vector2(x, z).distance_to(s["c"]) < s["r"] + RADIO and p3.y < 1.5:
			return true
	return false


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	if estado != "jugar":
		return
	inv = maxf(0.0, inv - dt)
	var d := _dir_entrada()
	if _p3_ok and _p3h != null:
		_mover_godot(d, dt)
	else:
		_mover_legacy(d, dt)
	# premios
	for pr in premios:
		if pr["got"]:
			continue
		if Vector2(p3.x, p3.z).distance_to(Vector2(pr["x"], pr["z"])) < (3.0 if _iman_act() else 1.0) and absf(p3.y + 0.8 - 1.0) < 1.6:
			pr["got"] = true
			recogidos += 1
			puntos += _vale(pr["t"])
			_sonido.tocar(880.0 if pr["t"] == "coin" else 1200.0, 0.1)
	for pe in peligros:
		if Vector2(p3.x, p3.z).distance_to(Vector2(pe["x"], pe["z"])) < 0.9 and p3.y < 0.6:
			_herir()
	for b in bichos:
		if b["muerto"]:
			b["sqt"] += dt
			continue
		var bx: float = b["x"] + b["dir"] * b["sp"] * dt
		if _bicho_choca(bx, b["z"]):
			b["dir"] = -b["dir"]  # un bloque: da la vuelta en vez de atravesarlo
		else:
			b["x"] = bx
		if b["x"] > b["x0"] + b["r"]:
			b["dir"] = -1.0
		if b["x"] < b["x0"] - b["r"]:
			b["dir"] = 1.0
		if Vector2(p3.x, p3.z).distance_to(Vector2(b["x"], b["z"])) < 1.0:
			if vy < -1.0 and p3.y > 0.7:
				b["muerto"] = true
				vy = 7.5
				enelsuelo = false
				puntos += _vale("enemy")
				_sonido.tocar(300.0, 0.15)
			elif p3.y < 1.2:
				_herir()
	if meta_pos != null and Vector2(p3.x, p3.z).distance_to(meta_pos) < 1.4 and estado == "jugar":
		if _faltan() > 0:
			_decir("Te faltan %d premios para abrir la meta" % _faltan())
		else:
			estado = "gano"
			_sonido.tocar(1000.0, 0.4, "triangulo")
			_mostrar_fin("🎉", "¡Llegaste a la meta!", "Puntos: %d · Recogiste %d de %d" % [puntos, recogidos, total])


func _mover_legacy(d: Vector2, dt: float) -> void:
	var nx := p3.x + d.x * VEL3 * dt
	var nz := p3.z + d.y * VEL3 * dt
	nx = clampf(nx, RADIO, _mundo_ancho - RADIO)
	nz = clampf(nz, RADIO, _mundo_fondo - RADIO)
	if not _choca(nx, p3.z):
		p3.x = nx
	if not _choca(p3.x, nz):
		p3.z = nz
	if d.length() > 0.1:
		giro = lerp_angle(giro, atan2(d.x, d.y), minf(1.0, dt * 14.0))
	# salto y gravedad
	var base := _techo(p3.x, p3.z)
	if _salto and enelsuelo:
		vy = SALTO3 * _k_salto
		enelsuelo = false
		_sonido.tocar(520.0, 0.12)
	_salto = false
	vy -= G3 * dt
	p3.y += vy * dt
	if p3.y <= base and vy <= 0.0:
		p3.y = base
		vy = 0.0
		enelsuelo = true
	else:
		if p3.y > base + 0.02:
			enelsuelo = false


## Física real de Godot (3D): el héroe es un CharacterBody3D y los bloques StaticBody3D.
var _p3w: SubViewport = null
var _p3h: CharacterBody3D = null
var _p3_ok := false
var _p3_espera := false
var _p3_gen := 0


func _p3_borrar() -> void:
	_p3_gen += 1
	_p3_ok = false
	_p3_espera = false
	if _p3w != null:
		_p3w.queue_free()
		_p3w = null
	_p3h = null


func _p3_cuerpo(forma: Shape3D, pos3: Vector3, top: float) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = forma
	b.add_child(cs)
	b.position = pos3
	b.set_meta("top", top)
	_p3w.add_child(b)
	return b


func _p3_construir() -> void:
	_p3_borrar()
	_p3w = SubViewport.new()
	_p3w.own_world_3d = true
	_p3w.size = Vector2i(2, 2)
	_p3w.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_p3w)
	var sf := BoxShape3D.new()
	sf.size = Vector3(_mundo_ancho + 80.0, 1.0, _mundo_fondo + 80.0)
	_p3_cuerpo(sf, Vector3(_mundo_ancho / 2.0, -0.5, _mundo_fondo / 2.0), 0.0)
	for b in bloques:
		var r: Rect2 = b["r"]
		var bf := BoxShape3D.new()
		bf.size = Vector3(r.size.x, float(b["top"]), r.size.y)
		_p3_cuerpo(bf, Vector3(r.position.x + r.size.x / 2.0, float(b["top"]) / 2.0, r.position.y + r.size.y / 2.0), float(b["top"]))
	for so in solidos:
		var cf := CylinderShape3D.new()
		cf.radius = float(so["r"])
		cf.height = 1.5
		_p3_cuerpo(cf, Vector3((so["c"] as Vector2).x, 0.75, (so["c"] as Vector2).y), 1.5)
	_p3h = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIO
	cap.height = 1.6
	cs.shape = cap
	_p3h.add_child(cs)
	_p3h.position = p3 + Vector3(0, 0.8, 0)
	_p3w.add_child(_p3h)


func _pw_vigilar() -> void:
	if _p3w == null or _p3_ok or _p3_espera or not is_inside_tree():
		return
	_p3_espera = true
	var gen := _p3_gen
	await get_tree().physics_frame
	await get_tree().physics_frame
	if gen == _p3_gen and is_inside_tree():
		_p3_ok = true
		_p3_espera = false


func _p3_mover(m: Vector3) -> KinematicCollision3D:
	_p3h.position = p3 + Vector3(0, 0.8, 0)
	var c := _p3h.move_and_collide(m, false, 0.02)
	p3 = _p3h.position - Vector3(0, 0.8, 0)
	return c


func _mover_godot(d: Vector2, dt: float) -> void:
	var dx := d.x * VEL3 * dt
	var dz := d.y * VEL3 * dt
	for eje in [Vector3(dx, 0, 0), Vector3(0, 0, dz)]:
		var c := _p3_mover(eje)
		if c != null:
			# escalón: si el borde del bloque está cerca de los pies, se sube en vez de frenar
			var ob := c.get_collider()
			var top := float(ob.get_meta("top", 0.0)) if ob != null else 0.0
			if top > p3.y and top - p3.y <= 0.45:
				p3.y = top
				_p3_mover(eje)
	p3.x = clampf(p3.x, RADIO, _mundo_ancho - RADIO)
	p3.z = clampf(p3.z, RADIO, _mundo_fondo - RADIO)
	if d.length() > 0.1:
		giro = lerp_angle(giro, atan2(d.x, d.y), minf(1.0, dt * 14.0))
	if _salto and enelsuelo:
		vy = SALTO3 * _k_salto
		enelsuelo = false
		_sonido.tocar(520.0, 0.12)
	_salto = false
	vy -= G3 * dt
	enelsuelo = false
	var cy := _p3_mover(Vector3(0, vy * dt, 0))
	if cy != null:
		if cy.get_normal().y > 0.5 and vy <= 0.0:
			enelsuelo = true
		vy = 0.0


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
		vy = 6.0
		enelsuelo = false


func _sincronizar() -> void:
	var objetivo := Vector3(p3.x, 0, p3.z)
	var cp := Vector3(clampf(objetivo.x, 8.0, maxf(8.0, _mundo_ancho - 8.0)), 0, clampf(objetivo.z, 2.0, maxf(2.0, _mundo_fondo)))
	var alto := 18.0
	var atras := 13.0
	if size.y > size.x:
		alto = 21.0
		atras = 15.0
	_cam3.position = _cam3.position.lerp(cp + Vector3(0, alto + p3.y * 0.3, atras), 0.15) if _cam3.position.length() > 0.1 else cp + Vector3(0, alto, atras)
	_cam3.look_at(Vector3(_cam3.position.x, 0.0, _cam3.position.z - atras * 0.95), Vector3.UP)
	if _jug is Sprite3D:
		_jug.position = Vector3(p3.x, p3.y + 0.85, p3.z)
	else:
		_jug.position = Vector3(p3.x, p3.y, p3.z)
		_jug.rotation.y = giro
		_mascota_3d(_mundo3, p3, Vector3(0.8, 0.0, 0.8))
		var mueve := _dir_entrada().length() > 0.1 and enelsuelo
		Assets3D.animar(_jug, t, 1.0 if mueve else (0.0 if enelsuelo else 0.5))
	_jug.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1)
	_sombra.position = Vector3(p3.x, _techo(p3.x, p3.z) + 0.03, p3.z)
	_sombra.scale = Vector3.ONE * clampf(1.0 - (p3.y - _techo(p3.x, p3.z)) * 0.15, 0.4, 1.0)
	for pr in premios:
		var nodo: Node3D = pr["nodo"]
		nodo.visible = not pr["got"]
		nodo.position.y = 1.0 + sin(t * 4.0 + pr["x"]) * 0.12
		if pr["t"] == "coin":
			nodo.rotation.y = t * 3.0
	for b in bichos:
		var nb: Node3D = b["nodo"]
		nb.visible = not b["muerto"] or b["sqt"] < 0.5
		nb.position = Vector3(b["x"], 0, b["z"])
		nb.rotation.y = lerp_angle(nb.rotation.y, PI / 2.0 * b["dir"], 0.2)
		nb.scale = Vector3(1.2, 0.35, 1.2) if b["muerto"] else Vector3.ONE
		if nb is Sprite3D:
			nb.position.y = 0.75
		else:
			Assets3D.animar(nb, t, 0.0 if b["muerto"] else 0.8)


# ------------------------------------------------------------------ pantalla
func _dibujar_hud(ci: CanvasItem) -> void:
	_hud_extra(ci)
	var fuente := ThemeDB.fallback_font
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.45), 22), Rect2(12, 10, maxf(250.0, 126.0 + int(reglas["vidas"]) * 30.0), 40))
	Dibujo.emoji(ci, "⭐", Vector2(34, 30), 26.0)
	ci.draw_string(fuente, Vector2(52, 38), str(puntos), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	for i in maxi(0, vidas):
		Dibujo.emoji(ci, "❤", Vector2(130 + i * 30, 30), 26.0)
	if tactil:
		var base := Vector2(size.x * 0.17, size.y - 110.0)
		ci.draw_circle(base, 70.0, Color(1, 1, 1, 0.18))
		ci.draw_arc(base, 70.0, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 3.0)
		ci.draw_circle(base + _joy * 50.0, 30.0, Color(1, 1, 1, 0.55))
		var sb := Vector2(size.x - 110.0, size.y - 110.0)
		ci.draw_circle(sb, 56.0, Color(1, 1, 1, 0.28))
		ci.draw_arc(sb, 56.0, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([sb + Vector2(0, -20), sb + Vector2(-20, 14), sb + Vector2(20, 14)]), Color.WHITE)
	elif t < 6.0 and estado == "jugar":
		var txt := "Flechas o WASD para caminar     Espacio para saltar"
		var w := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 18), Rect2((size.x - w) / 2.0 - 16, 70, w + 32, 40))
		ci.draw_string(fuente, Vector2((size.x - w) / 2.0, 98), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
