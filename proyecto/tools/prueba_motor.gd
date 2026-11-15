extends Node
# Prueba sin pantalla: crea el juego, simula teclas y comprueba que se puede ganar.
const Juego := preload("res://scripts/juego.gd")

func _ready() -> void:
	var root := get_tree().root
	var datos = Datos
	var j := Juego.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(datos.nivel_inicial(), false, false)
	print("items: plats=", j.plats.size(), " premios=", j.total, " enemigos=", j.enemigos.size())
	# deja caer al jugador y comprueba que aterriza
	for i in 90: j._actualizar(1.0 / 60.0)
	print("aterrizó en suelo: ", j.suelo, " pos=", j.pos)
	# simula: corre a la derecha saltando de vez en cuando
	var frames := 0
	while j.estado == "jugar" and frames < 60 * 60:
		frames += 1
		Input.action_release("ui_left")
		# forzamos entrada directa
		j.dedos = {0: "der"}
		j.tactil = true
		if frames % 40 == 0: j.salto_pulsado = true
		j._actualizar(1.0 / 60.0)
	print("estado final: ", j.estado, " frames=", frames, " puntos=", j.puntos, " vidas=", j.vidas, " x=", int(j.pos.x))
	# redibujar (en headless no pinta, pero ejecuta la lógica de _process)
	j._process(0.016)
	get_tree().quit(0)
