extends Node
const Paquete := preload("res://scripts/paquete.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var r: Dictionary = Paquete.abrir_proyecto("/tmp/dino_out/dino-run.atrapa.json")
	ok(r["ok"] and r["assets"] >= 30, "abre Dino Run (%s archivos)" % str(r.get("assets")))
	ok(Datos.niveles.size() == 5 and str(Datos.niveles[0]["name"]) == "Bosque de Aysén", "5 mundos con sus nombres")
	ok(Datos.tema_de(Datos.niveles[1])["cielo"][0].is_equal_approx(Color("f2c08a")), "paleta propia del mundo 2")
	ok(Datos.reglas["catalogo"].size() == 15 and Datos.reglas["jugables"].size() == 5, "tienda de 15 y 5 jugables")
	var g: Dictionary = Paquete.guardar_proyecto("/tmp/dino_rt", "Dino Run")
	ok(g["ok"] and g["assets"] >= 30, "guarda de nuevo con %d assets" % g["assets"])
	var a: Dictionary = Paquete.abrir_apk("/tmp/prueba.apk")
	ok(a["ok"] and str(a["html"]).ends_with("index.html") and a["paquete"] == "com.ejemplo.dinorun" and a["codigo"], "APK: web detectada, paquete %s" % a.get("paquete"))
	print(Paquete.resumen_apk(a))
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
