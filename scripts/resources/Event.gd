extends Resource
class_name Event

## Generic Multipurpose Event Resource
## Create Disaster Events, Navigation Events, Player Events

signal started
signal ended

var occurring : bool = false : 
	set(value):
		if occurring != value:
			occurring = value
			if occurring:
				started.emit()
			else:
				ended.emit()

func can_start() -> bool:
	# TODO: No conflicting events are occurring
	return true

# May not need
func can_end() -> bool:
	return true

func start() -> void:
	if not can_start() and not occurring:
		return
	
	occurring = true

func end() -> void:
	if not can_end() and occurring:
		return
	
	occurring = false
