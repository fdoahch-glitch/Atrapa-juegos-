extends Node
## Sonidos simples generados por código (no hace falta ningún archivo de audio).

var silencio := false
var _cache := {}
var _jugadores: Array[AudioStreamPlayer] = []
var _siguiente := 0


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_jugadores.append(p)


func _crear(frec: float, dur: float, tipo: String) -> AudioStreamWAV:
	var tasa := 22050
	var n := int(tasa * dur)
	var datos := PackedByteArray()
	datos.resize(n * 2)
	for i in n:
		var fase := fmod(float(i) / tasa * frec, 1.0)
		var v := 0.0
		match tipo:
			"cuadrada":
				v = 1.0 if fase < 0.5 else -1.0
			"triangulo":
				v = 4.0 * absf(fase - 0.5) - 1.0
			"sierra":
				v = 2.0 * fase - 1.0
			_:
				v = sin(TAU * fase)
		var env := 1.0 - float(i) / n
		datos.encode_s16(i * 2, int(clampf(v * env * 0.22, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = tasa
	w.data = datos
	return w


func tocar(frec: float, dur: float = 0.12, tipo: String = "cuadrada") -> void:
	if silencio or _jugadores.is_empty():
		return
	var clave := "%s_%s_%s" % [frec, dur, tipo]
	if not _cache.has(clave):
		_cache[clave] = _crear(frec, dur, tipo)
	var p := _jugadores[_siguiente]
	_siguiente = (_siguiente + 1) % _jugadores.size()
	p.stream = _cache[clave]
	p.play()
