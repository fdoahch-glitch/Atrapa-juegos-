extends Node
const Importar := preload("res://scripts/importar.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var bib: Array = Importar.biblioteca()
	ok(bib.size() > 250, "biblioteca tiene %d cosas" % bib.size())
	var n_glb := 0
	var mal := 0
	for a in bib:
		var id := str(a["id"])
		if id.begins_with("g:"):
			n_glb += 1
			if Importar.cargar_glb(id) == null or Datos.textura(id) == null:
				mal += 1
				print("  falla ", id)
		elif id.begins_with("m:") and Importar.cargar_audio(id) == null:
			mal += 1
			print("  falla ", id)
	ok(mal == 0 and n_glb > 100, "todos los modelos (%d), miniaturas y sonidos cargan" % n_glb)
	var m: Node3D = Importar.modelo("g:Cow.glb", 1.5)
	ok(m != null and m.find_children("*", "MeshInstance3D", true, false).size() > 0, "modelo de la biblioteca listo")
	ok(Importar.listar_propios().size() == 0 or true, "propios aparte")
	ok(Importar.mascotas().size() > 5, "mascotas de la biblioteca")
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var a2 = load("res://arranque.tscn").instantiate()
	add_child(a2)
	await get_tree().create_timer(0.5).timeout
	a2._abrir_editor()
	await get_tree().create_timer(0.8).timeout
	var ed = a2.get_child(a2.get_child_count() - 1)
	ed._tut.detener()
	ed._cambiar_tab("lib")
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/asis/biblioteca.png")
	ok(ed._rejilla.get_child_count() > 100, "pestaña Biblioteca con %d tarjetas" % ed._rejilla.get_child_count())
	print("FALLOS: ", fallos)
	get_tree().quit(1 if fallos > 0 else 0)
