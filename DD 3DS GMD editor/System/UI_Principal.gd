extends Control

# Nodos de la interfaz
@onready var boton_abrir = $BtnAbrir
@onready var boton_guardar = $BtnGuardar # <-- NUEVO BOTÓN
@onready var dialogo_archivo = $FileDialog
@onready var dialogo_guardar = $SaveDialog # <-- TU NUEVO DIALOG
@onready var item_list = $ItemList
@onready var display_texto = $TextEdit

const CONFIG_PATH = "user://config.cfg"

var gmd_actual: GMDParser.GMDContentData = null
var indice_actual: int = -1

func _ready():
	# Configuración del buscador de abrir archivos
	dialogo_archivo.access = FileDialog.ACCESS_FILESYSTEM
	dialogo_archivo.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialogo_archivo.filters = ["*.gmd ; Archivos GMD"]
	
	# NUEVO: Configuración del buscador de guardado
	dialogo_guardar.access = FileDialog.ACCESS_FILESYSTEM
	dialogo_guardar.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialogo_guardar.filters = ["*.gmd ; Archivos GMD"]
	
	# Conexión de señales
	boton_abrir.pressed.connect(_on_boton_abrir_pressed)
	dialogo_archivo.file_selected.connect(_on_archivo_seleccionado)
	item_list.item_selected.connect(_on_item_list_item_selected)
	display_texto.text_changed.connect(_on_display_texto_text_changed)
	
	# NUEVO: Conexiones para guardar
	if has_node("BtnGuardar"):
		boton_guardar.pressed.connect(_on_boton_guardar_pressed)
	dialogo_guardar.file_selected.connect(_on_archivo_guardar_seleccionado)
	
	# Carga de la ruta guardada
	var ruta_guardada = _cargar_ultima_ruta()
	if ruta_guardada != "" and DirAccess.dir_exists_absolute(ruta_guardada):
		dialogo_archivo.current_dir = ruta_guardada
		dialogo_guardar.current_dir = ruta_guardada

# --- LÓGICA DE PERSISTENCIA ---
func _guardar_ultima_ruta(path_completo: String):
	var carpeta_path = path_completo.get_base_dir()
	var config = ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("Historial", "ultima_ruta", carpeta_path)
	config.save(CONFIG_PATH)

func _cargar_ultima_ruta() -> String:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		return config.get_value("Historial", "ultima_ruta", "")
	return ""

# --- EVENTOS DE INTERFAZ (ABRIR) ---
func _on_boton_abrir_pressed():
	dialogo_archivo.popup_centered(Vector2(800, 600))

func _on_archivo_seleccionado(ruta_archivo: String):
	limpiar_estado_anterior()
	_guardar_ultima_ruta(ruta_archivo)
	gmd_actual = GMDParser.load_gmd(ruta_archivo)
	_poblar_interfaz()
	
	#$PaginasManager.cargar_nuevo_bloque(display_texto.text)

# --- NUEVO: EVENTOS DE INTERFAZ (GUARDAR) ---
func _on_boton_guardar_pressed():
	if gmd_actual == null:
		print("No hay ningún archivo GMD abierto para guardar.")
		return
		
	# Sugerimos un nombre por defecto basado en el nombre interno del script
	dialogo_guardar.current_file = gmd_actual.name + "_traducido.gmd"
	
	# Aseguramos que se abra en la misma ruta donde estamos trabajando
	var ruta_guardada = _cargar_ultima_ruta()
	if ruta_guardada != "" and DirAccess.dir_exists_absolute(ruta_guardada):
		dialogo_guardar.current_dir = ruta_guardada
		
	dialogo_guardar.popup_centered(Vector2(800, 600))

func _on_archivo_guardar_seleccionado(ruta_destino: String):
	# 1. Obtenemos el texto completo y unificado del PageManager
	# (Asegúrate de que el nodo se llame "PageManager")
	var texto_completo = $PageManager.obtener_texto_unificado()
	
	# 2. Actualizamos el gmd_actual con el texto correcto
	gmd_actual.entries[indice_actual]["text"] = texto_completo
	
	# 3. Guardamos
	GMDParser.save_gmd(ruta_destino, gmd_actual)
	print("¡Guardado exitoso con todas las páginas!")

# --- LÓGICA DEL PARSER EN LA UI ---
func _poblar_interfaz():
	item_list.clear()
	display_texto.text = ""
	indice_actual = -1
	
	if gmd_actual == null or gmd_actual.entries.size() == 0:
		return
		
	for i in range(gmd_actual.entries.size()):
		var etiqueta = gmd_actual.entries[i]["label"]
		item_list.add_item("%d: %s" % [i, etiqueta])
		
	item_list.select(0)
	_on_item_list_item_selected(0)

# Variable necesaria en tu UI_Principal
var indice_previo: int = -1

func _on_item_list_item_selected(index: int):
	# 1. Sincronizamos los cambios del bloque anterior antes de que desaparezcan
	if indice_previo != -1:
		var texto_unificado = $PageManager.obtener_texto_unificado()
		if gmd_actual != null:
			gmd_actual.entries[indice_previo]["text"] = texto_unificado
	
	# 2. Cargamos el nuevo bloque
	indice_actual = index
	indice_previo = index
	
	var nuevo_texto = gmd_actual.entries[index]["text"]
	$PageManager.cargar_nuevo_bloque(nuevo_texto)

func _on_display_texto_text_changed():
	if gmd_actual != null and indice_actual != -1:
		gmd_actual.entries[indice_actual]["text"] = display_texto.text

func limpiar_estado_anterior():
	# 1. Limpiamos la memoria de la UI
	gmd_actual = null
	indice_actual = -1
	indice_previo = -1
	item_list.clear()
	display_texto.text = ""
	
	# 2. Limpiamos el PageManager (el componente que mantiene las páginas)
	# Asumiendo que PageManager es un nodo hijo llamado "PageManager"
	if has_node("PageManager"):
		$PageManager.reset_manager()
		
	print("Estado limpiado correctamente para nuevo archivo.")
