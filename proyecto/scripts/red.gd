extends Node
## Multijugador en línea con ENet (el sistema de red de Godot). Una persona crea
## la sala y las demás se unen con su dirección. Cada jugador manda su posición
## unas 20 veces por segundo y ve a los demás como "fantasmas" de colores.

signal alguien_entro(id: int)
signal alguien_salio(id: int)

const PUERTO := 24680
const COLORES := [Color("ff6b6b"), Color("4dabf7"), Color("ffd43b"), Color("69db7c")]

var mp := SceneMultiplayer.new()
var peer := ENetMultiplayerPeer.new()
var modo := ""          # "crear" | "unirse"
var remotos: Dictionary = {}
var _envio := 0.0


func crear(puerto: int = PUERTO) -> int:
	modo = "crear"
	var e := peer.create_server(puerto, 3)
	if e == OK:
		_listo()
	return e


func unirse(ip: String, puerto: int = PUERTO) -> int:
	modo = "unirse"
	var e := peer.create_client(ip, puerto)
	if e == OK:
		_listo()
	return e


func _listo() -> void:
	mp.root_path = get_path()
	mp.multiplayer_peer = peer
	mp.peer_connected.connect(func(id: int): alguien_entro.emit(id))
	mp.peer_disconnected.connect(func(id: int):
		remotos.erase(id)
		alguien_salio.emit(id))
	mp.peer_packet.connect(_llego)


func conectados() -> int:
	return mp.get_peers().size()


func mi_id() -> int:
	return mp.get_unique_id()


func cerrar() -> void:
	peer.close()
	remotos.clear()


## Manda el estado propio a todos (sin garantía de entrega: lo siguiente lo reemplaza).
func enviar(estado: Dictionary) -> void:
	if mp.multiplayer_peer == null or conectados() == 0:
		return
	mp.send_bytes(var_to_bytes(estado), 0, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, 0)


func _llego(id: int, datos: PackedByteArray) -> void:
	if datos.size() > 512:
		return
	var d = bytes_to_var(datos)
	if not (d is Dictionary):
		return
	var x = d.get("x", 0.0)
	var y = d.get("y", 0.0)
	if not ((x is float or x is int) and (y is float or y is int)):
		return
	remotos[id] = {"x": float(x), "y": float(y), "c": float(d.get("c", 1.0)), "n": int(d.get("n", 0)), "t": Time.get_ticks_msec()}


func _process(dt: float) -> void:
	if mp.multiplayer_peer != null:
		mp.poll()
	_envio += dt


func toca_enviar() -> bool:
	if _envio >= 0.05:
		_envio = 0.0
		return true
	return false


func dibujar(ci: CanvasItem, T: float, nivel_idx: int) -> void:
	var k := 0
	for id in remotos:
		var r: Dictionary = remotos[id]
		if int(r["n"]) != nivel_idx:
			continue
		var c: Color = COLORES[k % COLORES.size()]
		k += 1
		c.a = 0.75
		var p := Vector2(r["x"], r["y"])
		ci.draw_rect(Rect2(p, Vector2(0.62, 0.88) * T), c, true)
		ci.draw_circle(p + Vector2(0.31, 0.2) * T, T * 0.22, c.lightened(0.3))
		ci.draw_rect(Rect2(p + Vector2(0.31 + 0.12 * float(r["c"]), 0.12) * T, Vector2(5, 5)), Color.WHITE, true)
