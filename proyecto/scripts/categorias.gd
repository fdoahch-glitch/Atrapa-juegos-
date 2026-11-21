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
		{"id": "pista", "emoji": "🏁", "titulo": "Carreras de pista", "txt": "Vueltas a un circuito contra otros. Como Mario Kart.", "ok": false},
		{"id": "karts", "emoji": "🏎", "titulo": "Go-karts", "txt": "Karts con derrapes y atajos.", "ok": false},
	]},
	{"id": "plataformas", "emoji": "🍄", "titulo": "Plataformas", "txt": "Saltar, recoger y llegar a la meta.", "color": Color("2ecc71"), "tipos": [
		{"id": "clasico", "emoji": "🍄", "titulo": "Plataformas 2D", "txt": "El clásico: salta entre plataformas.", "ok": true,
			"modo": "2d", "tipo": "plataformas", "theme": "dia", "hero": "🐱"},
		{"id": "papel", "emoji": "🧊", "titulo": "Plataformas 2.5D", "txt": "Igual, pero con bloques con profundidad.", "ok": true,
			"modo": "25d", "tipo": "plataformas", "theme": "dia", "hero": "🐱"},
	]},
	{"id": "aventura", "emoji": "🗺", "titulo": "Aventura y RPG", "txt": "Explora mundos y encuentra tesoros.", "color": Color("00a8b5"), "tipos": [
		{"id": "mundo3d", "emoji": "🗺", "titulo": "Aventura en 3D", "txt": "Camina libre por un mundo en 3D.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "bosque", "hero": "🐱"},
		{"id": "rpg", "emoji": "⚔", "titulo": "RPG desde arriba", "txt": "Explora un mapa visto desde arriba, con enemigos y tesoros.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "bosque", "hero": "🧙"},
	]},
	{"id": "accion", "emoji": "💥", "titulo": "Acción", "txt": "Esquiva, atrapa y vence enemigos.", "color": Color("ff8a3d"), "tipos": [
		{"id": "accion_arriba", "emoji": "💥", "titulo": "Acción desde arriba", "txt": "Muévete por el mapa y esquiva enemigos.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "desierto", "hero": "🤖"},
		{"id": "accion_3d", "emoji": "🎯", "titulo": "Acción en 3D", "txt": "Corre y salta por un mundo en 3D lleno de peligros.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "atardecer", "hero": "🤖"},
	]},
	{"id": "terror", "emoji": "👻", "titulo": "Terror", "txt": "Oscuridad, sustos y misterio (apto para niños).", "color": Color("6d28d9"), "tipos": [
		{"id": "terror3d", "emoji": "👻", "titulo": "Misterio en 3D", "txt": "Explora un mundo de noche lleno de fantasmas.", "ok": true,
			"modo": "3d", "tipo": "aventura", "theme": "noche", "hero": "🧙"},
		{"id": "terror2d", "emoji": "🕯", "titulo": "Misterio desde arriba", "txt": "Un laberinto oscuro visto desde arriba.", "ok": true,
			"modo": "2d", "tipo": "arriba", "theme": "noche", "hero": "🧙"},
	]},
	{"id": "pelea", "emoji": "🥊", "titulo": "Pelea y lucha", "txt": "Combates uno contra uno.", "color": Color("dc2626"), "tipos": [
		{"id": "pelea2d", "emoji": "🥊", "titulo": "Lucha 2D", "txt": "Dos luchadores frente a frente.", "ok": false},
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
