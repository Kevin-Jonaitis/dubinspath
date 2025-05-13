## Demo for dubins path. The "white" line represents the shortest path. All the other colored lines represent possible dubins paths that are longer than the shortest path.

extends Node2D

@onready var dubins_path: DubinPath2D = $DubinPath2D
@onready var truck: Sprite2D = $Truck

var start_mouse_drag: bool = false
var start_mouse_pos: Vector2
var is_truck_moving: bool = false
var truck_progress: float = 0.0
var truck_speed: float = 150
var min_turn_radius: float = 70.0 # CHANGE THIS TO CHANGE THE TURNING RADIUS


func _ready() -> void:
	pass

func _draw():
	if start_mouse_drag:
		var end_position: Vector2 = get_global_mouse_position()
		draw_line(start_mouse_pos, end_position, Color.WHITE, 5) # This lines visualizes the "end" direction the truck will face

func _input(event: InputEvent):
	pass
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		start_mouse_pos  = event.position
		start_mouse_drag = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		start_mouse_drag = false
		var end_mouse_pos: Vector2 = event.position
		move_truck_to(start_mouse_pos, calculate_direction(start_mouse_pos, end_mouse_pos))
	if event is InputEventMouseMotion and start_mouse_drag:
		queue_redraw()

# Calculate the angle(in rads) between the start and end positions of our dragged line
func calculate_direction(start_pos: Vector2, end_pos: Vector2) -> float:
	return (end_pos - start_pos).angle()

func move_truck_to(pos: Vector2, end_truck_direction: float) -> void:
	# Move the truck to the clicked position
	var current_truck_direction: float = get_truck_direction()
	# Update the DubinPath2D with the new truck position and rotation
	print("VARIABLES FOR CALCULATING PATHS:")
	print("Truck Position: ", truck.position)
	print("Truck Direction: ", current_truck_direction)
	print("End Position: ", pos)
	print("End Direction: ", end_truck_direction)
	dubins_path.calculate_and_draw_paths(truck.position, current_truck_direction, pos, end_truck_direction, min_turn_radius, true)
	is_truck_moving = true
	truck_progress = 0.0

func _process(delta):
	if (is_truck_moving):
		var total_distance: float = dubins_path.shortest_path.length
		truck_progress += truck_speed * delta
		if (truck_progress > total_distance):
			truck_progress = total_distance
			is_truck_moving = false
		var truck_location: Vector2 = dubins_path.shortest_path.get_point_at_offset(truck_progress)
		truck.position = truck_location
		var truck_rotation: float = dubins_path.shortest_path.get_angle_at_offset(truck_progress)
		truck.rotation = add_truck_rotation_offset(truck_rotation)
	pass

	
# The truck sprite faces "upwards", while 0 radians starts to the right, so we need to offset by PI/2

func get_truck_direction() -> float:
	return truck.rotation - PI/2

func add_truck_rotation_offset(truck_rotation: float) -> float:
	return truck_rotation + PI/2
