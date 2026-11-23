extends "res://scripts/juego_arriba.gd"
## Disparos desde arriba: caminas con flechas/WASD y disparas con ESPACIO, con J o tocando
## (o con clic) hacia donde quieres. Cada enemigo que tocas con una bala suma puntos.

const VEL_BALA := 520.0
const PUNTOS_ENEMIGO := 50
# espera entre disparos, balas por disparo, abanico (grados), alcance, velocidad, color
const ARMAS := {
	"pistola": {"espera": 0.24, "n": 1, "abre": 0.0, "alcance": 640.0, "vel": 520.0},
	"rafaga": {"espera": 0.08, "n": 1, "abre": 6.0, "alcance": 560.0, "vel": 600.0},
	"escopeta": {"espera": 0.7, "n": 5, "abre": 30.0, "alcance": 320.0, "vel": 480.0},
	"rifle": {"espera": 0.5, "n": 1, "abre": 0.0, "alcance": 1100.0, "vel": 900.0},
}
var _arma: Dictionary = ARMAS["pistola"]

var balas: Array = []
var _apunta := Vector2(1, 0)
var _enfria := 0.0
var _clic_dir := Vector2.ZERO


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	super.iniciar(n, forzar_tactil, mostrar_salir)
	_arma = ARMAS.get(str(reglas.get("arma", "pistola")), ARMAS["pistola"])


func resetear() -> void:
	super.resetear()
	balas = []
	_enfria = 0.0


func _input(ev: InputEvent) -> void:
	super._input(ev)
	if estado != "jugar":
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_SPACE, KEY_J]:
		_disparar(_apunta)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position - global_position
		if not tactil or p.x >= size.x * 0.6:
			var desde := (_centro() - Vector2(cam, 0.0)) * escala
			var d: Vector2 = p - desde
			if d.length() > 8.0:
				_disparar(d.normalized())


func _disparar(dir: Vector2) -> void:
	if _enfria > 0.0:
		return
	_enfria = float(_arma["espera"])
	var k := int(_arma["n"])
	for i in k:
		var ang := 0.0 if k == 1 else deg_to_rad((float(i) / float(k - 1) - 0.5) * float(_arma["abre"]))
		if k == 1 and float(_arma["abre"]) > 0.0:
			ang = deg_to_rad(randf_range(-0.5, 0.5) * float(_arma["abre"]))
		balas.append({"p": _centro(), "d": dir.normalized().rotated(ang), "r": 0.0})
	_sonido.tocar(620.0, 0.06, "cuadrada")


func _actualizar(dt: float) -> void:
	var d := _dir_entrada()
	if d.length() > 0.2:
		_apunta = d.normalized()
	_enfria = maxf(0.0, _enfria - dt)
	super._actualizar(dt)
	if estado != "jugar":
		return
	var vivas: Array = []
	for b in balas:
		b["p"] += b["d"] * float(_arma["vel"]) * dt
		b["r"] += float(_arma["vel"]) * dt
		var impacto: bool = b["r"] > float(_arma["alcance"])
		var pc: Rect2 = Rect2(b["p"] - Vector2(6, 6), Vector2(12, 12))
		for w in plats:
			if pc.intersects(w):
				impacto = true
		if not impacto:
			for e in enemigos.duplicate():
				if pc.intersects(Rect2(e["x"] * T + 6, e["y"] * T + 6, T - 12, T - 12)):
					enemigos.erase(e)
					puntos += PUNTOS_ENEMIGO
					_sonido.tocar(300.0, 0.15, "sierra")
					impacto = true
					break
		if not impacto:
			vivas.append(b)
	balas = vivas


func _dibujar_mundo(ci: CanvasItem) -> void:
	super._dibujar_mundo(ci)
	for b in balas:
		ci.draw_circle(b["p"], 7.0, Color(1.0, 0.85, 0.2))
		ci.draw_circle(b["p"], 4.0, Color.WHITE)


func _dibujar_hud(ci: CanvasItem) -> void:
	super._dibujar_hud(ci)
	if t < 8.0 and estado == "jugar" and not tactil:
		var f := ThemeDB.fallback_font
		ci.draw_string(f, Vector2(size.x / 2.0 - 150.0, 130), "Espacio o clic para disparar", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9))
