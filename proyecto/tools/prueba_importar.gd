extends Node
const Imp := preload("res://scripts/importar.gd")
func _ready() -> void:
	var fallos := 0
	var id := Imp.importar_archivo("/tmp/glb/cubo rosa.glb")
	print("id: ", id)
	if id != "g:cubo_rosa.glb": fallos += 1
	var m := Imp.modelo(id, 2.0)
	await Imp.hacer_miniatura(get_tree(), id)
	var ok := FileAccess.file_exists(Imp.ruta_dibujo(id))
	print("miniatura: ", ok)
	if not ok: fallos += 1
	print("lista: ", Imp.listar())
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
