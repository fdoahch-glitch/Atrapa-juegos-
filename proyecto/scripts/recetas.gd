extends RefCounted
## «Recetas»: para cada categoría, los pasos que hacen falta para crear ese juego, en orden.
## Cada paso abre el panel del editor que corresponde («abre»). Si el panel todavía no existe, «abre» es
## "pronto" y el editor lo dice con claridad.
##
## abre: portada | personajes | fondos | objetos | deco | biblioteca | mis | pista | reglas | rendimiento | exportar | tipos | pronto

static func _p(id: String, emoji: String, titulo: String, pregunta: String, abre: String) -> Dictionary:
	return {"id": id, "emoji": emoji, "titulo": titulo, "pregunta": pregunta, "abre": abre}


## Pasos que todos los juegos tienen al principio y al final.
static func _inicio() -> Array:
	return [_p("portada", "🖼", "Portada", "¿Cómo se ve la primera pantalla? Imagen, título y botones.", "portada")]


static func _final(extra_pantallas: Array = []) -> Array:
	var r: Array = [
		_p("espera", "⏳", "Salón de espera", "Cuenta regresiva antes de empezar (en Reglas).", "reglas"),
		_p("pantallas", "🏆", "Pantallas finales y logros", "Qué pasa cuando ganas, pierdes o consigues una medalla (en Reglas).", "reglas"),
		_p("rendimiento", "⚡", "Calidad y rendimiento", "¿En qué aparatos va a jugarse? Calidad, FSR y límite de imágenes por segundo.", "rendimiento"),
		_p("exportar", "🚀", "Exportar", "Crea el programa (.exe), la app o la página web.", "exportar"),
	]
	return extra_pantallas + r


## Pasos por categoría; las categorías nuevas comparten la receta que más se les parece.
static func pasos(categoria: String, tipo: String = "") -> Array:
	categoria = {"narrativo": "aventura", "terror": "aventura", "accion": "aventura", "otros": ""}.get(categoria, categoria)
	return _pasos(categoria, tipo)


static func _pasos(categoria: String, tipo: String = "") -> Array:
	var r: Array = _inicio()
	match categoria:
		"carreras":
			r += [
				_p("vehiculo", "🏎", "Vehículo o personaje", "¿Qué corre? Elige un modelo, su color y su diseño. También puedes importar el tuyo.", "personajes"),
				_p("pista", "🛣", "Pista y su ambiente", "Color y textura de la pista, cielo, clima, hora del día y perseguidor.", "pista"),
				_p("objetos_pista", "🚧", "Objetos de la pista", "Obstáculos, monedas, turbos y meta. Cada obstáculo puede ser un modelo tuyo.", "objetos"),
				_p("laterales", "🌳", "Decorado de los lados", "¿Qué hay a los costados? Árboles, casas, edificios, rocas…", "deco"),
				_p("fondos", "🖼", "Fondos y cielo", "El paisaje de fondo y los elementos del cielo.", "fondos"),
				_p("elementos", "🌍", "Elementos del mundo", "Lista de todo lo del mundo: reemplaza o activa y desactiva modelos, tamaño real del personaje.", "elementos"),
				_p("curvas", "↪", "Curvas, subidas y bajadas", "Giros a izquierda y derecha y subidas o bajadas (al final del panel de colores y ambiente).", "pista"),
				_p("fisica", "⚙", "Física y velocidad", "Velocidad, salto, vidas, qué pasa al chocar y cómo se pierde.", "reglas"),
				_p("puntos", "⭐", "Puntuación y recompensas", "Monedas, estrellas, tienda, vestuario y misiones.", "reglas"),
			]
			r += _final([_p("seleccion", "🚗", "Selección de vehículo", "Pantalla para elegir tu vehículo o personaje antes de correr (tienda y personajes jugables, en Reglas).", "reglas")])
		"plataformas":
			r += [
				_p("heroe", "🐱", "Personaje", "¿Quién salta? Elige su diseño o importa el tuyo.", "personajes"),
				_p("mundo", "🍄", "Plataformas y mapa", "Dibuja el nivel: plataformas, resortes, puertas y meta.", "objetos"),
				_p("enemigos", "🐌", "Enemigos y peligros", "¿Qué te hace perder? Pinchos, enemigos, caídas.", "objetos"),
				_p("fondos", "🖼", "Fondos", "El paisaje detrás del nivel.", "fondos"),
				_p("deco", "🌸", "Decoración", "Árboles, nubes, flores y detalles.", "deco"),
				_p("colores", "🎨", "Colores del mundo", "Cielo, colinas y suelo.", "pista"),
				_p("reglas", "📜", "Reglas y puntuación", "Vidas, premios para ganar, poderes y tienda.", "reglas"),
			]
			r += _final()
		"aventura", "mundo_libre":
			r += [
				_p("heroe", "🧙", "Personaje", "¿Quién eres? Elige tu personaje, ropa y accesorios.", "personajes"),
				_p("mundo", "🗺", "Mundo y terreno", "¿Dónde ocurre? Selva, ciudad, desierto… color y textura del suelo.", "pista"),
				_p("decorado", "🌴", "Elementos del lugar", "Árboles, casas, rocas, caminos y todo lo que decora el mundo.", "deco"),
				_p("objetos", "💎", "Tesoros y misiones", "Qué hay que encontrar y recoger.", "objetos"),
				_p("enemigos", "👾", "Enemigos y peligros", "¿Qué amenaza hay y cómo se vence?", "objetos"),
				_p("fondos", "🖼", "Cielo y fondos", "Cielo, clima y hora del día.", "fondos"),
				_p("reglas", "📜", "Reglas y progreso", "Vidas, objetivos, tienda, misiones y vestuario.", "reglas"),
			]
			r += _final()
		"disparos":
			r += [
				_p("heroe", "🤖", "Tu personaje", "¿Quién dispara? Diseño, color y accesorios.", "personajes"),
				_p("mapa", "🏙", "Mapa", "Paredes, edificios y zonas del lugar donde se pelea.", "objetos"),
				_p("enemigos", "👾", "Enemigos", "¿Quiénes te atacan y cuántos hay?", "objetos"),
				_p("armas", "🔫", "Armas", "Pistola, ráfaga, escopeta o rifle (en Reglas).", "reglas"),
				_p("deco", "🌆", "Decorado y texturas", "Colores y detalles del lugar.", "deco"),
				_p("fondos", "🖼", "Fondos", "El paisaje alrededor del mapa.", "fondos"),
				_p("reglas", "📜", "Reglas y puntuación", "Vidas, puntos por enemigo, premios y tienda.", "reglas"),
			]
			r += _final()
		"pelea":
			r += [
				_p("luchadores", "🥊", "Luchadores", "Elige a los dos luchadores, su diseño y color.", "personajes"),
				_p("arena", "🏟", "Arena", "Fondo, suelo y decorado del combate.", "fondos"),
				_p("reglas", "📜", "Rondas y reglas", "Vidas, rondas, tiempo y poderes.", "reglas"),
			]
			r += _final([_p("seleccion", "🥋", "Selección de luchador", "Pantalla para elegir tu luchador.", "reglas")])
		_:
			r += [
				_p("heroe", "🐱", "Personaje", "¿Quién juega? Elige su diseño o importa el tuyo.", "personajes"),
				_p("mundo", "🗺", "Mundo", "Construye el lugar del juego.", "objetos"),
				_p("fondos", "🖼", "Fondos y decorado", "El paisaje, el cielo y los detalles.", "fondos"),
				_p("reglas", "📜", "Reglas y puntuación", "Cómo se gana, cómo se pierde y qué se recibe.", "reglas"),
			]
			r += _final()
	return r
