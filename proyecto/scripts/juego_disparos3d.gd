extends "res://scripts/juego_aventura.gd"
## Disparos 3D: la aventura 3D donde disparas hacia donde miras (Espacio al saltar, F o J para disparar,
## o toca la zona de arriba a la derecha). La tecla C cambia entre cámara en tercera y primera persona.

const VEL_BALA3 := 22.0
const ALCANCE3 := 24.0

var balas3: Array = []   # {p: Vector3, d: Vector3, r: float, nodo}
var _enfria3 := 0.0
var primera := false


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	primera = str(nivel.get("camara", "tercera")) == "primera"


func resetear() -> void:
	super.resetear()
	for b in balas3:
		if is_instance_valid(b["nodo"]):
			b["nodo"].queue_free()
	balas3 = []
	_enfria3 = 0.0


func _input(ev: InputEvent) -> void:
	super._input(ev)
	if estado != "jugar":
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_F, KEY_J]:
			disparar()
		elif ev.keycode == KEY_C:
			primera = not primera
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position - global_position
		if p.x > size.x * 0.62 and p.y < size.y * 0.45:
			disparar()


func disparar() -> void:
	if _enfria3 > 0.0 or _mundo3 == null:
		return
	_enfria3 = 0.3
	var d := Vector3(sin(giro), 0.0, cos(giro))
	var nodo := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	nodo.mesh = sm
	nodo.material_override = Mundo3D.mat(Color("fde047"), 0.0, true)
	_mundo3.add_child(nodo)
	var origen := Vector3(p3.x, p3.y + 0.9, p3.z) + d * 0.6
	nodo.position = origen
	balas3.append({"p": origen, "d": d, "r": 0.0, "nodo": nodo})
	_sonido.tocar(620.0, 0.06, "cuadrada")


func _actualizar(dt: float) -> void:
	super._actualizar(dt)
	_enfria3 = maxf(0.0, _enfria3 - dt)
	var vivas: Array = []
	for b in balas3:
		b["p"] += b["d"] * VEL_BALA3 * dt
		b["r"] += VEL_BALA3 * dt
		var fin: bool = b["r"] > ALCANCE3 or _choca(b["p"].x, b["p"].z)
		if not fin:
			for e in bichos:
				if not e["muerto"] and Vector2(b["p"].x, b["p"].z).distance_to(Vector2(e["x"], e["z"])) < 0.9:
					e["muerto"] = true
					puntos += _vale("enemy") + 3
					_sonido.tocar(300.0, 0.15)
					fin = true
					break
		if fin:
			if is_instance_valid(b["nodo"]):
				b["nodo"].queue_free()
		else:
			b["nodo"].position = b["p"]
			vivas.append(b)
	balas3 = vivas


func _sincronizar() -> void:
	super._sincronizar()
	if primera and _cam3 != null and _jug != null:
		var d := Vector3(sin(giro), 0.0, cos(giro))
		_cam3.position = Vector3(p3.x, p3.y + 1.6, p3.z) - d * 0.15
		_cam3.look_at(_cam3.position + d * 8.0 + Vector3(0, -0.1, 0), Vector3.UP)
		_jug.visible = false


func _dibujar_hud(ci: CanvasItem) -> void:
	super._dibujar_hud(ci)
	var f := ThemeDB.fallback_font
	ci.draw_string(f, Vector2(size.x / 2.0 - 190.0, size.y - 18.0), "F o J: disparar · C: cámara %s" % ("tercera" if primera else "primera"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.85))
	if primera:
		ci.draw_circle(size / 2.0, 4.0, Color(1, 1, 1, 0.8))
