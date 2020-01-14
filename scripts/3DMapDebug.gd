extends Node

var TestCube = preload("res://objects/DebugCell.tscn")
onready var mapGen = get_node("../3DMapGenerator")

func _ready():
	if false:
		var map = mapGen.map
		for x in range(map.size()):
			for y in range(map[x].size()):
				for z in range(map[x][y].size()):
					var testCube = TestCube.instance()
					testCube.translation = Vector3(x, y, z)
					testCube.scale = Vector3(0.15, 0.15, 0.15)
					if map[x][y][z] > mapGen.densityThreshold:
						get_tree().current_scene.call_deferred("add_child", testCube)
					pass