extends Node

@onready var edit_principal = $"../TextEdit"
@onready var searchbar = $HSlider
@onready var searchnumber = $LineEditSearch
@onready var contador = $Contador
@onready var btn_prev = $"../BtnPrev"
@onready var btn_next = $"../BtnNext"

var lista_paginas = []
var indice_pagina_actual = 0

func _ready():
	# Conexión de botones existentes
	if btn_prev: btn_prev.pressed.connect(_on_prev_pressed)
	if btn_next: btn_next.pressed.connect(_on_next_pressed)
	
	# Conexión de nuevos elementos de búsqueda
	searchbar.value_changed.connect(_on_slider_changed)
	searchnumber.text_submitted.connect(_on_lineedit_submitted)
	
	actualizar_interfaz()

func cargar_nuevo_bloque(texto_completo: String):
	lista_paginas = texto_completo.split("<PAGE>")
	
	# 1. Resetear el índice lógico
	indice_pagina_actual = 0
	
	# 2. Resetear los elementos visuales
	if searchbar:
		searchbar.value = 0
		# Importante: Actualizamos el rango del slider al nuevo total de páginas
		searchbar.max_value = max(0, lista_paginas.size() - 1)
		
	if searchnumber:
		searchnumber.text = "1" # El usuario ve la página 1, aunque internamente sea 0
		
	# 3. Limpieza de bordes (lo que ya tenías)
	for i in range(lista_paginas.size()):
		lista_paginas[i] = lista_paginas[i].lstrip("\n\r ").rstrip("\n\r ")
		
	if lista_paginas.size() > 0:
		edit_principal.text = lista_paginas[0]
	
	# 4. Actualizar la interfaz
	actualizar_interfaz()

# El "cerebro" de la UI: actualiza todo a la vez
func actualizar_interfaz():
	var total = lista_paginas.size()
	var hay_multiples = total > 1
	
	# 1. Botones Prev/Next
	btn_prev.disabled = !hay_multiples or (indice_pagina_actual == 0)
	btn_next.disabled = !hay_multiples or (indice_pagina_actual == total - 1)
	
	# 2. Contador
	if contador:
		contador.text = str(indice_pagina_actual + 1) + " / " + str(total)
	
	# 3. Barra deslizante (HSlider)
	searchbar.max_value = max(0, total - 1)
	searchbar.value = indice_pagina_actual
	searchbar.editable = hay_multiples
	
	# 4. Input numérico
	searchnumber.text = str(indice_pagina_actual + 1)
	searchnumber.editable = hay_multiples

func obtener_texto_unificado() -> String:
	if lista_paginas.size() > indice_pagina_actual:
		lista_paginas[indice_pagina_actual] = edit_principal.text
	
	var res = ""
	for i in range(lista_paginas.size()):
		res += lista_paginas[i]
		if i < lista_paginas.size() - 1:
			res += "<PAGE>\n"
	return res

# Navegación por botones
func _on_prev_pressed():
	if indice_pagina_actual > 0:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual -= 1
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

func _on_next_pressed():
	if indice_pagina_actual < lista_paginas.size() - 1:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual += 1
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

# Navegación por Slider
func _on_slider_changed(value: float):
	var nuevo_indice = int(value)
	if nuevo_indice != indice_pagina_actual:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual = nuevo_indice
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

# Navegación por LineEdit (Número de página)
func _on_lineedit_submitted(nuevo_texto: String):
	var pagina_deseada = int(nuevo_texto) - 1 # -1 porque los humanos cuentan desde 1
	if pagina_deseada >= 0 and pagina_deseada < lista_paginas.size():
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual = pagina_deseada
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()
	else:
		# Si escriben un número inválido, reseteamos al valor actual
		searchnumber.text = str(indice_pagina_actual + 1)

func reset_manager():
	lista_paginas = []
	indice_pagina_actual = 0
	edit_principal.text = ""
	actualizar_interfaz()
