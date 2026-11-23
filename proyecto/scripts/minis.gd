extends RefCounted
## Catálogo de minijuegos: cada uno es una DEMO jugable que el creador amplía cambiando su contenido
## (cartas, preguntas, diálogos, notas, oleadas…) desde el panel «Contenido» del editor.
## campos: k = clave en mini_cfg, n = nombre, t = "int" | "txt" | "lista", ayuda = una línea de explicación.

const MINIS := {
	"puzzle": {"n": "Parejas (memoria)", "emoji": "🧩", "clase": "puzzle", "tema": "dia", "hero": "🐱",
		"info": "Da vuelta las cartas y encuentra las parejas. Agrega emojis para hacerlo más grande.",
		"cfg": {"emojis": "🐱 🐶 🦊 🐼 🐸 🐵", "intentos": 0},
		"campos": [{"k": "emojis", "n": "Cartas (emojis separados por espacio)", "t": "txt"}, {"k": "intentos", "n": "Intentos máximos (0 = sin límite)", "t": "int"}]},
	"ritmo": {"n": "Ritmo y música", "emoji": "🎵", "clase": "ritmo", "tema": "noche", "hero": "🐱",
		"info": "Caen notas por 4 carriles. Tócalas con D F J K o con el dedo. Dibuja tu canción con números.",
		"cfg": {"patron": "1 2 3 4 . 1 3 . 2 4 . 1 2 3 4 . 4 3 2 1 . 1 4 . 2 3 . 1 2 3 4 . . 1 3 2 4 . 1 2 3 4", "bpm": 110, "fallos": 8},
		"campos": [{"k": "patron", "n": "Notas (1-4 = carril, punto = silencio)", "t": "txt"}, {"k": "bpm", "n": "Velocidad (pulsos por minuto)", "t": "int"}, {"k": "fallos", "n": "Notas que puedes fallar", "t": "int"}]},
	"defensa": {"n": "Defensa de torres", "emoji": "🏰", "clase": "defensa", "tema": "dia", "hero": "🤖",
		"info": "Toca el mapa para poner torres y detén las oleadas antes de que lleguen a tu casa.",
		"cfg": {"oleadas": "5 8 12", "vida": 3, "torre": "🏹", "enemigo": "👾", "monedas": 60, "costo": 25},
		"campos": [{"k": "oleadas", "n": "Enemigos por oleada (números separados por espacio)", "t": "txt"}, {"k": "vida", "n": "Golpes para vencer a un enemigo", "t": "int"}, {"k": "monedas", "n": "Monedas al empezar", "t": "int"}, {"k": "costo", "n": "Costo de una torre", "t": "int"}, {"k": "torre", "n": "Emoji de la torre", "t": "txt"}, {"k": "enemigo", "n": "Emoji del enemigo", "t": "txt"}]},
	"penales": {"n": "Penales (deportes)", "emoji": "⚽", "clase": "penales", "tema": "dia", "hero": "🐼",
		"info": "Toca la portería para patear. El portero se mueve: ¡apunta donde no llegue!",
		"cfg": {"tiros": 5, "meta": 3, "portero": 1.0, "pelota": "⚽"},
		"campos": [{"k": "tiros", "n": "Cantidad de tiros", "t": "int"}, {"k": "meta", "n": "Goles para ganar", "t": "int"}, {"k": "portero", "n": "Velocidad del portero (1 = normal)", "t": "txt"}, {"k": "pelota", "n": "Emoji de la pelota", "t": "txt"}]},
	"granja": {"n": "Granja", "emoji": "🌾", "clase": "granja", "tema": "dia", "hero": "🧑‍🌾",
		"info": "Siembra, riega y cosecha para juntar monedas. Cada cultivo crece a su ritmo.",
		"cfg": {"cultivos": "🥕 8 6\n🍅 14 12\n🌽 22 22", "meta": 80},
		"campos": [{"k": "cultivos", "n": "Cultivos: emoji, segundos para crecer, precio (uno por línea)", "t": "lista"}, {"k": "meta", "n": "Monedas para ganar", "t": "int"}]},
	"novela": {"n": "Novela con diálogos", "emoji": "💬", "clase": "novela", "tema": "bosque", "hero": "🧙",
		"info": "Una historia con elecciones. Cada línea: id | texto | opción>id ; opción>id. Usa «gana» y «pierde» para los finales.",
		"cfg": {"personaje": "🧙", "guion": "inicio | Un viejo mago te detiene en el camino: «¿Buscas el tesoro del bosque?» | Sí, quiero ayuda>mapa ; No, gracias>pierde\nmapa | El mago te da un mapa con dos caminos. | Ir por el río>rio ; Ir por la cueva>cueva\nrio | El río está lleno de cocodrilos. Un tronco flota cerca. | Subirme al tronco>gana ; Nadar>pierde\ncueva | En la cueva brilla un cofre. ¡Es el tesoro! | Abrir el cofre>gana"},
		"campos": [{"k": "personaje", "n": "Emoji del personaje que habla", "t": "txt"}, {"k": "guion", "n": "Guion (una escena por línea: id | texto | opción>id ; opción>id)", "t": "lista"}]},
	"educativo": {"n": "Preguntas y respuestas", "emoji": "🎓", "clase": "quiz", "tema": "dia", "hero": "🐼",
		"info": "Un juego de preguntas. Cada línea: pregunta | respuesta A ; respuesta B ; respuesta C | número de la correcta.",
		"cfg": {"preguntas": "¿Cuánto es 2 + 2? | 3 ; 4 ; 5 | 2\n¿Qué animal hace miau? | El perro ; El gato ; La vaca | 2\n¿De qué color es el cielo de día? | Azul ; Verde ; Rojo | 1\n¿Cuántas patas tiene una araña? | 6 ; 8 ; 10 | 2"},
		"campos": [{"k": "preguntas", "n": "Preguntas (una por línea)", "t": "lista"}]},
	"estrategia": {"n": "Estrategia: conquista", "emoji": "🏴", "clase": "conquista", "tema": "dia", "hero": "🤖",
		"info": "Toca una isla tuya y luego otra para enviar la mitad de tus tropas. Conquista todas las islas.",
		"cfg": {"ia": 3.0, "tropas": 12},
		"campos": [{"k": "ia", "n": "Cada cuántos segundos ataca el rival", "t": "txt"}, {"k": "tropas", "n": "Tropas de cada isla neutral", "t": "int"}]},
	"frontal": {"n": "Carrera 2D frontal", "emoji": "🏎", "clase": "frontal", "tema": "desierto", "hero": "🚗",
		"info": "Conduces de frente por una carretera con curvas y tráfico. Flechas o toca los lados.",
		"cfg": {"curvas": "0 0 1 1 0 -1 -1 0 0 1 0 -1 -1 -1 0 1 1 0", "largo": 1400, "trafico": 14, "auto": "🚗"},
		"campos": [{"k": "curvas", "n": "Curvas (-1 izquierda, 0 recta, 1 derecha)", "t": "txt"}, {"k": "largo", "n": "Largo de la carrera (metros)", "t": "int"}, {"k": "trafico", "n": "Autos en la carretera", "t": "int"}, {"k": "auto", "n": "Emoji de tu auto", "t": "txt"}]},
}


static func existe(id: String) -> bool:
	return MINIS.has(id)


static func cfg_base(id: String) -> Dictionary:
	return (MINIS[id]["cfg"] as Dictionary).duplicate(true) if MINIS.has(id) else {}


## Une lo guardado con lo base y deja sólo valores simples (texto o número).
static func cfg_limpia(id: String, c: Variant) -> Dictionary:
	var r := cfg_base(id)
	if c is Dictionary:
		for k in r.keys():
			if c.has(k):
				if r[k] is int or r[k] is float:
					r[k] = float(c[k]) if r[k] is float else int(c[k])
				else:
					r[k] = str(c[k]).substr(0, 4000)
	return r
