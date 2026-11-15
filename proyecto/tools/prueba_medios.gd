extends Node
const Imp := preload("res://scripts/importar.gd")
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var ids := []
	for f in ["atardecer.png", "musica_test.wav", "musica_test.ogg", "musica_test.mp3"]:
		var r: String = "/tmp/med/" + f
		if FileAccess.file_exists(r):
			var id: String = Imp.importar_archivo(r)
			ids.append(id)
			ok(id != "", "importar " + f + " -> " + id)
	for id in ids:
		if Imp.es_audio(id):
			var st := Imp.cargar_audio(id)
			ok(st != null, "cargar audio " + id + " " + (st.get_class() if st else ""))
			ok(st != null and st.get_length() > 1.5, "duración %.2f" % (st.get_length() if st else 0.0))
	var img: String = ids[0]
	for modo in ["2d", "25d", "3d"]:
		var n: Dictionary = Datos.nivel_inicial() if modo != "3d" else Datos.nivel_aventura()
		n["modo"] = modo
		n["fondo"] = img
		Datos.establecer(Datos.normalizar(n))
		Datos.reglas["musica"] = ids[1]
		var pa: Control = Partida.new()
		add_child(pa)
		pa.size = Vector2(1280, 720)
		pa.iniciar(Datos.proyecto(), 0, false, false, false)
		await get_tree().create_timer(0.8).timeout
		ok(pa._musica != null and pa._musica.playing, modo + ": música sonando")
		get_viewport().get_texture().get_image().save_png("/tmp/med/fondo_%s.png" % modo)
		pa.queue_free()
		await get_tree().process_frame
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
