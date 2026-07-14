class_name GMDCrypto

# Llaves DD (v1)
const K1_DD = "fjfajfahajra;tira9tgujagjjgajgoa"
const K2_DD = "mva;eignhpe/dfkfjgp295jtugkpejfu"

# Llaves TGAA (v2)
const K1_TGAA = "e43bcc7fcab+a6c4ed22fcd433/9d2e6cb053fa462-463f3a446b19"
const K2_TGAA = "861f1dca05a0;9ddd5261e5dcc@6b438e6c.8ba7d71c*4fd11f3af1"

static func de_xor(input_data: PackedByteArray, is_v2: bool = false) -> PackedByteArray:
	var k1 = (K1_TGAA if is_v2 else K1_DD).to_ascii_buffer()
	var k2 = (K2_TGAA if is_v2 else K2_DD).to_ascii_buffer()
	
	var output = PackedByteArray()
	output.resize(input_data.size())
	
	for i in range(input_data.size()):
		output[i] = input_data[i] ^ k1[i % k1.size()] ^ k2[i % k2.size()]
	return output

# Se cambió "input" por "data_to_test" para evitar conflictos de Scope
static func _try_dexor(data_to_test: PackedByteArray, k1: PackedByteArray, k2: PackedByteArray):
	if data_to_test.size() == 0:
		return null
		
	var last_byte = data_to_test[data_to_test.size() - 1]
	var test_byte = last_byte ^ k1[(data_to_test.size() - 1) % k1.size()] ^ k2[(data_to_test.size() - 1) % k2.size()]
	
	if test_byte == 0:
		var output = PackedByteArray()
		output.resize(data_to_test.size())
		for i in range(data_to_test.size()):
			output[i] = data_to_test[i] ^ k1[i % k1.size()] ^ k2[i % k2.size()]
		return output
	return null

static func re_xor_dd(input_data: PackedByteArray) -> PackedByteArray:
	var k1 = K1_DD.to_ascii_buffer()
	var k2 = K2_DD.to_ascii_buffer()
	var output = PackedByteArray()
	output.resize(input_data.size())
	for i in range(input_data.size()):
		output[i] = input_data[i] ^ k1[i % k1.size()] ^ k2[i % k2.size()]
	return output
