extends RefCounted
## Asistente de ideas (funciona sin internet, dentro del programa): lee lo que cuentas de tu juego y recomienda
## categoría, tipo, enemigos, premios, cómo se pierde y qué calidad conviene según dónde se jugará.

const Cat := preload("res://scripts/categorias.gd")

# [palabras clave, categoría, tipo, enemigos, premios, obstáculos/pérdida, puntuación]
const REGLAS := [
	[["memoria", "parejas", "puzzle", "rompecabezas", "cartas"], "otros", "puzzle", "ninguno: el reto es la memoria", "puntos por pareja", "quedarte sin intentos", "parejas encontradas"],
	[["ritmo", "música", "musica", "guitarra", "baile", "canción"], "otros", "ritmo", "ninguno: las notas que se escapan", "combos", "fallar demasiadas notas", "aciertos y combo"],
	[["torre", "defensa", "oleada", "castillo"], "estrategia", "defensa_e", "oleadas de enemigos por un camino", "monedas para más torres", "que lleguen a tu casa", "enemigos vencidos"],
	[["fútbol", "futbol", "penal", "gol", "deporte", "básquet", "basquet"], "otros", "deportes", "un portero rival", "puntos por gol", "quedarte sin tiros", "goles"],
	[["granja", "cultiv", "sembrar", "cosecha", "animales de granja"], "otros", "granja", "ninguno: el tiempo", "monedas por cosecha", "no hay: es relajado", "monedas ahorradas"],
	[["novela", "diálogo", "dialogo", "decisiones", "elegir", "historia interactiva"], "narrativo", "dialogos", "ninguno: tus decisiones", "finales distintos", "elegir mal", "escenas recorridas"],
	[["pregunta", "quiz", "aprender", "educativ", "colegio", "escuela", "trivia"], "educativo", "quiz", "ninguno: el reto es saber", "puntos por respuesta", "equivocarte con pocas vidas", "respuestas correctas"],
	[["conquist", "estrategia", "islas", "ejército", "ejercito", "tropas"], "estrategia", "conquista", "un rival que ataca solo", "islas conquistadas", "perder todas tus islas", "islas ganadas"],
	[["supervivencia", "sobrevivir", "zombi", "oleadas de enemigos", "aguantar"], "supervivencia", "superv2d", "enemigos que te persiguen sin parar", "puntos por tiempo", "que te toquen", "segundos aguantados"],
	[["carretera", "frontal", "tráfico", "trafico", "outrun"], "carreras", "frontal", "autos en la carretera", "kilómetros", "chocar demasiado", "distancia"],
	[["carrera", "autos", "auto ", "kart", "pista", "velocidad", "correr con"], "carreras", "pista", "otros autos y obstáculos en la pista", "monedas y turbos", "chocar o salirte de la pista", "puntos por vuelta y por monedas"],
	[["run ", "corre", "corredor", "infinito", "subway", "dino"], "carreras", "corredor2d", "troncos, rocas y un perseguidor", "monedas, gemas y estrellas", "chocar con un obstáculo", "metros recorridos + monedas"],
	[["dispar", "pistola", "arma", "shooter", "balas", "soldado", "guerra"], "disparos", "shooter2d", "robots y soldados que te persiguen", "munición y botiquines", "que te toquen o te disparen", "puntos por enemigo vencido"],
	[["rpg", "magia", "mago", "espada", "dragón", "dragon", "misión", "tesoro", "mazmorra"], "aventura", "rpg", "monstruos y jefes", "tesoros, llaves y pociones", "perder todas las vidas", "tesoros reunidos y misiones"],
	[["mundo abierto", "libre", "selva", "explorar", "isla", "ciudad"], "mundo_libre", "selva", "animales salvajes", "frutas, cofres y mapas", "caer en trampas o barro", "objetos descubiertos"],
	[["pelea", "luch", "box", "combate", "karate"], "pelea", "pelea2d", "el otro luchador", "poderes especiales", "quedarte sin energía", "rondas ganadas"],
	[["plataforma", "salta", "saltar", "mario", "saltos"], "plataformas", "clasico", "caracoles y pinchos", "monedas, estrellas y gemas", "caer o tocar pinchos", "monedas y estrellas"],
	[["terror", "fantasma", "miedo", "misterio", "noche"], "terror", "terror2d", "fantasmas que patrullan", "llaves y velas", "que te alcance un fantasma", "llaves reunidas"],
	[["cuento", "historia", "narrativ", "personajes que hablan"], "narrativo", "cuento", "personajes problemáticos", "objetos de la historia", "tomar la decisión equivocada", "capítulos completados"],
]


## Devuelve {cat, tipo, texto (explicación), cfg (para crear el juego, o {})}.
static func recomendar(idea: String, plataforma: String = "windows") -> Dictionary:
	var t := idea.to_lower()
	var mejor: Array = []
	var pts := 0
	for r in REGLAS:
		var n := 0
		for k in r[0]:
			if t.contains(str(k)):
				n += 1
		if n > pts:
			pts = n
			mejor = r
	if mejor.is_empty():
		return {"ok": false, "texto": "Cuéntame un poco más: ¿se corre, se salta, se dispara, se explora o se pelea? Con una palabra clave ya te puedo recomendar."}
	var tipo: Dictionary = Cat.tipo(str(mejor[1]), str(mejor[2]))
	var movil := plataforma == "android" or t.contains("celular") or t.contains("móvil") or t.contains("movil")
	var calidad := "Para celular: calidad baja o media, imagen al 75 %, 30 FPS y FSR 1 para que no se caliente." if movil else "Para PC con 8 GB de RAM y 4 GB de video: calidad media o alta con FSR 2.2 y 60 FPS."
	var dim := ""
	if t.contains("3d"):
		dim = "Pediste 3D: úsalo si el mundo se recorre en profundidad; en celulares viejos conviene 2D o 2.5D."
	elif t.contains("2d"):
		dim = "En 2D va muy fluido en cualquier aparato."
	var txt := "Te recomiendo la categoría «%s» → «%s».\nEnemigos: %s.\nPremios: %s.\nSe pierde al: %s.\nPuntuación: %s.\n%s %s" % [
		str(Cat.categoria(str(mejor[1])).get("titulo", mejor[1])), str(tipo.get("titulo", mejor[2])), mejor[3], mejor[4], mejor[5], mejor[6], calidad, dim]
	var ok: bool = bool(tipo.get("ok", false))
	if not ok:
		txt += "\n(Ese tipo todavía está en preparación; puedes elegir uno parecido.)"
	return {"ok": ok, "cat": mejor[1], "tipo": mejor[2], "texto": txt.strip_edges(), "movil": movil}
