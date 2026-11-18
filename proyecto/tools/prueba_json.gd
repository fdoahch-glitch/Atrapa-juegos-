extends Node
func _ready() -> void:
	var casos := ['{"items":[{"t":"plat","x":null,"y":3,"w":2,"h":1}]}', '{"modo":"3d","items":[{"t":"coin","x":2,"y":3}]}', '{"items":[{"t":"deco","x":2,"y":3},{"t":"enemy","x":4,"y":5}]}', '{"items":[{"t":"plat","x":2,"y":3,"w":0,"h":-4}]}']
	for c in casos:
		var n: Dictionary = Datos.normalizar(JSON.parse_string(c))
		print(n["theme"], " ", n["items"])
	get_tree().quit()
