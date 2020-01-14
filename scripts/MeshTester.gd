extends Node

func _ready():
	
	var vertPool = PoolVector3Array()
	var normPool = PoolVector3Array()
	var uvPool = PoolVector2Array()
	var index = PoolIntArray()
	var meshArrays = []
	meshArrays.resize(Mesh.ARRAY_MAX)
	
	vertPool.append(Vector3(-10, 0, -10))
	vertPool.append(Vector3(-10, 0, 10))
	vertPool.append(Vector3(10, 0, 10))
	vertPool.append(Vector3(10, 0, -10))
	
	for i in range(vertPool.size()):
		normPool.append(Vector3.UP)
		uvPool.append(Vector2.ZERO)
	
	index.append(2)
	index.append(1)
	index.append(0)
	
	index.append(3)
	index.append(2)
	index.append(1)
	
	meshArrays[Mesh.ARRAY_VERTEX] = vertPool
	meshArrays[Mesh.ARRAY_NORMAL] = normPool
	meshArrays[Mesh.ARRAY_TEX_UV] = uvPool
	meshArrays[Mesh.ARRAY_INDEX] = index
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshArrays)
	ResourceSaver.save("res://meshes/testSquareMesh.tres", mesh)
	