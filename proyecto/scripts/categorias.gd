extends RefCounted
## Categorías de juegos que ofrece el asistente de inicio. Cada tipo trae su "receta":
## el motor que usa, el fondo, el héroe y las reglas con que arranca.

const PLATAFORMAS := [
	{"id": "windows", "emoji": "🖥", "titulo": "Windows", "txt": "Un programa para computadores con Windows.", "color": Color("2f6fed"), "disp": "pc"},
	{"id": "linux", "emoji": "🐧", "titulo": "Linux", "txt": "Un programa para computadores con Linux.", "color": Color("f2a900"), "disp": "pc"},
	{"id": "android", "emoji": "📱", "titulo": "Android", "txt": "Una app para celulares y tablets.", "color": Color("2ecc71"), "disp": "movil"},
	{"id": "web", "emoji": "🌐", "titulo": "Navegador", "txt": "Se juega en internet, sin instalar nada.", "color": Color("8b5cf6"), "disp": "pc"},
]

# "ok": false = todavía no está construido (se muestra como «Pronto»).
const CATEGORIAS := [
	{"id": "carreras", "emoji": "🏎", "titulo": "Carreras", "txt": "Velocidad, curvas y obstáculos.", "color": Color("ef4444"), "tipos": [
		{"id": "subway", "emoji": "🏃", "titulo": "Corredor infinito", "txt": "Tres carriles, saltos y monedas. Como Subway Surfers.", "ok": true,
			"modo": "3d", "tipo": "corredor", "theme": "dia", "hero": "🐱"},
		{"id": "corredor2d", "emoji": "🏃", "titulo": "Corredor 2D (celular)", "txt": "Corre solo hacia adelante y tú saltas. Como Run, pero en 2D.", "ok": true,
			"modo": "2d", "tipo": "plataformas", "estilo": "corredor2d", "theme": "dia", "hero": "🐱"},
		{"id": "frontal", "emoji": "🏎", "titulo": "Carrera 2D frontal", "txt": "Carretera en perspectiva con curvas y tráfico.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "frontal", "theme": "desierto", "hero": "🚗"},
		{"id": "pista", "emoji": "🏁", "titulo": "Carreras de pista", "txt": "Vueltas a un circuito contra otros. Como Mario Kart.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "carrera", "theme": "dia", "hero": "🐱"},
		{"id": "pista3d", "emoji": "🏁", "titulo": "Carreras 3D", "txt": "Como Mario Kart: ves la pista desde atrás del auto.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "carrera", "vista3d": true, "theme": "dia", "hero": "🐱"},
		{"id": "karts3d", "emoji": "🏎", "titulo": "Go-karts 3D", "txt": "Karts en 3D con derrapes y turbos.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "kart", "vista3d": true, "theme": "desierto", "hero": "🦊"},
		{"id": "karts", "emoji": "🏎", "titulo": "Go-karts", "txt": "Karts con derrapes, turbos y obstáculos.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "kart", "theme": "desierto", "hero": "🦊"},
	]},
	{"id": "plataformas", "emoji": "🍄", "titulo": "Plataformas", "txt": "Saltar, recoger y llegar a la meta.", "color": Color("2ecc71"), "tipos": [
		{"id": "clasico", "emoji": "🍄", "titulo": "Plataformas 2D", "txt": "El clásico: salta entre plataformas.", "ok": true,
			"modo": "2d", "tipo": "plataformas", "theme": "dia", "hero": "🐱"},
		{"id": "papel", "emoji": "🧊", "titulo": "Plataformas 2.5D", "txt": "Igual, pero con bloques con profundidad.", "ok": true,
			"modo": "25d", "tipo": "plataformas", "theme": "dia", "hero": "🐱"},
		{"id": "trio", "emoji": "⚔", "titulo": "Trío de héroes", "txt": "Como Trine: cambia entre caballero, mago y ladrón (teclas 1, 2 y 3).", "ok": true,
			"modo": "2d", "tipo": "plataformas", "estilo": "trio", "theme": "dia", "hero": "a:caballero"},
	]},
	{"id": "aventura", "emoji": "🗺", "titulo": "Aventura y RPG", "txt": "Explora mundos y encuentra tesoros.", "color": Color("00a8b5"), "tipos": [
		{"id": "mundo3d", "emoji": "🗺", "titulo": "Aventura en 3D", "txt": "Camina libre por un mundo en 3D.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "bosque", "hero": "🐱"},
		{"id": "rpg_dialogos", "emoji": "🧑‍🌾", "titulo": "RPG con personajes", "txt": "Habla con los personajes del mapa y busca tesoros.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "rpg", "theme": "bosque", "hero": "🧙"},
		{"id": "rpg", "emoji": "⚔", "titulo": "RPG desde arriba", "txt": "Explora un mapa visto desde arriba, con enemigos y tesoros.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "bosque", "hero": "🧙"},
	]},
	{"id": "accion", "emoji": "💥", "titulo": "Acción", "txt": "Esquiva, atrapa y vence enemigos.", "color": Color("ff8a3d"), "tipos": [
		{"id": "accion_arriba", "emoji": "💥", "titulo": "Acción desde arriba", "txt": "Muévete por el mapa y esquiva enemigos.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "desierto", "hero": "🤖"},
		{"id": "accion_3d", "emoji": "🎯", "titulo": "Acción en 3D", "txt": "Corre y salta por un mundo en 3D lleno de peligros.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "atardecer", "hero": "🤖"},
	]},
	{"id": "disparos", "emoji": "🔫", "titulo": "Disparos (shooter)", "txt": "Dispara a enemigos desde arriba, en 2D.", "color": Color("0ea5e9"), "tipos": [
		{"id": "shooter2d", "emoji": "🔫", "titulo": "Shooter desde arriba", "txt": "Muévete, apunta y dispara con Espacio o clic.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "disparos", "theme": "desierto", "hero": "🤖"},
		{"id": "shooter_ciudad", "emoji": "🏙", "titulo": "Shooter en la ciudad", "txt": "Lo mismo, de noche entre edificios.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "disparos", "theme": "noche", "hero": "🤖"},
		{"id": "shooter3d", "emoji": "🎯", "titulo": "Shooter 1ª/3ª persona (3D)", "txt": "Dispara en 3D. La tecla C cambia entre primera y tercera persona.", "ok": true,
			"modo": "3d", "tipo": "aventura", "estilo": "disparos3d", "theme": "noche", "hero": "a:explorador"},
	]},
	{"id": "estrategia", "emoji": "🏴", "titulo": "Estrategia", "txt": "Conquista islas y toma decisiones.", "color": Color("b45309"), "tipos": [
		{"id": "conquista", "emoji": "🏴", "titulo": "Conquista de islas", "txt": "Envía tropas y vence al rival.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "estrategia", "theme": "dia", "hero": "🤖"},
		{"id": "defensa_e", "emoji": "🏰", "titulo": "Defensa de torres", "txt": "Coloca defensas y detén las oleadas.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "defensa", "theme": "dia", "hero": "🤖"},
	]},
	{"id": "supervivencia", "emoji": "🏕", "titulo": "Supervivencia", "txt": "Aguanta el mayor tiempo posible.", "color": Color("78350f"), "tipos": [
		{"id": "superv2d", "emoji": "🏕", "titulo": "Supervivencia desde arriba", "txt": "Llegan enemigos sin parar: dispara y aguanta.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "supervivencia", "theme": "noche", "hero": "🤖"},
	]},
	{"id": "educativo", "emoji": "🎓", "titulo": "Educativo", "txt": "Aprende jugando.", "color": Color("0891b2"), "tipos": [
		{"id": "quiz", "emoji": "🎓", "titulo": "Preguntas y respuestas", "txt": "Un concurso: escribe tus propias preguntas.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "educativo", "theme": "dia", "hero": "🐼"},
		{"id": "parejas_e", "emoji": "🧩", "titulo": "Parejas de memoria", "txt": "Cartas para entrenar la memoria.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "puzzle", "theme": "dia", "hero": "🐱"},
	]},
	{"id": "mundo_libre", "emoji": "🌎", "titulo": "Mundo libre", "txt": "Un mundo abierto para explorar a tu manera.", "color": Color("16a34a"), "tipos": [
		{"id": "selva", "emoji": "🌴", "titulo": "Selva y aventura 3D", "txt": "Camina por una selva: árboles, caminos, barro y tesoros.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "bosque", "hero": "🧙"},
		{"id": "ciudad_abierta", "emoji": "🏙", "titulo": "Ciudad abierta", "txt": "Calles, edificios y autos para recorrer libremente en 3D.", "ok": true,
			"modo": "3d", "tipo": "aventura", "estilo": "ciudad", "theme": "atardecer", "hero": "a:explorador"},
	]},
	{"id": "narrativo", "emoji": "📖", "titulo": "Narrativo", "txt": "Historias con personajes y decisiones.", "color": Color("db2777"), "tipos": [
		{"id": "cuento", "emoji": "📖", "titulo": "Cuento jugable", "txt": "Mundos con portada y personajes, uno tras otro, como un cuento.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "bosque", "hero": "🧙"},
		{"id": "dialogos", "emoji": "💬", "titulo": "Novela con diálogos", "txt": "Conversaciones y elecciones que cambian el final.", "ok": true,
			"modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "novela", "theme": "bosque", "hero": "🧙"},
	]},
	{"id": "otros", "emoji": "🧩", "titulo": "Otros géneros", "txt": "Puzzles, ritmo, deportes, estrategia y más.", "color": Color("64748b"), "tipos": [
		{"id": "puzzle", "emoji": "🧩", "titulo": "Puzzles: parejas", "txt": "Encuentra las parejas de cartas.", "ok": true, "modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "puzzle", "theme": "dia", "hero": "🐱"},
		{"id": "ritmo", "emoji": "🎵", "titulo": "Ritmo y música", "txt": "Toca las notas al compás.", "ok": true, "modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "ritmo", "theme": "dia", "hero": "🐱"},
		{"id": "deportes", "emoji": "⚽", "titulo": "Deportes: penales", "txt": "Patea y marca goles.", "ok": true, "modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "penales", "theme": "dia", "hero": "🐱"},
		{"id": "defensa", "emoji": "🏰", "titulo": "Defensa de torres", "txt": "Coloca defensas y detén las oleadas.", "ok": true, "modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "defensa", "theme": "dia", "hero": "🐱"},
		{"id": "granja", "emoji": "🌾", "titulo": "Granja y simulación", "txt": "Siembra, riega y cosecha.", "ok": true, "modo": "2d", "tipo": "arriba", "estilo": "mini", "mini": "granja", "theme": "dia", "hero": "🐱"},
	]},
	{"id": "terror", "emoji": "👻", "titulo": "Terror", "txt": "Oscuridad, sustos y misterio (apto para niños).", "color": Color("6d28d9"), "tipos": [
		{"id": "terror3d", "emoji": "👻", "titulo": "Misterio en 3D", "txt": "Explora un mundo de noche lleno de fantasmas.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "noche", "hero": "🧙"},
		{"id": "terror2d", "emoji": "🕯", "titulo": "Misterio desde arriba", "txt": "Un laberinto oscuro visto desde arriba.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "noche", "hero": "🧙"},
	]},
	{"id": "pelea", "emoji": "🥊", "titulo": "Pelea y lucha", "txt": "Combates uno contra uno.", "color": Color("dc2626"), "tipos": [
		{"id": "pelea2d", "emoji": "🥊", "titulo": "Lucha 2D", "txt": "Dos luchadores frente a frente. Mejor de 3 rondas.", "ok": true,
			"modo": "2d", "tipo": "plataformas", "estilo": "pelea", "theme": "dia", "hero": "🐼"},
		{"id": "pelea_nieve", "emoji": "❄", "titulo": "Lucha en la nieve", "txt": "El mismo combate, en una arena nevada.", "ok": true,
			"modo": "2d", "tipo": "plataformas", "estilo": "pelea", "theme": "nieve", "hero": "🐰"},
	]},
]


static func categoria(id: String) -> Dictionary:
	for c in CATEGORIAS:
		if c["id"] == id:
			return c
	return {}


static func plataforma(id: String) -> Dictionary:
	for p in PLATAFORMAS:
		if p["id"] == id:
			return p
	return PLATAFORMAS[0]


static func tipo(cat_id: String, tipo_id: String) -> Dictionary:
	for t in categoria(cat_id).get("tipos", []):
		if t["id"] == tipo_id:
			return t
	return {}
