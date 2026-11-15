extends Node
func _ready() -> void:
	var n: Dictionary = Datos.nivel_arriba()
	n["fondo"] = "u:atardecer.png"
	n["disp"] = "pc"
	Datos.establecer(Datos.normalizar(n))
	Datos.agregar_nivel(true)
	Datos.reglas["tiempo"] = 90
	Datos.reglas["musica"] = "m:musica_test.wav"
	FileAccess.open("/tmp/jt/nivel.json", FileAccess.WRITE).store_string(Datos.a_json())
	get_tree().quit()
