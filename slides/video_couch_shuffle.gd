extends MPFSlide

var SLOT_X: PackedFloat32Array = PackedFloat32Array([160.0, 476.0, 792.0, 1108.0, 1424.0])
const SLOT_Y: float = 570.0

var _name_labels: Array[Label] = []   # typé -> [i] retourne Label
var _cursor_arrow: Label
var _feedback_lbl: Label
var _running: bool = false

func _ready() -> void:
	for i: int in range(5):
		var lbl: Label = Label.new()
		lbl.text = "?"
		lbl.add_theme_font_size_override("font_size", 44)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(260.0, 60.0)
		lbl.position = Vector2(SLOT_X[i], SLOT_Y)
		add_child(lbl)
		_name_labels.append(lbl)

	_cursor_arrow = Label.new()
	_cursor_arrow.text = "^^^"
	_cursor_arrow.add_theme_font_size_override("font_size", 44)
	_cursor_arrow.add_theme_color_override("font_color", Color.YELLOW)
	_cursor_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cursor_arrow.size = Vector2(260.0, 60.0)
	_cursor_arrow.position = Vector2(SLOT_X[0], SLOT_Y + 65.0)
	add_child(_cursor_arrow)

	_feedback_lbl = Label.new()
	_feedback_lbl.text = "Remets la famille dans l'ordre!"
	_feedback_lbl.add_theme_font_size_override("font_size", 46)
	_feedback_lbl.add_theme_color_override("font_color", Color.WHITE)
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.size = Vector2(1820.0, 70.0)
	_feedback_lbl.position = Vector2(50.0, 680.0)
	add_child(_feedback_lbl)

	MPF.server.add_event_handler("video_couch_shuffle_state", _on_state)
	MPF.server.add_event_handler("video_couch_shuffle_success", _on_success)
	_running = true

func _exit_tree() -> void:
	_running = false
	MPF.server.remove_event_handler("video_couch_shuffle_state", _on_state)
	MPF.server.remove_event_handler("video_couch_shuffle_success", _on_success)

func _on_state(payload: Dictionary = {}) -> void:
	var positions_str: String = str(payload.get("positions", ""))
	var cursor: int = int(str(payload.get("cursor", 0)))
	var held: int = int(str(payload.get("held", -1)))

	if positions_str.is_empty():
		return

	var chars: PackedStringArray = positions_str.split(",")
	for i: int in range(mini(chars.size(), 5)):
		var lbl: Label = _name_labels[i]
		if not is_instance_valid(lbl):
			continue
		lbl.text = chars[i]
		if i == held:
			lbl.add_theme_color_override("font_color", Color.ORANGE)
		elif i == cursor:
			lbl.add_theme_color_override("font_color", Color.YELLOW)
		else:
			lbl.add_theme_color_override("font_color", Color.WHITE)

	if is_instance_valid(_cursor_arrow) and cursor >= 0 and cursor < 5:
		_cursor_arrow.position = Vector2(SLOT_X[cursor], SLOT_Y + 65.0)

func _on_success(_payload: Dictionary = {}) -> void:
	if is_instance_valid(_feedback_lbl):
		_feedback_lbl.text = "PARFAIT!  BONUS +50000!"
		_feedback_lbl.add_theme_color_override("font_color", Color.GREEN)
