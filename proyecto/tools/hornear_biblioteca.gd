extends Node
# Fabrica las miniaturas (assets/biblioteca/*.png) de los modelos 3D de la biblioteca incluida.
# Ejecutar con pantalla: xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/hornear_biblioteca.tscn
const Importar := preload("res://scripts/importar.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const Hornear := preload("res://scripts/hornear.gd")
func _ready() -> void:
	var n := 0
	var mal := 0
	for a in Importar.biblioteca():
		var id := str(a["id"])
		if not id.begins_with("g:"):
			continue
		if FileAccess.file_exists("res://assets/biblioteca/" + id.substr(2) + ".png.bib"):
			continue
		var m := Importar.cargar_glb(id)
		if m == null:
			print("MAL no carga ", id)
			mal += 1
			continue
		var pers := str(a.get("cat", "")) in ["Personas", "Animales", "Monstruos", "Dinosaurios"]
		var nodo := Assets3D._normalizar(m, 1.7)
		var img: Image = await Hornear.foto(get_tree(), nodo, 384, -50.0 if pers else 30.0)
		var f := FileAccess.open("res://assets/biblioteca/" + id.substr(2) + ".png.bib", FileAccess.WRITE)
		f.store_buffer(Hornear.a_sprite(img, 128).save_png_to_buffer())
		f.close()
		n += 1
	print("miniaturas: ", n, " fallos: ", mal)
	get_tree().quit(0)
