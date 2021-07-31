tool
extends CreationPopup
# Permite crear una nueva habitación con los archivos necesarios para que funcione
# en el Popochiu: RoomName.tscn, RoomName.gd, RoomName.tres.

const INVENTORY_ITEM_SCRIPT_TEMPLATE := \
'res://script_templates/InventoryItemTemplate.gd'
const BASE_INVENTORY_ITEM_PATH := \
'res://src/Nodes/InventoryItem/InventoryItem.tscn'

var _new_item_name := ''
var _new_item_path := ''
var _item_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: Panel) -> void:
	.set_main_dock(node)
	# Por defecto: res://src/Characters
	_item_path_template = _main_dock.inventory_items_path + '%s/Inventory%s'


func create() -> void:
	if not _new_item_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya un ítem en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# Crear el directorio donde se guardará el nuevo ítem ----------------------
	_main_dock.dir.make_dir(_main_dock.inventory_items_path + _new_item_name)

	# Crear el script del nuevo ítem -------------------------------------------
	var item_template := load(INVENTORY_ITEM_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_item_path + '.gd', item_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Crear la instancia del nuevo ítem y asignarle el script creado -----------
	var new_item: InventoryItem = preload(BASE_INVENTORY_ITEM_PATH).instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_item.set_script(load(_new_item_path + '.gd'))
	new_item.script_name = _new_item_name
	new_item.name = 'Inventory' + _new_item_name
	new_item.size_flags_horizontal = new_item.SIZE_EXPAND
	new_item.size_flags_vertical = new_item.SIZE_EXPAND
	
	# Crear el archivo de la escena --------------------------------------------
	var new_item_packed_scene: PackedScene = PackedScene.new()
	new_item_packed_scene.pack(new_item)
	if ResourceSaver.save(_new_item_path + '.tscn', new_item_packed_scene) != OK:
		push_error('No se pudo crear la escena: %s.tscn' % _new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# Crear el Resource del ítem ------------------------------------------
	var item_resource: GAQInventoryItem = GAQInventoryItem.new()
	item_resource.id = _new_item_name
	item_resource.scene = _new_item_path + '.tscn'
	item_resource.resource_name = _new_item_name
	if ResourceSaver.save(_new_item_path + '.tres',\
	item_resource) != OK:
		push_error('No se pudo crear el GAQInventoryItem del ítem: %s' %\
		_new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Agregar el ítem al Godot Adventure Quest ----------------------------
	var gaq: Node = ResourceLoader.load(_main_dock.GAQ_PATH).instance()
	gaq.inventory_items.append(ResourceLoader.load(_new_item_path + '.tres'))
	var new_gaq: PackedScene = PackedScene.new()
	new_gaq.pack(gaq)
	if ResourceSaver.save(_main_dock.GAQ_PATH, new_gaq) != OK:
		push_error('No se pudo agregar el ítem a GAQ: %s' %\
		_new_item_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	_main_dock.ei.reload_scene_from_path(_main_dock.GAQ_PATH)
	
	# Actualizar la lista de habitaciones en el Dock ---------------------------
	_main_dock.add_item_to_list(_new_item_name)

	# Abrir la escena creada en el editor --------------------------------------
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_item_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_item_path + '.tscn')
	
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_item_name = _name
		_new_item_path = _item_path_template %\
		[_new_item_name, _new_item_name]

		_info.bbcode_text = (
			'En [b]%s[/b] se crearán los archivos:\n[code]%s, %s y %s[/code]' \
			% [
				_main_dock.inventory_items_path + _new_item_name,
				'Inventory' + _new_item_name + '.tscn',
				'Inventory' + _new_item_name + '.gd',
				'Inventory' + _new_item_name + '.tres'
			])
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_item_name = ''
	_new_item_path = ''
