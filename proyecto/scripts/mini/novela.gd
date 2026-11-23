extends "res://scripts/juego_mini.gd"
## Novela con diálogos: cada escena tiene un texto y opciones que llevan a otra escena.

var escenas := {}
var _orden: Array = []
var actual := ""


func _empezar() -> void:
	escenas = {}
	_orden = []
	for l in _lineas("guion"):
		var p: PackedStringArray = l.split("|")
		if p.size() < 2:
			continue
		var id: String = p[0].strip_edges()
		var ops: Array = []
		if p.size() >= 3:
			for o in p[2].split(";"):
				var q: PackedStringArray = o.split(">")
				if q.size() == 2:
					ops.append({"t": q[0].strip_edges(), "a": q[1].strip_edges()})
		escenas[id] = {"txt": p[1].strip_edges(), "ops": ops}
		_orden.append(id)
	actual = _orden[0] if _orden.size() > 0 else ""
	total = escenas.size()


func _ir(destino: String) -> void:
	if destino == "gana":
		_ganar("Terminaste la historia")
	elif destino == "pierde":
		_perder("Esa elección no salió bien")
	elif escenas.has(destino):
		actual = destino
		recogidos += 1
		puntos += 5
		_sonido.tocar(600.0, 0.06)
	else:
		_perder("Esa escena no existe: " + destino)


func _dibujar(ci: CanvasItem) -> void:
	if not escenas.has(actual):
		_txt(ci, "Escribe tu guion en el panel Contenido", Vector2(size.x / 2.0, size.y / 2.0), 28, Color.WHITE, 1)
		return
	var e: Dictionary = escenas[actual]
	Dibujo.emoji(ci, str(cfg.get("personaje", "🧙")), Vector2(size.x / 2.0, size.y * 0.2), minf(size.y * 0.28, 160.0))
	var caja := Rect2(30, size.y * 0.36, size.x - 60, size.y * 0.26)
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.6), 22), caja)
	_parrafo(ci, e["txt"], caja.position + Vector2(20, 38), caja.size.x - 40, 24)
	var ops: Array = e["ops"]
	if ops.is_empty():
		var i := _orden.find(actual)
		var sig: String = _orden[i + 1] if i + 1 < _orden.size() else "gana"
		_boton(ci, Rect2(size.x / 2.0 - 130, size.y * 0.7, 260, 58), "Continuar", Color("22c55e"), sig)
	else:
		for k in ops.size():
			_boton(ci, Rect2(40, size.y * 0.66 + k * 64, size.x - 80, 56), ops[k]["t"], Color("2563eb"), ops[k]["a"])


func _al_pulsar(id: Variant) -> void:
	_ir(str(id))
