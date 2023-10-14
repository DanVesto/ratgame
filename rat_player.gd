extends CharacterBody2D
@export var move_speed :  float = 100
@export var friction :  float = .12
@export var sneak_move_speed_modifier :  float = .5
@export var sneak_friction_modifier :  float = 2
@export var direction : Vector2 = Vector2.DOWN
@export var dash_speed : float = 17

var dash_velocity = Vector2.ZERO;
func _physics_process(delta):
	# Get input direction
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		 Input.get_action_strength("down") - Input.get_action_strength("up"),
	)
	if(input_direction.length_squared() > 0):
		direction = input_direction.normalized()
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
		
	var final_move_speed = move_speed
	var final_friction = friction
	if Input.is_action_pressed("sneak"):
		final_move_speed *= sneak_move_speed_modifier 
		final_friction *= sneak_friction_modifier
	var target_velocity = input_direction * final_move_speed
	velocity += (target_velocity - velocity) * final_friction
	if Input.is_action_just_pressed("dash"):
		dash_velocity = direction * dash_speed
	dash_velocity = dash_velocity.lerp(Vector2.ZERO,delta*20)
	move_and_collide(dash_velocity);
	move_and_slide()
