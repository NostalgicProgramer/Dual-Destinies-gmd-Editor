class_name GMDParser

class GMDContentData:
	var name: String
	var entries: Array[Dictionary] = [] 

static func read_c_string(file: FileAccess) -> String:
	var bytes: PackedByteArray = PackedByteArray()
	var b = file.get_8()
	while b != 0:
		bytes.append(b)
		b = file.get_8()
	return bytes.get_string_from_ascii()

static func load_gmd(filepath: String) -> GMDContentData:
	var file = FileAccess.open(filepath, FileAccess.READ)
	file.set_big_endian(false)
	var data = GMDContentData.new()
	
	# --- 1. CABECERA ---
	file.get_buffer(4) # Magic
	var version = file.get_32()
	var language = file.get_32()
	var zero1 = file.get_64()
	var label_count = file.get_32()
	var section_count = file.get_32()
	var label_size = file.get_32()
	var section_size = file.get_32()
	var name_size = file.get_32()
	data.name = read_c_string(file)
	
	# --- 2. LEER ENTRADAS (LABELS) ---
	var label_entries = []
	for i in range(label_count):
		label_entries.append({
			"section_id": file.get_32(),
			"label_offset": file.get_32()
		})
		
	# Calculamos el min_offset para normalizar las direcciones (tu arreglo previo)
	var min_offset = 0xFFFFFFFF
	for entry in label_entries:
		if entry.label_offset < min_offset:
			min_offset = entry.label_offset
			
	# Guardamos dónde empieza el bloque de etiquetas para leer los strings
	var label_blob_start = file.get_position()
	
	# Mapeamos los Labels: ID_SECCION -> NOMBRE_LABEL
	# Usamos un diccionario para consulta rápida
	var label_map = {} 
	for entry in label_entries:
		var real_offset = entry.label_offset - min_offset
		file.seek(label_blob_start + real_offset)
		var label_name = read_c_string(file)
		
		# Si un ID de sección tiene múltiples labels, esto guarda el último encontrado
		label_map[entry.section_id] = label_name
	
	# --- 3. LEER TEXTOS (Tu lógica original que funcionaba) ---
	# Saltamos al inicio del bloque de texto
	# La fórmula del seek es la suma de todo lo anterior
	file.seek(0x28 + (name_size + 1) + (label_count * 0x8) + label_size)
	var encrypted_text = file.get_buffer(section_size)
	var decrypted_text = GMDCrypto.de_xor(encrypted_text)
	
	var text_offset = 0
	for i in range(section_count):
		# Encontrar el fin del string actual (null terminator)
		var text_end = text_offset
		while text_end < decrypted_text.size() and decrypted_text[text_end] != 0:
			text_end += 1
			
		var section_bytes = decrypted_text.slice(text_offset, text_end)
		var text_string = section_bytes.get_string_from_utf8()
		text_string = text_string.replace("\n", "\r\n")
		
		text_offset = text_end + 1
		
		# --- 4. INTEGRACIÓN ---
		# Buscamos en nuestro mapa si existe un label para este section_id (i)
		var label_name = label_map.get(i, "no_name_%03d" % i)
		
		data.entries.append({
			"label": label_name,
			"section_id": i,
			"text": text_string
		})
		
	file.close()
	return data

# Guardado estricto GMDv1 (Dual Destinies)
static func save_gmd(filepath: String, data: GMDContentData):
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	file.set_big_endian(false)
	
	# 1. Preparar Text Blob
	var text_blob_bytes = PackedByteArray()
	for entry in data.entries:
		# Convertimos de vuelta para asegurar el formato que espera el motor
		var text_str = entry.text.replace("\r\n", "\n")
		text_blob_bytes.append_array(text_str.to_utf8_buffer())
		text_blob_bytes.append(0) 
		
	# Usamos el método de encriptación específico para DD (Key 0)
	var encrypted_text = GMDCrypto.re_xor_dd(text_blob_bytes) 
	
	# 2. Preparar Etiquetas y Punteros
	var label_blob_bytes = PackedByteArray()
	var total_label_count = data.entries.size() 
	var label_entries = []
	var current_label_offset = 0
	
	# En DD, cada sección tiene su etiqueta (o "no_name"), por eso iteramos todo
	for i in range(data.entries.size()):
		var entry = data.entries[i]
		
		# La constante 0x29080170 es crítica para la lectura en memoria del motor de DD
		var magic_base = 0x29080170 + (total_label_count * 0x80)
		
		label_entries.append({
			"section_id": i,
			"label_offset": current_label_offset + magic_base
		})
		
		label_blob_bytes.append_array(entry.label.to_ascii_buffer())
		label_blob_bytes.append(0)
		current_label_offset += entry.label.length() + 1
			
	# 3. Escribir Header
	file.store_buffer(PackedByteArray([0x47, 0x4D, 0x44, 0x00])) # "GMD\0"
	file.store_32(0x00010201) # Versión v1 (DD)
	file.store_32(1) # Idioma (English)
	file.store_64(0) 
	file.store_32(total_label_count) # Cantidad total de etiquetas
	file.store_32(data.entries.size()) # Cantidad total de secciones
	file.store_32(label_blob_bytes.size())
	file.store_32(encrypted_text.size())
	file.store_32(data.name.length())
	
	# Nombre del archivo (ej: "mes_script")
	file.store_buffer(data.name.to_ascii_buffer())
	file.store_8(0)
	
	# 4. Escribir Punteros
	for e in label_entries:
		file.store_32(e.section_id)
		file.store_32(e.label_offset)
		
	# 5. Escribir Bloques finales
	file.store_buffer(label_blob_bytes)
	file.store_buffer(encrypted_text)
	
	file.close()
