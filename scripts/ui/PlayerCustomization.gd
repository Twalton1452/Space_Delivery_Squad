extends Control
class_name PlayerCustomization

@onready var player_view_mesh_to_color = $PlayerView/SubViewport/bean_armature/Armature/Skeleton3D/Body
@onready var display_name_edit = $DisplayName/LineEdit
@onready var color_buttons_parent = $Colors/HBoxContainer
@onready var viewport : SubViewport = $PlayerView/SubViewport

func _ready() -> void:
	for child in color_buttons_parent.get_children():
		(child as TextureButton).pressed.connect(_on_color_button_pressed)
	await LevelManager.changed_level
	hide()

func _on_color_button_pressed() -> void:
	for child in color_buttons_parent.get_children():
		var button : TextureButton = child
		if button.button_pressed:
			var player_mat : StandardMaterial3D = player_view_mesh_to_color.get_surface_override_material(0)
			player_mat.albedo_color = button.self_modulate

func store_local_settings() -> void:
	var player_display_name = display_name_edit.text
	var player_mat : StandardMaterial3D = player_view_mesh_to_color.get_surface_override_material(0)
	var player_color = player_mat.albedo_color
	PlayerManager.store_local_player_settings(player_display_name, player_color)
	finished_customizing()

func finished_customizing() -> void:
	for child in viewport.get_children():
		child.hide()
