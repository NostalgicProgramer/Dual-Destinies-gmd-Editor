extends Node

@onready var edit_principal = $"../TextEdit"
@onready var searchbar = $HSlider
@onready var searchnumber = $LineEditSearch
@onready var contador = $Contador
@onready var btn_prev = $"../BtnPrev"
@onready var btn_next = $"../BtnNext"
@onready var btn_copy = $"../BtnCopy"

# Referencia al switch en tu interfaz (puedes cambiar la ruta según dónde tengas tu CheckButton/CheckBox)
@onready var check_modo_paginado = $"../CheckModoPaginado" # Ajusta esta ruta si es necesario

var lista_paginas = []
var indice_pagina_actual = 0
var modo_paginado: bool = true

func _ready():
	# Conexión de botones existentes
	if btn_prev: btn_prev.pressed.connect(_on_prev_pressed)
	if btn_next: btn_next.pressed.connect(_on_next_pressed)
	
	# Conexión de elementos de búsqueda
	searchbar.value_changed.connect(_on_slider_changed)
	searchnumber.text_submitted.connect(_on_lineedit_submitted)
	
	# Conexión del Switch de la UI (asumiendo que es un CheckButton o CheckBox)
	if check_modo_paginado:
		check_modo_paginado.button_pressed = modo_paginado
		check_modo_paginado.toggled.connect(_on_modo_paginado_toggled)
	
	actualizar_interfaz()

func cargar_nuevo_bloque(texto_completo: String):
	# Guardamos primero el texto completo bruto
	if modo_paginado:
		lista_paginas = texto_completo.split("<PAGE>")
	else:
		lista_paginas = [texto_completo]
	
	# 1. Resetear el índice lógico
	indice_pagina_actual = 0
	
	# 2. Resetear los elementos visuales
	if searchbar:
		searchbar.value = 0
		searchbar.max_value = max(0, lista_paginas.size() - 1)
		
	if searchnumber:
		searchnumber.text = "1" 
		
	# 3. Limpieza de bordes pero SIN destruir el contenido ni los comandos
	for i in range(lista_paginas.size()):
		lista_paginas[i] = lista_paginas[i].lstrip("\n\r ").rstrip("\n\r ")
		
	if lista_paginas.size() > 0:
		if modo_paginado:
			edit_principal.text = lista_paginas[0]
		else:
			edit_principal.text = texto_completo
	
	# 4. Actualizar la interfaz
	actualizar_interfaz()

# El "cerebro" de la UI: actualiza todo a la vez
func actualizar_interfaz():
	var total = lista_paginas.size()
	var hay_multiples = modo_paginado and (total > 1)
	
	# 1. Botones Prev/Next
	btn_prev.disabled = !hay_multiples or (indice_pagina_actual == 0)
	btn_next.disabled = !hay_multiples or (indice_pagina_actual == total - 1)
	#btn_copy.disabled = !hay_multiples or (indice_pagina_actual == total - 1)
	
	# 2. Contador
	if contador:
		if modo_paginado:
			contador.text = str(indice_pagina_actual + 1) + " / " + str(total)
		else:
			contador.text = "1"
	
	# 3. Barra deslizante (HSlider)
	searchbar.max_value = max(0, total - 1)
	searchbar.value = indice_pagina_actual if modo_paginado else 0
	searchbar.editable = hay_multiples
	
	# 4. Input numérico
	searchnumber.text = str(indice_pagina_actual + 1)
	searchnumber.editable = hay_multiples

func obtener_texto_unificado() -> String:
	# Si estamos en modo completo, el TextEdit ya contiene todo tal cual lo dejamos
	if not modo_paginado:
		return edit_principal.text
	
	# Si estamos en modo paginado, guardamos los cambios de la página actual antes de unir
	if lista_paginas.size() > indice_pagina_actual:
		lista_paginas[indice_pagina_actual] = edit_principal.text
	
	var res = ""
	for i in range(lista_paginas.size()):
		res += lista_paginas[i]
		if i < lista_paginas.size() - 1:
			# Respetando tu formato: <PAGE> seguido únicamente de su salto de línea al final
			res += "<PAGE>\n"
	return res

# Control del Switch desde la interfaz gráfica
func _on_modo_paginado_toggled(button_pressed: bool):
	if modo_paginado == button_pressed:
		return
		
	if not modo_paginado:
		# De Completo -> Paginado: Partimos el texto actual usando <PAGE>
		var texto_actual = edit_principal.text
		lista_paginas = texto_actual.split("<PAGE>")
		for i in range(lista_paginas.size()):
			lista_paginas[i] = lista_paginas[i].lstrip("\n\r ").rstrip("\n\r ")
		modo_paginado = true
		indice_pagina_actual = 0
		if lista_paginas.size() > 0:
			edit_principal.text = lista_paginas[0]
	else:
		# De Paginado -> Completo: Unimos todas las páginas conservando los <PAGE>\n en su sitio
		var texto_unificado = obtener_texto_unificado()
		modo_paginado = false
		lista_paginas = [texto_unificado]
		edit_principal.text = texto_unificado
		indice_pagina_actual = 0
		
	actualizar_interfaz()

# Navegación por botones
func _on_prev_pressed():
	if modo_paginado and indice_pagina_actual > 0:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual -= 1
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

func _on_next_pressed():
	if modo_paginado and indice_pagina_actual < lista_paginas.size() - 1:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual += 1
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

# Navegación por Slider
func _on_slider_changed(value: float):
	if not modo_paginado:
		return
	var nuevo_indice = int(value)
	if nuevo_indice != indice_pagina_actual:
		lista_paginas[indice_pagina_actual] = edit_principal.text
		indice_pagina_actual = nuevo_indice
		edit_principal.text = lista_paginas[indice_pagina_actual]
		actualizar_interfaz()

# Navegación por LineEdit (Número de página)
func _on_lineedit_submitted(nuevo_texto: String):
	if not modo_paginado:
		return
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
