extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var n := Datos.normalizar(Datos.nivel_mini("educativo"))
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"categoria": "educativo"})})
	var e: Control = load("res://scripts/editor.gd").new()
	add_child(e)
	e.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.6).timeout
	ok(e._mini_ed.visible and not e._esc.visible, "minijuego muestra panel Contenido")
	ok(e._mini_ed.get_child_count() > 0, "panel construido")
	# editar texto de preguntas
	Datos.nivel["mini_cfg"]["preguntas"] = "¿1+1? | 1 ; 2 | 2"
	Datos.confirmar()
	ok(str(Datos.nivel["mini_cfg"]["preguntas"]).begins_with("¿1+1"), "contenido editable")
	e._abrir_guia()
	await get_tree().create_timer(0.2).timeout
	ok(e._modal != null, "guía abre para minijuego")
	e._cerrar_modal()
	e._ir_paso("contenido")
	ok(e._mini_ed.visible, "paso Contenido")
	e._jugar()
	await get_tree().create_timer(0.5).timeout
	ok(e._jugando != null, "se puede jugar el mini editado")
	# nivel normal: el mapa sigue
	e._cerrar_modal()
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	await get_tree().create_timer(0.4).timeout
	print("FALLOS ", fallos)
	get_tree().quit()
