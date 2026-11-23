extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	ok(Datos.traducir("Continuar", "es") == "Continuar", "español queda igual")
	ok(Datos.traducir("Continuar", "en") == "Continue", "inglés")
	ok(Datos.traducir("¡Perdiste!", "pt") == "Você perdeu!", "portugués")
	ok(Datos.traducir("¡Perdiste!", "fr") == "Perdu !", "francés")
	ok(Datos.traducir("Nivel 2 de 5", "pt") == "Nível 2 de 5", "portugués con números (%s)" % Datos.traducir("Nivel 2 de 5", "pt"))
	ok(Datos.traducir("Te faltan 3 premios para abrir la meta", "fr") == "Il manque 3 trésors pour ouvrir le but", "francés con números (%s)" % Datos.traducir("Te faltan 3 premios para abrir la meta", "fr"))
	ok(Datos.traducir("hola mundo mío", "fr") == "hola mundo mío", "el texto propio no se traduce")
	ok(Datos.traducir("Salir", "xx") == "Salir", "idioma desconocido no rompe")
	var b := Button.new()
	b.text = "Pausa"
	add_child(b)
	Datos.traducir_arbol(self, "fr")
	ok(b.text == "Pause", "traduce un árbol de controles")
	var r: Dictionary = Datos.reglas_completas({"idioma": "pt"})
	ok(r["idioma"] == "pt", "las reglas aceptan portugués")
	print("FALLOS ", fallos)
	get_tree().quit()
