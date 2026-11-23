extends RefCounted
## Guía en vivo: mira cómo va tu juego y dice, con palabras simples, qué podrías hacer ahora.
## También da una mini explicación de la sección en que estás y consejos según la plataforma.

const Rend := preload("res://scripts/rendimiento.gd")


static func _a(emoji: String, titulo: String, texto: String, abre: String, boton: String) -> Dictionary:
	return {"emoji": emoji, "titulo": titulo, "texto": texto, "abre": abre, "boton": boton}


## Lo siguiente que conviene hacer, según lo que ya hay en el proyecto.
static func ahora(proy: Dictionary) -> Dictionary:
	var reglas: Dictionary = proy["reglas"]
	var plat := str(reglas.get("plataforma", "windows"))
	var por: Dictionary = Datos.portada_normal(reglas.get("portada", {}))
	if (por["botones"] as Array).is_empty():
		return _a("🖼", "Arma tu portada", "Lo primero que ve quien juega es la portada. Pon un título, una imagen y un botón «Jugar».", "portada", "Ir a la portada")
	var errores: Array = Rend.analizar(proy).filter(func(p): return p["sev"] == "error")
	if not errores.is_empty():
		return _a("🛠", "Hay algo por arreglar", str(errores[0]["txt"]) + " Toca «Revisar» y lo arreglo por ti.", "rendimiento", "Revisar")
	var n: Dictionary = proy["niveles"][clampi(Datos.idx, 0, proy["niveles"].size() - 1)]
	var items: Array = n.get("items", [])
	var utiles := 0
	var decos := 0
	for it in items:
		if str(it.get("t", "")) == "deco":
			decos += 1
		elif not str(it.get("t", "")) in ["player", "goal"]:
			utiles += 1
	if utiles < 6:
		return _a("🧱", "Llena tu mundo", "Tu mundo está casi vacío. Agrega plataformas, monedas y enemigos desde la pestaña «Objetos» y arrástralos al escenario.", "objetos", "Ver objetos")
	if decos == 0 and Datos.tipo_de(n) in ["plataformas", "aventura", "corredor", "25d"]:
		return _a("🌳", "Decóralo", "Árboles, flores y rocas hacen que el mundo se vea vivo. Elige algunos en «Decoración».", "deco", "Ver decoración")
	if str(reglas.get("musica", "")) == "":
		return _a("🎵", "Ponle música", "Con música el juego se siente mucho mejor. Elige una melodía en «Reglas».", "reglas", "Elegir música")
	if Rend.ultima_medicion().is_empty():
		return _a("🔎", "Analiza tu juego", "Mido cómo corre y te digo cómo mejorarlo para %s." % Rend.PERFILES.get(plat, Rend.PERFILES["windows"])["nombre"], "rendimiento", "Analizar")
	return _a("🚀", "¡Listo para compartir!", "Tu juego está completo. Expórtalo para %s y pruébalo en el aparato real." % Rend.PERFILES.get(plat, Rend.PERFILES["windows"])["nombre"], "exportar", "Exportar")


## Mini tutorial de la sección donde está la persona.
static func tutorial(etapa: String, pestana: String, plat: String) -> String:
	var t := ""
	match etapa:
		"portada":
			t = "Esta es tu portada. Arrastra el título y los botones para moverlos; toca uno para cambiar su texto, imagen o animación."
		"personajes":
			t = "Aquí eliges quién juega. Mira cada personaje, cambia su color y agrégale accesorios."
		_:
			match pestana:
				"objetos":
					t = "Toca un objeto y luego toca el escenario para ponerlo. Arrastra para mover, y toca las manillas para estirarlo."
				"deco":
					t = "La decoración no estorba: sólo adorna. Prueba poner árboles al fondo y flores adelante."
				"fondos":
					t = "El fondo cambia el ambiente completo. Prueba uno y mira cómo se transforma."
				"lib":
					t = "La biblioteca tiene cientos de modelos. Si el color no combina, elige una paleta en Efectos."
				_:
					t = "Este es tu mundo. Elige un objeto a la izquierda y colócalo con un toque; usa «Jugar» para probarlo cuando quieras."
	match plat:
		"android":
			t += "\n📱 Para celular: botones grandes y pocas cosas en pantalla a la vez."
		"web":
			t += "\n🌐 Para el navegador: imágenes livianas (WebP) para que cargue rápido."
		"windows", "linux":
			t += "\n🖥 Para PC: puedes usar más detalle y calidad alta."
	return t
