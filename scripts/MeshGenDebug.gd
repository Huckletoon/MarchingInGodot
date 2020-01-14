extends Control

onready var parent = get_node("../MeshGenerator")

var size = Vector2(8, 8)
#warning-ignore:unused_class_variable
var midSize = Vector2(2, 2)

#warning-ignore:unused_argument
func _physics_process(delta):
	update()

func getPosition(square, width, height, x, y):
	var posx = square.position.x + width/2.0 + x*size.x + size.x
	var posy = square.position.z + height/2.0 + y*size.y + size.y
	return Vector2(posx, posy + 200)

func _draw():
	var empty = Color.white
	var filled = Color.black
#warning-ignore:unused_variable
	var mid = Color.gray
	var width = parent.squareGrid.width
	var height = parent.squareGrid.height
	if parent.squareGrid != null:
		for x in range(parent.squareGrid.squares.size()):
			for y in range(parent.squareGrid.squares[0].size()):
				draw_rect(Rect2(getPosition(parent.squareGrid.squares[x][y].topLeft, width, height, x, y), size * 0.5),
					filled if parent.squareGrid.squares[x][y].topLeft.active else empty)
					
				draw_rect(Rect2(getPosition(parent.squareGrid.squares[x][y].topRight, width, height, x, y), size * 0.5),
					filled if parent.squareGrid.squares[x][y].topRight.active else empty)
					
				draw_rect(Rect2(getPosition(parent.squareGrid.squares[x][y].bottomRight, width, height, x, y), size * 0.5),
					filled if parent.squareGrid.squares[x][y].bottomRight.active else empty)
					
				draw_rect(Rect2(getPosition(parent.squareGrid.squares[x][y].bottomLeft, width, height, x, y), size * 0.5),
					filled if parent.squareGrid.squares[x][y].bottomLeft.active else empty)