extends "res://scripts/juego.gd"
## Modo 3D: corredor de 3 carriles (estilo Subway Surfers).
## El héroe corre solo hacia adelante: cambia de carril, salta las vallas,
## se agacha bajo las vigas y esquiva las paredes. ¡Recoge monedas y llega a la meta!

const Mundo3D := preload("res://scripts/mundo3d.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const CELDA_M := 5.0       # metros por celda del editor
const ANCHO_CARRIL := 2.2
const VEL0 := 11.0
const VEL_MAX := 18.0
const Ambiente := preload("res://scripts/ambiente3d.gd")
const Progreso := preload("res://scripts/progreso.gd")
const G3 := 34.0
const SALTO3 := 12.0
const AUTO_ARBOL := {"dia": "arbol", "atardecer": "arbol", "noche": "pino", "bosque": "pino", "desierto": "cactus", "mar": "arbusto", "espacio": "cristal", "nieve": "pino"}

var _raiz: Node3D
var _mundo3: Node3D
var _horizonte: Node3D
var _cam3: Camera3D
var _s_jug: Node3D
var _sombra: MeshInstance3D
var dist := 0.0
var carril := 1
var px := 0.0
var py := 0.0
var vy := 0.0
var agachado := 0.0
var rapidez := VEL0
var fin_z := 100.0
var obst: Array = []       # {t, lane, z, nodo, golpeado}
var premios: Array = []    # {t, lane, z, nodo, got}
var _toque_ini := Vector2.ZERO
var _toque_activo := false
var _pista_lista := false
# segundo jugador (modo «2 jugadores» en el mismo teclado)
var j2 := false
var carril2 := 1
var px2 := 0.0
var py2 := 0.0
var vy2 := 0.0
var agachado2 := 0.0
var _s_jug2: Node3D
var _amb: Node3D
var _n_obst := 0
var _vel_k := 1.0
var stats := {"recogidos": 0, "monedas": 0, "puntos": 0, "gemas": 0, "estrellas": 0, "perseguidor": 0}
var _sol3: DirectionalLight3D
var _we3: WorldEnvironment
var _joy_ult := Vector2.ZERO


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	var v := Mundo3D.visor(self)
	_raiz = v[1]
	_we3 = Mundo3D.entorno(tema, str(nivel.get("fondo", "")))
	_raiz.add_child(_we3)
	_sol3 = Mundo3D.sol()
	_raiz.add_child(_sol3)
	_cam3 = Camera3D.new()
	_cam3.fov = 68.0
	_cam3.far = 400.0
	_raiz.add_child(_cam3)
	_amb = Ambiente.new()
	_raiz.add_child(_amb)
	_amb.config(nivel, reglas, _we3, _sol3, _cam3)
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
	dist = 0.0
	carril = 1
	px = 0.0
	py = 0.0
	vy = 0.0
	agachado = 0.0
	carril2 = 1
	px2 = 0.0
	py2 = 0.0
	vy2 = 0.0
	agachado2 = 0.0
	j2 = int(reglas.get("jugadores", 1)) == 2
	var dif: Dictionary = Progreso.DIFICULTADES[Progreso.dificultad(reglas)]
	_vel_k = float(dif["vel"])
	vidas = clampi(vidas + int(dif["vidas"]), 1, 12)
	stats = {"recogidos": 0, "monedas": 0, "puntos": 0, "gemas": 0, "estrellas": 0, "perseguidor": 0}
	if _amb:
		_amb.reiniciar()
	rapidez = VEL0 * _vel_k
	obst = []
	premios = []
	fin_z = float(nivel["cols"]) * CELDA_M
	for it in nivel["items"]:
		var tp := str(it["t"])
		if not Datos.TIPOS_PISTA.has(tp):
			continue
		var lane := Datos.a_carril(int(it["y"]))
		var z := float(it["x"]) * CELDA_M + 2.0
		match tp:
			"valla", "pared", "viga":
				obst.append({"t": tp, "lane": lane, "z": z, "nodo": null, "golpeado": false})
			"coin", "star", "gem":
				premios.append({"t": tp, "lane": lane, "z": z, "nodo": null, "got": false})
				total += 1
			"goal":
				fin_z = z
	if _raiz:
		_reconstruir()


func _draw() -> void:
	pass


func _dibujar_mundo(_ci: CanvasItem) -> void:
	pass


# ------------------------------------------------------------------ mundo 3D
# ------------------------------------------------------------------ curvas y subidas
## Tramos de pista: [{"d":[desde%,hasta%], "curva":-1..1, "subida":-1..1}]. Cada tramo mueve la pista hacia un lado o
## hacia arriba de forma suave y el cambio se queda (así se pueden encadenar curvas en S y colinas).
func _tramos() -> Array:
	var r: Variant = nivel.get("pista", [])
	return r if r is Array else []


func _ss(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _xo(d: float) -> float:
	var r := 0.0
	for tr in _tramos():
		var a := float(tr["d"][0]) / 100.0 * fin_z
		var b := float(tr["d"][1]) / 100.0 * fin_z
		r += float(tr.get("curva", 0.0)) * 14.0 * _ss((d - a) / maxf(b - a, 1.0))
	return r


func _yo(d: float) -> float:
	var r := 0.0
	for tr in _tramos():
		var a := float(tr["d"][0]) / 100.0 * fin_z
		var b := float(tr["d"][1]) / 100.0 * fin_z
		r += float(tr.get("subida", 0.0)) * 7.0 * _ss((d - a) / maxf(b - a, 1.0))
	return r


## Mueve y gira un nodo ya puesto en (x, y, -d) para que siga la pista.
func _ajustar(n: Node3D) -> void:
	var d := -n.position.z
	var lado := absf(n.position.x) > 5.0   # el decorado de los lados queda en el suelo; sólo la pista sube
	n.position.x += _xo(d)
	if not lado:
		n.position.y += _yo(d)


func _pista_con_curvas() -> void:
	var pl: Array = tema["plat"]
	# quitar la pista recta y poner tramos cortos que siguen la curva
	for c in _mundo3.get_children():
		if c.has_meta("via"):
			c.queue_free()
	var largo := fin_z + 60.0
	var d := -20.0
	while d < largo:
		var paso := 3.0
		var mid := d + paso / 2.0
		var a := (_xo(mid + 0.5) - _xo(mid - 0.5))
		var b := (_yo(mid + 0.5) - _yo(mid - 0.5))
		var largo_seg := paso * 1.25
		var cuerpo := Mundo3D.caja(Vector3(7.0, 0.3, largo_seg), pl[0], Vector3.ZERO)
		var borde1 := Mundo3D.caja(Vector3(0.18, 0.4, largo_seg), pl[1], Vector3(-3.55, 0.2, 0))
		var borde2 := Mundo3D.caja(Vector3(0.18, 0.4, largo_seg), pl[1], Vector3(3.55, 0.2, 0))
		var seg := Node3D.new()
		seg.add_child(cuerpo)
		seg.add_child(borde1)
		seg.add_child(borde2)
		seg.position = Vector3(_xo(mid), _yo(mid) - 0.15, -mid)
		seg.rotation = Vector3(atan(b), atan2(-a, 1.0), 0.0)
		seg.set_meta("fijo", true)
		_mundo3.add_child(seg)
		d += paso


func _reconstruir() -> void:
	if _mundo3:
		_mundo3.queue_free()
	_mundo3 = Node3D.new()
	_raiz.add_child(_mundo3)
	var pl: Array = tema["plat"]
	var largo := fin_z + 90.0
	# suelo y pista
	var suelo := Mundo3D.caja(Vector3(900, 0.2, largo + 200.0), (tema["cerca"] as Color).darkened(0.3), Vector3(0, -0.35, -largo / 2.0 + 60.0))
	suelo.set_meta("fijo", true)
	_mundo3.add_child(suelo)
	var via1 := Mundo3D.caja(Vector3(7.0, 0.3, largo + 100.0), pl[0], Vector3(0, -0.15, -largo / 2.0 + 20.0))
	via1.set_meta("via", true)
	_mundo3.add_child(via1)
	for lx in [-3.55, 3.55]:
		var via2 := Mundo3D.caja(Vector3(0.18, 0.4, largo + 100.0), pl[1], Vector3(lx, 0.05, -largo / 2.0 + 20.0))
		via2.set_meta("via", true)
		_mundo3.add_child(via2)
	for lx in [-1.1, 1.1]:
		var z := 0.0
		while z < fin_z + 40.0:
			_mundo3.add_child(Mundo3D.caja(Vector3(0.1, 0.02, 1.6), Color(1, 1, 1, 1), Vector3(lx, 0.0, -z - 1.0)))
			z += 4.0
	# línea de salida y arco de meta
	_mundo3.add_child(Mundo3D.caja(Vector3(7.0, 0.02, 0.4), Color("fef08a"), Vector3(0, 0.01, 0.5)))
	for lx in [-3.7, 3.7]:
		_mundo3.add_child(Mundo3D.caja(Vector3(0.3, 4.6, 0.3), Color("e5e7eb"), Vector3(lx, 2.3, -fin_z)))
	var banda := Mundo3D.caja(Vector3(7.7, 0.9, 0.25), Color("1f2937"), Vector3(0, 4.4, -fin_z))
	_mundo3.add_child(banda)
	for k in 8:
		_mundo3.add_child(Mundo3D.caja(Vector3(0.96, 0.45, 0.28), Color.WHITE if k % 2 == 0 else Color("1f2937"), Vector3(-3.37 + k * 0.96, 4.62 if k % 2 == 0 else 4.17, -fin_z)))
	var bandera := Mundo3D.sprite("🏁", 2.2)
	bandera.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	bandera.position = Vector3(0, 3.2, -fin_z + 0.3)
	_mundo3.add_child(bandera)
	# horizonte (sigue a la cámara para que parezca infinito)
	_horizonte = Node3D.new()
	_horizonte.set_meta("fijo", true)
	_mundo3.add_child(_horizonte)
	_horizonte.add_child(Mundo3D.colinas(tema["lejos"], 0.0, 3.0, 5.5, 22.0, -260.0, 260.0))
	_horizonte.add_child(Mundo3D.colinas(tema["cerca"], 30.0, 0.6, 2.4, 14.0, -200.0, 200.0, 40.0))
	# decorado automático a los lados: el del mundo (modelos propios) o el árbol del tema
	var dec: Array = nivel.get("decorado", []) if nivel.get("decorado", []) is Array else []
	var dens := clampf(float(nivel.get("densidad", 1.0)), 0.2, 2.5)
	var arbol: String = AUTO_ARBOL.get(str(nivel["theme"]), "arbol")
	var z2 := 3.0
	var i := 0
	while z2 < fin_z + 60.0:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var mo: Node3D
		var dist_lado := 6.5 + float((i * 7) % 5)
		if dec.size() > 0:
			var d: Dictionary = dec[(i * 7919 + i / 3) % dec.size()]
			var alto := float(d.get("alto", 3.0)) * (0.85 + float((i * 37) % 30) / 100.0)
			mo = Mundo3D.objeto_caja(str(d["e"]), alto * 1.6, alto)
			var rng: Array = d.get("dist", [5.5, 11.0])
			dist_lado = float(rng[0]) + (float(rng[1]) - float(rng[0])) * float((i * 13) % 10) / 10.0
		else:
			mo = Assets3D.construir(arbol, 3.0 + float(i % 3) * 0.8)
		mo.position = Vector3(lado * dist_lado, 0, -z2 - float((i * 5) % 3))
		mo.rotation_degrees.y = float((i * 53) % 360) if dec.size() > 0 else float((i * 53) % 90)
		_mundo3.add_child(mo)
		z2 += (7.0 if dec.is_empty() else 3.2) / dens
		i += 1
	# decoración puesta por el niño
	for it in nivel["items"]:
		if str(it["t"]) != "deco":
			continue
		var px := float(it.get("s", 56))
		var e := str(it["e"])
		var lado2 := -1.0 if int(it["y"]) < 7 else 1.0
		var pos := Vector3(lado2 * 5.0, 0, -float(it["x"]) * CELDA_M)
		if Mundo3D.es_modelo(e):
			Datos.pal_item = str(it.get("pal", ""))
			var mo2 := Mundo3D.objeto(e, px / 48.0 * 2.0, px * 2.0)
			Datos.pal_item = ""
			mo2.position = pos
			_mundo3.add_child(mo2)
		else:
			var sz := px / 48.0 * 2.4
			var sp2 := Mundo3D.sprite(e, sz)
			sp2.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			sp2.position = pos + Vector3(0, sz / 2.0, 0)
			_mundo3.add_child(sp2)
	# obstáculos y premios
	for o in obst:
		o["nodo"] = _hacer_obstaculo(o["t"])
		o["nodo"].position = Vector3((o["lane"] - 1) * ANCHO_CARRIL, 0, -o["z"])
		_mundo3.add_child(o["nodo"])
	for p in premios:
		var nodo: Node3D
		var pm: Dictionary = nivel.get("premios", {}) if nivel.get("premios", {}) is Dictionary else {}
		if pm.has(p["t"]) and str(pm[p["t"]]) != "":
			var pv := Node3D.new()
			pv.add_child(Mundo3D.objeto_caja(str(pm[p["t"]]), 0.9, 0.9))
			pv.position.y = -0.45
			nodo = Node3D.new()
			nodo.add_child(pv)
		else:
			match p["t"]:
				"coin":
					nodo = Mundo3D.moneda()
				"star":
					nodo = Mundo3D.sprite("⭐", 1.1)
				_:
					nodo = Mundo3D.sprite("💎", 1.0)
		nodo.position = Vector3((p["lane"] - 1) * ANCHO_CARRIL, 1.0, -p["z"])
		_mundo3.add_child(nodo)
		p["nodo"] = nodo
	if _tramos().size() > 0:
		_pista_con_curvas()
		for c in _mundo3.get_children():
			if c is Node3D and not c.has_meta("fijo") and not c.has_meta("via"):
				_ajustar(c)
	# héroe
	_sombra = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.55
	cm.bottom_radius = 0.55
	cm.height = 0.02
	_sombra.mesh = cm
	_sombra.material_override = Mundo3D.mat(Color(0, 0, 0, 0.35), 0.0, true)
	_sombra.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mundo3.add_child(_sombra)
	_s_jug = Mundo3D.objeto(str(nivel["hero"]), clampf(float(nivel.get("hero_alto", 1.7)), 0.5, 6.0))
	if _s_jug is Sprite3D:
		(_s_jug as Sprite3D).pixel_size *= 1.6 / 1.7
		(_s_jug as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	else:
		_s_jug.rotation_degrees.y = 180.0
	_mundo3.add_child(_s_jug)
	_amb.vestir(_s_jug)
	_s_jug2 = null
	if int(reglas.get("jugadores", 1)) == 2:
		_s_jug2 = Mundo3D.objeto(_heroe2(), 1.7)
		if _s_jug2 is Sprite3D:
			(_s_jug2 as Sprite3D).pixel_size *= 1.6 / 1.7
			(_s_jug2 as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		else:
			_s_jug2.rotation_degrees.y = 180.0
		_mundo3.add_child(_s_jug2)


## El héroe del jugador 2: el que eligió el creador, o el siguiente de la lista.
func _heroe2() -> String:
	var h2 := str(reglas.get("heroe2", ""))
	var h1 := str(nivel["hero"])
	if h2 != "" and h2 != h1:
		return h2
	for jg in reglas.get("jugables", []):
		if str(jg["id"]) != h1:
			return str(jg["id"])
	if h1.begins_with("g:"):
		return "g:gonkoken.glb" if h1 != "g:gonkoken.glb" else "g:chilesaurus.glb"
	for i in Datos.heroes.size():
		if Datos.heroes[i][1] == h1:
			return Datos.heroes[(i + 1) % Datos.heroes.size()][1]
	return "🐶"


func _hacer_obstaculo(tipo: String) -> Node3D:
	var mods: Dictionary = nivel.get("obstaculos", {}) if nivel.get("obstaculos", {}) is Dictionary else {}
	if mods.has(tipo) and str(mods[tipo]) != "":
		var cajas := {"valla": Vector2(1.9, 0.85), "pared": Vector2(1.9, 2.5), "viga": Vector2(2.3, 3.0)}
		var cv: Vector2 = cajas.get(tipo, Vector2(1.9, 1.5))
		var lista: Array = mods[tipo] if mods[tipo] is Array else [mods[tipo]]
		_n_obst += 1
		return Mundo3D.objeto_caja(str(lista[_n_obst % lista.size()]), cv.x, cv.y)
	var n := Node3D.new()
	match tipo:
		"valla":
			for lx in [-0.85, 0.85]:
				n.add_child(Mundo3D.caja(Vector3(0.15, 0.9, 0.15), Color("6b7280"), Vector3(lx, 0.45, 0)))
			for k in 4:
				n.add_child(Mundo3D.caja(Vector3(0.45, 0.45, 0.3), Color("ef4444") if k % 2 == 0 else Color("fff7f7"), Vector3(-0.675 + k * 0.45, 0.65, 0)))
		"pared":
			n.add_child(Mundo3D.caja(Vector3(1.9, 2.5, 1.0), Color("8b8f9c"), Vector3(0, 1.25, 0)))
			n.add_child(Mundo3D.caja(Vector3(1.95, 0.25, 1.05), Color("4b5060"), Vector3(0, 2.5, 0)))
			n.add_child(Mundo3D.caja(Vector3(1.95, 0.2, 1.05), Color("ef4444"), Vector3(0, 0.9, 0)))
			n.add_child(Mundo3D.caja(Vector3(1.95, 0.2, 1.05), Color("ef4444"), Vector3(0, 1.6, 0)))
		"viga":
			for lx in [-0.9, 0.9]:
				n.add_child(Mundo3D.caja(Vector3(0.18, 1.8, 0.18), Color("6b7280"), Vector3(lx, 0.9, 0)))
			for k in 4:
				n.add_child(Mundo3D.caja(Vector3(0.475, 0.55, 0.6), Color("f59e0b") if k % 2 == 0 else Color("1f2937"), Vector3(-0.7125 + k * 0.475, 1.55, 0)))
	return n


# ------------------------------------------------------------------ entrada
func _input(ev: InputEvent) -> void:
	if estado != "jugar":
		if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE and con_salir:
			salir.emit()
		return
	# mando (gamepad): cruceta o palanca para moverse, A salta, B/abajo se agacha
	if ev is InputEventJoypadButton and ev.pressed:
		match ev.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_cambiar_carril(-1)
			JOY_BUTTON_DPAD_RIGHT:
				_cambiar_carril(1)
			JOY_BUTTON_A, JOY_BUTTON_DPAD_UP:
				_saltar()
			JOY_BUTTON_B, JOY_BUTTON_DPAD_DOWN:
				_agachar()
		return
	if ev is InputEventJoypadMotion:
		var ax := ev as InputEventJoypadMotion
		var val := ax.axis_value
		if ax.axis == JOY_AXIS_LEFT_X:
			if absf(val) > 0.6 and absf(_joy_ult.x) <= 0.6:
				_cambiar_carril(1 if val > 0.0 else -1)
			_joy_ult.x = val
		elif ax.axis == JOY_AXIS_LEFT_Y:
			if absf(val) > 0.6 and absf(_joy_ult.y) <= 0.6:
				if val < 0.0:
					_saltar()
				else:
					_agachar()
			_joy_ult.y = val
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if int(reglas.get("jugadores", 1)) == 2:
			match ev.keycode:
				KEY_A:
					_cambiar_carril(-1)
				KEY_D:
					_cambiar_carril(1)
				KEY_W, KEY_SPACE:
					_saltar()
				KEY_S:
					_agachar()
				KEY_LEFT:
					carril2 = clampi(carril2 - 1, 0, 2)
				KEY_RIGHT:
					carril2 = clampi(carril2 + 1, 0, 2)
				KEY_UP:
					if py2 <= 0.01:
						vy2 = SALTO3 * _k_salto
						agachado2 = 0.0
						_sonido.tocar(560.0, 0.12)
				KEY_DOWN:
					agachado2 = 0.75
					if py2 > 0.01:
						vy2 = -20.0
		else:
			match ev.keycode:
				KEY_LEFT, KEY_A:
					_cambiar_carril(-1)
				KEY_RIGHT, KEY_D:
					_cambiar_carril(1)
				KEY_UP, KEY_W, KEY_SPACE:
					_saltar()
				KEY_DOWN, KEY_S:
					_agachar()
		match ev.keycode:
			KEY_ESCAPE:
				if con_salir:
					salir.emit()
				elif not OS.has_feature("web") and not OS.has_feature("android"):
					get_tree().quit()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		# deslizar el dedo (o el mouse) para moverse
		if ev.pressed:
			_toque_ini = ev.position
			_toque_activo = true
		elif _toque_activo:
			_toque_activo = false
			var d: Vector2 = ev.position - _toque_ini
			if d.length() > 30.0:
				if absf(d.x) > absf(d.y):
					_cambiar_carril(1 if d.x > 0 else -1)
				elif d.y < 0:
					_saltar()
				else:
					_agachar()


func _cambiar_carril(d: int) -> void:
	var n := clampi(carril + d, 0, 2)
	if n != carril:
		carril = n
		_sonido.tocar(420.0, 0.06)


func _saltar() -> void:
	if py <= 0.01:
		vy = SALTO3 * _k_salto
		agachado = 0.0
		_sonido.tocar(520.0, 0.12)


func _agachar() -> void:
	agachado = 0.75
	if py > 0.01:
		vy = -20.0


# ------------------------------------------------------------------ lógica
func _process(delta: float) -> void:
	_avanzar(delta)
	if _raiz and _mundo3:
		_sincronizar()
	_hud.queue_redraw()


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	if estado != "jugar":
		return
	inv = maxf(0.0, inv - dt)
	rapidez = minf(VEL_MAX * _vel_k, VEL0 * _vel_k + dist * 0.012 * _vel_k)
	dist += rapidez * dt
	if _amb:
		_amb.tick(dt, dist, px + _xo(dist))
		if _amb.sobrevivio:
			_amb.sobrevivio = false
			stats["perseguidor"] = 1
	px += ((carril - 1) * ANCHO_CARRIL - px) * minf(1.0, dt * 14.0)
	agachado = maxf(0.0, agachado - dt)
	if py > 0.0 or vy > 0.0:
		vy -= G3 * dt
		py += vy * dt
		if py <= 0.0:
			py = 0.0
			vy = 0.0
	if j2:
		px2 += ((carril2 - 1) * ANCHO_CARRIL - px2) * minf(1.0, dt * 14.0)
		agachado2 = maxf(0.0, agachado2 - dt)
		if py2 > 0.0 or vy2 > 0.0:
			vy2 -= G3 * dt
			py2 += vy2 * dt
			if py2 <= 0.0:
				py2 = 0.0
				vy2 = 0.0
	# cada jugador: [x, altura del salto, altura del cuerpo]
	var jugs: Array = [[px, py, 0.9 if agachado > 0.0 else 1.6]]
	if j2:
		jugs.append([px2, py2, 0.9 if agachado2 > 0.0 else 1.6])
	for o in obst:
		if o["golpeado"] or absf(o["z"] - dist) > 0.7:
			continue
		var choca := false
		for jg in jugs:
			if absf(jg[0] - (o["lane"] - 1) * ANCHO_CARRIL) > 0.95:
				continue
			match o["t"]:
				"valla":
					choca = choca or jg[1] < 0.85
				"pared":
					# con modelo propio, solo choca por debajo de su altura real (así se puede saltar una roca baja)
					var an := 99.0
					if o["nodo"] != null and (o["nodo"] as Node).has_meta("alto"):
						an = float((o["nodo"] as Node).get_meta("alto")) * 0.9
					choca = choca or jg[1] < an
				"viga":
					choca = choca or (jg[1] < 1.8 and jg[1] + jg[2] > 1.3)
		if choca:
			o["golpeado"] = true
			_herir()
	for p in premios:
		var ext := 3.0 if _iman_act() else 0.0
		if p["got"] or absf(p["z"] - dist) > 0.9 + ext:
			continue
		var cerca := false
		for jg in jugs:
			if absf(jg[0] - (p["lane"] - 1) * ANCHO_CARRIL) <= 1.0 + ext * 0.7 and jg[1] <= 2.4:
				cerca = true
		if not cerca:
			continue
		p["got"] = true
		recogidos += 1
		stats["recogidos"] += 1
		match str(p["t"]):
			"coin": stats["monedas"] += 1
			"gem": stats["gemas"] += 1
			"star": stats["estrellas"] += 1
		puntos += _vale(p["t"])
		_sonido.tocar(880.0 if p["t"] == "coin" else 1200.0, 0.1)
	if estado == "jugar" and dist >= fin_z:
		if _faltan() > 0:
			estado = "perdio"
			_sonido.tocar(150.0, 0.3, "sierra")
			_mostrar_fin("😕", "¡Casi! Faltaron premios", "Te faltaron %d premios para ganar" % _faltan())
		else:
			estado = "gano"
			_sonido.tocar(1000.0, 0.4, "triangulo")
			_mostrar_fin("🎉", "¡Llegaste a la meta!", "Puntos: %d · Recogiste %d de %d" % [puntos, recogidos, total])


## Vuelve a la carrera después de perder (lo paga el jugador con monedas, ver Partida).
func revivir() -> void:
	if _fin:
		_fin.queue_free()
		_fin = null
	estado = "jugar"
	vidas = 1
	inv = 3.0
	if _amb:
		_amb.acercamiento = 0.0


func _herir() -> void:
	if inv > 0.0 or estado != "jugar":
		return
	if _absorber():
		return
	vidas -= 1
	_sonido.tocar(150.0, 0.3, "sierra")
	for jid in Input.get_connected_joypads():
		Input.start_joy_vibration(jid, 0.5, 0.8, 0.25)
	if _amb and _amb.golpe() and vidas > 0:
		vidas = 0
	if vidas <= 0:
		estado = "perdio"
		_mostrar_fin("😵", "¡Ups! Se acabaron las vidas", "Recorriste %d de %d metros" % [int(dist), int(fin_z)])
	else:
		inv = _inv_golpe
		dist = maxf(0.0, dist - 0.0)
		rapidez = VEL0 * _vel_k


func _sincronizar() -> void:
	var cz := -dist
	var pm := (px + px2) / 2.0 if j2 else px
	var hx := _xo(dist)
	var hy := _yo(dist)
	var ax := _xo(dist + 9.0)
	var ay := _yo(dist + 9.0)
	_cam3.position = Vector3(pm * 0.6 + _xo(maxf(dist - 6.2, 0.0)), 3.5 + _yo(maxf(dist - 6.2, 0.0)), cz + 6.2)
	_cam3.look_at(Vector3(pm * 0.45 + ax, 1.2 + ay, cz - 9.0), Vector3.UP)
	_horizonte.position = Vector3(hx, hy, cz - 120.0)
	var bote := sin(t * 15.0) * 0.07 if py <= 0.01 and agachado <= 0.0 else 0.0
	var escala_y := 0.55 if agachado > 0.0 else 1.0
	if _s_jug is Sprite3D:
		_s_jug.position = Vector3(px + hx, hy + py + 0.72 * escala_y + 0.05 + bote, cz)
	else:
		_s_jug.position = Vector3(px + hx, hy + py + bote, cz)
		Assets3D.animar(_s_jug, t, 1.2 if py <= 0.01 else 0.4)
	_s_jug.scale = Vector3(1.0, escala_y, 1.0)
	_mascota_3d(_mundo3, Vector3(px + hx, hy + py, cz), Vector3(1.15 if px < 1.0 else -1.15, 0.0, 0.9))
	_s_jug.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1)
	if _s_jug2:
		var esc2 := 0.55 if agachado2 > 0.0 else 1.0
		var bote2 := sin(t * 15.0 + 1.0) * 0.07 if py2 <= 0.01 and agachado2 <= 0.0 else 0.0
		if _s_jug2 is Sprite3D:
			_s_jug2.position = Vector3(px2 + hx, hy + py2 + 0.72 * esc2 + 0.05 + bote2, cz)
		else:
			_s_jug2.position = Vector3(px2 + hx, hy + py2 + bote2, cz)
			Assets3D.animar(_s_jug2, t + 0.5, 1.2 if py2 <= 0.01 else 0.4)
		_s_jug2.scale = Vector3(1.0, esc2, 1.0)
		_s_jug2.visible = _s_jug.visible
	_sombra.position = Vector3(px + hx, hy + 0.02, cz)
	_sombra.scale = Vector3.ONE * clampf(1.0 - py * 0.18, 0.4, 1.0)
	for p in premios:
		var nodo: Node3D = p["nodo"]
		nodo.visible = not p["got"]
		nodo.position.y = 1.0 + _yo(p["z"]) + sin(t * 4.0 + p["z"]) * 0.1
		if p["t"] == "coin":
			nodo.rotation.y = t * 3.5


# ------------------------------------------------------------------ pantalla
func _dibujar_hud(ci: CanvasItem) -> void:
	_hud_extra(ci)
	var fuente := ThemeDB.fallback_font
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.45), 22), Rect2(12, 10, maxf(250.0, 126.0 + int(reglas["vidas"]) * 30.0), 40))
	Dibujo.emoji(ci, "⭐", Vector2(34, 30), 26.0)
	ci.draw_string(fuente, Vector2(52, 38), str(puntos), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	for i in maxi(0, vidas):
		Dibujo.emoji(ci, "❤", Vector2(130 + i * 30, 30), 26.0)
	# progreso hacia la meta
	var ancho := minf(420.0, size.x * 0.4)
	var x0 := (size.x - ancho) / 2.0
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.4), 10), Rect2(x0, size.y - 34, ancho, 16))
	var f := clampf(dist / maxf(1.0, fin_z), 0.0, 1.0)
	ci.draw_style_box(Estilo.caja(Estilo.VERDE, 10), Rect2(x0, size.y - 34, maxf(16.0, ancho * f), 16))
	Dibujo.emoji(ci, "🏁", Vector2(x0 + ancho + 14, size.y - 26), 26.0)
	if t < 5.0 and estado == "jugar":
		var txt := "← →  cambia de carril     ↑ salta     ↓ agáchate     (o desliza el dedo)"
		if int(reglas.get("jugadores", 1)) == 2:
			txt = "Jugador 1: A D W S          Jugador 2: ← → ↑ ↓"
		var w := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.5), 18), Rect2((size.x - w) / 2.0 - 16, 70, w + 32, 40))
		ci.draw_string(fuente, Vector2((size.x - w) / 2.0, 98), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
