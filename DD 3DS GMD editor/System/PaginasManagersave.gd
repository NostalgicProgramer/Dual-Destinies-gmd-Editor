extends Node

@onready var edit_principal = $"../TextEdit"
@onready var searchbar = $HSlider
@onready var searchnumber = $LineEditSearch
@onready var contador = $Contador

var lista_paginas = []
var indice_pagina_actual = 0

func _ready():
	var btn_prev = get_node_or_null("../BtnPrev")
	var btn_next = get_node_or_null("../BtnNext")
	
	if btn_prev: btn_prev.pressed.connect(_on_prev_pressed)
	if btn_next: btn_next.pressed.connect(_on_next_pressed)

# Carga un bloque nuevo y divide por <PAGE>
func cargar_nuevo_bloque(texto_completo: String):
	lista_paginas = texto_completo.split("<PAGE>")
	indice_pagina_actual = 0
	
	if lista_paginas.size() > 0:
		edit_principal.text = lista_paginas[0]

# Esta función SÍ o SÍ debe llamarse antes de cambiar de Label en el UI_Principal
# o antes de guardar el archivo.
func obtener_texto_unificado() -> String:
	# Guardamos el estado actual del TextEdit en la lista
	if lista_paginas.size() > indice_pagina_actual:
		lista_paginas[indice_pagina_actual] = edit_principal.text
	
	return "<PAGE>".join(lista_paginas)

func _on_prev_pressed():
	if lista_paginas.size() > 0 and indice_pagina_actual > 0:
		# Guardamos lo que había antes de movernos
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual -= 1
		# Cargamos la nueva página
		edit_principal.text = lista_paginas[indice_pagina_actual]

func _on_next_pressed():
	if lista_paginas.size() > 0 and indice_pagina_actual < lista_paginas.size() - 1:
		# Guardamos lo que había antes de movernos
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual += 1
		# Cargamos la nueva página
		edit_principal.text = lista_paginas[indice_pagina_actual]


func reset_manager():
	lista_paginas = []
	indice_pagina_actual = 0
	if edit_principal:
		edit_principal.text = ""
