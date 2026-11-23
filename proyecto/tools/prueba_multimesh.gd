extends Node
const J3 := preload("res://scripts/juego3d.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _cuenta(n: Node, tipo: String) -> int:
	var k := 1 if n.get_class() == tipo else 0
	for c in n.get_children():
		k += _cuenta(c, tipo)
	return k
func _ready() -> void:
	await get_tree().process_frame
	var j: Control = J3.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.nivel_corredor(), false, false)
	for i in 10: await get_tree().physics_frame
	var rep: Node = j._mundo3.get_node_or_null("ArbolesRepetidos")
	ok(rep != null, "los árboles del lateral van en MultiMesh")
	if rep != null:
		var mm: MultiMeshInstance3D = null
		for c in rep.get_children():
			if c is MultiMeshInstance3D:
				mm = c
				break
		ok(mm != null and mm.multimesh.instance_count >= 20, "una sola pieza dibuja muchos árboles (%d)" % (mm.multimesh.instance_count if mm else 0))
		ok(rep.get_child_count() <= 8, "pocas llamadas de dibujo (%d piezas)" % rep.get_child_count())
	print("FALLOS ", fallos)
	get_tree().quit()
