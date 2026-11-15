extends Node2D
## Capa de dibujo genérica: delega el _draw en una función (Callable).
## Sirve para tener "capas" con su propia transformación (cámara, zoom).

var al_dibujar: Callable


func _draw() -> void:
	if al_dibujar.is_valid():
		al_dibujar.call(self)
