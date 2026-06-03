extends MPFSlide

# PackedStringArray : [i] retourne String (pas Variant)
var DIRS: PackedStringArray = PackedStringArray(["left", "right", "up", "down"])
const PROMPT_TIME: float = 3.5
const FEEDBACK_TIME: float = 1.5

# States: "playing", "feedback"
var _state: String = "playing"
var _correct: String = "left"
var _choice_t: float = 0.0
var _feedback_t: float = 0.0
var _prompt_lbl: Label
var _feedback_lbl: Label
var _running: bool = false

func _ready() -> void:
	_prompt_lbl = Label.new()
	_prompt_lbl.add_theme_font_size_override("font_size", 220)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.size = Vector2(1120.0, 320.0)
	_prompt_lbl.position = Vector2(400.0, 360.0)
	add_child(_prompt_lbl)

	_feedback_lbl = Label.new()
	_feedback_lbl.add_theme_font_size_override("font_size", 75)
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.size = Vector2(1520.0, 120.0)
	_feedback_lbl.position = Vector2(200.0, 660.0)
	add_child(_feedback_lbl)

	MPF.server.add_event_handler("video_mode_left", _on_left)
	MPF.server.add_event_handler("video_mode_right", _on_right)
	MPF.server.add_event_handler("video_mode_up", _on_up)
	MPF.server.add_event_handler("video_mode_down", _on_down)

	_new_prompt()
	_running = true

func _exit_tree() -> void:
	_running = false
	MPF.server.remove_event_handler("video_mode_left", _on_left)
	MPF.server.remove_event_handler("video_mode_right", _on_right)
	MPF.server.remove_event_handler("video_mode_up", _on_up)
	MPF.server.remove_event_handler("video_mode_down", _on_down)

# match évite le Dictionary (qui retournerait Variant)
func _arrow_for(dir: String) -> String:
	match dir:
		"left":  return "<---"
		"right": return "--->"
		"up":    return " ^^^"
		"down":  return " vvv"
	return "?"

func _new_prompt() -> void:
	_correct = DIRS[randi() % 4]
	_choice_t = 0.0
	_state = "playing"
	if is_instance_valid(_prompt_lbl):
		_prompt_lbl.text = _arrow_for(_correct)
		_prompt_lbl.add_theme_color_override("font_color", Color.YELLOW)
	if is_instance_valid(_feedback_lbl):
		_feedback_lbl.text = "Quelle direction pour sortir ?"
		_feedback_lbl.add_theme_color_override("font_color", Color.WHITE)

func _on_left(_p: Dictionary = {}) -> void:
	_check("left")

func _on_right(_p: Dictionary = {}) -> void:
	_check("right")

func _on_up(_p: Dictionary = {}) -> void:
	_check("up")

func _on_down(_p: Dictionary = {}) -> void:
	_check("down")

func _check(dir: String) -> void:
	if _state != "playing":
		return
	if dir == _correct:
		_show_feedback("BONNE SORTIE!  +15000", Color.GREEN, true)
	else:
		_show_feedback("MAUVAIS COULOIR!", Color.RED, false)

func _show_feedback(text: String, color: Color, good: bool) -> void:
	_state = "feedback"
	_feedback_t = 0.0
	if is_instance_valid(_feedback_lbl):
		_feedback_lbl.text = text
		_feedback_lbl.add_theme_color_override("font_color", color)
	if is_instance_valid(_prompt_lbl):
		_prompt_lbl.add_theme_color_override("font_color", Color.WHITE)
	if good:
		MPF.server.send_event("video_reactor_escape_good")
	else:
		MPF.server.send_event("video_reactor_escape_bad")

func _process(delta: float) -> void:
	if not _running:
		return
	if _state == "playing":
		_choice_t += delta
		if _choice_t >= PROMPT_TIME:
			_show_feedback("TROP LENT!", Color.ORANGE, false)
	elif _state == "feedback":
		_feedback_t += delta
		if _feedback_t >= FEEDBACK_TIME:
			_new_prompt()
