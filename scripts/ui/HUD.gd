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

func update_interact_text_to(new_text: String) -> void:
	interact_label.text = new_text
