extends "res://scripts/juego_carrera.gd"
## Carreras en 3D con cámara detrás del auto (como Mario Kart).
## Usa la misma pista que el editor (vista desde arriba) y la misma física que las carreras 2D.

const Mundo3D := preload("res://scripts/mundo3d.gd")

var _raiz: Node3D
var _cam3: Camera3D
var _cam_ang := 0.0
var _auto: Node3D
var _autos_riv: Array = []
var _monedas: Array = []
var _construido := false
var _alto := 0.0
var _vy := 0.0
var _turbo_ant := 0.0


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	var v := Mundo3D.visor(self)
	_raiz = v[1]
	_mundo.visible = false
	_raiz.add_child(Mundo3D.entorno(tema, str(nivel.get("fondo", ""))))
	_raiz.add_child(Mundo3D.sol())
	_cam3 = Camera3D.new()
	_cam3.fov = 78.0
	_cam3.far = 300.0
	_raiz.add_child(_cam3)
	_cam_ang = ang
	_construir()


func _suelo_tex(c1: Color, c2: Color) -> ImageTexture:
	var im := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	im.set_pixel(0, 0, c1)
	im.set_pixel(1, 1, c1)
	im.set_pixel(1, 0, c2)
	im.set_pixel(0, 1, c2)
	return ImageTexture.create_from_image(im)


func _plano(tam: Vector2, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tam
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	return mi


func _crear_auto(col: Color, piloto: String) -> Node3D:
	var a := Node3D.new()
	var cuerpo := Mundo3D.caja(Vector3(1.15, 0.28, 0.62), col, Vector3(0, 0.26, 0))
	a.add_child(cuerpo)
	a.add_child(Mundo3D.caja(Vector3(0.45, 0.2, 0.5), col.lightened(0.35), Vector3(-0.1, 0.46, 0)))
	a.add_child(Mundo3D.caja(Vector3(0.12, 0.34, 0.7), col.darkened(0.3), Vector3(-0.56, 0.42, 0)))   # alerón
	for sx in [-0.38, 0.38]:
		for sz in [-0.36, 0.36]:
			a.add_child(Mundo3D.caja(Vector3(0.3, 0.3, 0.14), Color(0.08, 0.08, 0.1), Vector3(sx, 0.15, sz)))
	var s := Mundo3D.sprite(piloto, 0.75)
	s.position = Vector3(0.0, 0.85, 0.0)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	a.add_child(s)
	return a


func _construir() -> void:
	if _construido:
		return
	_construido = true
	var cols := int(nivel["cols"])
	var filas := Datos.FILAS
	var pl: Array = tema["plat"]
	var c_a: Color = (tema["cerca"] as Color).lightened(0.1)
	var c_b: Color = (tema["cerca"] as Color).darkened(0.05)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _suelo_tex(c_a, c_b)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(cols / 2.0, filas / 2.0, 1.0)
	_raiz.add_child(_plano(Vector2(cols, filas), Vector3(cols / 2.0, 0.0, filas / 2.0), m))
	_raiz.add_child(_plano(Vector2(500, 500), Vector3(cols / 2.0, -0.05, filas / 2.0), Mundo3D.mat((tema["lejos"] as Color).darkened(0.2))))
	for p in items_plat:
		var w := float(p["w"])
		var h := float(p["h"])
		var muro := Mundo3D.caja(Vector3(w, 0.9, h), pl[0], Vector3(float(p["x"]) + w / 2.0, 0.45, float(p["y"]) + h / 2.0))
		_raiz.add_child(muro)
		_raiz.add_child(Mundo3D.caja(Vector3(w, 0.08, h), pl[1], Vector3(float(p["x"]) + w / 2.0, 0.93, float(p["y"]) + h / 2.0)))
	for c in _lin_meta:
		var par: bool = (c.x + c.y) % 2 == 0
		_raiz.add_child(Mundo3D.caja(Vector3(1, 0.02, 1), Color.WHITE if par else Color(0.1, 0.1, 0.12), Vector3(c.x + 0.5, 0.02, c.y + 0.5)))
	for r in resortes:
		var t1 := Mundo3D.caja(Vector3(0.9, 0.03, 0.9), Color(1.0, 0.65, 0.1), Vector3(float(r["x"]) + 0.5, 0.03, float(r["y"]) + 0.5))
		t1.material_override = Mundo3D.mat(Color(1.0, 0.65, 0.1), 1.2)
		_raiz.add_child(t1)
	for s in pinchos:
		var disco := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.4
		cm.bottom_radius = 0.4
		cm.height = 0.03
		disco.mesh = cm
		disco.material_override = Mundo3D.mat(Color(0.08, 0.08, 0.12))
		disco.position = Vector3(float(s["x"]) + 0.5, 0.03, float(s["y"]) + 0.5)
		_raiz.add_child(disco)
	_monedas = []
	for r in recogibles:
		var mo := Mundo3D.moneda()
		mo.position = Vector3(float(r["x"]) + 0.5, 0.5, float(r["y"]) + 0.5)
		mo.scale = Vector3.ONE * 0.7
		_raiz.add_child(mo)
		_monedas.append({"n": mo, "r": r})
	_auto = _crear_auto(Color("ff6b3d"), str(nivel["hero"]))
	_raiz.add_child(_auto)
	_autos_riv = []
	for r in rivales:
		var a := _crear_auto(r["col"], str(r["e"]))
		_raiz.add_child(a)
		_autos_riv.append(a)


func _process(delta: float) -> void:
	super._process(delta)
	if _auto == null:
		return
	var c := _centro() / float(T)
	# saltito al pisar un turbo
	if _turbo > 1.1 and _turbo_ant < 0.6 and _alto <= 0.001:
		_vy = 3.4
	_turbo_ant = _turbo
	if _alto > 0.0 or _vy > 0.0:
		_vy -= 11.0 * delta
		_alto = maxf(0.0, _alto + _vy * delta)
		if _alto == 0.0:
			_vy = 0.0
	_auto.position = Vector3(c.x, _alto, c.y)
	_auto.rotation = Vector3(0.0, -ang, 0.0)
	_auto.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1)
	for i in _autos_riv.size():
		var r: Dictionary = rivales[i]
		var p: Vector2 = r["p"] / float(T)
		_autos_riv[i].position = Vector3(p.x, 0.0, p.y)
		_autos_riv[i].rotation = Vector3(0.0, -float(r["ang"]), 0.0)
	for mo in _monedas:
		mo["n"].visible = not mo["r"]["got"]
		mo["n"].rotation.y += delta * 3.0
	_cam_ang = lerp_angle(_cam_ang, ang, minf(1.0, delta * 4.5))
	var dir := Vector3(cos(_cam_ang), 0.0, sin(_cam_ang))
	var atras := 2.7 + clampf(vl.length() / 500.0, 0.0, 0.9)
	var pos_cam := Vector3(c.x, 0.0, c.y) - dir * atras + Vector3(0, 1.45, 0)
	_cam3.look_at_from_position(pos_cam, Vector3(c.x, 0.25, c.y) + dir * 2.4, Vector3.UP)
	_cam3.fov = 78.0 + (10.0 if _turbo > 0.0 else 0.0)
