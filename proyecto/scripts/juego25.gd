extends "res://scripts/juego.gd"
## Modo 2.5D: las mismas reglas de plataformas 2D, pero el mundo se ve en 3D
## (bloques con profundidad, cámara en perspectiva, fondos que se mueven distinto).

const Mundo3D := preload("res://scripts/mundo3d.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const PROF := 2.0
const FOV := 40.0

var _raiz: Node3D
var _mundo3: Node3D
var _cam3: Camera3D
var _s_jug: Node3D
var _n_enem: Array = []      # [nodo, enemigo]
var _n_rec: Array = []       # [nodo, item, tipo]
var _n_res: Array = []       # [tapa, item]


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	var v := Mundo3D.visor(self)
	_raiz = v[1]
	_raiz.add_child(Mundo3D.entorno(tema, str(nivel.get("fondo", ""))))
	_raiz.add_child(Mundo3D.sol())
	_cam3 = Camera3D.new()
	_cam3.fov = FOV
	_raiz.add_child(_cam3)
	_reconstruir()


func resetear() -> void:
	super.resetear()
	if _raiz:
		_reconstruir()


func _draw() -> void:
	pass


func _dibujar_mundo(_ci: CanvasItem) -> void:
	pass


func _y3(py_celdas: float) -> float:
	return float(Datos.FILAS) - py_celdas


func _reconstruir() -> void:
	if _mundo3:
		_mundo3.queue_free()
	_m3 = null
	_mundo3 = Node3D.new()
	_raiz.add_child(_mundo3)
	_n_enem = []
	_n_rec = []
	_n_res = []
	var cols := float(nivel["cols"])
	var pl: Array = tema["plat"]
	# fondo lejano
	_mundo3.add_child(Mundo3D.colinas(tema["lejos"], -16.0, 4.5, 2.4, 9.0, -70.0, cols + 70.0))
	_mundo3.add_child(Mundo3D.colinas(tema["cerca"], -8.0, 2.6, 1.5, 6.0, -50.0, cols + 50.0, 20.0))
	for p in items_plat:
		var w := float(p["w"])
		var h := float(p["h"])
		var cx := float(p["x"]) + w / 2.0
		var cy := _y3(float(p["y"]) + h / 2.0)
		_mundo3.add_child(Mundo3D.caja(Vector3(w, h, PROF), pl[0], Vector3(cx, cy, 0)))
		_mundo3.add_child(Mundo3D.caja(Vector3(w + 0.04, 0.3, PROF + 0.04), pl[1], Vector3(cx, _y3(float(p["y"])) - 0.15, 0)))
	var i := 0
	for d in decos:
		var px: float = float(d.get("s", 56))
		var e := str(d["e"])
		var nube := Datos.es_nube(e)
		var z := -9.0 if nube else -1.6 - float(i % 3) * 0.9
		var xx := float(d["x"]) + 0.5
		if Mundo3D.es_modelo(e):
			Datos.pal_item = str(d.get("pal", ""))
			var mo := Mundo3D.objeto(e, px / T, px)
			Datos.pal_item = ""
			var base := _y3(float(d["y"]) + 1.0) - 0.05
			if nube:
				base = _y3(float(d["y"]) + 0.5) - 0.3
				mo.scale = Vector3.ONE * 2.2
			mo.position = Vector3(xx, base, z)
			mo.rotation_degrees.y = float(i % 3 - 1) * 20.0
			_mundo3.add_child(mo)
		else:
			var sz: float = px / T * 1.1
			var sp := Mundo3D.sprite(e, sz)
			var yy := _y3(float(d["y"]) + 0.5) if nube else _y3(float(d["y"]) + 1.0) + sz / 2.0 - 0.05
			sp.position = Vector3(xx, yy, z)
			if nube:
				sp.scale = Vector3.ONE * 2.2
			_mundo3.add_child(sp)
		i += 1
	for s in pinchos:
		for k in 3:
			var c := Mundo3D.cono(0.16, 0.55, Color("d4d8e0"))
			c.position = Vector3(float(s["x"]) + (k + 0.5) / 3.0, _y3(float(s["y"]) + 1.0) + 0.275, 0)
			_mundo3.add_child(c)
	for r in resortes:
		var base := Mundo3D.caja(Vector3(0.7, 0.2, 0.7), Color("6b7280"), Vector3(float(r["x"]) + 0.5, _y3(float(r["y"]) + 1.0) + 0.1, 0))
		_mundo3.add_child(base)
		var tapa := Mundo3D.caja(Vector3(0.85, 0.22, 0.85), Color("ef4444"), Vector3.ZERO)
		_mundo3.add_child(tapa)
		_n_res.append([tapa, r])
	for c in recogibles:
		var nodo: Node3D
		if c["t"] == "coin":
			nodo = Mundo3D.moneda()
		else:
			nodo = Mundo3D.sprite("⭐" if c["t"] == "star" else "💎", 0.85)
		nodo.position = Vector3(float(c["x"]) + 0.5, _y3(float(c["y"]) + 0.5), 0)
		_mundo3.add_child(nodo)
		_n_rec.append([nodo, c])
	if meta != null:
		var mp := Mundo3D.caja(Vector3(0.1, 2.0, 0.1), Color("e5e7eb"), Vector3(float(meta["x"]) + 0.15, _y3(float(meta["y"]) + 1.0) + 1.0, 0))
		_mundo3.add_child(mp)
		var bandera := Mundo3D.sprite("🏁", 1.2)
		bandera.position = Vector3(float(meta["x"]) + 0.7, _y3(float(meta["y"]) + 1.0) + 1.6, 0)
		_mundo3.add_child(bandera)
	for e in enemigos:
		var se := Mundo3D.objeto(str(e["it"]["e"]), 0.95)
		_mundo3.add_child(se)
		_n_enem.append([se, e])
	_s_jug = Mundo3D.objeto(str(nivel["hero"]), 1.0)
	_s_jug.position.z = 0.3
	_mundo3.add_child(_s_jug)


func _process(delta: float) -> void:
	super._process(delta)
	if _raiz == null or _mundo3 == null:
		return
	# cámara: sigue al héroe, mirando un poco desde arriba
	var vista := size.x / escala
	var cx := (cam + vista / 2.0) / T
	var d := (float(Datos.FILAS) / 2.0) / tan(deg_to_rad(FOV / 2.0))
	_cam3.position = Vector3(cx, 8.2, d)
	_cam3.look_at(Vector3(cx, 6.2, 0.0), Vector3.UP)
	# héroe
	var cx_h := (pos.x + PW * T / 2.0) / T
	if _s_jug is Sprite3D:
		_s_jug.position.x = cx_h
		_s_jug.position.y = _y3((pos.y + PH * T / 2.0) / T)
		(_s_jug as Sprite3D).flip_h = cara < 0.0
	else:
		_s_jug.position.x = cx_h
		_s_jug.position.y = _y3((pos.y + PH * T) / T)
		_s_jug.rotation_degrees.y = lerpf(_s_jug.rotation_degrees.y, 65.0 if cara >= 0.0 else -65.0, 0.3)
		var fuerza := clampf(absf(vel.x) / MOVER, 0.0, 1.0) if suelo else 0.5
		Assets3D.animar(_s_jug, t, fuerza)
	_mascota_3d(_mundo3, _s_jug.position, Vector3(-0.9 * cara, 0.0, 0.25))
	_s_jug.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1)
	for par in _n_rec:
		var nodo: Node3D = par[0]
		var c: Dictionary = par[1]
		nodo.visible = not c["got"]
		nodo.position.y = _y3(float(c["y"]) + 0.5) + sin(t * 4.0 + float(c["x"])) * 0.08
		if c["t"] == "coin":
			nodo.rotation.y = t * 3.0
	for par in _n_enem:
		var se: Node3D = par[0]
		var e: Dictionary = par[1]
		se.visible = not e["muerto"] or e["sqt"] < 0.5
		var dy := sin(t * 3.0 + float(e["x0"])) * 0.15 if e["it"].get("fly", false) else 0.0
		var cy := _y3(float(e["it"]["y"]) + 0.5) + dy - (0.2 if e["muerto"] else 0.0)
		if se is Sprite3D:
			se.position = Vector3(float(e["x"]) + 0.5, cy, 0)
			(se as Sprite3D).flip_h = e["dir"] >= 0.0
		else:
			se.position = Vector3(float(e["x"]) + 0.5, _y3(float(e["it"]["y"]) + 1.0) + dy - (0.1 if e["muerto"] else 0.0), 0)
			se.rotation_degrees.y = lerpf(se.rotation_degrees.y, 65.0 if e["dir"] >= 0.0 else -65.0, 0.3)
			Assets3D.animar(se, t, 0.0 if e["muerto"] else 0.8)
		se.scale = Vector3(1.2, 0.4, 1.2) if e["muerto"] else Vector3.ONE
	for par in _n_res:
		var tapa: Node3D = par[0]
		var r: Dictionary = par[1]
		tapa.position = Vector3(float(r["x"]) + 0.5, _y3(float(r["y"]) + 1.0) + 0.45 - float(r["sq"]) * 0.25, 0)
