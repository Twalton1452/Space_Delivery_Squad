class_name Request

signal resolved(successful: bool)
## Invalidations occur when multiple drop requests were processed
## at the same time and the latest one took precedence over the previous
signal invalidated

var sequence : int = -1

func fulfill() -> void:
	resolved.emit(true)

func fail() -> void:
	resolved.emit(false)

func invalidate() -> void:
	invalidated.emit()
