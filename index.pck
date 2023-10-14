GDPC                P                                                                         X   res://.godot/exported/133200997/export-22c13d1a1a989d1d94a1054af995216c-ratlantis.scn   �%     �      ��N��YP��3��0�(�    X   res://.godot/exported/133200997/export-7a81085f9621e04a1721a461abb0c25f-rat_player.scn   -     @      rD2����e�    X   res://.godot/exported/133200997/export-e2d8c9f711c5cfdaac13d86df2cf34d0-game_level.scn  ��           /\�tKЏ�v�Z�=i    ,   res://.godot/global_script_class_cache.cfg  �:            ��Р�8���8~$}P�    L   res://.godot/imported/Ratlantis.tmx-35dd9ff52da71aaa44380dbbc6ae6ad5.tscn   �     �>      �~B� "nq"6��9�    P   res://.godot/imported/sewerstilemap.png-c162c4dc34f68b3134457be9226bfe0c.ctex   `1     �      .X���}�(��C���    H   res://.godot/imported/tinyrat.png-bc216ad82c427405e7ce560906b19528.ctex �7     �       (;5�6KT>1+;�k�S       res://.godot/uid_cache.bin  �:     �       #-�&Z��h��J�]       res://Ratlantis.tmx.import   %     �       I�&��m��ELN� }    (   res://addons/YATI/DictionaryBuilder.gd          �	      B�Kt[>��aI;u	c�    (   res://addons/YATI/DictionaryFromXml.gd  �	      *      �x�b������?�        res://addons/YATI/Importer.gd   �&      $      z�;.P����>C    $   res://addons/YATI/PostProcessing.gd �:      {      E�d��w�����        res://addons/YATI/TiledImport.gdpC      |      ��B� ^tN��`��    $   res://addons/YATI/TilemapCreator.gd �H      z     �4M(���P:�\�@�i    $   res://addons/YATI/TilesetCreator.gd p`     @y      ���Ժ;Q���iW�\    $   res://addons/YATI/XmlParserCtrl.gd  ��     9	      $IB8�
�ۗ�S\�ep       res://game_level.tscn.remap `9     g       �pb! ���]�-i�       res://project.binary�;     �      Q�)"/3t#���관�O       res://rat_player.gd @(     �      �b����	���z��1       res://rat_player.tscn.remap @:     g       ���Ⱥ
�l��&�        res://ratlantis.tscn.remap  �9     f       q`�=(��T�����        res://sewerstilemap.png.import  �6     �       �u�RM�c�`U��$�       res://tinyrat.png.import�8     �       �U��vL
v����<    �?�ę�I�# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

enum FileType {
	Xml,
	Json,
	Unknown
}

func get_dictionary(source_file: String):
	var checked_file = source_file
	if !FileAccess.file_exists(checked_file):
		checked_file = source_file.get_base_dir().path_join(source_file)
		if !FileAccess.file_exists(checked_file):
			printerr("ERROR: File '" + source_file + "' not found. -> Continuing but result may be unusable")
			return null

	var type = FileType.Unknown
	var extension = source_file.get_file().get_extension()
	if ["tmx", "tsx", "xml", "tx"].find(extension) >= 0:
		type = FileType.Xml
	elif ["tmj", "tsj", "json", "tj"].find(extension) >= 0:
		type = FileType.Json
	else:
		var file = FileAccess.open(checked_file, FileAccess.READ)
		var chunk = file.get_buffer(12)
		if chunk.starts_with("<?xml "):
			type = FileType.Xml
		elif chunk.starts_with("{ \""):
			type = FileType.Json
		file.close()

	match type:
		FileType.Xml:
			var dict_builder = preload("DictionaryFromXml.gd").new()
			return dict_builder.create(checked_file)
		FileType.Json:
			var json = JSON.new()
			var file = FileAccess.open(checked_file, FileAccess.READ)
			if json.parse(file.get_as_text()) == OK:
				return json.data
		FileType.Unknown:
			printerr("ERROR: File '" + source_file + "' has an unknown type. -> Continuing but result may be unusable")

	return null
�M �# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

var _xml = preload("XmlParserCtrl.gd").new()
var _current_element = ""
var _result = {}
var _current_dictionary = _result
var _current_array = []
var _csv_encoded = true
var _is_map: bool
var _in_tileset: bool = false

func create(source_file_name: String):
	var err = _xml.open(source_file_name)
	if err != OK:
		return null

	_current_element = _xml.next_element()
	_current_dictionary = _result
	var base_attributes = _xml.get_attributes()

	_current_dictionary["type"] = _current_element
	insert_attributes(_current_dictionary, base_attributes)
	_is_map = _current_element == "map"

	var base_element = _current_element
	while (err == OK and (not _xml.is_end() or _current_element != base_element)):
		_current_element = _xml.next_element()
		if _current_element == null:
			err = ERR_PARSE_ERROR
			break
		if _xml.is_end():
			continue
		var c_attributes = _xml.get_attributes()
		var dictionary_bookmark = _current_dictionary
		if _xml.is_empty():
			err = simple_element(_current_element, c_attributes)
		else:
			err = nested_element(_current_element, c_attributes)
		_current_dictionary = dictionary_bookmark

	if err == OK:
		return _result
	else:
		print("Import aborted with ", err, " error.")
		return null

func simple_element(element_name: String, attribs: Dictionary) -> int:
	if element_name == "image":
		_current_dictionary["image"] = attribs["source"]
		if attribs.has("width"):
			_current_dictionary["imagewidth"] = int(attribs["width"])
		if attribs.has("height"):
				_current_dictionary["imageheight"] = int(attribs["height"])
		if attribs.has("trans"):
			_current_dictionary["transparentcolor"] = attribs["trans"]
		return OK
	if element_name == "wangcolor":
		element_name = "color"
	if element_name == "point":
		_current_dictionary["point"] = true
		return OK
	if element_name == "ellipse":
		_current_dictionary["ellipse"] = true
		return OK

	var dict_key = element_name
	if (element_name == "objectgroup" and (not _is_map or _in_tileset)) or (element_name == "text") or (element_name == "tileoffset") or (element_name == "grid"):
		# Create a single dictionary, not an array.
		_current_dictionary[dict_key] = {}
		_current_dictionary = _current_dictionary[dict_key]
		if attribs.size() > 0:
			insert_attributes(_current_dictionary, attribs)
	else:
		if dict_key == "polygon" or dict_key == "polyline":
			var arr = []
			for pt in attribs["points"].split(" "):
				var dict = {}
				var x = float(pt.split(",")[0])
				var y = float(pt.split(",")[1])
				dict["x"] = x
				dict["y"] = y
				arr.append(dict)
			_current_dictionary[dict_key] = arr
		elif dict_key == "frame" or dict_key == "property":
			# i.e. will be part of the superior array (animation or properties)
			var dict = {}
			insert_attributes(dict, attribs)
			_current_array.append(dict)
		else:
			if dict_key == "objectgroup" or dict_key == "imagelayer":
				# to be later added to the layer attributes (by insert_attributes)
				attribs["type"] = dict_key
				dict_key = "layer"
			if dict_key == "group":
				# Add nested layers array
				attribs["type"] = "group"
				if _current_dictionary.has("layers"):
					_current_array = _current_dictionary["layers"]
				else:
					_current_array = []
					_current_dictionary["layers"] = _current_array
				dict_key = "layer"
			if dict_key != "animation" and dict_key != "properties":
				dict_key = dict_key + "s"
			if _current_dictionary.has(dict_key):
				_current_array = _current_dictionary[dict_key]
			else:
				_current_array = []
				_current_dictionary[dict_key] = _current_array
			if dict_key != "animation" and dict_key != "properties":
				_current_dictionary = {}
				_current_array.append(_current_dictionary)
			if dict_key == "wangtiles":
				_current_dictionary["tileid"] = int(attribs["tileid"])
				var arr = []
				for s in attribs["wangid"].split(","):
					arr.append(int(s))
				_current_dictionary["wangid"] = arr
			else:
				if attribs.size() > 0:
					insert_attributes(_current_dictionary, attribs)
	return OK        


func nested_element(element_name: String, attribs: Dictionary):
	var err = OK
	if element_name == "wangsets":
		return OK
	elif element_name == "data":
		_current_dictionary["type"] = "tilelayer"
		if attribs.has("encoding"):
			_current_dictionary["encoding"] = attribs["encoding"]
			_csv_encoded = attribs["encoding"] == "csv"
		if attribs.has("compression"):
			_current_dictionary["compression"] = attribs["compression"]
		return OK
	elif element_name == "tileset":
		_in_tileset = true
	var dictionary_bookmark_1 = _current_dictionary
	var array_bookmark_1 = _current_array
	err = simple_element(element_name, attribs)
	var base_element = _current_element
	while err == OK and (_xml.is_end() == false or (_current_element != base_element)):
		_current_element = _xml.next_element()
		if _current_element == null:
			return ERR_PARSE_ERROR
		if _xml.is_end():
			continue
		if _current_element == "<data>":
			var data = _xml.get_data()
			if base_element == "text" or base_element == "property":
				_current_dictionary[base_element] = str(data);
			else:
				data = data.strip_edges(true, true)
				if _csv_encoded:
					var arr = []
					for s in data.split(','):
						arr.append(int(s.strip_edges(true, true)))
					data = arr
				_current_array[-1]["data"] = data
			continue
		var c_attributes = _xml.get_attributes()
		var dictionary_bookmark_2 = _current_dictionary
		var array_bookmark_2 = _current_array
		if _xml.is_empty():
			err = simple_element(_current_element, c_attributes)
		else:
			err = nested_element(_current_element, c_attributes)
		_current_dictionary = dictionary_bookmark_2
		_current_array = array_bookmark_2

	_current_dictionary = dictionary_bookmark_1
	_current_array = array_bookmark_1
	if base_element == "tileset":
		_in_tileset = false
	return err
	
func insert_attributes(target_dictionary: Dictionary, attribs: Dictionary):
	for key in attribs:
		var attr_val: Variant
		if key == "infinite":
			attr_val = attribs[key] == "1"
		elif key == "visible":
			attr_val = attribs[key] == "1"
		elif key == "wrap":
			attr_val = attribs[key] == "1"
		else:
			attr_val = attribs[key]
		
		if "version" not in key:
			if str(attr_val).is_valid_int():
				attr_val = int(attr_val)
			elif str(attr_val).is_valid_float():
				attr_val = float(attr_val)

		target_dictionary[key] = attr_val
w�\�h# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "YATI"

func _get_visible_name() -> String:
	return "Import from Tiled"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["tmx", "tmj"])

func _get_resource_type() -> String:
	return "PackedScene"

func _get_save_extension() -> String:
	return "tscn"
	
func _get_priority() -> float:
	return 0.1
	
func _get_preset_count() -> int:
	return 0

func _get_preset_name(preset_index: int) -> String:
	return ""

func _get_import_options(path: String, preset_index: int) -> Array:
	return [
		{ "name": "use_tilemap_layers", "default_value": false },
		{ "name": "use_default_filter", "default_value": false },
		{ "name": "add_class_as_metadata", "default_value": false },
		{ "name": "map_wangset_to_terrain", "default_value": false },
		{ "name": "post_processor", "default_value": "", "property_hint": PROPERTY_HINT_FILE, "hint_string": "*.gd;GDScript" },
		{ "name": "save_tileset_to", "default_value": "", "property_hint": PROPERTY_HINT_SAVE_FILE, "hint_string": "*.tres;Resource File" }
	]

func _get_import_order() -> int:
	return 99

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array):
	print("Import file '" + source_file + "'")
	if !FileAccess.file_exists(source_file):
		printerr("Import file '" + source_file + "' not found!")
		return ERR_FILE_NOT_FOUND

	var tilemapCreator = preload("TilemapCreator.gd").new()
	if options["use_tilemap_layers"] == false:
		tilemapCreator.set_map_layers_to_tilemaps(true)
	if options["use_default_filter"] == true:
		tilemapCreator.set_use_default_filter(true)
	if options["add_class_as_metadata"] == true:
		tilemapCreator.set_add_class_as_metadata(true)
	if options["map_wangset_to_terrain"] == true:
		tilemapCreator.set_map_wangset_to_terrain(true)
	var node2D = tilemapCreator.create(source_file)
	if node2D == null:
		return FAILED

	var errors = tilemapCreator.get_error_count()
	var warnings = tilemapCreator.get_warning_count()
	if options.has("save_tileset_to") and options["save_tileset_to"] != "":
		var tile_set = tilemapCreator.get_tileset()
		var save_ret = ResourceSaver.save(tile_set, options["save_tileset_to"])
		if save_ret == OK:
			print("Successfully saved tileset to '" + options["save_tileset_to"] + "'")
		else:
			printerr("Saving tileset returned error " + str(save_ret))
			errors += 1

	var post_proc_error = false
	if options.has("post_processor") and options["post_processor"] != "":
		var post_proc = preload("PostProcessing.gd").new()
		node2D = post_proc.call_post_process(node2D, options["post_processor"])
		post_proc_error = post_proc.get_error() != OK

	var packed_scene = PackedScene.new()
	packed_scene.pack(node2D)
	# return ResourceSaver.save(packed_scene, source_file.get_basename() + "." + _get_save_extension())
	var ret = ResourceSaver.save(packed_scene, save_path + "." + _get_save_extension())
	# v1.5.3: Copying no longer necessary, leave that to Godot's "Please confirm..." dialog box
	#if ret == OK:
	#	var dir = DirAccess.open(source_file.get_basename().get_base_dir())
	#	ret = dir.copy(save_path + "." + _get_save_extension(), source_file.get_basename() + "." + _get_save_extension())
	if ret == OK:
		var final_message_string = "Import succeeded."
		if post_proc_error:
			final_message_string = "Import finished."
		if errors > 0 or warnings > 0:
			final_message_string = "Import finished with "
			if errors > 0:
				final_message_string += str(errors) + " error"
			if errors > 1:
				final_message_string += "s"
			if warnings > 0:
				if errors > 0:
					final_message_string += " and "
				final_message_string += str(warnings) + " warning"
				if warnings > 1:
					final_message_string += "s"
			final_message_string += "."
		print(final_message_string)
		if post_proc_error:
			print("Postprocessing was skipped due to some error.")
	return ret
�޼g`��u|4�{# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

var _error: Error = OK

func get_error():
    return _error

func call_post_process(base_node: Node2D, path: String):
    var script = load(path)
    if script == null or not script is GDScript:
        printerr("Script could not be properly recognized/loaded. -> Postprocessing skipped")
        _error = ERR_FILE_UNRECOGNIZED
        return base_node
    var script_obj = script.new()
    if script_obj == null:
        printerr("Script could not be instanciated. -> Postprocessing skipped")
        _error = ERR_SCRIPT_FAILED
        return base_node
    if not script_obj.has_method("_post_process"):
        printerr("Script has no method '_post_process'. -> Postprocessing skipped")
        _error = ERR_METHOD_NOT_FOUND
        return base_node
    var returned_node = script_obj._post_process(base_node)
    if returned_node == null or not returned_node is Node2D:
        printerr("Script returned invalid data. -> Postprocessing skipped")
        _error = ERR_INVALID_DATA
        return base_node
    return returned_node���L# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorPlugin

var _xmlImport = null

func _get_plugin_name() -> String:
	return "Yet another Tiled importer"

func _enter_tree():
	_xmlImport = preload("Importer.gd").new()
	add_import_plugin(_xmlImport)

func _exit_tree():
	remove_import_plugin(_xmlImport)
	_xmlImport = null
rP�# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG = 0x40000000
const FLIPPED_DIAGONALLY_FLAG = 0x20000000

const BACKGROUND_COLOR_RECT_NAME = "Background Color"
const WARNING_COLOR = "Yellow"
const CUSTOM_DATA_INTERNAL = "__internal__"
const GODOT_NODE_TYPE_PROPERTY = "godot_node_type"
const GODOT_GROUP_PROPERTY = "godot_group"
const DEFAULT_ALIGNMENT = "unspecified"

var _map_orientation: String
var _map_width: int = 0
var _map_height: int = 0
var _map_tile_width: int = 0
var _map_tile_height: int = 0
var _infinite = false
var _parallax_origin_x: int = 0
var _parallax_origin_y: int = 0
var _background_color = ""

var _tilemap = null
var _tilemap_offset_x: float = 0.0
var _tilemap_offset_y: float = 0.0
var _tileset = null
var _current_tileset_orientation: String
var _current_object_alignment: String
var _base_node = null
var _parallax_background = null
var _background = null
var _parallax_layer_existing = false

var _base_path = ""
var _base_name = ""
var _encoding = ""
var _compression = ""
var _map_layers_to_tilemaps = false
var _tm_layer_counter: int = 0
var _first_gids = []
var _atlas_sources = null
var _use_default_filter = false
var _map_wangset_to_terrain = false
var _add_class_as_metadata = false
var _object_groups

var _iso_rot: float = 0.0
var _iso_skew: float = 0.0
var _iso_scale: Vector2

var _error_count = 0
var _warning_count = 0

enum _godot_type {
	EMPTY,
	BODY,
	CBODY,
	RBODY,
	AREA,
	NAVIGATION,
	OCCLUDER,
	LINE,
	PATH,
	POLYGON,
	INSTANCE,
	UNKNOWN
}


func custom_compare(a: Dictionary, b: Dictionary):
	return a["sourceId"] < b["sourceId"]


func get_error_count():
	return _error_count


func get_warning_count():
	return _warning_count
	

func set_map_layers_to_tilemaps(value: bool):
	_map_layers_to_tilemaps = value


func set_use_default_filter(value: bool):
	_use_default_filter = value


func set_add_class_as_metadata(value: bool):
	_add_class_as_metadata = value


func set_map_wangset_to_terrain(value: bool):
		_map_wangset_to_terrain = value
	
	
func get_tileset():
	return _tileset


func create(source_file: String):
	_base_path = source_file.get_base_dir()
	var base_dictionary = preload("DictionaryBuilder.gd").new().get_dictionary(source_file)
	_map_orientation = base_dictionary.get("orientation", "othogonal")
	_map_width = base_dictionary.get("width", 0)
	_map_height = base_dictionary.get("height", 0)
	_map_tile_width = base_dictionary.get("tilewidth", 0)
	_map_tile_height = base_dictionary.get("tileheight", 0)
	_infinite = base_dictionary.get("infinite", false)
	_parallax_origin_x = base_dictionary.get("parallaxoriginx", 0)
	_parallax_origin_y = base_dictionary.get("parallaxoriginy", 0)
	_background_color = base_dictionary.get("backgroundcolor", "")

	if base_dictionary.has("tilesets"):
		var tilesets = base_dictionary["tilesets"]
		for tileSet in tilesets:
			_first_gids.append(int(tileSet["firstgid"]))
		var tileset_creator = preload("TilesetCreator.gd").new()
		tileset_creator.set_base_path(source_file)
		tileset_creator.set_map_parameters(Vector2i(_map_tile_width, _map_tile_height))
		if _map_wangset_to_terrain:
			tileset_creator.map_wangset_to_terrain()
		_tileset = tileset_creator.create_from_dictionary_array(tilesets)
		_error_count = tileset_creator.get_error_count()
		_warning_count = tileset_creator.get_warning_count()
		_atlas_sources = tileset_creator.get_registered_atlas_sources()
		_atlas_sources.sort_custom(custom_compare)
		_object_groups = tileset_creator.get_registered_object_groups()
	if _tileset == null:
		# If tileset still null create an empty one
		_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(_map_tile_width, _map_tile_height)
	match _map_orientation:
		"isometric":
			_tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
			_tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
		"staggered":
			var stagger_axis = base_dictionary.get("staggeraxis", "y")
			var stagger_index = base_dictionary.get("staggerindex", "odd")
			_tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
			_tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED if stagger_index == "odd" else TileSet.TILE_LAYOUT_STACKED_OFFSET
			_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL if stagger_axis == "x" else TileSet.TILE_OFFSET_AXIS_HORIZONTAL
		"hexagonal":
			var stagger_axis = base_dictionary.get("staggeraxis", "y")
			var stagger_index = base_dictionary.get("staggerindex", "odd")
			_tileset.tile_shape = TileSet.TILE_SHAPE_HEXAGON
			_tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED if stagger_index == "odd" else TileSet.TILE_LAYOUT_STACKED_OFFSET
			_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL if stagger_axis == "x" else TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	
	_tm_layer_counter = 0

	_base_node = Node2D.new()
	_base_name = source_file.get_file().get_basename()
	_base_node.name = _base_name
	_parallax_background = ParallaxBackground.new()
	_base_node.add_child(_parallax_background)
	_parallax_background.name = _base_name + " (PBG)"
	_parallax_background.owner = _base_node
	if _background_color != "":
		_background = ColorRect.new()
		_background.color = Color(_background_color)
		_background.size = Vector2(_map_width * _map_tile_width, _map_height * _map_tile_height)
		_base_node.add_child(_background)
		_background.name = BACKGROUND_COLOR_RECT_NAME
		_background.owner = _base_node
	
	if base_dictionary.has("layers"):
		for layer in base_dictionary["layers"]:
			handle_layer(layer, _base_node)

	if base_dictionary.has("properties"):
		handle_properties(_base_node, base_dictionary["properties"], true)

	if _parallax_background.get_child_count() == 0:
		_base_node.remove_child(_parallax_background)

	# Remove internal helper custom data
	if _tileset.get_custom_data_layers_count() > 0:
		_tileset.remove_custom_data_layer(0)

	if _base_node.get_child_count() > 1: return _base_node

	var ret = _base_node.get_child(0)
	if base_dictionary.has("properties"):
		handle_properties(ret, base_dictionary["properties"], true)
	ret.name = _base_name
	return ret


func handle_layer(layer: Dictionary, parent: Node2D):
	var layer_offset_x = layer.get("offsetx", 0)
	var layer_offset_y = layer.get("offsety", 0)
	var layer_opacity = layer.get("opacity", 1.0)
	var layer_visible = layer.get("visible", true)
	_encoding = layer.get("encoding", "csv")
	_compression = layer.get("compression", "")
	var layer_type = layer.get("type", "tilelayer")
	var tint_color = layer.get("tintcolor", "#ffffff")

	# v1.2: Skip layer
	if get_property(layer, "no_import", "bool") == "true":
		return

	if layer_type != "tilelayer" and not _map_layers_to_tilemaps:
		_tilemap = null
		_tm_layer_counter = 0

	if layer_type == "tilelayer":
		if _map_orientation == "isometric":
			layer_offset_x += _map_tile_width * (_map_height / 2.0 - 0.5)
		var layer_name = str(layer["name"])
		if _map_layers_to_tilemaps:
			_tilemap = TileMap.new()
			if layer_name != "":
				_tilemap.name = layer_name
			_tilemap.visible = layer_visible
			if layer_offset_x > 0 or layer_offset_y > 0:
				_tilemap.position = Vector2(layer_offset_x, layer_offset_y)
			if layer_opacity < 1.0 or tint_color != "#ffffff":
				_tilemap.modulate = Color(tint_color, layer_opacity)
			_tilemap.tile_set = _tileset
			handle_parallaxes(parent, _tilemap, layer)
			if _map_orientation == "isometric" or _map_orientation == "staggered":
				_tilemap.y_sort_enabled = true
				_tilemap.set_layer_y_sort_enabled(0, true)
		else:
			if _tilemap == null:
				_tilemap = TileMap.new()
				if layer_name != "":
					_tilemap.name = layer_name
				_tilemap.remove_layer(0)
				handle_parallaxes(parent, _tilemap, layer)
				_tilemap_offset_x = layer_offset_x
				_tilemap_offset_y = layer_offset_y
				_tilemap.position = Vector2(layer_offset_x, layer_offset_y)
				if _map_orientation == "isometric" or _map_orientation == "staggered":
					_tilemap.y_sort_enabled = true
			elif layer_name != "":
				_tilemap.name += "|" + layer_name
			if _tilemap.tile_set == null:
				_tilemap.tile_set = _tileset 
			_tilemap.add_layer(_tm_layer_counter)
			_tilemap.set_layer_name(_tm_layer_counter, layer_name)
			_tilemap.set_layer_enabled(_tm_layer_counter, layer_visible)
			if _map_orientation == "isometric" or _map_orientation == "staggered":
				_tilemap.set_layer_y_sort_enabled(_tm_layer_counter, true)
			if abs(layer_offset_x -_tilemap_offset_x) > 0.01 or abs(layer_offset_y - _tilemap_offset_y) > 0.01:
				print_rich("[color="+WARNING_COLOR+"]Godot 4 has no tilemap layer offsets -> switch off 'use_tilemap_layers'[/color]")
				_warning_count += 1
			if layer_opacity < 1.0 or tint_color != "#ffffff":
				_tilemap.set_layer_modulate(_tm_layer_counter, Color(tint_color, layer_opacity))

		if not _use_default_filter:
			_tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if _infinite and layer.has("chunks"):
			# Chunks
			for chunk in layer["chunks"]:
				var offset_x = int(chunk["x"])
				var offset_y = int(chunk["y"])
				var chunk_width = int(chunk["width"])
				var chunk_height = int(chunk["height"])
				var chunk_data = handle_data(chunk["data"], chunk_width * chunk_height)
				if chunk_data != null:
					create_map_from_data(chunk_data, offset_x, offset_y, chunk_width)

		elif layer.has("data"):
			# Data
			var data = handle_data(layer["data"], _map_width * _map_height)
			if data != null:
				create_map_from_data(data, 0, 0, _map_width)

		if layer.has("properties"):
			handle_properties(_tilemap, layer["properties"])

		if not _map_layers_to_tilemaps:
			_tm_layer_counter += 1

	elif layer_type == "objectgroup":
		var layer_node = Node2D.new()
		handle_parallaxes(parent, layer_node, layer)
		
		if "name" in layer:
			layer_node.name = layer["name"]
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			layer_node.modulate = Color(tint_color, layer_opacity)
		layer_node.visible = layer.get("visible", true)
		var layer_pos_x = layer.get("x", 0.0)
		var layer_pos_y = layer.get("y", 0.0)
		layer_node.position = Vector2(layer_pos_x + layer_offset_x, layer_pos_y + layer_offset_y)
		if not _use_default_filter:
			layer_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _map_orientation == "isometric" or _map_orientation == "staggered":
			layer_node.y_sort_enabled = true

		if layer.has("objects"):
			for obj in layer["objects"]:
				handle_object(obj, layer_node, _tileset, Vector2.ZERO)

		if layer.has("properties"):
			handle_properties(layer_node, layer["properties"])

	elif layer_type == "group":
		var group_node = Node2D.new()
		handle_parallaxes(parent, group_node, layer)
		group_node.name = layer.get("name", "group")
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			group_node.modulate = Color(tint_color, layer_opacity)
		group_node.visible = layer.get("visible", true)
		var layer_pos_x = layer.get("x", 0.0)
		var layer_pos_y = layer.get("y", 0.0)
		group_node.position = Vector2(layer_pos_x + layer_offset_x, layer_pos_y + layer_offset_y)
	
		for child_layer in layer["layers"]:
			handle_layer(child_layer, group_node)

		if layer.has("properties"):
			handle_properties(group_node, layer["properties"])

	elif layer_type == "imagelayer":
		var texture_rect = TextureRect.new()
		handle_parallaxes(parent, texture_rect, layer)

		texture_rect.name = layer.get("name", "image")
		texture_rect.position = Vector2(layer_offset_x, layer_offset_y)

		var imagewidth = layer.get("imagewidth", 0)
		var imageheight = layer.get("imageheight", 0)
		texture_rect.size = Vector2(imagewidth, imageheight)
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			texture_rect.modulate = Color(tint_color, layer_opacity)
		texture_rect.visible = layer_visible

		# ToDo: Not sure if this first check makes any sense since an image can't be imported properly if not in project tree
		var texture_path = layer["image"]
		if not FileAccess.file_exists(texture_path):
			texture_path = _base_path.get_base_dir().path_join(layer["image"])
		if not FileAccess.file_exists(texture_path):
			texture_path = _base_path.path_join(layer["image"])
		if FileAccess.file_exists(texture_path):
			texture_rect.texture = load(texture_path)
			var exists = ResourceLoader.exists(texture_path, "Image")
			if exists:
				texture_rect.texture = load(texture_path)
			else:
				var image = Image.load_from_file(texture_path)
				texture_rect.texture = ImageTexture.create_from_image(image)
		else:
			printerr("ERROR: Image file '" + layer["image"] + "' not found.")
			_error_count += 1

		if layer.has("properties"):
			handle_properties(texture_rect, layer["properties"])

func handle_parallaxes(parent: Node, layer_node: Node, layer_dict: Dictionary):
	if layer_dict.has("parallaxx") or layer_dict.has("parallaxy"):
		if not _parallax_layer_existing:
			if _background != null:
				_background.reparent(_parallax_background)
			_parallax_layer_existing = true
	
		var par_x = layer_dict.get("parallaxx", 0.0)
		var par_y = layer_dict.get("parallaxy", 0.0)
		var parallax_node = ParallaxLayer.new()
		_parallax_background.add_child(parallax_node)
		parallax_node.owner = _base_node
		var px_name = layer_dict.get("name", "")
		parallax_node.name = px_name + " (PL)" if px_name != "" else "ParallaxLayer"
		parallax_node.motion_scale = Vector2(par_x, par_y)
		parallax_node.add_child(layer_node)
		layer_node.owner = _base_node
	else:
		parent.add_child(layer_node)
		layer_node.owner = _base_node


func handle_data(data, map_size):
	var ret: Array = []
	match _encoding:
		"csv":
			for cell in data:
				ret.append(cell)
		"base64":
			var bytes = Marshalls.base64_to_raw(data)
			if _compression != "":
				match _compression:
					"gzip":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_GZIP)
					"zlib":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_DEFLATE)
					"zstd":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_ZSTD)
					_:
						printerr("Decompression for type '" + _compression + "' not yet implemented.")
						_error_count += 1
						return []
				bytes = PackedByteArray(ret)
			ret = bytes.to_int32_array()	
	return ret


func create_polygons_on_alternative_tiles(source_data: TileData, target_data: TileData, alt_id: int):
	var flipped_h = (alt_id & 1) > 0
	var flipped_v = (alt_id & 2) > 0
	var flipped_d = (alt_id & 4) > 0
	var origin = Vector2(source_data.texture_origin)
	var physics_layers_count = _tileset.get_physics_layers_count()
	for layer_id in range(physics_layers_count):
		var collision_polygons_count = source_data.get_collision_polygons_count(layer_id)
		for polygon_id in range(collision_polygons_count):
			var pts = source_data.get_collision_polygon_points(layer_id, polygon_id)
			var pts_new: PackedVector2Array
			var i = 0
			for pt in pts:
				pts_new.append(pt+origin)
				if flipped_d:
					var tmp = pts_new[i].x
					pts_new[i].x = pts_new[i].y
					pts_new[i].y = tmp
				if flipped_h:
					pts_new[i].x = -pts_new[i].x
				if flipped_v:
					pts_new[i].y = -pts_new[i].y
				pts_new[i] -= Vector2(target_data.texture_origin)
				i += 1
			target_data.add_collision_polygon(layer_id)
			target_data.set_collision_polygon_points(layer_id, polygon_id, pts_new)
	var navigation_layers_count = _tileset.get_navigation_layers_count()
	for layer_id in range(navigation_layers_count):
		var nav_p = source_data.get_navigation_polygon(layer_id)
		if nav_p == null: continue
		var pts = nav_p.get_outline(0)
		var pts_new: PackedVector2Array
		var i = 0
		for pt in pts:
			pts_new.append(pt+origin)
			if flipped_d:
				var tmp = pts_new[i].x
				pts_new[i].x = pts_new[i].y
				pts_new[i].y = tmp
			if flipped_h:
				pts_new[i].x = -pts_new[i].x
			if flipped_v:
				pts_new[i].y = -pts_new[i].y
			pts_new[i] -= Vector2(target_data.texture_origin)
			i += 1
		var navigation_polygon = NavigationPolygon.new()
		navigation_polygon.add_outline(pts_new)
		navigation_polygon.make_polygons_from_outlines()
		target_data.set_navigation_polygon(layer_id, navigation_polygon)
	var occlusion_layers_count = _tileset.get_occlusion_layers_count()
	for layer_id in range(occlusion_layers_count):
		var occ = source_data.get_occluder(layer_id)
		if occ == null: continue
		var pts = occ.polygon
		var pts_new: PackedVector2Array
		var i = 0
		for pt in pts:
			pts_new.append(pt+origin)
			if flipped_d:
				var tmp = pts_new[i].x
				pts_new[i].x = pts_new[i].y
				pts_new[i].y = tmp
			if flipped_h:
				pts_new[i].x = -pts_new[i].x
			if flipped_v:
				pts_new[i].y = -pts_new[i].y
			pts_new[i] -= Vector2(target_data.texture_origin)
			i += 1
		var occluder_polygon = OccluderPolygon2D.new()
		occluder_polygon.polygon = pts_new
		target_data.set_occluder(layer_id, occluder_polygon)
		

func create_map_from_data(layer_data: Array, offset_x: int, offset_y: int, map_width: int):
	var cell_counter: int = -1
	for cell in layer_data:
		cell_counter += 1
		var int_id: int = int(cell) & 0xFFFFFFFF
		var flipped_h = (int_id & FLIPPED_HORIZONTALLY_FLAG) > 0
		var flipped_v = (int_id & FLIPPED_VERTICALLY_FLAG) > 0
		var flipped_d = (int_id & FLIPPED_DIAGONALLY_FLAG) > 0
		var gid: int = int_id & 0x0FFFFFFF
		if gid <= 0: continue
		var cell_coords = Vector2(cell_counter % map_width + offset_x, cell_counter / map_width + offset_y)

		var source_id = get_matching_source_id(gid)
		var tile_offset = get_tile_offset(gid)
		var first_gid_id = get_first_gid_index(gid)
		if first_gid_id > source_id:
			source_id = first_gid_id
		# Should not be the case, but who knows...
		if source_id < 0: continue

		var atlas_source
		if _tileset.has_source(source_id):
			atlas_source = _tileset.get_source(source_id)
		else: continue
		var atlas_width: int = atlas_source.get_atlas_grid_size().x
		if atlas_width <= 0: continue

		var effective_gid: int = gid - _first_gids[get_first_gid_index(gid)]
		var atlas_coords = Vector2i.ZERO
		if get_num_tiles_for_source_id(source_id) > 1:
			if atlas_source.get_atlas_grid_size() == Vector2i.ONE:
				atlas_coords = Vector2i.ZERO
			else:
				atlas_coords = Vector2(effective_gid % atlas_width, effective_gid / atlas_width)
		if not atlas_source.has_tile(atlas_coords):
			atlas_source.create_tile(atlas_coords)
			var current_tile = atlas_source.get_tile_data(atlas_coords, 0)
			var tile_size = atlas_source.texture_region_size
			if tile_size.x != _map_tile_width or tile_size.y != _map_tile_height:
				var diff_x = tile_size.x - _map_tile_width
				if diff_x % 2 != 0:
					diff_x -= 1
				var diff_y = tile_size.y - _map_tile_height
				if diff_y % 2 != 0:
					diff_y += 1
				current_tile.texture_origin = Vector2i(-diff_x/2, diff_y/2) - tile_offset

		var alt_id = 0
		if flipped_h or flipped_v or flipped_d:
			alt_id = (1 if flipped_h else 0) + (2 if flipped_v else 0) + (4 if flipped_d else 0)
			if not atlas_source.has_alternative_tile(atlas_coords, alt_id):
				atlas_source.create_alternative_tile(atlas_coords, alt_id)
				var tile_data = atlas_source.get_tile_data(atlas_coords, alt_id)
				tile_data.flip_h = flipped_h
				tile_data.flip_v = flipped_v
				tile_data.transpose = flipped_d
				var tile_size = atlas_source.texture_region_size
				if flipped_d:
					tile_size = Vector2i(tile_size.y, tile_size.x)
				if tile_size.x != _map_tile_width or tile_size.y != _map_tile_height:
					var diff_x = tile_size.x - _map_tile_width
					if diff_x % 2 != 0:
						diff_x -= 1
					var diff_y = tile_size.y - _map_tile_height
					if diff_y % 2 != 0:
						diff_y += 1
					tile_data.texture_origin = Vector2i(-diff_x/2, diff_y/2) - tile_offset
				create_polygons_on_alternative_tiles(atlas_source.get_tile_data(atlas_coords, 0), tile_data, alt_id)
		
		_tilemap.set_cell(_tm_layer_counter, cell_coords, source_id, atlas_coords, alt_id)


func get_godot_type(godot_type_string: String):
	var gts = godot_type_string.to_lower()
	var _godot_type = {
		"": _godot_type.EMPTY,
		"collision": _godot_type.BODY,
		"staticbody": _godot_type.BODY,
		"characterbody": _godot_type.CBODY,
		"rigidbody": _godot_type.RBODY,
		"area": _godot_type.AREA,
		"navigation": _godot_type.NAVIGATION,
		"occluder": _godot_type.OCCLUDER,
		"line": _godot_type.LINE,
		"path": _godot_type.PATH,
		"polygon": _godot_type.POLYGON,
		"instance": _godot_type.INSTANCE
	}.get(gts, _godot_type.UNKNOWN)
	return _godot_type


func get_godot_node_type_property(obj: Dictionary):
	var ret = ""
	var property_found = false
	if obj.has("properties"):
		for property in obj["properties"]:
			var name: String = property.get("name", "")
			var type: String = property.get("type", "string")
			var val: String = str(property.get("value", ""))
			if name.to_lower() == GODOT_NODE_TYPE_PROPERTY and type == "string":
				property_found = true
				ret = val
				break
	return [ret, property_found]


func set_sprite_offset(obj_sprite: Sprite2D, width: float, height: float, alignment: String):
	obj_sprite.offset = {
		"bottomleft": Vector2(width / 2.0, -height / 2.0),
		"bottom": Vector2(0.0, -height / 2.0),
		"bottomright": Vector2(-width / 2.0, -height / 2.0),
		"left": Vector2(width / 2.0, 0.0),
		"center": Vector2(0.0, 0.0),
		"right": Vector2(-width / 2.0, 0.0),
		"topleft": Vector2(width / 2.0, height / 2.0),
		"top": Vector2(0.0, height / 2.0),
		"topright": Vector2(-width / 2.0, height / 2.0),
	}.get(alignment, Vector2(width / 2.0, -height / 2.0))


func handle_object(obj: Dictionary, layer_node: Node, tileset: TileSet, offset: Vector2) -> void:
	var obj_x = obj.get("x", offset.x)
	var obj_y = obj.get("y", offset.y)
	var obj_rot = obj.get("rotation", 0.0)
	var obj_width = obj.get("width", 0.0)
	var obj_height = obj.get("height", 0.0)
	var obj_visible = obj.get("visible", true)
	var obj_name = obj.get("name", "")
	var class_string = obj.get("class", "")
	if class_string == "":
		class_string = obj.get("type", "")
	var search_result = get_godot_node_type_property(obj)
	var godot_node_type_property_string = search_result[0]
	var godot_node_type_prop_found = search_result[1]
	if not godot_node_type_prop_found:
		godot_node_type_property_string = class_string
	var godot_type = get_godot_type(godot_node_type_property_string)

	if godot_type == _godot_type.UNKNOWN:
		if not _add_class_as_metadata and class_string != "" and not godot_node_type_prop_found:
			print_rich("[color=" + WARNING_COLOR +"] -- Unknown class '" + class_string + "'. -> Assuming Default[/color]")
			_warning_count += 1
		elif godot_node_type_prop_found and godot_node_type_property_string != "":	
			print_rich("[color=" + WARNING_COLOR +"] -- Unknown " + GODOT_NODE_TYPE_PROPERTY + " '" + godot_node_type_property_string + "'. -> Assuming Default[/color]")
			_warning_count += 1
		godot_type = _godot_type.BODY


	if obj.has("template"):
		var template_path = _base_path.path_join(obj["template"])
		var template_dict = preload("DictionaryBuilder.gd").new().get_dictionary(template_path)
		var template_tileset = null

		if template_dict.has("tilesets"):
			var tilesets = template_dict["tilesets"]
			var tileset_creator = preload("TilesetCreator.gd").new()
			tileset_creator.set_base_path(template_path)
			tileset_creator.set_map_parameters(Vector2i(_map_tile_width, _map_tile_height))
			if _map_wangset_to_terrain:
				tileset_creator.map_wangset_to_terrain()
			template_tileset = tileset_creator.create_from_dictionary_array(tilesets)

		if template_dict.has("objects"):
			for template_obj in template_dict["objects"]:
				template_obj["template_dir_path"] = template_path.get_base_dir()

				# v1.5.3 Fix according to Carlo M (dogezen)
				# override and merge properties defined in obj with properties defined in template
				# since obj may override and define additional properties to those defined in template
				if obj.has("properties"):
					if template_obj.has("properties"):
						# merge obj properties that may have been overridden in the obj instance
						# and add any additional properties defined in instanced obj that are 
						# not defined in template
						for prop in obj["properties"]:
							var found = false
							for templ_prop in template_obj["properties"]:
								if prop.name == templ_prop.name:
									templ_prop.value = prop.value
									found = true
									break
							if not found:
								template_obj["properties"].append(prop)
					else:
						# template comes without properties, since obj has properties
						# then merge them into the template
						template_obj["properties"] = obj.properties

				handle_object(template_obj, layer_node, template_tileset, Vector2(obj_x, obj_y))

	# v1.2: New class 'instance'
	if godot_type == _godot_type.INSTANCE and not obj.has("template") and not obj.has("text"):
		var res_path = get_property(obj, "res_path", "file")
		if res_path == "":
			printerr("Object of class 'instance': Mandatory file property 'res_path' not found or invalid. -> Skipped")
			_error_count += 1
		else:
			if obj.has("template_dir_path"):
				res_path = obj.template_dir_path.path_join(res_path)
			var scene = load_resource_from_file(res_path)
			# Error check
			if scene == null: return
			var instance = scene.instantiate()
			layer_node.add_child(instance)
			instance.owner = _base_node
			instance.name = obj_name if obj_name != "" else res_path.get_file().get_basename()
			instance.position = transpose_coords(obj_x, obj_y)
			instance.rotation_degrees = obj_rot
			instance.visible = obj_visible
			if obj.has("properties"):
				handle_properties(instance, obj["properties"])
		return

	if obj.has("gid"):
		# gid refers to a tile in a tile set and object is created as sprite
		var int_id: int = obj["gid"]
		var flippedH = (int_id & FLIPPED_HORIZONTALLY_FLAG) > 0
		var flippedV = (int_id & FLIPPED_VERTICALLY_FLAG) > 0
		var gid: int = int_id & 0x0FFFFFFF

		var source_id = get_matching_source_id(gid)
		var tile_offset = get_tile_offset(gid)
		_current_tileset_orientation = get_tileset_orientation(gid)
		_current_object_alignment = get_tileset_alignment(gid)
		if _current_object_alignment == DEFAULT_ALIGNMENT:
			_current_object_alignment = "bottomleft" if _map_orientation == "orthogonal" else "bottom"
		var first_gid_id = get_first_gid_index(gid)
		if first_gid_id > source_id:
			source_id = first_gid_id
		# Should not be the case, but who knows...
		if source_id < 0: return

		var gid_source = tileset.get_source(source_id)
		var obj_sprite = Sprite2D.new()
		layer_node.add_child(obj_sprite)
		obj_sprite.owner = _base_node
		obj_sprite.name = obj_name if obj_name != "" \
							else gid_source.resource_name if gid_source.resource_name != "" \
							else gid_source.texture.resource_path.get_file().get_basename() + "_tile"
		obj_sprite.position = transpose_coords(obj_x, obj_y) + Vector2(tile_offset)
		obj_sprite.texture = gid_source.texture
		obj_sprite.rotation_degrees = obj_rot
		obj_sprite.visible = obj_visible
		var td
		if get_num_tiles_for_source_id(source_id) > 1:
			# Object is tile from partitioned tileset 
			var atlas_width: int = gid_source.get_atlas_grid_size().x

			# Can be zero if tileset had an error
			if atlas_width <= 0: return

			var effective_gid: int = gid - _first_gids[get_first_gid_index(gid)]
			var atlas_coords = Vector2(effective_gid % atlas_width, effective_gid / atlas_width)
			if not gid_source.has_tile(atlas_coords):
				gid_source.create_tile(atlas_coords)
			td = gid_source.get_tile_data(atlas_coords, 0)
			obj_sprite.region_enabled = true
			var region_size = Vector2(gid_source.texture_region_size)
			var pos: Vector2 = atlas_coords * region_size
			if get_property(obj, "clip_artifacts", "bool") == "true":
				pos += Vector2(0.5, 0.5)
				region_size -= Vector2(1.0, 1.0)
				obj_width -= 1.0
				obj_height -= 1.0
			obj_sprite.region_rect = Rect2(pos, region_size)
			set_sprite_offset(obj_sprite, region_size.x, region_size.y, _current_object_alignment)
			if abs(region_size.x - obj_width) > 0.01 or abs(region_size.y - obj_height) > 0.01:
				var scale_x: float = float(obj_width) / float(region_size.x)
				var scale_y: float = float(obj_height) / float(region_size.y)
				obj_sprite.scale = Vector2(scale_x, scale_y)
		else:
			# Object is single image tile
			var gid_width: int = gid_source.texture_region_size.x
			var gid_height: int = gid_source.texture_region_size.y
			obj_sprite.offset = Vector2(gid_width / 2.0, -gid_height / 2.0)
			set_sprite_offset(obj_sprite, gid_width, gid_height, _current_object_alignment)
			# Tiled sub rects?
			if gid_width != gid_source.texture.get_width() or gid_height != gid_source.texture.get_height():
				obj_sprite.region_enabled = true
				obj_sprite.region_rect = Rect2(gid_source.margins, gid_source.texture_region_size)
			if gid_width != obj_width or gid_height != obj_height:
				var scale_x: float = float(obj_width) / gid_width
				var scale_y: float = float(obj_height) / gid_height
				obj_sprite.scale = Vector2(scale_x, scale_y)
			td = gid_source.get_tile_data(Vector2i.ZERO, 0)

		var idx = td.get_custom_data(CUSTOM_DATA_INTERNAL)
		if idx > 0:
			var parent = {
				_godot_type.AREA: Area2D.new(),
				_godot_type.CBODY: CharacterBody2D.new(),
				_godot_type.RBODY: RigidBody2D.new(),
				_godot_type.BODY: StaticBody2D.new(),
			}.get(godot_type, null)
			if parent != null:
				layer_node.remove_child(obj_sprite)
				layer_node.add_child(parent)
				parent.owner = _base_node
				parent.name = obj_sprite.name
				parent.position = obj_sprite.position
				parent.rotation_degrees = obj_sprite.rotation_degrees
				obj_sprite.position = Vector2.ZERO
				obj_sprite.rotation_degrees = 0.0
				parent.add_child(obj_sprite)
				add_collision_shapes(parent, get_object_group(idx), obj_width, obj_height, flippedH, flippedV, obj_sprite.scale)
				if obj.has("properties"):
					handle_properties(parent, obj["properties"])
			
		obj_sprite.flip_h = flippedH
		obj_sprite.flip_v = flippedV

		if _add_class_as_metadata and class_string != "":
			obj_sprite.set_meta("class", class_string)
		if obj.has("properties"):
			handle_properties(obj_sprite, obj["properties"])

	elif obj.has("text"):
		var obj_text = Label.new()
		layer_node.add_child(obj_text)
		obj_text.owner = _base_node
		obj_text.name = obj_name if obj_name != "" else "Text"
		obj_text.position = transpose_coords(obj_x, obj_y)
		obj_text.size = Vector2(obj_width, obj_height)
		obj_text.clip_text = true
		obj_text.rotation_degrees = obj_rot
		obj_text.visible = obj_visible
		var txt = obj["text"]
		obj_text.text = txt.get("text", "Hello World")
		var wrap = txt.get("wrap", false)
		obj_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
		var align_h = txt.get("halign", "left")
		match align_h:
			"left": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			"center": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			"right": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			"justify": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
		var align_v = txt.get("valign", "top")
		match align_v:
			"top": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			"center": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			"bottom": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		var font_family = txt.get("fontfamily", "Sans-Serif")
		var font = SystemFont.new()
		font.font_names = [font_family]
		font.oversampling = 5.0
		obj_text.add_theme_font_override("font", font)
		obj_text.add_theme_font_size_override("font_size", txt.get("pixelsize", 16))
		obj_text.add_theme_color_override("font_color", Color(txt.get("color", "#000000")))
		if obj.has("properties"):
			handle_properties(obj_text, obj["properties"])

	elif not obj.has("template"):

		if godot_type == _godot_type.EMPTY:
			godot_type = _godot_type.BODY

		var object_base_coords = transpose_coords(obj_x, obj_y)

		if obj.has("point"):
			var marker = Marker2D.new()
			layer_node.add_child(marker)
			marker.owner = _base_node
			marker.name = obj_name if obj_name != "" else "point"
			marker.position = object_base_coords
			marker.rotation_degrees = obj_rot
			marker.visible = obj_visible
			if _add_class_as_metadata and class_string != "":
				marker.set_meta("class", class_string)
			if obj.has("properties"):
				handle_properties(marker, obj["properties"])
		elif obj.has("polygon"):
			if godot_type == _godot_type.BODY or godot_type == _godot_type.AREA:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible
				var polygon_shape = CollisionPolygon2D.new()
				polygon_shape.polygon = polygon_from_array(obj["polygon"])
				co.add_child(polygon_shape)
				polygon_shape.owner = _base_node
				polygon_shape.name = obj_name if obj_name != "" else "Polygon Shape"
				polygon_shape.position = Vector2.ZERO
				polygon_shape.rotation_degrees = obj_rot
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
			elif godot_type == _godot_type.NAVIGATION:
				var nav_region = NavigationRegion2D.new()
				layer_node.add_child(nav_region)
				nav_region.owner = _base_node
				nav_region.name = obj_name + " (NR)" if obj_name != "" else "Navigation"
				nav_region.position = object_base_coords
				nav_region.rotation_degrees = obj_rot
				nav_region.visible = obj_visible
				var nav_poly = NavigationPolygon.new()
				nav_region.navigation_polygon = nav_poly
				nav_poly.add_outline(polygon_from_array(obj["polygon"]))
				nav_poly.make_polygons_from_outlines()
				if _add_class_as_metadata and class_string != "":
					nav_region.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(nav_region, obj["properties"])
			elif godot_type == _godot_type.OCCLUDER:
				var light_occ = LightOccluder2D.new()
				layer_node.add_child(light_occ)
				light_occ.owner = _base_node
				light_occ.name = obj_name + " (LO)" if obj_name != "" else "Occluder"
				light_occ.position = object_base_coords
				light_occ.rotation_degrees = obj_rot
				light_occ.visible = obj_visible
				var occ_poly = OccluderPolygon2D.new()
				light_occ.occluder = occ_poly
				occ_poly.polygon = polygon_from_array(obj["polygon"])
				if _add_class_as_metadata and class_string != "":
					light_occ.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(light_occ, obj["properties"])
			elif godot_type == _godot_type.POLYGON:
				var polygon = Polygon2D.new()
				layer_node.add_child(polygon)
				polygon.owner = _base_node
				polygon.name = obj_name if obj_name != "" else "Polygon"
				polygon.position = object_base_coords
				polygon.rotation_degrees = obj_rot
				polygon.visible = obj_visible
				polygon.polygon = polygon_from_array(obj["polygon"])
				if _add_class_as_metadata and class_string != "":
					polygon.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(polygon, obj["properties"])	
		elif obj.has("polyline"):
			if godot_type == _godot_type.LINE:
				var line = Line2D.new()
				layer_node.add_child(line)
				line.owner = _base_node
				line.name = obj_name if obj_name != "" else "Line"
				line.position = object_base_coords
				line.visible = obj_visible
				line.rotation_degrees = obj_rot
				line.width = 1.0
				line.points = polygon_from_array(obj["polyline"])
				if _add_class_as_metadata and class_string != "":
					line.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(line, obj["properties"])
			elif godot_type == _godot_type.PATH:
				var path = Path2D.new()
				layer_node.add_child(path)
				path.owner = _base_node
				path.name = obj_name if obj_name != "" else "Path"
				path.position = object_base_coords
				path.visible = obj_visible
				path.rotation_degrees = obj_rot
				var curve = Curve2D.new()
				for point in obj["polyline"]:
					curve.add_point(Vector2(point.x, point.y))
				path.curve = curve
				if _add_class_as_metadata and class_string != "":
					path.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(path, obj["properties"])
			else:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible
				var polyline_points: Array = obj["polyline"]
				for i in range(0, polyline_points.size()-1):
					var collision_shape = CollisionShape2D.new()
					co.add_child(collision_shape)
					var segment_shape = SegmentShape2D.new()
					segment_shape.a = transpose_coords(polyline_points[i]["x"], polyline_points[i]["y"], true)
					segment_shape.b = transpose_coords(polyline_points[i+1]["x"], polyline_points[i+1]["y"], true)
					collision_shape.owner = _base_node
					collision_shape.shape = segment_shape
					collision_shape.position = Vector2(obj_width / 2.0, obj_height / 2.0)
					collision_shape.rotation_degrees = obj_rot
					collision_shape.name = "Segment Shape"
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
		else:
			if godot_type == _godot_type.BODY or godot_type == _godot_type.AREA:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible

				var collision_shape = CollisionShape2D.new()
				co.add_child(collision_shape)
				collision_shape.owner = _base_node
				if obj.has("ellipse"):
					var capsule_shape = CapsuleShape2D.new()
					capsule_shape.height = obj_height
					capsule_shape.radius = obj_width / 2.0
					collision_shape.shape = capsule_shape
					collision_shape.name = obj_name if obj_name != "" else "Capsule Shape"
				else: #Rectangle
					var rectangle_shape = RectangleShape2D.new()
					rectangle_shape.size = Vector2(obj_width, obj_height)
					collision_shape.shape = rectangle_shape
					collision_shape.name = obj_name if obj_name != "" else "Rectangle Shape"

				if _map_orientation == "isometric":
					if _iso_rot == 0.0:
						var q = float(_map_tile_height) / float(_map_tile_width)
						q *= q
						var cos_a = sqrt(1 / (q + 1))
						_iso_rot = acos(cos_a) * 180 / PI
						_iso_skew = (90 - 2 * _iso_rot) * PI / 180
						var scale = float(_map_tile_width) / (float(_map_tile_height) * 2 * cos_a)
						_iso_scale = Vector2(scale, scale)

					collision_shape.skew = _iso_skew
					collision_shape.scale = _iso_scale
					obj_rot += _iso_rot

				collision_shape.position = transpose_coords(obj_width / 2.0, obj_height / 2.0, true)
				collision_shape.rotation_degrees = obj_rot
				collision_shape.visible = obj_visible
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
			elif godot_type == _godot_type.NAVIGATION:
				if obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for NavigationRegion2D. -> Skipped[/color]")
					_warning_count += 1
				else:
					var nav_region = NavigationRegion2D.new()
					layer_node.add_child(nav_region)
					nav_region.owner = _base_node
					nav_region.name = obj_name + " (NR)" if obj_name != "" else "Navigation"
					nav_region.position = object_base_coords
					nav_region.rotation_degrees = obj_rot
					nav_region.visible = obj_visible
					var nav_poly = NavigationPolygon.new()
					nav_region.navigation_polygon = nav_poly
					nav_poly.add_outline(polygon_from_rectangle(obj_width, obj_height))
					nav_poly.make_polygons_from_outlines()
					if _add_class_as_metadata and class_string != "":
						nav_region.set_meta("class", class_string)
					if obj.has("properties"):
						handle_properties(nav_region, obj["properties"])
			elif godot_type == _godot_type.OCCLUDER:
				if obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for LightOccluder2D. -> Skipped[/color]")
					_warning_count += 1
				else:
					var light_occ = LightOccluder2D.new()
					layer_node.add_child(light_occ)
					light_occ.owner = _base_node
					light_occ.name = obj_name + " (LO)" if obj_name != "" else "Occluder"
					light_occ.position = object_base_coords
					light_occ.rotation_degrees = obj_rot
					light_occ.visible = obj_visible
					var occ_poly = OccluderPolygon2D.new()
					light_occ.occluder = occ_poly
					occ_poly.polygon = polygon_from_rectangle(obj_width, obj_height)
					if _add_class_as_metadata and class_string != "":
						light_occ.set_meta("class", class_string)
					if obj.has("properties"):
						handle_properties(light_occ, obj["properties"])
			elif godot_type == _godot_type.POLYGON:
				if obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for Polygon2D. -> Skipped[/color]")
					_warning_count += 1
				else:
					var polygon = Polygon2D.new()
					layer_node.add_child(polygon)
					polygon.owner = _base_node
					polygon.name = obj_name if obj_name != "" else "Polygon"
					polygon.position = object_base_coords
					polygon.rotation_degrees = obj_rot
					polygon.visible = obj_visible
					polygon.polygon = polygon_from_rectangle(obj_width, obj_height)
					if _add_class_as_metadata and class_string != "":
						polygon.set_meta("class", class_string)
					if obj.has("properties"):
						handle_properties(polygon, obj["properties"])	


func add_collision_shapes(parent: CollisionObject2D, object_group: Dictionary, tile_width: float, tile_height: float, flippedH: bool, flippedV: bool, scale: Vector2):
	var objects = object_group["objects"]
	for obj in objects:
		var obj_name = obj.get("name", "")
		if obj.has("point") and obj["point"]:
			print_rich("[color="+WARNING_COLOR+"] -- 'Point' has currently no corresponding collision element in Godot 4. -> Skipped[/color]")
			_warning_count += 1
			break

		var fact = tile_height / _map_tile_height
		var object_base_coords = Vector2(obj["x"], obj["y"]) * scale
		if _current_tileset_orientation == "isometric":
			object_base_coords = transpose_coords(obj["x"], obj["y"], true) * scale
			tile_width = _map_tile_width
			tile_height = _map_tile_height

		if obj.has("polygon"):
			var polygon_points = obj["polygon"] as Array
			var rot = obj.get("rotation", 0.0)			
			var polygon = []
			for pt in polygon_points:
				var p_coord = Vector2(pt["x"], pt["y"]) * scale
				if _current_tileset_orientation == "isometric":
					p_coord = transpose_coords(p_coord.x, p_coord.y, true)
				if flippedH:
					p_coord.x = -p_coord.x
				if flippedV:
					p_coord.y = -p_coord.y
				polygon.append(p_coord)

			var collision_polygon = CollisionPolygon2D.new()
			parent.add_child(collision_polygon)
			collision_polygon.owner = _base_node
			collision_polygon.polygon = polygon
			var pos_x = object_base_coords.x
			var pos_y = object_base_coords.y - tile_height
			if _map_orientation == "isometric" and _current_tileset_orientation == "orthogonal":
				pos_x -= tile_width / 2.0
			if flippedH:
				pos_x = tile_width - pos_x
				if _map_orientation == "isometric":
					pos_x -= tile_width
				rot = -rot
			if flippedV:
				pos_y = -tile_height - pos_y
				if _current_tileset_orientation == "isometric":
					pos_y -= _map_tile_height * fact - tile_height
				rot = -rot
			collision_polygon.rotation_degrees = rot
			collision_polygon.position = Vector2(pos_x, pos_y)
			collision_polygon.name = obj_name if obj_name != "" else "Collision Polygon"
			if get_property(obj, "one_way", "bool") == "true":
				collision_polygon.one_way_collision = true
			var coll_margin = get_property(obj, "one_way_margin", "int")
			if coll_margin == "":
				coll_margin = get_property(obj, "one_way_margin", "float")
			if coll_margin != "":
				collision_polygon.one_way_collision_margin = coll_margin
		else:
			# Ellipse or rectangle
			var collision_shape = CollisionShape2D.new()
			parent.add_child(collision_shape)
			collision_shape.owner = _base_node
			var x = obj["x"] * scale.x
			var y = obj["y"] * scale.y
			var w = obj["width"] * scale.x
			var h = obj["height"] * scale.y
			var rot = obj.get("rotation", 0.0)
			var sin_a = sin(rot * PI / 180.0)
			var cos_a = cos(rot * PI / 180.0)
			var pos_x = x + w / 2.0 * cos_a - h / 2.0 * sin_a
			var pos_y = -tile_height + y + h / 2.0 * cos_a + w / 2.0 * sin_a
			if _current_tileset_orientation == "isometric":
				var trans_pos = transpose_coords(pos_x, pos_y, true)
				pos_x = trans_pos.x
				pos_y = trans_pos.y
				pos_x -= tile_width / 2.0 - h * fact / 4.0 * sin_a
				pos_y -= tile_height / 2.0
			elif _map_orientation == "isometric":
				pos_x -= tile_width / 2.0
			if flippedH:
				pos_x = tile_width - pos_x 
				if _map_orientation == "isometric":
					pos_x -= tile_width
				rot = -rot
			if flippedV:
				pos_y = -tile_height - pos_y
				if _current_tileset_orientation == "isometric":
					pos_y -= _map_tile_height * fact - tile_height
				rot = -rot
			collision_shape.position = Vector2(pos_x, pos_y)
			collision_shape.scale = scale
			var shape
			if obj.has("ellipse") and obj["ellipse"]:
				shape = CapsuleShape2D.new()
				shape.height = h / scale.y
				shape.radius = w / 2.0 / scale.x
				collision_shape.name = obj_name if obj_name != "" else "Capsule Shape"
			else:
				shape = RectangleShape2D.new()
				shape.size = Vector2(w, h) / scale
				collision_shape.name = obj_name if obj_name != "" else "Rectangle Shape"

			if _current_tileset_orientation == "isometric":
				if _iso_rot == 0.0:
					var q = float(_map_tile_height) / float(_map_tile_width)
					q *= q
					var cos_b = sqrt(1 / (q + 1))
					_iso_rot = acos(cos_b) * 180 / PI
					_iso_skew = (90 - 2 * _iso_rot) * PI / 180
					var scale_b = float(_map_tile_width) / (float(_map_tile_height) * 2 * cos_b)
					_iso_scale = Vector2(scale_b, scale_b)

				var effective_rot = _iso_rot
				var effective_skew = _iso_skew
				if flippedH:
					effective_rot = -effective_rot
					effective_skew = -effective_skew
				if flippedV:
					effective_rot = -effective_rot
					effective_skew = -effective_skew
	
				collision_shape.skew = effective_skew
				collision_shape.scale = _iso_scale
				rot += effective_rot

			collision_shape.shape = shape
			collision_shape.rotation_degrees = rot
			if get_property(obj, "one_way", "bool") == "true":
				collision_shape.one_way_collision = true
			var coll_margin = get_property(obj, "one_way_margin", "int")
			if coll_margin == "":
				coll_margin = get_property(obj, "one_way_margin", "float")
			if coll_margin != "":
				collision_shape.one_way_collision_margin = coll_margin


func get_property(obj: Dictionary, property_name: String, property_type: String):
	var ret = ""
	if not obj.has("properties"): return ret
	for property in obj["properties"]:
		var name = property.get("name", "")
		var type = property.get("type", "string")
		var val = property.get("value", "")
		if name.to_lower() == property_name and type == property_type:
			return val
	return ret


func polygon_from_array(poly_array: Array):
	var polygon = []
	for pt in poly_array:
		var p_coord = transpose_coords(pt["x"], pt["y"], true)
		polygon.append(p_coord)
	return polygon


func polygon_from_rectangle(width: float, height: float):
	var polygon = [Vector2(), Vector2(), Vector2(), Vector2()]
	polygon[0] = Vector2.ZERO
	polygon[1].y = polygon[0].y + height
	polygon[1].x = polygon[0].x
	polygon[2].y = polygon[1].y
	polygon[2].x = polygon[0].x + width
	polygon[3].y = polygon[0].y
	polygon[3].x = polygon[2].x
	polygon[1] = transpose_coords(polygon[1].x, polygon[1].y, true)
	polygon[2] = transpose_coords(polygon[2].x, polygon[2].y, true)
	polygon[3] = transpose_coords(polygon[3].x, polygon[3].y, true)
	return polygon


func transpose_coords(x: float, y: float, no_offset_x: bool = false):
	if _map_orientation == "isometric":
		var trans_x = (x - y) * _map_tile_width / _map_tile_height / 2.0
		if not no_offset_x:
			trans_x += _map_height * _map_tile_width / 2.0
		var trans_y = (x + y) * 0.5
		return Vector2(trans_x, trans_y)

	return Vector2(x, y)


func get_first_gid_index(gid: int):
	var index = 0
	var gid_index = 0
	for first_gid in _first_gids:
		if gid >= first_gid:
			gid_index = index
		index += 1
	return gid_index


func get_matching_source_id(gid: int):
	var limit: int = 0
	var prev_source_id: int = -1
	if _atlas_sources == null:
		return -1
	for src in _atlas_sources:
		var source_id: int = src["sourceId"]
		limit += src["numTiles"] + source_id - prev_source_id - 1
		if gid <= limit:
			return source_id
		prev_source_id = source_id
	return -1


func get_tile_offset(gid: int):
	var limit: int = 0
	var prev_source_id: int = -1
	if _atlas_sources == null:
		return Vector2i.ZERO
	for src in _atlas_sources:
		var source_id: int = src["sourceId"]
		limit += src["numTiles"] + source_id - prev_source_id - 1
		if gid <= limit:
			return src["tileOffset"]
		prev_source_id = source_id
	return Vector2i.ZERO
	

func get_tileset_orientation(gid: int):
	var limit: int = 0
	var prev_source_id: int = -1
	if _atlas_sources == null:
		return _map_orientation
	for src in _atlas_sources:
		var source_id: int = src["sourceId"]
		limit += src["numTiles"] + source_id - prev_source_id - 1
		if gid <= limit:
			return src["tilesetOrientation"]
		prev_source_id = source_id
	return _map_orientation
	

func get_tileset_alignment(gid: int):
	var limit: int = 0
	var prev_source_id: int = -1
	if _atlas_sources == null:
		return DEFAULT_ALIGNMENT
	for src in _atlas_sources:
		var source_id: int = src["sourceId"]
		limit += src["numTiles"] + source_id - prev_source_id - 1
		if gid <= limit:
			return src["objectAlignment"]
		prev_source_id = source_id
	return DEFAULT_ALIGNMENT
	

func get_num_tiles_for_source_id(source_id: int):
	for src in _atlas_sources:
		if src["sourceId"] == source_id:
			return src["numTiles"]
	return -1


func load_resource_from_file(path: String):
	var orig_path = path
	var ret: Resource = null
	# ToDo: Not sure if this first check makes any sense since an image can't be properly imported if not in project tree
	if not FileAccess.file_exists(path):
		path = _base_path.get_base_dir().path_join(orig_path)
	if not FileAccess.file_exists(path):
		path = _base_path.path_join(orig_path)
	if FileAccess.file_exists(path):
		ret = ResourceLoader.load(path)
	else:
		printerr("ERROR: Resource file '" + orig_path + "' not found.")
		_error_count += 1
	return ret
	
	
func get_bitmask_integer_from_string(mask_string: String, max: int):
	var ret: int = 0
	var s1_arr = mask_string.split(",", false)
	for s1 in s1_arr:
		if s1.contains("-"):
			var s2_arr = s1.split("-", false, 1)
			var i1 = int(s2_arr[0]) if s2_arr[0].is_valid_int() else 0
			var i2 = int(s2_arr[1]) if s2_arr[1].is_valid_int() else 0
			if i1 == 0 or i2 == 0 or i1 > i2: continue
			for i in range(i1, i2+1):
				if i <= max:
					ret += pow(2, i-1)
		elif s1.is_valid_int():
			var i = int(s1)
			if i <= max:
				ret += pow(2, i-1)
	return ret


func get_object_group(index: int):
	var ret = null
	if _object_groups != null:
		ret = _object_groups.get(index, null)
	return ret


func get_right_typed_value(type: String, val: String):
	if type == "bool":
		return val == "true"
	elif type == "float":
		return float(val)
	elif type == "int":
		return int(val)
	elif type == "color":
		# If alpha is present it's strangely the first byte, so we have to shift it to the end
		if val.length() == 9: val = val[0] + val.substr(3) + val.substr(1,2)
		return val
	else:
		return val
	

func handle_properties(target_node: Node, properties: Array, map_properties: bool = false):
	var has_children = false
	if target_node is StaticBody2D or target_node is Area2D or target_node is CharacterBody2D or target_node is RigidBody2D:
		has_children = target_node.get_child_count() > 0 
	for property in properties:
		var name: String = property.get("name", "")
		var type: String = property.get("type", "string")
		var val: String = str(property.get("value", ""))
		if name == "" or name.to_lower() == GODOT_NODE_TYPE_PROPERTY: continue
		if name.begins_with("__") and has_children:
			var child_prop_dict = {}
			child_prop_dict["name"] = name.substr(2)
			child_prop_dict["type"] = type
			child_prop_dict["value"] = val
			var child_props = []
			child_props.append(child_prop_dict)
			for child in target_node.get_children():
				handle_properties(child, child_props)
		
		# Node properties
		# v1.5.4: godot_group property
		if name.to_lower() == GODOT_GROUP_PROPERTY and type == "string":
			for group in val.split(",", false):
				target_node.add_to_group(group.strip_edges(), true)

		# CanvasItem properties
		elif name.to_lower() == "modulate" and type == "string":
			target_node.modulate = Color(val)
		elif name.to_lower() == "self_modulate" and type == "string":
			target_node.self_modulate = Color(val)
		elif name.to_lower() == "show_behind_parent" and type == "bool":
			target_node.show_behind_parent = val.to_lower() == "true"
		elif name.to_lower() == "top_level" and type == "bool":
			target_node.top_level = val.to_lower() == "true"
		elif name.to_lower() == "clip_children" and type == "int":
			if int(val) < CanvasItem.CLIP_CHILDREN_MAX:
				target_node.clip_children = int(val)
		elif name.to_lower() == "light_mask" and type == "string":
			target_node.light_mask = get_bitmask_integer_from_string(val, 20)
		elif name.to_lower() == "visibility_layer" and type == "string":
			target_node.visibility_layer = get_bitmask_integer_from_string(val, 20)	
		elif name.to_lower() == "z_index" and type == "int" and (not target_node is TileMap or map_properties):
			target_node.z_index = int(val)
		elif name.to_lower() == "canvas_z_index" and type == "int":
			target_node.z_index = int(val)
		elif name.to_lower() == "z_as_relative" and type == "bool":
			target_node.z_as_relative = val.to_lower() == "true"
		elif name.to_lower() == "y_sort_enabled" and type == "bool":
			target_node.y_sort_enabled = val.to_lower() == "true"
			if target_node is TileMap:
				target_node.set_layer_y_sort_enabled(_tm_layer_counter, val.to_lower() == "true")
		elif name.to_lower() == "texture_filter" and type == "int":
			if int(val) < CanvasItem.TEXTURE_FILTER_MAX:
				target_node.texture_filter = int(val)
		elif name.to_lower() == "texture_repeat" and type == "int":
			if int(val) < CanvasItem.TEXTURE_REPEAT_MAX:
				target_node.texture_repeat = int(val)
		elif name.to_lower() == "material" and type == "file":
			target_node.material = load_resource_from_file(val)
		elif name.to_lower() == "use_parent_material" and type == "bool":
			target_node.use_parent_material = val.to_lower() == "true"
	
		# TileMap properties
		elif name.to_lower() == "cell_quadrant_size" and type == "int" and target_node is TileMap:
			target_node.cell_quadrant_size = int(val)
		elif name.to_lower() == "collision_animatable" and type == "bool" and target_node is TileMap:
			target_node.collision_animatable = val.to_lower() == "true"
		elif name.to_lower() == "collision_visibility_mode" and type == "int" and target_node is TileMap:
			if int(val) < 3:
				target_node.collision_visibility_mode = int(val)
		elif name.to_lower() == "navigation_visibility_mode" and type == "int" and target_node is TileMap:
			if int(val) < 3:
				target_node.navigation_visibility_mode = int(val)

		# TileMap layer properties
		elif name.to_lower() == "layer_z_index" and type == "int" and target_node is TileMap:
			target_node.z_index = int(val)
		elif name.to_lower() == "z_index" and type == "int" and target_node is TileMap:
			if _map_layers_to_tilemaps:
				target_node.z_index = int(val)
			else:
				target_node.set_layer_z_index(_tm_layer_counter, int(val))
		elif name.to_lower() == "y_sort_origin" and type == "int" and target_node is TileMap:
			target_node.set_layer_y_sort_origin(_tm_layer_counter, int(val))
		
		# CollisionObject2D properties
		elif name.to_lower() == "disable_mode" and type == "int" and target_node is CollisionObject2D:
			if int(val) < 3:
				target_node.disable_mode = int(val)
		elif name.to_lower() == "collision_layer" and type == "string" and target_node is CollisionObject2D:
			target_node.collision_layer = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_mask" and type == "string" and target_node is CollisionObject2D:
			target_node.collision_mask = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_priority" and  (type == "float" or type == "int") and target_node is CollisionObject2D:
			target_node.collision_priority = float(val)
		elif name.to_lower() == "input_pickable" and type == "bool" and target_node is CollisionObject2D:
			target_node.input_pickable = val.to_lower() == "true"

		# CollisionPolygon2D properties
		elif name.to_lower() == "build_mode" and type == "int" and has_children and int(val) < 2:
			for child in target_node.get_children():
				if child is CollisionPolygon2D:
					child.build_mode = int(val)

		# CollisionPolygon2D & CollisionShape2D properties
		elif name.to_lower() == "disabled" and type == "bool" and has_children:
			for child in target_node.get_children():
				child.disabled = val.to_lower() == "true"
		elif name.to_lower() == "one_way_collision" and type == "bool" and has_children:
			for child in target_node.get_children():
				child.one_way_collision = val.to_lower() == "true"
		elif name.to_lower() == "one_way_collision_margin" and (type == "float" or type == "int") and has_children:
			for child in target_node.get_children():
				child.one_way_collision_margin = float(val)

		# CollisionShape2D properties
		elif name.to_lower() == "debug_color" and type == "string" and has_children:
			for child in target_node.get_children():
				if child is CollisionShape2D:
					child.debug_color = Color(val)

		# Area2D properties
		elif name.to_lower() == "monitoring" and type == "bool" and target_node is Area2D:
			target_node.monitoring = val.to_lower() == "true"
		elif name.to_lower() == "monitorable" and type == "bool" and target_node is Area2D:
			target_node.monitorable = val.to_lower() == "true"
		elif name.to_lower() == "priority" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.priority = float(val)
		elif name.to_lower() == "gravity_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.gravity_space_override = int(val)
		elif name.to_lower() == "gravity_point" and type == "bool" and target_node is Area2D:
			target_node.gravity_point = val.to_lower() == "true"
		elif name.to_lower() == "gravitiy_point_center_x" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_point_center = Vector2(float(val), target_node.gravity_point_center.y)
		elif name.to_lower() == "gravitiy_point_center_y" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_point_center = Vector2(target_node.gravity_point_center.x, float(val))
		elif name.to_lower() == "gravity_point_unit_distance" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravitiy_point_unit_distance = float(val)
		elif name.to_lower() == "gravitiy_direction_x" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_direction = Vector2(float(val), target_node.gravity_direction.y)
		elif name.to_lower() == "gravitiy_direction_y" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_direction = Vector2(target_node.gravity_direction.x, float(val))
		elif name.to_lower() == "gravity" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravitiy = float(val)
		elif name.to_lower() == "linear_damp_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.linear_damp_space_override = int(val)
		elif name.to_lower() == "linear_damp" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.linear_damp = float(val)
		elif name.to_lower() == "angular_damp_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.angular_damp_space_override = int(val)
		elif name.to_lower() == "angular_damp" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.angular_damp = float(val)
			
		# StaticBody2D properties
		elif name.to_lower() == "physics_material_override" and type == "file" and target_node is StaticBody2D:
			target_node.physics_material_override = load_resource_from_file(val)
		elif name.to_lower() == "constant_linear_velocity_x" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_linear_velocity = Vector2(float(val), target_node.constant_linear_velocity.y)
		elif name.to_lower() == "constant_linear_velocity_y" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_linear_velocity = Vector2(target_node.constant_linear_velocity.x, float(val))
		elif name.to_lower() == "constant_angular_velocity" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_angular_velocity = float(val)

		# CharacterBody2D properties
		elif name.to_lower() == "motion_mode" and type == "int" and target_node is CharacterBody2D:
			if int(val) < 2:
				target_node.motion_mode = int(val)
		elif name.to_lower() == "up_direction_x" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.up_direction = Vector2(float(val), target_node.up_direction.y)
		elif name.to_lower() == "up_direction_y" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.up_direction = Vector2(target_node.up_direction.x, float(val))
		elif name.to_lower() == "slide_on_ceiling" and type == "bool" and target_node is CharacterBody2D:
			target_node.slide_on_ceiling = val.to_lower() == "true"
		elif name.to_lower() == "wall_min_slide_angle" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.wall_min_slide_angle = float(val)
		elif name.to_lower() == "floor_stop_on_slope" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_stop_on_slope = val.to_lower() == "true"
		elif name.to_lower() == "floor_constant_speed" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_constant_speed = val.to_lower() == "true"
		elif name.to_lower() == "floor_block_on_wall" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_block_on_wall = val.to_lower() == "true"
		elif name.to_lower() == "floor_max_angle" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.floor_max_angle = float(val)
		elif name.to_lower() == "floor_snap_length" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.floor_snap_length = float(val)
		elif name.to_lower() == "platform_on_leave" and type == "int" and target_node is CharacterBody2D:
			if int(val) < 3:
				target_node.platform_on_leave = int(val)
		elif name.to_lower() == "platform_floor_layers" and type == "string" and target_node is CharacterBody2D:
			target_node.platform_floor_layers = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "platform_wall_layers" and type == "string" and target_node is CharacterBody2D:
			target_node.platform_wall_layers = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "safe_margin" and  (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.safe_margin = float(val)
		elif name.to_lower() == "collision_layer" and type == "string" and target_node is CharacterBody2D:
			target_node.collision_layer = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_mask" and type == "string" and target_node is CharacterBody2D:
			target_node.collision_mask = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_priority" and  (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.collision_priority = float(val)

		# RigidBody2D properties
		elif name.to_lower() == "mass" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.mass = float(val)
		elif name.to_lower() == "inertia" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.inertia = float(val)
		elif name.to_lower() == "center_of_mass_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.center_of_mass_mode = int(val)
		elif name.to_lower() == "physics_material_override" and type == "file" and target_node is RigidBody2D:
			target_node.physics_material_override = load_resource_from_file(val)
		elif name.to_lower() == "gravity_scale" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.gravity_scale = float(val)
		elif name.to_lower() == "custom_integrator" and type == "bool" and target_node is RigidBody2D:
			target_node.custom_integrator = val.to_lower() == "true"
		elif name.to_lower() == "continuous_cd" and type == "int" and target_node is RigidBody2D:
			if int(val) < 3:
				target_node.continuous_cd = int(val)
		elif name.to_lower() == "max_contacts_reported" and type == "int" and target_node is RigidBody2D:
			target_node.max_contacts_reported = int(val)
		elif name.to_lower() == "contact_monitor" and type == "bool" and target_node is RigidBody2D:
			target_node.contact_monitor = val.to_lower() == "true"
		elif name.to_lower() == "sleeping" and type == "bool" and target_node is RigidBody2D:
			target_node.sleeping = val.to_lower() == "true"
		elif name.to_lower() == "can_sleep" and type == "bool" and target_node is RigidBody2D:
			target_node.can_sleep = val.to_lower() == "true"
		elif name.to_lower() == "lock_rotation" and type == "bool" and target_node is RigidBody2D:
			target_node.lock_rotation = val.to_lower() == "true"
		elif name.to_lower() == "freeze" and type == "bool" and target_node is RigidBody2D:
			target_node.freeze = val.to_lower() == "true"
		elif name.to_lower() == "freeze_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.freeze_mode = int(val)
		elif name.to_lower() == "linear_velocity_x" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_velocity = Vector2(float(val), target_node.linear_velocity.y)
		elif name.to_lower() == "linear_velocity_y" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_velocity = Vector2(target_node.linear_velocity.x, float(val))
		elif name.to_lower() == "linear_damp_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.linear_damp_mode = int(val)
		elif name.to_lower() == "linear_damp" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_damp = float(val)
		elif name.to_lower() == "angular_velocity" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.angular_velocity = float(val)
		elif name.to_lower() == "angular_damp_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.angular_damp_mode = int(val)
		elif name.to_lower() == "angular_damp" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.angular_damp = float(val)
		elif name.to_lower() == "constant_force_x" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_force = Vector2(float(val), target_node.constant_force.y)
		elif name.to_lower() == "constant_force_y" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_force = Vector2(target_node.constant_force.x, float(val))
		elif name.to_lower() == "constant_torque" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_torque = float(val)
				
		# NavigationRegion2D properties
		elif name.to_lower() == "enabled" and type == "bool" and target_node is NavigationRegion2D:
			target_node.enabled = val.to_lower() == "true"
		elif name.to_lower() == "navigation_layers" and type == "string" and target_node is NavigationRegion2D:
			target_node.navigation_layers = get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "enter_cost" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			target_node.enter_cost = float(val)
		elif name.to_lower() == "travel_cost" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			target_node.travel_cost = float(val)

		# LightOccluder2D properties
		elif name.to_lower() == "sdf_collision" and type == "bool" and target_node is LightOccluder2D:
			target_node.sdf_collision = val.to_lower() == "true"
		elif name.to_lower() == "occluder_light_mask" and type == "string" and target_node is LightOccluder2D:
			target_node.occluder_light_mask = get_bitmask_integer_from_string(val, 20)

		# Polygon2D properties
		elif name.to_lower() == "color" and type == "string" and target_node is Polygon2D:
			target_node.color = Color(val)

		# Line2D properties
		elif name.to_lower() == "width" and (type == "float" or type == "int") and target_node is Line2D:
			target_node.width = float(val)
		elif name.to_lower() == "default_color" and type == "string" and target_node is Line2D:
			target_node.default_color = Color(val)

		# Marker2D properties
		elif name.to_lower() == "gizmo_extents" and (type == "float" or type == "int") and target_node is Marker2D:
			target_node.gizmo_extents = float(val)

		# Other properties are added as Metadata
		else:
			target_node.set_meta(name, get_right_typed_value(type, val))
�
�d�7# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

const WARNING_COLOR = "yellow"
const CUSTOM_DATA_INTERNAL = "__internal__"

var _tileset = null
var _current_atlas_source = null
var _current_max_x = 0
var _current_max_y = 0
var _atlas_source_counter: int = 0
var _base_path_map = ""
var _base_path_tileset = ""
var _terrain_sets_counter: int = -1
var _terrain_counter: int = 0
var _tile_count: int = 0
var _columns: int = 0
var _tile_size: Vector2i
var _physics_layer_counter: int = -1
var _navigation_layer_counter: int = -1
var _occlusion_layer_counter: int = -1
var _append = false
var _atlas_sources = null
var _error_count = 0
var _warning_count = 0
var _map_tile_size: Vector2i
var _grid_size: Vector2i
var _tile_offset: Vector2i
var _object_alignment
var _object_groups = null
var _object_groups_counter: int = 0
var _tileset_orientation
var _map_wangset_to_terrain: bool = false

enum layer_type {
	PHYSICS,
	NAVIGATION,
	OCCLUSION
}


func get_error_count():
	return _error_count


func get_warning_count():
	return _warning_count
	

func set_base_path(source_file: String):
	_base_path_map = source_file.get_base_dir()
	_base_path_tileset = _base_path_map


func set_map_parameters(map_tile_size: Vector2i):
	_map_tile_size = map_tile_size


func map_wangset_to_terrain():
	_map_wangset_to_terrain = true
	

func create_from_dictionary_array(tileSets: Array):
	for tile_set in tileSets:
		var tile_set_dict = tile_set
	
		if tile_set.has("source"):
			var checked_file: String = tile_set["source"]
 
			# Catch the AutoMap Rules tileset (is Tiled internal)
			if checked_file.begins_with(":/automap"):
				return _tileset # This is no error skip it
 
			if not FileAccess.file_exists(checked_file):
				checked_file = _base_path_map.path_join(checked_file)
			_base_path_tileset = checked_file.get_base_dir()
 
			tile_set_dict = preload("DictionaryBuilder.gd").new().get_dictionary(checked_file)
	
		# Possible error condition
		if tile_set_dict == null:
			_error_count += 1
			return null
	
		create_or_append(tile_set_dict)
		_append = true
   
	return _tileset


func create_from_file(source_file: String):
	var tile_set = preload("DictionaryBuilder.gd").new().get_dictionary(source_file)
	create_or_append(tile_set)
	return _tileset


func get_registered_atlas_sources():
	return _atlas_sources


func get_registered_object_groups():
	return _object_groups
	

func create_or_append(tile_set: Dictionary):
	# Catch the AutoMap Rules tileset (is Tiled internal)
	if tile_set.has("name") and tile_set["name"] == "AutoMap Rules":
		return # This is no error just skip it

	if not _append:
		_tileset = TileSet.new()
		_tileset.add_custom_data_layer()
		_tileset.set_custom_data_layer_name(0, CUSTOM_DATA_INTERNAL)
		_tileset.set_custom_data_layer_type(0, TYPE_INT)

	_tile_size = Vector2i(tile_set["tilewidth"], tile_set["tileheight"])
	if not _append:
		_tileset.tile_size = _map_tile_size
	_tile_count = tile_set.get("tilecount", 0)
	_columns = tile_set.get("columns", 0)
	_tileset_orientation = "orthogonal"
	_grid_size = _tile_size
	if tile_set.has("tileoffset"):
		var to = tile_set["tileoffset"]
		_tile_offset = Vector2i(to["x"], to["y"])
	else:
		_tile_offset = Vector2i.ZERO
	if tile_set.has("grid"):
		var grid = tile_set["grid"]
		if grid.has("orientation"):
			_tileset_orientation = grid["orientation"]
		_grid_size.x = grid.get("width", _tile_size.x)
		_grid_size.y = grid.get("height", _tile_size.y)

	if tile_set.has("objectalignment"):
		_object_alignment = tile_set["objectalignment"]
	else:
		_object_alignment = "unspecified"

	if _append:
		_terrain_counter = 0

	if "image" in tile_set:
		_current_atlas_source = TileSetAtlasSource.new()
		_tileset.add_source(_current_atlas_source, _atlas_source_counter)
		_current_atlas_source.texture_region_size = _tile_size
		if tile_set.has("margin"):
			_current_atlas_source.margins = Vector2i(tile_set["margin"], tile_set["margin"])
		if tile_set.has("spacing"):
			_current_atlas_source.separation = Vector2i(tile_set["spacing"], tile_set["spacing"])

		var texture = load_image(tile_set["image"])
		if not texture:
			# Can't continue without texture but as source was already added, counter must be incremented
			_atlas_source_counter += 1
			return;

		_current_atlas_source.texture = texture
		
		if (_tile_count == 0) or (_columns == 0):
			var image_width: int = tile_set.get("imagewidth", 0)
			var image_height: int = tile_set.get("imageheight", 0)
			if image_width == 0:
				var img = _current_atlas_source.texture
				image_width = img.get_width()
				image_height = img.get_height()
			_columns = image_width / _tile_size.x
			_tile_count = _columns * image_height / _tile_size.x
	
		register_atlas_source(_atlas_source_counter, _tile_count, -1, _tile_offset)
		var atlas_grid_size = _current_atlas_source.get_atlas_grid_size()
		_current_max_x = atlas_grid_size.x - 1
		_current_max_y = atlas_grid_size.y - 1
		_atlas_source_counter += 1

	if tile_set.has("tiles"):
		handle_tiles(tile_set["tiles"])
	if tile_set.has("wangsets"):
		if _map_wangset_to_terrain:
			handle_wangsets_old_mapping(tile_set["wangsets"])
		else:
			handle_wangsets(tile_set["wangsets"])
	if tile_set.has("properties"):
		handle_tileset_properties(tile_set["properties"])


func load_image(path: String):
	var orig_path = path
	var ret: Texture2D = null
	# ToDo: Not sure if this first check makes any sense since an image can't be properly imported if not in project tree
	if not FileAccess.file_exists(path):
		path = _base_path_map.get_base_dir().path_join(orig_path)
	if not FileAccess.file_exists(path):
		path = _base_path_tileset.path_join(orig_path)
	if FileAccess.file_exists(path):
		var exists = ResourceLoader.exists(path, "Image")
		if exists:
			ret = load(path)
		else:
			var image = Image.load_from_file(path)
			ret = ImageTexture.create_from_image(image)
	else:
		printerr("ERROR: Image file '" + orig_path + "' not found.")
		_error_count += 1
	return ret


func register_atlas_source(source_id: int, num_tiles: int, assigned_tile_id: int, tile_offset: Vector2i):
	if _atlas_sources == null:
		_atlas_sources = []
	var atlas_source_item = {}
	atlas_source_item["sourceId"] = source_id
	atlas_source_item["numTiles"] = num_tiles
	atlas_source_item["assignedId"] = assigned_tile_id
	atlas_source_item["tileOffset"] = tile_offset
	atlas_source_item["tilesetOrientation"] = _tileset_orientation
	atlas_source_item["objectAlignment"] = _object_alignment
	_atlas_sources.push_back(atlas_source_item)
	

func register_object_group(tile_id: int, object_group: Dictionary):
	if _object_groups == null:
		_object_groups = {}
	_object_groups[tile_id] = object_group


func create_tile_if_not_existing_and_get_tiledata(tile_id: int):
	if tile_id < _tile_count:
		var row = tile_id / _columns
		var col = tile_id % _columns
		var tile_coords = Vector2i(col, row)
		if col > _current_max_x or row > _current_max_y:
			print_rich("[color="+WARNING_COLOR+"] -- Tile " + str(tile_id) + " at " + str(col) + "," + str(row) + " outside texture range. -> Skipped[/color]")
			_warning_count += 1
			return null
		var tile_at_coords = _current_atlas_source.get_tile_at_coords(tile_coords)
		if tile_at_coords == Vector2i(-1, -1):
			_current_atlas_source.create_tile(tile_coords)
		elif tile_at_coords != tile_coords:
			print_rich("[color="+WARNING_COLOR+"]WARNING: tile_at_coords not equal tile_coords![/color]")
			print_rich("[color="+WARNING_COLOR+"]         tile_coords:   " + str(col) + "," + str(row) + "[/color]")
			print_rich("[color="+WARNING_COLOR+"]         tile_at_coords: " + str(tile_at_coords.x) + "," + str(tile_at_coords.x) + "[/color]")
			print_rich("[color="+WARNING_COLOR+"]-> Tile skipped[/color]")
			_warning_count += 1
			return null
		return _current_atlas_source.get_tile_data(tile_coords, 0)
	print_rich("[color="+WARNING_COLOR+"] -- Tile id " + str(tile_id) + " outside tile count range (0-" + str(_tile_count-1) + "). -> Skipped.[/color]")
	_warning_count += 1
	return null


func handle_tiles(tiles: Array):
	var max_last_atlas_source_count = _atlas_source_counter
	for tile in tiles:
		var tile_id = tile["id"]

		var current_tile
		if tile.has("image"):
			# Tile with its own image -> separate atlas source
			_current_atlas_source = TileSetAtlasSource.new()
			var last_atlas_source_count = _atlas_source_counter + tile_id + 1
			if last_atlas_source_count > max_last_atlas_source_count:
				max_last_atlas_source_count = last_atlas_source_count
			_tileset.add_source(_current_atlas_source, last_atlas_source_count-1)
			register_atlas_source(last_atlas_source_count-1, 1, tile_id, Vector2i.ZERO)

			var texture_path = tile["image"]
			_current_atlas_source.texture = load_image(texture_path)
			_current_atlas_source.resource_name = texture_path.get_file().get_basename()
			var texture_width = _current_atlas_source.texture.get_width()
			if tile.has("width"):
				texture_width = tile["width"]
			var texture_height = _current_atlas_source.texture.get_height()
			if tile.has("height"):
				texture_height = tile["height"]
			_current_atlas_source.texture_region_size = Vector2i(texture_width, texture_height)
			var tile_offset_x = 0
			if tile.has("x"):
				tile_offset_x = tile["x"]
			var tile_offset_y = 0
			if tile.has("y"):
				tile_offset_y = tile["y"]
			_current_atlas_source.margins = Vector2i(tile_offset_x, tile_offset_y)

			_current_atlas_source.create_tile(Vector2(0, 0))
			current_tile = _current_atlas_source.get_tile_data(Vector2(0, 0), 0)
			current_tile.probability = tile.get("probability", 1.0)
		else:
			current_tile = create_tile_if_not_existing_and_get_tiledata(tile_id)
			if current_tile == null:
				#Error occurred
				continue

		if _tile_size.x != _map_tile_size.x or _tile_size.y != _map_tile_size.y:
			var diff_x = _tile_size.x - _map_tile_size.x
			if diff_x % 2 != 0:
				diff_x -= 1
			var diff_y = _tile_size.y - _map_tile_size.y
			if diff_y % 2 != 0:
				diff_y += 1
			current_tile.texture_origin = Vector2i(-diff_x/2, diff_y/2) - _tile_offset
				
		if tile.has("probability"):
			current_tile.probability = tile["probability"]
		if tile.has("animation"):
			handle_animation(tile["animation"], tile_id)
		if tile.has("objectgroup"):
			handle_objectgroup(tile["objectgroup"], current_tile)
		if tile.has("properties"):
			handle_tile_properties(tile["properties"], current_tile)
	
	_atlas_source_counter = max_last_atlas_source_count


func handle_animation(frames: Array, tile_id: int) -> void:
	var frame_count: int = 0
	var separation_x: int = 0
	var separation_y: int = 0
	var separation_vect = Vector2(separation_x, separation_y)
	var anim_columns: int = 0
	var tile_coords = Vector2(tile_id % _columns, tile_id / _columns)
	var max_diff_x = _columns - tile_coords.x
	var max_diff_y = _tile_count / _columns - tile_coords.y
	var diff_x = 0
	var diff_y = 0
	for frame in frames:
		frame_count += 1
		var frame_tile_id: int = frame["tileid"]
		if frame_count == 2:
			diff_x = (frame_tile_id - tile_id) % _columns
			diff_y = (frame_tile_id - tile_id) / _columns
			if diff_x == 0 and diff_y > 0 and diff_y < max_diff_y:
				separation_y = diff_y - 1
				anim_columns = 1
			elif diff_y == 0 and diff_x > 0 and diff_x < max_diff_x:
				separation_x = diff_x - 1
				anim_columns = 0
			else:
				print_rich("[color="+WARNING_COLOR+"] -- Animated tile " + str(tile_id) + ": Succession of tiles not supported in Godot 4. -> Skipped[/color]")
				_warning_count += 1
				return
			separation_vect = Vector2(separation_x, separation_y)

		if frame_count > 1 and frame_count < frames.size():
			var next_frame_tile_id: int = frames[frame_count]["tileid"]
			var compare_diff_x = (next_frame_tile_id - frame_tile_id) % _columns
			var compare_diff_y = (next_frame_tile_id - frame_tile_id) / _columns
			if compare_diff_x != diff_x or compare_diff_y != diff_y:
				print_rich("[color="+WARNING_COLOR+"] -- Animated tile " + str(tile_id) + ": Succession of tiles not supported in Godot 4. -> Skipped[/color]")
				_warning_count += 1
				return

		if _current_atlas_source.has_room_for_tile(tile_coords, Vector2.ONE, anim_columns, separation_vect, frame_count, tile_coords):
			_current_atlas_source.set_tile_animation_separation(tile_coords, separation_vect)
			_current_atlas_source.set_tile_animation_columns(tile_coords, anim_columns)
			_current_atlas_source.set_tile_animation_frames_count(tile_coords, frame_count)
			var duration_in_secs = 1.0
			if "duration" in frame:
				duration_in_secs = float(frame["duration"]) / 1000.0
			_current_atlas_source.set_tile_animation_frame_duration(tile_coords, frame_count-1, duration_in_secs)
		else:
			print_rich("[color="+WARNING_COLOR+"] -- TileId " + str(tile_id) +": Not enough room for all animation frames, could only set " + str(frame_count) + " frames.[/color]")
			_warning_count += 1
			break


func handle_objectgroup(object_group: Dictionary, current_tile: TileData):

	# v1.2:
	_object_groups_counter += 1
	register_object_group(_object_groups_counter, object_group)
	current_tile.set_custom_data(CUSTOM_DATA_INTERNAL, _object_groups_counter)
	
	var polygon_index = -1
	var objects = object_group["objects"] as Array
	for obj in objects:
		if obj.has("point") and obj["point"]:
			# print_rich("[color="+WARNING_COLOR+"] -- 'Point' has currently no corresponding tileset element in Godot 4. -> Skipped[/color]")
			# _warning_count += 1
			break
		if obj.has("ellipse") and obj["ellipse"]:
			# print_rich("[color="+WARNING_COLOR+"] -- 'Ellipse' has currently no corresponding tileset element in Godot 4. -> Skipped[/color]")
			# _warning_count += 1
			break

		var object_base_coords = Vector2(obj["x"], obj["y"])
		object_base_coords = transpose_coords(object_base_coords.x, object_base_coords.y)
		object_base_coords -= Vector2(current_tile.texture_origin)
		if _tileset_orientation == "isometric":
			object_base_coords.y -= _grid_size.y / 2.0
			if _grid_size.y != _tile_size.y:
				object_base_coords.y += (_tile_size.y - _grid_size.y) / 2.0
		else:
			object_base_coords -= Vector2(_tile_size / 2.0)

		var rot = obj.get("rotation", 0.0)
		var sin_a = sin(rot * PI / 180.0)
		var cos_a = cos(rot * PI / 180.0)

		var polygon
		if obj.has("polygon"):
			var polygon_points = obj["polygon"] as Array
			polygon = []
			for pt in polygon_points:
				var p_coord = transpose_coords(pt["x"], pt["y"])
				var p_coord_rot = Vector2(p_coord.x * cos_a - p_coord.y * sin_a, p_coord.x * sin_a + p_coord.y * cos_a)
				polygon.append(object_base_coords + p_coord_rot)
		else:
			# Should be a simple rectangle
			polygon = [Vector2(), Vector2(), Vector2(), Vector2()]
			polygon[0] = Vector2.ZERO
			polygon[1].y = polygon[0].y + obj["height"]
			polygon[1].x = polygon[0].x
			polygon[2].y = polygon[1].y
			polygon[2].x = polygon[0].x + obj["width"]
			polygon[3].y = polygon[0].y
			polygon[3].x = polygon[2].x
			var i = 0
			for pt in polygon:
				var pt_trans = transpose_coords(pt.x, pt.y)
				var pt_rot = Vector2(pt_trans.x * cos_a - pt_trans.y * sin_a, pt_trans.x * sin_a + pt_trans.y * cos_a)
				polygon[i] = object_base_coords + pt_rot
				i += 1

		var nav = get_layer_number_for_special_property(obj, "navigation_layer")
		if nav >= 0:
			var nav_p = NavigationPolygon.new()
			nav_p.add_outline(polygon)
			nav_p.make_polygons_from_outlines()
			ensure_layer_existing(layer_type.NAVIGATION, nav)
			current_tile.set_navigation_polygon(nav, nav_p)

		var occ = get_layer_number_for_special_property(obj, "occlusion_layer")
		if occ >= 0:
			var occ_p = OccluderPolygon2D.new()
			occ_p.polygon = polygon
			ensure_layer_existing(layer_type.OCCLUSION, occ)
			current_tile.set_occluder(occ, occ_p)

		var phys = get_layer_number_for_special_property(obj, "physics_layer")
		# If no property is specified assume collision (i.e. default)
		if phys < 0 and nav < 0 and occ < 0:
			phys = 0
		if phys < 0: continue
		polygon_index += 1
		ensure_layer_existing(layer_type.PHYSICS, phys)
		current_tile.add_collision_polygon(phys)
		current_tile.set_collision_polygon_points(phys, polygon_index, polygon)
		if not obj.has("properties"): continue
		for property in obj["properties"]:
			var name = property.get("name", "")
			var type = property.get("type", "string")
			var val = property.get("value", "")
			if name == "": continue
			if name.to_lower() == "one_way" and type == "bool":
				current_tile.set_collision_polygon_one_way(phys, polygon_index, val.to_lower() == "true")
			elif name.to_lower() == "one_way_margin" and type == "int":
				current_tile.set_collision_polygon_one_way_margin(phys, polygon_index, int(val))


func transpose_coords(x: float, y: float):
	if _tileset_orientation == "isometric":
		var trans_x = (x - y) * _grid_size.x / _grid_size.y / 2.0
		var trans_y = (x + y) * 0.5
		return Vector2(trans_x, trans_y)

	return Vector2(x, y)


func get_layer_number_for_special_property(dict: Dictionary, property_name: String):
	if not dict.has("properties"): return -1
	for	property in dict["properties"]:
		var name = property.get("name", "")
		var type = property.get("type", "string")
		var val = property.get("value", "")
		if name == "": continue
		if name.to_lower() == property_name and type == "int":
			return int(val)
	return -1


func load_resource_from_file(path: String):
	var orig_path = path
	var ret: Texture2D = null
	# ToDo: Not sure if this first check makes any sense since an image can't be properly imported if not in project tree
	if not FileAccess.file_exists(path):
		path = _base_path_map.get_base_dir().path_join(orig_path)
	if not FileAccess.file_exists(path):
		path = _base_path_tileset.path_join(orig_path)
	if FileAccess.file_exists(path):
		ret = ResourceLoader.load(path)
	else:
		printerr("ERROR: Resource file '" + orig_path + "' not found.")
		_error_count += 1
		return ret


func get_bitmask_integer_from_string(mask_string: String, max: int):
	var ret: int = 0
	var s1_arr = mask_string.split(",", false)
	for s1 in s1_arr:
		if s1.contains("-"):
			var s2_arr = s1.split("-", false, 1)
			var i1 = int(s2_arr[0]) if s2_arr[0].is_valid_int() else 0
			var i2 = int(s2_arr[1]) if s2_arr[1].is_valid_int() else 0
			if i1 == 0 or i2 == 0 or i1 > i2: continue
			for i in range(i1, i2+1):
				if i <= max:
					ret += pow(2, i-1)
		elif s1.is_valid_int():
			var i = int(s1)
			if i <= max:
				ret += pow(2, i-1)
	return ret


func get_right_typed_value(type: String, val: String):
	if type == "bool":
		return val == "true"
	elif type == "float":
		return float(val)
	elif type == "int":
		return int(val)
	elif type == "color":
		# If alpha is present it's strangely the first byte, so we have to shift it to the end
		if val.length() == 9: val = val[0] + val.substr(3) + val.substr(1,2)
		return val
	else:
		return val


func handle_tile_properties(properties: Array, current_tile: TileData):
	for property in properties:
		var name = property.get("name", "")
		var type = property.get("type", "string")
		var val = str(property.get("value", ""))
		if name == "": continue
		if name.to_lower() == "texture_origin_x" and  type == "int":
			current_tile.texture_origin = Vector2i(int(val), current_tile.texture_origin.y)
		elif name.to_lower() == "texture_origin_y" and  type == "int":
			current_tile.texture_origin = Vector2i(current_tile.texture_origin.x, int(val))
		elif name.to_lower() == "modulate" and  type == "string":
			current_tile.modulate = Color(val)
		elif name.to_lower() == "material" and  type == "file":
			current_tile.material = load_resource_from_file(val)
		elif name.to_lower() == "z_index" and  type == "int":
			current_tile.z_index = int(val)
		elif name.to_lower() == "y_sort_origin" and  type == "int":
			current_tile.y_sort_origin = int(val)
		elif name.to_lower() == "linear_velocity_x" and (type == "int" or type == "float"):
			ensure_layer_existing(layer_type.PHYSICS, 0)
			var lin_velo = current_tile.get_constant_linear_velocity(0)
			lin_velo.x = float(val)
			current_tile.set_constant_linear_velocity(0, lin_velo)
		elif name.to_lower().begins_with("linear_velocity_x_") and (type == "int" or type == "float"):
			if not name.substr(18).is_valid_int(): continue
			var layer_index = int(name.substr(18))
			ensure_layer_existing(layer_type.PHYSICS, layer_index)
			var lin_velo = current_tile.get_constant_linear_velocity(layer_index)
			lin_velo.x = float(val)
			current_tile.set_constant_linear_velocity(layer_index, lin_velo)
		elif name.to_lower() == "linear_velocity_y" and (type == "int" or type == "float"):
			ensure_layer_existing(layer_type.PHYSICS, 0)
			var lin_velo = current_tile.get_constant_linear_velocity(0)
			lin_velo.y = float(val)
			current_tile.set_constant_linear_velocity(0, lin_velo)
		elif name.to_lower().begins_with("linear_velocity_y_") and (type == "int" or type == "float"):
			if not name.substr(18).is_valid_int(): continue
			var layer_index = int(name.substr(18))
			ensure_layer_existing(layer_type.PHYSICS, layer_index)
			var lin_velo = current_tile.get_constant_linear_velocity(layer_index)
			lin_velo.y = float(val)
			current_tile.set_constant_linear_velocity(layer_index, lin_velo)
		elif name.to_lower() == "angular_velocity" and (type == "int" or type == "float"):
			ensure_layer_existing(layer_type.PHYSICS, 0)
			current_tile.set_constant_angular_velocity(0, float(val))
		elif name.to_lower().begins_with("angular_velocity_") and (type == "int" or type == "float"):
			if not name.substr(17).is_valid_int(): continue
			var layer_index = int(name.substr(17))
			ensure_layer_existing(layer_type.PHYSICS, layer_index)
			current_tile.set_constant_angular_velocity(layer_index, float(val))
		else:
			var custom_layer = _tileset.get_custom_data_layer_by_name(name)
			if custom_layer < 0:
				_tileset.add_custom_data_layer()
				custom_layer = _tileset.get_custom_data_layers_count() - 1
				_tileset.set_custom_data_layer_name(custom_layer, name)
				var custom_type = {
					"bool": TYPE_BOOL,
					"int": TYPE_INT,
					"string": TYPE_STRING,
					"float": TYPE_FLOAT,
					"color": TYPE_COLOR
				}.get(type, TYPE_STRING)
				_tileset.set_custom_data_layer_type(custom_layer, custom_type)
			current_tile.set_custom_data(name, get_right_typed_value(type, val))


func handle_tileset_properties(properties: Array):
	for property in properties:
		var name = property.get("name", "")
		var type = property.get("type", "string")
		var val = str(property.get("value", ""))
		if name == "": continue
		var layer_index
		if name.to_lower() == "collision_layer" and type == "string":
			ensure_layer_existing(layer_type.PHYSICS, 0)
			_tileset.set_physics_layer_collision_layer(0, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower().begins_with("collision_layer_") and type == "string":
			if not name.substr(16).is_valid_int(): continue
			layer_index = int(name.substr(16))
			ensure_layer_existing(layer_type.PHYSICS, layer_index)
			_tileset.set_physics_layer_collision_layer(layer_index, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower() == "collision_mask" and type == "string":
			ensure_layer_existing(layer_type.PHYSICS, 0)
			_tileset.set_physics_layer_collision_mask(0, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower().begins_with("collision_mask_") and type == "string":
			if not name.substr(15).is_valid_int(): continue
			layer_index = int(name.substr(15))
			ensure_layer_existing(layer_type.PHYSICS, layer_index)
			_tileset.set_physics_layer_collision_mask(layer_index, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower() == "layers" and type == "string":
			ensure_layer_existing(layer_type.NAVIGATION, 0)
			_tileset.set_navigation_layer_layers(0, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower().begins_with("layers_") and type == "string":
			if not name.substr(7).is_valid_int(): continue
			layer_index = int(name.substr(7))
			ensure_layer_existing(layer_type.NAVIGATION, layer_index)
			_tileset.set_navigation_layer_layers(layer_index, get_bitmask_integer_from_string(val, 32))
		elif name.to_lower() == "light_mask" and type == "string":
			ensure_layer_existing(layer_type.OCCLUSION, 0)
			_tileset.set_occlusion_layer_light_mask(0, get_bitmask_integer_from_string(val, 20))
		elif name.to_lower().begins_with("light_mask_") and type == "string":
			if not name.substr(11).is_valid_int(): continue
			layer_index = int(name.substr(11))
			ensure_layer_existing(layer_type.OCCLUSION, layer_index)
			_tileset.set_occlusion_layer_light_mask(layer_index, get_bitmask_integer_from_string(val, 20))
		elif name.to_lower() == "sdf_collision_" and type == "bool":
			ensure_layer_existing(layer_type.OCCLUSION, 0)
			_tileset.set_occlusion_layer_sdf_collision(0, val.to_lower() == "true")
		elif name.to_lower().begins_with("sdf_collision_") and type == "bool":
			if not name.substr(14).is_valid_int(): continue
			layer_index = int(name.substr(14))
			ensure_layer_existing(layer_type.OCCLUSION, layer_index)
			_tileset.set_occlusion_layer_sdf_collision(layer_index, val.to_lower() == "true")
		else:
			_tileset.set_meta(name, get_right_typed_value(type, val))


func ensure_layer_existing(tp: layer_type, layer: int):
	match tp:
		layer_type.PHYSICS:
			while _physics_layer_counter < layer:
				_tileset.add_physics_layer()
				_physics_layer_counter += 1
		layer_type.NAVIGATION:
			while _navigation_layer_counter < layer:
				_tileset.add_navigation_layer()
				_navigation_layer_counter += 1
		layer_type.OCCLUSION:
			while _occlusion_layer_counter < layer:
				_tileset.add_occlusion_layer()
				_occlusion_layer_counter += 1
	

func handle_wangsets_old_mapping(wangsets):
	_tileset.add_terrain_set()
	_terrain_sets_counter += 1
	for wangset in wangsets:
		var current_terrain_set = _terrain_sets_counter
		_tileset.add_terrain(current_terrain_set)
		var current_terrain = _terrain_counter
		if "name" in wangset:
			_tileset.set_terrain_name(current_terrain_set, _terrain_counter, wangset["name"])

		var terrain_mode = TileSet.TERRAIN_MODE_MATCH_CORNERS
		if wangset.has("type"):
			terrain_mode = {
				"corner": TileSet.TERRAIN_MODE_MATCH_CORNERS,
				"edge": TileSet.TERRAIN_MODE_MATCH_SIDES,
				"mixed": TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES
			}.get(wangset["type"], terrain_mode)

		_tileset.set_terrain_set_mode(current_terrain_set, terrain_mode)

		if wangset.has("colors"):
			_tileset.set_terrain_color(current_terrain_set, _terrain_counter, Color(wangset["colors"][0]["color"]))

		if wangset.has("wangtiles"):
			for wangtile in wangset["wangtiles"]:
				var tile_id = wangtile["tileid"]
				var current_tile = create_tile_if_not_existing_and_get_tiledata(tile_id)
				if current_tile == null:
					break

				if _tile_size.x != _map_tile_size.x or _tile_size.y != _map_tile_size.y:
					var diff_x = _tile_size.x - _map_tile_size.x
					if diff_x % 2 != 0:
						diff_x -= 1
					var diff_y = _tile_size.y - _map_tile_size.y
					if diff_y % 2 != 0:
						diff_y += 1
					current_tile.texture_origin = Vector2i(-diff_x/2, diff_y/2) - _tile_offset

				current_tile.terrain_set = current_terrain_set
				current_tile.terrain = current_terrain
				var i = 0
				for wi in wangtile["wangid"]:
					var peering_bit = {
						1: TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
						2: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
						3: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
						4: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
						5: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
						6: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
						7: TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
					}.get(i, TileSet.CELL_NEIGHBOR_TOP_SIDE)
					if wi > 0:
						current_tile.set_terrain_peering_bit(peering_bit, current_terrain)
					i += 1

		_terrain_counter += 1


func handle_wangsets(wangsets):
	for wangset in wangsets:
		_tileset.add_terrain_set()
		_terrain_sets_counter += 1
		_terrain_counter = -1
		var current_terrain_set = _terrain_sets_counter

		var current_terrain = _terrain_counter
		var terrain_set_name = ""
		if "name" in wangset:
			terrain_set_name = wangset["name"]

		var terrain_mode = TileSet.TERRAIN_MODE_MATCH_CORNERS
		if wangset.has("type"):
			terrain_mode = {
				"corner": TileSet.TERRAIN_MODE_MATCH_CORNERS,
				"edge": TileSet.TERRAIN_MODE_MATCH_SIDES,
				"mixed": TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES
			}.get(wangset["type"], terrain_mode)

		_tileset.set_terrain_set_mode(current_terrain_set, terrain_mode)

		if wangset.has("colors"):
			for wangcolor in wangset["colors"]:
				_terrain_counter += 1
				_tileset.add_terrain(current_terrain_set)
				_tileset.set_terrain_color(current_terrain_set, _terrain_counter, Color(wangcolor["color"]))
				var col_name = terrain_set_name
				if wangcolor.has("name"):
					if wangcolor["name"] != "":
						col_name = wangcolor["name"]
				_tileset.set_terrain_name(current_terrain_set, _terrain_counter, col_name)

		if wangset.has("wangtiles"):
			for wangtile in wangset["wangtiles"]:
				var tile_id = wangtile["tileid"]
				var current_tile = create_tile_if_not_existing_and_get_tiledata(tile_id)
				if current_tile == null:
					break

				if _tile_size.x != _map_tile_size.x or _tile_size.y != _map_tile_size.y:
					var diff_x = _tile_size.x - _map_tile_size.x
					if diff_x % 2 != 0:
						diff_x -= 1
					var diff_y = _tile_size.y - _map_tile_size.y
					if diff_y % 2 != 0:
						diff_y += 1
					current_tile.texture_origin = Vector2i(-diff_x/2, diff_y/2) - _tile_offset

				current_tile.terrain_set = current_terrain_set
				var i = 0
				for wi in wangtile["wangid"]:
					var peering_bit = {
						1: TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
						2: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
						3: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
						4: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
						5: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
						6: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
						7: TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
					}.get(i, TileSet.CELL_NEIGHBOR_TOP_SIDE)
					if wi > 0:
						current_tile.terrain = wi-1
						current_tile.set_terrain_peering_bit(peering_bit, wi-1)
					i += 1
# MIT License
#
# Copyright (c) 2023 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

var _parser = null
var _parsed_file_name = ""

func _init():
	_parser = XMLParser.new()

func open(source_file) -> int:
	_parsed_file_name = source_file
	return _parser.open(_parsed_file_name)

func next_element() -> String:
	var err = parse_on()
	if err != OK:
		return ""
	if _parser.get_node_type() == XMLParser.NODE_TEXT:
		var text = _parser.get_node_data().strip_edges(true, true)
		if text.length() > 0:
			return "<data>"
	while _parser.get_node_type() != XMLParser.NODE_ELEMENT and _parser.get_node_type() != XMLParser.NODE_ELEMENT_END:
		err = parse_on()
		if err != OK:
			return ""
	return _parser.get_node_name()

func is_end() -> bool:
	return _parser.get_node_type() == XMLParser.NODE_ELEMENT_END

func is_empty() -> bool:
	return _parser.is_empty()

func get_data() -> String:
	return _parser.get_node_data()

func get_attributes() -> Dictionary:
	var attributes = {}
	for i in range(_parser.get_attribute_count()):
		attributes[_parser.get_attribute_name(i)] = _parser.get_attribute_value(i)
	return attributes

func parse_on() -> int:
	var err = _parser.read()
	if err != OK:
		printerr("Error parsing file '" + _parsed_file_name + "' (around line " + str(_parser.get_current_line()) + ").")
	return err
��KlBNRSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       PackedScene    res://Ratlantis.tmx �?�
P�Ee   PackedScene    res://rat_player.tscn 2���.2      local://PackedScene_84600 B         PackedScene          	         names "      
   GameLevel    texture_filter    Node2D 
   Ratlantis 
   RatPlayer    	   variants                                      node_count             nodes        ��������       ����                      ���                      ���                    conn_count              conns               node_paths              editable_instances              version             RSRC�|G�ب[gd_scene load_steps=5 format=3]

[ext_resource type="Texture2D" uid="uid://bgsd3crbauls" path="res://sewerstilemap.png" id="1_tg46a"]

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_vswgx"]
texture = ExtResource("1_tg46a")
7:0/0 = 0
7:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
7:0/0/physics_layer_0/angular_velocity = 0.0
7:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, -8, 8, 8, 8, 8, -8)
8:0/0 = 0
8:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
8:0/0/physics_layer_0/angular_velocity = 0.0
8:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, -8, 8, 8, 8, 8, -8)
9:0/0 = 0
9:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
9:0/0/physics_layer_0/angular_velocity = 0.0
9:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, -8, 8, 8, 8, 8, -8)
0:1/0 = 0
0:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
0:1/0/physics_layer_0/angular_velocity = 0.0
5:1/0 = 0
5:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
5:1/0/physics_layer_0/angular_velocity = 0.0
3:1/0 = 0
3:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
3:1/0/physics_layer_0/angular_velocity = 0.0
2:1/0 = 0
2:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
2:1/0/physics_layer_0/angular_velocity = 0.0
7:1/0 = 0
7:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
7:1/0/physics_layer_0/angular_velocity = 0.0
4:1/0 = 0
4:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
4:1/0/physics_layer_0/angular_velocity = 0.0
8:1/0 = 0
8:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
8:1/0/physics_layer_0/angular_velocity = 0.0
6:1/0 = 0
6:1/0/physics_layer_0/linear_velocity = Vector2(0, 0)
6:1/0/physics_layer_0/angular_velocity = 0.0
4:0/next_alternative_id = 2
4:0/0 = 0
4:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
4:0/0/physics_layer_0/angular_velocity = 0.0
4:0/4 = 4
4:0/4/transpose = true
4:0/4/physics_layer_0/linear_velocity = Vector2(0, 0)
4:0/4/physics_layer_0/angular_velocity = 0.0
4:0/7 = 7
4:0/7/flip_h = true
4:0/7/flip_v = true
4:0/7/transpose = true
4:0/7/physics_layer_0/linear_velocity = Vector2(0, 0)
4:0/7/physics_layer_0/angular_velocity = 0.0
4:0/1 = 1
4:0/1/flip_h = true
4:0/1/physics_layer_0/linear_velocity = Vector2(0, 0)
4:0/1/physics_layer_0/angular_velocity = 0.0
6:0/0 = 0
6:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
6:0/0/physics_layer_0/angular_velocity = 0.0
6:0/4 = 4
6:0/4/transpose = true
6:0/4/physics_layer_0/linear_velocity = Vector2(0, 0)
6:0/4/physics_layer_0/angular_velocity = 0.0
6:0/7 = 7
6:0/7/flip_h = true
6:0/7/flip_v = true
6:0/7/transpose = true
6:0/7/physics_layer_0/linear_velocity = Vector2(0, 0)
6:0/7/physics_layer_0/angular_velocity = 0.0
5:0/next_alternative_id = 2
5:0/0 = 0
5:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
5:0/0/physics_layer_0/angular_velocity = 0.0
5:0/4 = 4
5:0/4/transpose = true
5:0/4/physics_layer_0/linear_velocity = Vector2(0, 0)
5:0/4/physics_layer_0/angular_velocity = 0.0
5:0/7 = 7
5:0/7/flip_h = true
5:0/7/flip_v = true
5:0/7/transpose = true
5:0/7/physics_layer_0/linear_velocity = Vector2(0, 0)
5:0/7/physics_layer_0/angular_velocity = 0.0
5:0/1 = 1
5:0/1/flip_h = true
5:0/1/physics_layer_0/linear_velocity = Vector2(0, 0)
5:0/1/physics_layer_0/angular_velocity = 0.0
13:0/0 = 0
13:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
13:0/0/physics_layer_0/angular_velocity = 0.0
10:0/0 = 0
10:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
10:0/0/physics_layer_0/angular_velocity = 0.0
10:0/5 = 5
10:0/5/flip_h = true
10:0/5/transpose = true
10:0/5/physics_layer_0/linear_velocity = Vector2(0, 0)
10:0/5/physics_layer_0/angular_velocity = 0.0
10:0/3 = 3
10:0/3/flip_h = true
10:0/3/flip_v = true
10:0/3/physics_layer_0/linear_velocity = Vector2(0, 0)
10:0/3/physics_layer_0/angular_velocity = 0.0
12:0/0 = 0
12:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
12:0/0/physics_layer_0/angular_velocity = 0.0
12:0/5 = 5
12:0/5/flip_h = true
12:0/5/transpose = true
12:0/5/physics_layer_0/linear_velocity = Vector2(0, 0)
12:0/5/physics_layer_0/angular_velocity = 0.0
12:0/3 = 3
12:0/3/flip_h = true
12:0/3/flip_v = true
12:0/3/physics_layer_0/linear_velocity = Vector2(0, 0)
12:0/3/physics_layer_0/angular_velocity = 0.0
11:0/0 = 0
11:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
11:0/0/physics_layer_0/angular_velocity = 0.0
11:0/5 = 5
11:0/5/flip_h = true
11:0/5/transpose = true
11:0/5/physics_layer_0/linear_velocity = Vector2(0, 0)
11:0/5/physics_layer_0/angular_velocity = 0.0
14:0/next_alternative_id = 2
14:0/0 = 0
14:0/0/physics_layer_0/linear_velocity = Vector2(0, 0)
14:0/0/physics_layer_0/angular_velocity = 0.0
14:0/1 = 1
14:0/1/flip_h = true
14:0/1/physics_layer_0/linear_velocity = Vector2(0, 0)
14:0/1/physics_layer_0/angular_velocity = 0.0

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_vcng0"]
texture = ExtResource("1_tg46a")

[sub_resource type="TileSet" id="TileSet_rdl6d"]
physics_layer_0/collision_layer = 1
sources/0 = SubResource("TileSetAtlasSource_vswgx")
sources/1 = SubResource("TileSetAtlasSource_vcng0")

[node name="Ratlantis" type="Node2D"]

[node name="Tile Layer 1" type="TileMap" parent="."]
texture_filter = 1
tile_set = SubResource("TileSet_rdl6d")
format = 2
layer_0/tile_data = PackedInt32Array(0, 0, 1, 1, 0, 1, 2, 0, 1, 3, 0, 1, 4, 0, 1, 5, 0, 1, 6, 0, 1, 7, 0, 1, 8, 0, 1, 9, 0, 1, 10, 0, 1, 11, 0, 1, 12, 0, 1, 13, 0, 1, 14, 0, 1, 15, 0, 1, 16, 0, 1, 17, 0, 1, 18, 0, 1, 19, 0, 1, 20, 0, 1, 21, 0, 1, 22, 0, 1, 23, 0, 1, 24, 0, 1, 25, 0, 1, 26, 0, 1, 27, 0, 1, 28, 0, 1, 29, 0, 1, 30, 0, 1, 31, 0, 1, 65536, 0, 1, 65537, 0, 1, 65538, 0, 1, 65539, 0, 1, 65540, 0, 1, 65541, 0, 1, 65542, 0, 1, 65543, 0, 1, 65544, 0, 1, 65545, 0, 1, 65546, 0, 1, 65547, 0, 1, 65548, 0, 1, 65549, 0, 1, 65550, 0, 1, 65551, 0, 1, 65552, 0, 1, 65553, 0, 1, 65554, 0, 1, 65555, 0, 1, 65556, 0, 1, 65557, 0, 1, 65558, 0, 1, 65559, 0, 1, 65560, 0, 1, 65561, 0, 1, 65562, 0, 1, 65563, 0, 1, 65564, 0, 1, 65565, 0, 1, 65566, 0, 1, 65567, 0, 1, 131072, 0, 1, 131073, 0, 1, 131074, 0, 1, 131075, 0, 1, 131076, 0, 1, 131077, 0, 1, 131078, 0, 1, 131079, 0, 1, 131080, 0, 1, 131081, 0, 1, 131082, 0, 1, 131083, 0, 1, 131084, 0, 1, 131085, 0, 1, 131086, 0, 1, 131087, 0, 1, 131088, 0, 1, 131089, 0, 1, 131090, 0, 1, 131091, 0, 1, 131092, 0, 1, 131093, 0, 1, 131094, 0, 1, 131095, 0, 1, 131096, 0, 1, 131097, 0, 1, 131098, 0, 1, 131099, 0, 1, 131100, 0, 1, 131101, 0, 1, 131102, 0, 1, 131103, 0, 1, 196608, 0, 1, 196609, 0, 1, 196610, 0, 1, 196611, 0, 1, 196612, 0, 1, 196613, 0, 1, 196614, 0, 1, 196615, 0, 1, 196616, 0, 1, 196617, 0, 1, 196618, 0, 1, 196619, 0, 1, 196620, 0, 1, 196621, 0, 1, 196622, 0, 1, 196623, 0, 1, 196624, 0, 1, 196625, 0, 1, 196626, 0, 1, 196627, 0, 1, 196628, 0, 1, 196629, 0, 1, 196630, 0, 1, 196631, 0, 1, 196632, 0, 1, 196633, 0, 1, 196634, 0, 1, 196635, 0, 1, 196636, 0, 1, 196637, 0, 1, 196638, 0, 1, 196639, 0, 1, 262144, 0, 1, 262145, 0, 1, 262146, 0, 1, 262147, 0, 1, 262148, 0, 1, 262149, 0, 1, 262150, 524288, 0, 262151, 524288, 0, 262152, 458752, 0, 262153, 524288, 0, 262154, 589824, 0, 262155, 524288, 0, 262156, 458752, 0, 262157, 524288, 0, 262158, 589824, 0, 262159, 524288, 0, 262160, 458752, 0, 262161, 524288, 0, 262162, 589824, 0, 262163, 458752, 0, 262164, 524288, 0, 262165, 458752, 0, 262166, 458752, 0, 262167, 458752, 0, 262168, 524288, 0, 262169, 458752, 0, 262170, 458752, 0, 262171, 524288, 0, 262172, 589824, 0, 262173, 458752, 0, 262174, 0, 1, 262175, 0, 1, 327680, 0, 1, 327681, 0, 1, 327682, 0, 1, 327683, 0, 1, 327684, 0, 1, 327685, 0, 1, 327686, 524288, 0, 327687, 589824, 0, 327688, 524288, 0, 327689, 524288, 0, 327690, 524288, 0, 327691, 524288, 0, 327692, 524288, 0, 327693, 589824, 0, 327694, 589824, 0, 327695, 524288, 0, 327696, 458752, 0, 327697, 524288, 0, 327698, 458752, 0, 327699, 524288, 0, 327700, 458752, 0, 327701, 524288, 0, 327702, 458752, 0, 327703, 458752, 0, 327704, 524288, 0, 327705, 589824, 0, 327706, 524288, 0, 327707, 524288, 0, 327708, 589824, 0, 327709, 589824, 0, 327710, 0, 1, 327711, 0, 1, 393216, 0, 1, 393217, 0, 1, 393218, 0, 1, 393219, 0, 1, 393220, 0, 1, 393221, 0, 1, 393222, 524288, 0, 393223, 589824, 0, 393224, 589824, 0, 393225, 589824, 0, 393226, 589824, 0, 393227, 458752, 0, 393228, 458752, 0, 393229, 458752, 0, 393230, 524288, 0, 393231, 524288, 0, 393232, 524288, 0, 393233, 589824, 0, 393234, 524288, 0, 393235, 458752, 0, 393236, 458752, 0, 393237, 458752, 0, 393238, 589824, 0, 393239, 458752, 0, 393240, 458752, 0, 393241, 524288, 0, 393242, 524288, 0, 393243, 589824, 0, 393244, 524288, 0, 393245, 524288, 0, 393246, 0, 1, 393247, 0, 1, 458752, 0, 1, 458753, 0, 1, 458754, 0, 1, 458755, 0, 1, 458756, 0, 1, 458757, 0, 1, 458758, 524288, 0, 458759, 589824, 0, 458760, 589824, 0, 458761, 458752, 0, 458762, 589824, 0, 458763, 589824, 0, 458764, 458752, 0, 458765, 589824, 0, 458766, 458752, 0, 458767, 458752, 0, 458768, 589824, 0, 458769, 589824, 0, 458770, 524288, 0, 458771, 458752, 0, 458772, 458752, 0, 458773, 458752, 0, 458774, 524288, 0, 458775, 524288, 0, 458776, 589824, 0, 458777, 458752, 0, 458778, 458752, 0, 458779, 524288, 0, 458780, 458752, 0, 458781, 524288, 0, 458782, 0, 1, 458783, 0, 1, 524288, 0, 1, 524289, 0, 1, 524290, 0, 1, 524291, 0, 1, 524292, 0, 1, 524293, 0, 1, 524294, 589824, 0, 524295, 589824, 0, 524296, 589824, 0, 524297, 458752, 0, 524298, 0, 1, 524299, 0, 1, 524300, 0, 1, 524301, 0, 1, 524302, 0, 1, 524303, 0, 1, 524304, 0, 1, 524305, 0, 1, 524306, 0, 1, 524307, 0, 1, 524308, 0, 1, 524309, 0, 1, 524310, 0, 1, 524311, 0, 1, 524312, 0, 1, 524313, 0, 1, 524314, 0, 1, 524315, 0, 1, 524316, 0, 1, 524317, 0, 1, 524318, 0, 1, 524319, 0, 1, 589824, 0, 1, 589825, 0, 1, 589826, 0, 1, 589827, 0, 1, 589828, 0, 1, 589829, 0, 1, 589830, 589824, 0, 589831, 524288, 0, 589832, 458752, 0, 589833, 524288, 0, 589834, 0, 1, 589835, 0, 1, 589836, 0, 1, 589837, 0, 1, 589838, 0, 1, 589839, 0, 1, 589840, 0, 1, 589841, 0, 1, 589842, 0, 1, 589843, 0, 1, 589844, 0, 1, 589845, 0, 1, 589846, 0, 1, 589847, 0, 1, 589848, 0, 1, 589849, 0, 1, 589850, 0, 1, 589851, 0, 1, 589852, 0, 1, 589853, 0, 1, 589854, 0, 1, 589855, 0, 1, 655360, 0, 1, 655361, 0, 1, 655362, 0, 1, 655363, 0, 1, 655364, 0, 1, 655365, 0, 1, 655366, 589824, 0, 655367, 458752, 0, 655368, 589824, 0, 655369, 524288, 0, 655370, 0, 1, 655371, 0, 1, 655372, 0, 1, 655373, 0, 1, 655374, 0, 1, 655375, 0, 1, 655376, 0, 1, 655377, 0, 1, 655378, 0, 1, 655379, 0, 1, 655380, 0, 1, 655381, 0, 1, 655382, 0, 1, 655383, 0, 1, 655384, 0, 1, 655385, 0, 1, 655386, 0, 1, 655387, 0, 1, 655388, 0, 1, 655389, 0, 1, 655390, 0, 1, 655391, 0, 1, 720896, 0, 1, 720897, 0, 1, 720898, 0, 1, 720899, 0, 1, 720900, 0, 1, 720901, 0, 1, 720902, 458752, 0, 720903, 524288, 0, 720904, 458752, 0, 720905, 524288, 0, 720906, 0, 1, 720907, 0, 1, 720908, 0, 1, 720909, 0, 1, 720910, 0, 1, 720911, 0, 1, 720912, 0, 1, 720913, 0, 1, 720914, 0, 1, 720915, 0, 1, 720916, 0, 1, 720917, 0, 1, 720918, 0, 1, 720919, 0, 1, 720920, 0, 1, 720921, 0, 1, 720922, 0, 1, 720923, 0, 1, 720924, 0, 1, 720925, 0, 1, 720926, 0, 1, 720927, 0, 1, 786432, 0, 1, 786433, 0, 1, 786434, 0, 1, 786435, 0, 1, 786436, 0, 1, 786437, 0, 1, 786438, 589824, 0, 786439, 458752, 0, 786440, 589824, 0, 786441, 524288, 0, 786442, 0, 1, 786443, 0, 1, 786444, 0, 1, 786445, 0, 1, 786446, 0, 1, 786447, 0, 1, 786448, 0, 1, 786449, 0, 1, 786450, 0, 1, 786451, 0, 1, 786452, 0, 1, 786453, 0, 1, 786454, 0, 1, 786455, 0, 1, 786456, 0, 1, 786457, 0, 1, 786458, 0, 1, 786459, 0, 1, 786460, 0, 1, 786461, 0, 1, 786462, 0, 1, 786463, 0, 1, 851968, 0, 1, 851969, 0, 1, 851970, 0, 1, 851971, 0, 1, 851972, 0, 1, 851973, 0, 1, 851974, 589824, 0, 851975, 589824, 0, 851976, 458752, 0, 851977, 458752, 0, 851978, 0, 1, 851979, 0, 1, 851980, 0, 1, 851981, 0, 1, 851982, 0, 1, 851983, 0, 1, 851984, 0, 1, 851985, 0, 1, 851986, 0, 1, 851987, 0, 1, 851988, 0, 1, 851989, 0, 1, 851990, 0, 1, 851991, 0, 1, 851992, 0, 1, 851993, 0, 1, 851994, 0, 1, 851995, 0, 1, 851996, 0, 1, 851997, 0, 1, 851998, 0, 1, 851999, 0, 1, 917504, 0, 1, 917505, 0, 1, 917506, 0, 1, 917507, 0, 1, 917508, 0, 1, 917509, 0, 1, 917510, 458752, 0, 917511, 524288, 0, 917512, 524288, 0, 917513, 524288, 0, 917514, 0, 1, 917515, 0, 1, 917516, 0, 1, 917517, 0, 1, 917518, 0, 1, 917519, 0, 1, 917520, 0, 1, 917521, 0, 1, 917522, 0, 1, 917523, 0, 1, 917524, 0, 1, 917525, 0, 1, 917526, 0, 1, 917527, 0, 1, 917528, 0, 1, 917529, 0, 1, 917530, 0, 1, 917531, 0, 1, 917532, 0, 1, 917533, 0, 1, 917534, 0, 1, 917535, 0, 1, 983040, 0, 1, 983041, 0, 1, 983042, 0, 1, 983043, 0, 1, 983044, 0, 1, 983045, 0, 1, 983046, 589824, 0, 983047, 589824, 0, 983048, 589824, 0, 983049, 589824, 0, 983050, 0, 1, 983051, 0, 1, 983052, 0, 1, 983053, 0, 1, 983054, 0, 1, 983055, 0, 1, 983056, 0, 1, 983057, 0, 1, 983058, 0, 1, 983059, 0, 1, 983060, 0, 1, 983061, 0, 1, 983062, 0, 1, 983063, 0, 1, 983064, 0, 1, 983065, 0, 1, 983066, 0, 1, 983067, 0, 1, 983068, 0, 1, 983069, 0, 1, 983070, 0, 1, 983071, 0, 1)

[node name="Tile Layer 2" type="TileMap" parent="."]
texture_filter = 1
tile_set = SubResource("TileSet_rdl6d")
format = 2
layer_0/tile_data = PackedInt32Array(3, 327680, 1, 12, 196608, 1, 17, 131072, 1, 22, 458752, 1, 30, 262144, 1, 65544, 524288, 1, 65551, 196608, 1, 65556, 196608, 1, 65561, 524288, 1, 131073, 393216, 1, 131078, 262144, 1, 131081, 524288, 1, 131092, 458752, 1, 131100, 327680, 1, 196611, 458752, 1, 196615, 262144, 1, 196623, 327680, 1, 196632, 458752, 1, 262147, 196608, 1, 262150, 262144, 0, 262151, 393216, 262144, 262152, 262144, 262144, 262153, 393216, 262144, 262154, 393216, 262144, 262155, 262144, 262144, 262156, 327680, 262144, 262157, 327680, 262144, 262158, 393216, 262144, 262159, 393216, 262144, 262160, 327680, 262144, 262161, 262144, 262144, 262162, 327680, 262144, 262163, 393216, 262144, 262164, 327680, 262144, 262165, 262144, 262144, 262166, 262144, 262144, 262167, 393216, 262144, 262168, 327680, 262144, 262169, 327680, 262144, 262170, 393216, 262144, 262171, 393216, 262144, 262172, 393216, 262144, 262173, 262144, 262144, 327681, 196608, 1, 327686, 262144, 0, 393222, 327680, 0, 458754, 131072, 1, 458757, 131072, 1, 458758, 393216, 0, 458762, 327680, 458752, 458763, 262144, 458752, 458764, 327680, 458752, 458765, 262144, 458752, 458766, 262144, 458752, 458767, 393216, 458752, 458768, 262144, 458752, 458769, 327680, 458752, 458770, 327680, 458752, 458771, 393216, 458752, 458772, 327680, 458752, 458773, 262144, 458752, 458774, 327680, 458752, 458775, 262144, 458752, 458776, 327680, 458752, 458777, 327680, 458752, 458778, 393216, 458752, 458779, 393216, 458752, 458780, 327680, 458752, 458781, 327680, 458752, 524291, 262144, 1, 524294, 393216, 0, 524297, 262144, 65536, 524311, 458752, 1, 524319, 131072, 1, 589830, 327680, 0, 589833, 327680, 65536, 589838, 327680, 1, 589843, 262144, 1, 589854, 196608, 1, 655364, 524288, 1, 655366, 262144, 0, 655369, 262144, 65536, 655371, 458752, 1, 655375, 524288, 1, 655377, 524288, 1, 655382, 393216, 1, 655386, 196608, 1, 720897, 262144, 1, 720902, 262144, 0, 720905, 327680, 65536, 720908, 327680, 1, 720910, 851968, 0, 720911, 655360, 327680, 720912, 655360, 327680, 720913, 786432, 327680, 720914, 786432, 327680, 720915, 720896, 327680, 720916, 655360, 327680, 720917, 655360, 327680, 720918, 720896, 327680, 720919, 786432, 327680, 720920, 655360, 327680, 720921, 655360, 327680, 720922, 655360, 327680, 720923, 786432, 327680, 720924, 917504, 65536, 720925, 196608, 1, 786436, 131072, 1, 786438, 327680, 0, 786441, 262144, 65536, 786443, 458752, 1, 786446, 655360, 0, 786451, 131072, 1, 786454, 131072, 1, 786457, 131072, 1, 786460, 786432, 196608, 851974, 262144, 0, 851977, 262144, 65536, 851980, 196608, 1, 851981, 524288, 1, 851982, 786432, 0, 851984, 131072, 1, 851989, 131072, 1, 851993, 131072, 1, 851996, 655360, 196608, 851999, 262144, 1, 917504, 393216, 1, 917508, 196608, 1, 917510, 262144, 0, 917513, 327680, 65536, 917518, 720896, 0, 917523, 131072, 1, 917532, 655360, 196608, 917534, 524288, 1, 983041, 524288, 1, 983046, 393216, 0, 983049, 262144, 65536, 983054, 786432, 0, 983055, 131072, 1, 983057, 131072, 1, 983061, 131072, 1, 983062, 131072, 1, 983066, 131072, 1, 983068, 655360, 196608)
U�5
�ׇWxl8P$[remap]

importer="YATI"
type="PackedScene"
uid="uid://db7538oret0jj"
path="res://.godot/imported/Ratlantis.tmx-35dd9ff52da71aaa44380dbbc6ae6ad5.tscn"
 ��A�C)�FRSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       PackedScene    res://Ratlantis.tmx �?�
P�Ee      local://PackedScene_q8go8          PackedScene          
         names "      
   Ratlantis    Tile Layer 1    Tile Layer 2    	   variants                       node_count             nodes        �����������    ����              conn_count              conns               node_paths              editable_instances              base_scene              version             RSRC\n.���+�oextends CharacterBody2D
@export var move_speed :  float = 100
@export var friction :  float = .12
@export var sneak_move_speed_modifier :  float = .5
@export var sneak_friction_modifier :  float = 2
@export var direction : Vector2 = Vector2.DOWN
@export var dash_speed : float = 17

var dash_velocity = Vector2.ZERO;
func _physics_process(delta):
	# Get input direction
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		 Input.get_action_strength("down") - Input.get_action_strength("up"),
	)
	if(input_direction.length_squared() > 0):
		direction = input_direction.normalized()
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
		
	var final_move_speed = move_speed
	var final_friction = friction
	if Input.is_action_pressed("sneak"):
		final_move_speed *= sneak_move_speed_modifier 
		final_friction *= sneak_friction_modifier
	var target_velocity = input_direction * final_move_speed
	velocity += (target_velocity - velocity) * final_friction
	if Input.is_action_just_pressed("dash"):
		dash_velocity = direction * dash_speed
	dash_velocity = dash_velocity.lerp(Vector2.ZERO,delta*20)
	move_and_collide(dash_velocity);
	move_and_slide()
N��XR�RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    custom_solver_bias    size    script 	   _bundled       Script    res://rat_player.gd ��������
   Texture2D    res://tinyrat.png ���yU]      local://RectangleShape2D_rm6tt �         local://PackedScene_k43sn �         RectangleShape2D       
     A  �@         PackedScene          	         names "   
   
   RatPlayer    script    CharacterBody2D    CollisionShape2D 	   position    shape    one_way_collision_margin 	   Sprite2D    texture_filter    texture    	   variants                 
      �  �@                       
     �?   ?               node_count             nodes     #   ��������       ����                            ����                                       ����               	                conn_count              conns               node_paths              editable_instances              version             RSRCGST2            ����                        V  RIFFN  WEBPVP8LB  /��?/�6�m%�$sw�)����i�m$I���1{�v��(��L#IV��=_�<~z?^ǀ�m�$��vh�6d	���5mh$;�]&�!ؒ�x�`�2 �at�5�tG �)�����rt���� t,�����<�m�n�FrMvfObE�����#qq*�����$�m� �wǠ/��m�����Im���ڟ��:���f��HJW�$9�Q��������:<~U�qh�25Ҭ6�p�(�:������FCGF[�Dq(!J��W���T�2�I/�3FN��l 牒H��޺ո��$:TA��N�X�R���Ęi0�u�|d���!����d�"��j�����I��0x��2���s$L��nN�|�0UB��r�����IM�e1*P�&YE�i�g4a�0X��S�����$əU�hf%�a�J�u)gnĂ�d�%��,��x��cLD��I,�WRe$�an !H�� v]T�%�	��43�ٷ5���q�0t	�0��q!��㻰0�H���M��(%�-�#��I��ch�^J�&,b� �43���q4�"�0B�t�na����!Y\>��k���뒳3�`� ׫	B�>�ے�#HUU%֐����n� l[����1&@��j��B�@��ԤjlPIJ��(���p(L�R��̺-�cr�X!����i�Ax�x9��=��U�M����	ktj�y��gG�@5{O��_,)?��U���y�H��!��h~��L���0�>excS��E�I�q���������@���
͟��3�#�S@)P�+��C0�L��N�3�>7bbr]�Uu��f�{��϶�@�:f��9!~�&�@�~5�P��F&����lv������PǶ��~N���j�|y�\2�K�<��wG���O#P���P�� �3��r>��g��"g���sA����6vu��\�O�o�0�&��S~�����f+rC���ocw�����I�E�)%�ܦZ֭��������M��R��������Ih@�'�13���w���S����{*���qn.Tc�?fWY��#�.��sI1�����*6�����,�q�᙭��^-}���E!����Vr)sT��Bl9���?�Z�b�%<��j�����(�yЃ� �9U�DZ?��k�>cp!f�p�N��@�w�H|Z�
=�Wz�H�uA�Z	b���hbh����]	k�Dׅ~w�0��N�͙��e����.�k�@�jڶ�a� �"Fk�"l�٦�l����t�a�uYk���?�V�Y�g���V�Y�g���V�Y�g���V���r6	L[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bgsd3crbauls"
path="res://.godot/imported/sewerstilemap.png-c162c4dc34f68b3134457be9226bfe0c.ctex"
metadata={
"vram_texture": false
}
 �u�pD$3GST2            ����                        �   RIFF�   WEBPVP8L�   /�7���6x�� ��Q�F
��2����m#���y���  �?����A�H��*��p� /-�/�?��!���O�ZV�8k}0+ ���"J�Y��W'j��mI�ѾZ^�m=������ �[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://c221p6yfxoo3f"
path="res://.godot/imported/tinyrat.png-bc216ad82c427405e7ce560906b19528.ctex"
metadata={
"vram_texture": false
}
 �2Ț����#� [remap]

path="res://.godot/exported/133200997/export-e2d8c9f711c5cfdaac13d86df2cf34d0-game_level.scn"
J����r��[remap]

path="res://.godot/exported/133200997/export-22c13d1a1a989d1d94a1054af995216c-ratlantis.scn"
����jr1Or[remap]

path="res://.godot/exported/133200997/export-7a81085f9621e04a1721a461abb0c25f-rat_player.scn"
hɨi�e$Nlist=Array[Dictionary]([])
���w{   ?�%��A   res://game_level.tscn�?�
P�Ee   res://Ratlantis.tmx�f�'��/   res://ratlantis.tscn2���.2   res://rat_player.tscn����E)   res://sewerstilemap.png���yU]   res://tinyrat.png'p�ڬ�?8�ECFG      application/config/name         Rat Prototype 1    application/run/main_scene          res://game_level.tscn      application/config/features$   "         4.1    Forward Plus       application/config/icon         res://icon.svg  "   display/window/size/viewport_width      �  #   display/window/size/viewport_height      8     display/window/stretch/scale        �@"   editor/import/use_multiple_threads             editor_plugins/enabled,   "         res://addons/YATI/plugin.cfg       input/right�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   D   	   key_label             unicode    d      echo          script      
   input/left�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   A   	   key_label             unicode    a      echo          script         input/up�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   W   	   key_label             unicode    w      echo          script      
   input/down�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   S   	   key_label             unicode    s      echo          script         input/sneak�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script      
   input/dash�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode       	   key_label             unicode           echo          script      #   rendering/renderer/rendering_method         gl_compatibility��o`���/�