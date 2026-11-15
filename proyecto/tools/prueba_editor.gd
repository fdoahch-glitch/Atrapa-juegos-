extends Node
# Prueba lógica del editor sin pantalla: colocar, estirar, mover, borrar y tutorial.
func ok(c: bool, t: String) -> void:
	print(("  OK  " if c else " FALLA ") + t)

func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.4).timeout
	var ed = a.get_child(0)
	var esc = ed._esc
	esc.size = Vector2(900, 650)
	esc._ajustar()
	Datos.establecer(Datos.nivel_en_blanco())
	# colocar plataforma tocando (3 de ancho) y otra arrastrando (5 de ancho)
	esc.stamp = {"id": "plat", "n": "Plataforma", "t": "plat"}
	esc.herramienta = "mover"
	var c := func(cx: float, cy: float) -> Vector2: return esc.origen + Vector2(cx + 0.5, cy + 0.5) * esc.Z
	esc._bajar(c.call(2, 5)); esc._subir()
	var p1 = Datos.nivel["items"][-1]
	ok(p1["t"] == "plat" and p1["w"] == 3 and p1["x"] == 2 and p1["y"] == 5, "tocar crea plataforma de 3")
	esc._bajar(c.call(8, 5)); esc._mover(c.call(12, 5)); esc._subir()
	var p2 = Datos.nivel["items"][-1]
	ok(p2["w"] == 5, "arrastrar estira la plataforma a 5 (w=%d)" % p2["w"])
	# monedas pintando
	esc.stamp = {"id": "coin", "n": "Moneda", "t": "coin"}
	esc._bajar(c.call(3, 3)); esc._mover(c.call(5, 3)); esc._subir()
	var monedas: int = Datos.nivel["items"].filter(func(i): return i["t"] == "coin").size()
	ok(monedas == 3, "pintar monedas deslizando (%d)" % monedas)
	# seleccionar y mover
	esc.stamp = {}
	esc._bajar(c.call(3, 5)); esc._mover(c.call(3, 7)); esc._subir()
	ok(p1["y"] == 7, "mover plataforma (y=%d)" % p1["y"])
	# estirar por la esquina
	esc.sel = p1
	var b: Rect2 = Datos.caja_de(p1)
	esc._bajar(esc.origen + b.end * esc.Z); esc._mover(esc.origen + (b.end + Vector2(2, 0)) * esc.Z); esc._subir()
	ok(p1["w"] == 5, "estirar por la esquina (w=%d)" % p1["w"])
	# borrar
	esc.herramienta = "borrar"
	esc._bajar(c.call(3, 3)); esc._subir()
	ok(Datos.nivel["items"].filter(func(i): return i["t"] == "coin").size() == 2, "goma borra una moneda")
	# héroe y meta únicos
	Datos.colocar({"t": "goal"}, 10, 4); Datos.colocar({"t": "goal"}, 12, 4)
	ok(Datos.nivel["items"].filter(func(i): return i["t"] == "goal").size() == 1, "solo una meta")
	# deshacer / rehacer
	Datos.confirmar()
	var antes: int = Datos.nivel["items"].size()
	Datos.deshacer(); Datos.rehacer()
	ok(Datos.nivel["items"].size() == antes, "deshacer y rehacer")
	# JSON ida y vuelta (compatible con la versión web)
	var j: String = Datos.a_json()
	ok(Datos.desde_json(j) and Datos.nivel["items"].size() == antes, "copiar y pegar nivel")
	# tutorial completo por eventos
	var t = ed._tut
	t.iniciar()
	for ev in ["tab:fondos", "tema", "tab:objetos", "add:plat", "add:coin", "tab:pers", "hero", "add:enemy", "select", "play", "export"]:
		t.avisar(ev)
		await get_tree().create_timer(0.45).timeout
	ok(not t.activo, "el tutorial avanza solo con las acciones y termina")
	get_tree().quit(0)
