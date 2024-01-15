extends Control
class_name HUD

@onready var interact_label : Label = $InteractLabel
@onready var stamina_bar : TextureProgressBar = $StaminaProgressBar
@onready var oxygen_bar : TextureProgressBar = $OxygenProgressBar
@onready var health_bar : TextureProgressBar = $HealthProgressBar
@onready var interact_bar : TextureProgressBar = $InteractProgressBar
@onready var package_label : PanelContainer = $PackageLabel

func _ready():
	interact_label.hide()
	hide_package_label()

func update_interact_text_to(new_text: String) -> void:
	interact_label.text = new_text

func update_package_label(package: Package) -> void:
	var recipient_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Recipient/Label
	var galaxy_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Galaxy/Label
	var planet_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Planet/Label
	var time_label : Label = $PackageLabel/MarginContainer/VBoxContainer/Time/Label
	
	recipient_label.text = package.recipient.display_name
	galaxy_label.text = package.destination_galaxy.display_name
	planet_label.text = package.destination_planet.display_name
	time_label.text = str(package.time_left_to_deliver)
	package_label.show()

func hide_package_label() -> void:
	package_label.hide()
