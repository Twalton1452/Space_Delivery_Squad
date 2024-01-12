extends EventListener


func _ready() -> void:
	PowerGrid.power_lost.connect(_on_power_lost)
	PowerGrid.power_gained.connect(_on_power_gained)

func _on_power_lost() -> void:
	notify_conditions_were_met()

func _on_power_gained() -> void:
	notify_conditions_were_unmet()
