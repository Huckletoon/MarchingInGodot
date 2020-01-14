extends Control

onready var parent = get_parent()

var size = Vector2(5, 5)

#warning-ignore:unused_argument
func _physics_process(delta):
	update()

func _draw():
	var empty = Color.white
	var filled = Color.black
	if parent != null and parent.map.size() != 0:
		for x in range(parent.width):
			for y in range(parent.height):
				draw_rect(Rect2(Vector2(20 + x*size.x + size.x, 20 + y*size.y + size.y), size), filled if parent.map[x][y] else empty)
	
	draw_circle(Vector2(10, 10), 5, Color.red)
	draw_circle(Vector2(20, 10), 6, Color.green)
	draw_circle(Vector2(20, 20), 7, Color.blue)
	draw_circle(Vector2(10, 20), 8, Color.white)