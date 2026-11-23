extends Node
const Analisis := preload("res://scripts/analisis.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = [
		{"t": "player", "x": 2, "y": 8, "id": "a1"},
		{"t": "plat", "x": 0, "y": 9, "w": 30, "h": 1, "id": "a2"},
		{"t": "plat", "x": 8, "y": 6, "w": 4, "h": 1, "id": "a3"},
		{"t": "plat", "x": 16, "y": 5, "w": 4, "h": 1, "id": "a4"},
		{"t": "goal", "x": 28, "y": 8, "id": "a5"}]
	var reg := Datos.reglas_completas({"plataforma": "android", "paleta_todo": true, "rend": {"msaa": 4, "escala": 1.0}})
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(n)], "reglas": reg})
	var med: Array = await Analisis.medir(self, Datos.proyecto(), 0.6)
	ok(med.size() == 1 and float(med[0]["fps"]) > 1.0, "midió el juego: %.0f FPS, %d dibujos" % [med[0]["fps"], med[0]["dibujos"]])
	var res: Array = Analisis.mejoras(Datos.proyecto(), med)
	for r in res: print("  - [%s/%s] %s" % [r["cat"], r["sev"], r["txt"]])
	var hay := func(op: String) -> bool: return res.any(func(r): return r["fix"]["op"] == op)
	ok(hay.call("paleta_todo_off"), "propone apagar la paleta en pantalla (Android)")
	ok(hay.call("msaa_off"), "propone apagar bordes suaves")
	ok(hay.call("deco_auto") and hay.call("monedas_auto"), "propone decoración y monedas")
	# aplicar todas
	for k in 20:
		var l: Array = Analisis.mejoras(Datos.proyecto(), med)
		var hecho := false
		for p in l:
			if p["fix"]["op"] != "info" and Analisis.aplicar(p):
				hecho = true
				break
		if not hecho: break
	var rd: Dictionary = Datos.proyecto()["reglas"]
	ok(rd["paleta_todo"] == false and rd["rend"]["msaa"] == 0, "se aplicaron los ajustes de rendimiento")
	var items: Array = Datos.proyecto()["niveles"][0]["items"]
	ok(items.any(func(i): return i["t"] == "deco") and items.any(func(i): return i["t"] == "coin"), "se agregaron decoración y monedas")
	ok(not (Analisis.mejoras(Datos.proyecto(), med).any(func(r): return r["fix"]["op"] in ["paleta_todo_off", "msaa_off", "deco_auto", "monedas_auto"])), "ya no quedan esas mejoras")
	var PanelRend = load("res://scripts/panel_rendimiento.gd")
	var pn = PanelRend.new()
	add_child(pn)
	pn.size = Vector2(1200, 700)
	await get_tree().process_frame
	pn._med_an = med
	pn._mostrar_an()
	ok(pn._lista_an.get_child_count() >= 1 and pn._res_an.text != "", "el panel muestra el análisis")
	print("FALLOS ", fallos)
	get_tree().quit()
