extends "res://scripts/juego_mini.gd"
## Penales: toca la portería para patear; el portero intenta atajar.

var tiros_hechos := 0
var goles := 0
var _vuelo := -1.0
var _destino := Vector2.ZERO
var _msg_s := ""
var _msg_ts := 0.0
var _pausa := 0.0


func _empezar() -> void:
	tiros_hechos = 0
	goles = 0
	_vuelo = -1.0
	_msg_s = ""
	_msg_ts = 0.0
	_pausa = 0.0


func _porteria() -> Rect2:
	var w := minf(size.x * 0.6, 560.0)
	return Rect2((size.x - w) / 2.0, 100.0, w, size.y * 0.3)


func _portero_x() -> float:
	var p := _porteria()
	return p.get_center().x + sin(t * 2.2 * _num("portero", 1.0)) * p.size.x * 0.38


func _balon_ini() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.84)


func _paso(dt: float) -> void:
	_msg_ts = maxf(0.0, _msg_ts - dt)
	if _pausa > 0.0:
		_pausa -= dt
		if _pausa <= 0.0 and tiros_hechos >= int(cfg.get("tiros", 5)):
			if goles >= int(cfg.get("meta", 3)):
				_ganar("%d goles de %d tiros" % [goles, tiros_hechos])
			else:
				_perder("Hiciste %d goles y necesitabas %d" % [goles, int(cfg.get("meta", 3))])
		return
	if _vuelo >= 0.0:
		_vuelo += dt / 0.55
		if _vuelo >= 1.0:
			_vuelo = -1.0
			tiros_hechos += 1
			var p := _porteria()
			var dentro := p.grow(6.0).has_point(_destino)
			if not dentro:
				_msg_s = "¡Afuera!"
			elif absf(_destino.x - _portero_x()) < 62.0 and _destino.y > p.position.y + p.size.y * 0.15:
				_msg_s = "¡Atajó el portero!"
			else:
				_msg_s = "¡GOOOL!"
				goles += 1
				puntos += 20
				_sonido.tocar(1000.0, 0.3, "triangulo")
			_msg_ts = 1.2
			_pausa = 1.2


func _dibujar(ci: CanvasItem) -> void:
	var p := _porteria()
	ci.draw_rect(Rect2(0, size.y * 0.42, size.x, size.y), Color("2f9e44"))
	ci.draw_rect(p, Color(1, 1, 1, 0.18))
	ci.draw_rect(p, Color.WHITE, false, 6.0)
	Dibujo.emoji(ci, "🧤", Vector2(_portero_x(), p.position.y + p.size.y * 0.62), 92.0)
	var b := _balon_ini()
	var s := 76.0
	if _vuelo >= 0.0:
		b = _balon_ini().lerp(_destino, _vuelo)
		s = lerpf(76.0, 36.0, _vuelo)
	Dibujo.emoji(ci, str(cfg.get("pelota", "⚽")), b, s)
	_txt(ci, "Goles %d  ·  Tiro %d de %d" % [goles, mini_tiro(), int(cfg.get("tiros", 5))], Vector2(20, 36), 26)
	_txt(ci, "Necesitas %d goles" % int(cfg.get("meta", 3)), Vector2(20, 68), 20)
	if _msg_ts > 0.0:
		_txt(ci, _msg_s, Vector2(size.x / 2.0, size.y * 0.55), 52, Color("fde047"), 1)
	elif tiros_hechos == 0 and _vuelo < 0.0:
		_txt(ci, "Toca la portería para patear", Vector2(size.x / 2.0, size.y * 0.6), 28, Color.WHITE, 1)


func mini_tiro() -> int:
	return mini(tiros_hechos + 1, int(cfg.get("tiros", 5)))


func _al_suelo(pos: Vector2) -> void:
	if _vuelo >= 0.0 or _pausa > 0.0:
		return
	if pos.y > size.y * 0.7:
		return
	_destino = pos
	_vuelo = 0.0
	_sonido.tocar(300.0, 0.08)
