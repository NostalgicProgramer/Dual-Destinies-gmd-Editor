extends Sprite2D

@onready var edit_principal = $"../TextEdit"
@onready var label_dialogo = $Label
@onready var label_pruebas = $"../Simulacion2/Label"
@onready var label_perfiles = $"../Simulacion3/Label"

# Diccionario para gestionar las vistas fácilmente
# Referencias a los nodos de vista
@onready var vistas = {
	"DIALOGO": $".",
	"PRUEBAS": $"../Simulacion2",
	"PERFILES": $"../Simulacion3",
}

# Referencias a los labels correspondientes a cada vista
@onready var labels = {
	"DIALOGO": $Label,
	"PERFILES": $"../Simulacion3/Label",
	"PRUEBAS": $"../Simulacion2/Label"
}

var vista_actual = "DIALOGO"

# --- CONFIGURACIÓN DE TAGS ---
const TAG_TRANSLATOR = {
	
	# --- COMANDOS ---
	"CNTR": "[center]",
	
	# --- COLORES ---
	"E005": "[color=#FFFFFF]", # c0 - white
	"E006": "[color=#FF8800]", # c1 - orange
	"E007": "[color=#00FFFF]", # c2 - cyan
	"E008": "[color=#00FF00]", # c3 - green
	"E009": "[color=#FFFF00]", # c4 - yellow
	"E010": "[color=#FF8800]", # c5 - orange
	"E011": "[color=#808080]", # c6 - gray
	"E012": "[color=#0000FF]", # c7 - blue
	"E013": "[color=#FF0000]", # c8 - red
	"E014": "[color=#F5F5DC]", # c9 - light beige
	"E015": "[color=#0000FF]", # c10 - blue
	"E016": "[color=#00FF00]", # c11 - green
	"E017": "[color=#00FF00]", # c12 - green
	"E018": "[color=#800080]", # c13 - purple
	"E019": "[color=#800080]",  # c14 - purple
	
	# --- ICONOS ---
	"ICON PAD_X": "[img=36]res://iconos/X.png[/img]",  #boton x
	"ICON PAD_A": "[img=36]res://iconos/A.png[/img]",  #boton x
	"ICON PAD_B": "[img=36]res://iconos/B.png[/img]",  #boton x
	"ICON PAD_Y": "[img=36]res://iconos/Y.png[/img]",  #boton x
	"ICON PAD_L": "[img=36]res://iconos/L.png[/img]",  #boton x
	"ICON PAD_R": "[img=36]res://iconos/R.png[/img]",  #boton x
	"ICON PAD_CROSS": "[img=36]res://iconos/DP.png[/img]",  #boton x
	"ICON PAD_SLIDE": "[img=36]res://iconos/LS.png[/img]",  #boton x
	"ICON PAD_CROSS02": "[img=36]res://iconos/DP02.png[/img]",  #boton x
}

func _ready():
	# Inicialización: activamos el modo por defecto
	label_dialogo.bbcode_enabled = true
	label_pruebas.bbcode_enabled = true
	label_perfiles.bbcode_enabled = true
	cambiar_vista("DIALOGO")

func _on_option_button_item_selected(index):
	if index == 0:
		cambiar_vista("DIALOGO")
	elif index == 1:
		cambiar_vista("PRUEBAS")
	else:
		cambiar_vista("PERFILES")

func cambiar_vista(nueva_vista):
	if vistas.has(nueva_vista):
		vista_actual = nueva_vista
		for nombre in vistas:
			vistas[nombre].visible = (nombre == nueva_vista)
		_actualizar_previsualizacion()

func _process(_delta):
	if edit_principal and edit_principal.text != null:
		_actualizar_previsualizacion()

func _actualizar_previsualizacion():
	# Elegimos qué label actualizar basándonos en la vista actual
	var label_a_usar = labels[vista_actual]
	var texto_sucio = edit_principal.text
	var texto_final = ""
	
	var i = 0
	while i < texto_sucio.length():
		if texto_sucio[i] == "<":
			var fin = texto_sucio.find(">", i)
			if fin != -1:
				var contenido = texto_sucio.substr(i + 1, fin - i - 1).strip_edges().to_upper()
				if TAG_TRANSLATOR.has(contenido):
					texto_final += TAG_TRANSLATOR[contenido]
				i = fin
			else:
				texto_final += texto_sucio[i]
		else:
			texto_final += texto_sucio[i]
		i += 1
		
	# Aplicamos el resultado al label correcto
	label_a_usar.text = texto_final
