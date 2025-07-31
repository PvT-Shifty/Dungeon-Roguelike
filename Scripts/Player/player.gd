extends CharacterBody2D

# ───── Movement tunables ─────
@export var MAX_SPEED : float = 220.0 # max velocity
@export var ACCELERATION : float = 1400.0 # how quickly can we reach velocity
@export var FRICTION : float = 1600.0 # how quickly can we change direction

# ───── Dash tunables ─────
@export var DASH_SPEED : float = 420.0 # burst velocity
@export var DASH_TIME : float = 0.18 # seconds the dash lasts
@export var DASH_COOLDOWN : float = 0.50 # seconds before next dash
@export var DASH_IFRAMES : bool = true # become invincible while dashing

var _dash_timer : float = 0.0
var _cooldown_timer : float = 0.0
var _is_dashing : bool = false
var _dash_dir : Vector2 = Vector2.ZERO

func _physics_process(delta):
	_handle_dash_timers(delta)

	if _is_dashing:
		# lock velocity until the dash timer expires
		velocity = _dash_dir * DASH_SPEED
	else:
		_apply_walk_input(delta)

	move_and_slide()

func _apply_walk_input(delta):
	var input_dir := Input.get_vector("move_left", "move_right",
									  "move_up",  "move_down").normalized()

	var desired_velocity := input_dir * MAX_SPEED

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	# ===== Dash trigger =====
	if Input.is_action_just_pressed("dash") \
			and _cooldown_timer <= 0.0 \
			and input_dir != Vector2.ZERO:
		_start_dash(input_dir)

func _start_dash(dir: Vector2):
	_is_dashing = true
	_dash_dir = dir # dash where the stick/key is tilted
	_dash_timer = DASH_TIME
	_cooldown_timer = DASH_COOLDOWN + DASH_TIME # overlap safety

	if DASH_IFRAMES:
		set_collision_mask_value(0, false) # disable all mask bits
		set_collision_layer_value(0, false) # optional: untargetable
	# Signal hooks for FX / sound / animation in the future:
	emit_signal("dashed", dir)

func _end_dash():
	_is_dashing = false
	if DASH_IFRAMES:
		set_collision_mask_value(0, true)
		set_collision_layer_value(0, true)

func _handle_dash_timers(delta):
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
