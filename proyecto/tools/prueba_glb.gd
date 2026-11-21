extends Node
const Importar := preload("res://scripts/importar.gd")
func _ready() -> void:
	for id in ["g:Cow.glb", "g:Banana.glb", "g:Pizza.glb", "g:K_tree.glb"]:
		var m := Importar.cargar_glb(id)
		print(id, " ", m)
		if m:
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				var x := mi as MeshInstance3D
				print("  ", x.name, " aabb=", x.get_aabb(), " scale=", x.scale, " gt=", x.global_transform.basis.get_scale(), " skin=", x.skin != null)
			print("  raiz scale ", m.scale, " hijos ", m.get_children())
	get_tree().quit(0)
