GDPC                �                                                                      
   X   res://.godot/exported/133200997/export-7a81085f9621e04a1721a461abb0c25f-rat_player.scn  0      @      J<�ۊ1�����Gs�    X   res://.godot/exported/133200997/export-e2d8c9f711c5cfdaac13d86df2cf34d0-game_level.scn          �      �����!�wK�����J    ,   res://.godot/global_script_class_cache.cfg  �
             ��Р�8���8~$}P�    H   res://.godot/imported/tinyrat.png-bc216ad82c427405e7ce560906b19528.ctex p      �       (;5�6KT>1+;�k�S       res://.godot/uid_cache.bin        c       �IӔ�= ��V�<=r       res://game_level.tscn.remap 
      g       �pb! ���]�-i�       res://project.binary�      Y      �x�,�|���I��b       res://rat_player.gd �      c      /JY³0���i�x�D�R       res://rat_player.tscn.remap �
      g       ���Ⱥ
�l��&�        res://tinyrat.png.import@	      �       C�B���F�������    '�?�RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       PackedScene    res://rat_player.tscn 2���.2      local://PackedScene_hicuf          PackedScene          	         names "      
   GameLevel    Node2D 
   RatPlayer 	   position    	   variants                 
     "C  !C      node_count             nodes        ��������       ����                ���                          conn_count              conns               node_paths              editable_instances              version             RSRC�S��(��6�y�\extends CharacterBody2D
@export var move_speed :  float = 100
func _physics_process(_delta):
	# Get input direction
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up"),
	)
	velocity = input_direction * move_speed
	move_and_slide()
�q��g�_�ww��RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    custom_solver_bias    size    script 	   _bundled       Script    res://rat_player.gd ��������
   Texture2D    res://tinyrat.png j��.�w9      local://RectangleShape2D_rm6tt �         local://PackedScene_80uml �         RectangleShape2D       
     `A  pA         PackedScene          	         names "   
   
   RatPlayer    script    CharacterBody2D    CollisionShape2D 	   position    shape    one_way_collision_margin 	   Sprite2D    texture_filter    texture    	   variants                 
      @   ?                       
     �?                   node_count             nodes     #   ��������       ����                            ����                                       ����               	                conn_count              conns               node_paths              editable_instances              version             RSRCGST2            ����                        �   RIFF�   WEBPVP8L�   /�7���6x�� ��Q�F
��2����m#���y���  �?����A�H��*��p� /-�/�?��!���O�ZV�8k}0+ ���"J�Y��W'j��mI�ѾZ^�m=������ d[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://by86crw1lksgw"
path="res://.godot/imported/tinyrat.png-bc216ad82c427405e7ce560906b19528.ctex"
metadata={
"vram_texture": false
}
 )	�o���[remap]

path="res://.godot/exported/133200997/export-e2d8c9f711c5cfdaac13d86df2cf34d0-game_level.scn"
�<6<XR*fb[remap]

path="res://.godot/exported/133200997/export-7a81085f9621e04a1721a461abb0c25f-rat_player.scn"
���}�V��list=Array[Dictionary]([])
��j�N   ?�%��A   res://game_level.tscn2���.2   res://rat_player.tscnj��.�w9   res://tinyrat.png�����������ECFG	      application/config/name         Rat Prototype 1    application/run/main_scene          res://game_level.tscn      application/config/features$   "         4.1    Forward Plus       application/config/icon         res://icon.svg     input/right�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   D   	   key_label             unicode    d      echo          script      
   input/left�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   A   	   key_label             unicode    a      echo          script         input/up�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   W   	   key_label             unicode    w      echo          script      
   input/down�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   S   	   key_label             unicode    s      echo          script      #   rendering/renderer/rendering_method         gl_compatibilityg���t`