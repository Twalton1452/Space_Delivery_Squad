extends Light3D
class_name ShipLight

var original_energy : float
var energy_tween : Tween

func _ready() -> void:
	original_energy = light_energy

func enable() -> void:
	if energy_tween != null and energy_tween.is_valid():
		energy_tween.kill()
	energy_tween = create_tween()
	energy_tween.tween_property(self, "light_energy", original_energy, 1.0)

func disable() -> void:
	if energy_tween != null and energy_tween.is_valid():
		energy_tween.kill()
	energy_tween = create_tween()
	energy_tween.tween_property(self, "light_energy", 0.0, 1.0)
