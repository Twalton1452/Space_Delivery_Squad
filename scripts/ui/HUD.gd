extends Control
class_name HUD

@onready var interact_label : Label = $InteractLabel
@onready var stamina_bar : TextureProgressBar = $StaminaProgressBar
@onready var oxygen_bar : TextureProgressBar = $OxygenProgressBar
@onready var health_bar : TextureProgressBar = $HealthProgressBar
@onready var interact_bar : TextureProgressBar = $InteractProgressBar
@onready var package_label : PanelContainer = $PackageLabel

var package_label_tween : Tween
var package_label_original_position : Vector2

func _ready():
	interact_label.hide()
	package_label.hide()
	package_label_original_position = package_label.position

func update_interact_text_to(new_text: String) -> void:
	interact_label.text = new_text

func update_package_label(package: Package) -> void:
	if package_label_tween != null and package_label_tween.is_valid():
		package_label_tween.kill()
	
	package_label.position = package_label_original_position + Vector2(100.0, 0.0)
	
	var recipient_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Recipient/Label
	var galaxy_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Galaxy/Label
	var planet_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Planet/Label
	var time_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Time/Label
	
	recipient_label.text = package.recipient.display_name
	galaxy_label.text = package.destination_galaxy.display_name
	planet_label.text = package.destination_planet.display_name
	time_label.text = str(package.time_left_to_deliver) + " days"
	
	package_label.show()
	package_label_tween = package_label.create_tween()
	package_label_tween.tween_property(package_label, "position", package_label_original_position, 0.1)

func hide_package_label() -> void:
	if package_label_tween != null and package_label_tween.is_valid():
		package_label_tween.kill()
	
	var exit_position = package_label_original_position + Vector2(500.0, 0.0)
	package_label_tween = package_label.create_tween()
	package_label_tween.tween_property(package_label, "position", exit_position, 0.2)
	package_label_tween.tween_callback(func(): package_label.hide())
	
