extends Node

const RUTA_GUARDADO := "user://meacore_quest.save"

var monedas: int = 0
var exp_total: int = 0

func _ready() -> void:
	cargar()

func guardar() -> void:
	var datos := {
		"monedas": monedas,
		"exp_total": exp_total,
	}
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_var(datos)
		archivo.close()

func cargar() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo:
		var datos = archivo.get_var()
		archivo.close()
		if datos is Dictionary:
			monedas = datos.get("monedas", 0)
			exp_total = datos.get("exp_total", 0)

func agregar_monedas(cantidad: int) -> void:
	monedas += cantidad
	guardar()

func agregar_exp(cantidad: int) -> void:
	exp_total += cantidad
	guardar()

func reiniciar() -> void:
	monedas = 0
	exp_total = 0
	guardar()
