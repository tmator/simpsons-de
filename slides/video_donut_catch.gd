extends MPFSlide

# PackedFloat32Array : LANES[i] retourne float (pas Variant)
var LANES: PackedFloat32Array = PackedFloat32Array([300.0, 960.0, 1620.0])
const PLAYER_Y: float = 850.0
const FALL_SPEED: float = 280.0
const CATCH_X: float = 70.0
const CATCH_Y: float = 85.0
const SPAWN_DELAY: float = 2.0

var _lane: int = 1
var _spawn_t: float = 1.0
var _donuts: Array[Sprite2D] = []   # typé -> [i] retourne Sprite2D
var _player: Label
var _score_label: Label
var _score: int = 0
var _running: bool = false

func _ready() -> void:
	_player = Label.new()
	_player.text = "HOMER"
	_player.add_theme_font_size_override("font_size", 42)
	_player.add_theme_color_override("font_color", Color.YELLOW)
	_player.position = Vector2(LANES[_lane] - 55.0, PLAYER_Y)
	add_child(_player)

	_score_label = Label.new()
	_score_label.text = "Attrapes: 0"
	_score_label.add_theme_font_size_override("font_size", 48)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.position = Vector2(40.0, 720.0)
	add_child(_score_label)

	MPF.server.add_event_handler("video_mode_left", _on_left)
	MPF.server.add_event_handler("video_mode_right", _on_right)
	_running = true

func _exit_tree() -> void:
	_running = false
	MPF.server.remove_event_handler("video_mode_left", _on_left)
	MPF.server.remove_event_handler("video_mode_right", _on_right)

func _on_left(_p: Dictionary = {}) -> void:
	_lane = max(0, _lane - 1)
	if is_instance_valid(_player):
		_player.position.x = LANES[_lane] - 55.0

func _on_right(_p: Dictionary = {}) -> void:
	_lane = min(2, _lane + 1)
	if is_instance_valid(_player):
		_player.position.x = LANES[_lane] - 55.0

func _process(delta: float) -> void:
	if not _running:
		return

	_spawn_t += delta
	if _spawn_t >= SPAWN_DELAY:
		_spawn_t = 0.0
		_spawn_donut()

	# Itération inverse pour supprimer en sécurité
	var i: int = _donuts.size() - 1
	while i >= 0:
		var d: Sprite2D = _donuts[i]
		if not is_instance_valid(d):
			_donuts.remove_at(i)
			i -= 1
			continue
		d.position.y += FALL_SPEED * delta
		var player_pos: Vector2 = Vector2(LANES[_lane], PLAYER_Y)
		var dx: float = absf(d.position.x - player_pos.x)
		var dy: float = absf(d.position.y - player_pos.y)
		if dx < CATCH_X and dy < CATCH_Y:
			_donuts.remove_at(i)
			d.queue_free()
			_score += 1
			if is_instance_valid(_score_label):
				_score_label.text = "Attrapes: %d" % _score
			MPF.server.send_event("video_donut_catch_score")
		elif d.position.y > 1150.0:
			_donuts.remove_at(i)
			d.queue_free()
			MPF.server.send_event("video_donut_catch_miss")
		i -= 1

func _spawn_donut() -> void:
	var tex_paths := PackedStringArray([
		"res://img/donut_blanc.png",
		"res://img/donut_rose.png",
		"res://img/donut_mauve.png",
	])
	var lane: int = randi() % 3
	var donut: Sprite2D = Sprite2D.new()
	donut.position = Vector2(LANES[lane], -50.0)
	var tex: Texture2D = load(tex_paths[randi() % 3]) as Texture2D
	if tex != null:
		donut.texture = tex
	add_child(donut)
	_donuts.append(donut)
