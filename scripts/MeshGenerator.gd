# Following https://www.youtube.com/watch?v=yOgIncKp0BE
# by Sebastian Lague

extends Node

class SquareGrid:
	var squares
	var width
	var height
	
	func _init(map, squareSize):
		var countX = map.size()
		var countY = map[0].size()
		width = countX * squareSize
		height = countY * squareSize
		
		var controlNodes = []
		squares = []
		
		for x in range(countX):
			controlNodes.append([])
			squares.append([])
			for y in range(countY):
				var pos = Vector3(-width/2.0 + x*squareSize + squareSize/2.0, 0, -height/2.0 + y*squareSize + squareSize/2.0)
				controlNodes[x].append(ControlNode.new(pos, map[x][y], squareSize))
				if y < countY - 1: squares[x].append(null)
		
		squares.pop_back()
		
		for x in range(countX - 1):
			for y in range(countY - 1):
				squares[x][y] = Square.new(controlNodes[x][y+1], controlNodes[x+1][y+1], controlNodes[x+1][y], controlNodes[x][y])

class Square:
	var topLeft
	var topRight
	var bottomRight
	var bottomLeft
	var centerTop
	var centerRight
	var centerBottom
	var centerLeft
	var configuration = 0
	
	func _init(tLeft, tRight, bRight, bLeft):
		topLeft = tLeft
		topRight = tRight
		bottomRight = bRight
		bottomLeft = bLeft
		
		centerTop = topLeft.rightNode
		centerRight = bottomRight.aboveNode
		centerBottom = bottomLeft.rightNode
		centerLeft = bottomLeft.aboveNode
		
		if topLeft.active: configuration += 8
		if topRight.active: configuration += 4
		if bottomRight.active: configuration += 2
		if bottomLeft.active: configuration += 1

class MeshNode:
	var position = Vector3()
#warning-ignore:unused_class_variable
	var vertexIndex = -1
	
	func _init(pos):
		position = pos

class ControlNode extends MeshNode:
	var active = false
	var aboveNode
	var rightNode
	
	func _init(pos, act, squareSize).(pos):
		active = act
		aboveNode = MeshNode.new(position + Vector3(0, 0, 1) * squareSize/2.0)
		rightNode = MeshNode.new(position + Vector3.RIGHT * squareSize/2.0)

class Triangle:
	var indexA
	var indexB
	var indexC
	
	func _init(a, b, c):
		indexA = a
		indexB = b
		indexC = c
	
	func contains(index):
		return index == indexA or index == indexB or index == indexC
	
	func get(x):
		match x:
			0: return indexA
			1: return indexB
			2: return indexC



var squareGrid
var vertices = []
var triangles = PoolIntArray()
var triDictionary = {}
var outlines = []
var checkedVerts = {}
var followRoutine
var calcOutlineRoutine
var createWallRoutine
var followCount = 0
var followLimit = 500
var done = false
var outerDone = false


func generateMesh(map, squareSize):
	
	outlines.clear()
	checkedVerts.clear()
	
	squareGrid = SquareGrid.new(map, squareSize)
	
	for x in range(squareGrid.squares.size()):
		for y in range(squareGrid.squares[0].size()):
			triangulateSquare(squareGrid.squares[x][y])
	
	print("squares triangulated")
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var norms = []
	var uvs = []
#warning-ignore:unused_variable
	for i in range(vertices.size()):
		norms.append(Vector3.UP)
		uvs.append(Vector2.ZERO)
	
	var vertPool = PoolVector3Array(vertices)
	var normPool = PoolVector3Array(norms)
	var uvPool = PoolVector2Array(uvs)
	var triPool = PoolIntArray(triangles)
	
	arrays[Mesh.ARRAY_VERTEX] = vertPool
	arrays[Mesh.ARRAY_NORMAL] = normPool
	arrays[Mesh.ARRAY_TEX_UV] = uvPool
	arrays[Mesh.ARRAY_INDEX] = triPool
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
#warning-ignore:return_value_discarded
	ResourceSaver.save("res://meshes/testMesh.tres", mesh)
	var meshNode = MeshInstance.new()
	meshNode.call_deferred("set_name", "TopMesh")
	meshNode.call_deferred("set_translation", Vector3(-10, 0, 0))
	meshNode.call_deferred("set_mesh", mesh)
	get_tree().current_scene.call_deferred("add_child", meshNode)
	
	print("preparing to create wall")
	yield(get_tree().create_timer(2.0), "timeout")
	
	createWallMesh()

func triangulateSquare(square):
	match square.configuration:
		0:
			pass
		1:
			meshFromPoints([square.centerBottom, square.centerLeft, square.bottomLeft])
		2:
			meshFromPoints([square.centerRight, square.centerBottom, square.bottomRight])
		4:
			meshFromPoints([square.centerTop, square.centerRight, square.topRight])
		8:
			meshFromPoints([square.centerLeft, square.centerTop, square.topLeft])
		
		3:
			meshFromPoints([square.centerRight, square.centerLeft, square.bottomLeft, square.bottomRight])
		6:
			meshFromPoints([square.centerTop, square.centerBottom, square.bottomRight, square.topRight])
		9:
			meshFromPoints([square.centerBottom, square.centerTop, square.topLeft, square.bottomLeft])
		12:
			meshFromPoints([square.centerLeft, square.centerRight, square.topRight, square.topLeft])
		5:
			meshFromPoints([square.centerTop, square.centerLeft, square.bottomLeft, square.centerBottom, square.centerRight, square.topRight])
		10:
			meshFromPoints([square.topLeft, square.centerLeft, square.centerBottom, square.bottomRight, square.centerRight, square.centerTop])
		
		7:
			meshFromPoints([square.centerTop, square.centerLeft, square.bottomLeft, square.bottomRight, square.topRight])
		11:
			meshFromPoints([square.centerRight, square.centerTop, square.topLeft, square.bottomLeft, square.bottomRight])
		13:
			meshFromPoints([square.centerBottom, square.centerRight, square.topRight, square.topLeft, square.bottomLeft])
		14:
			meshFromPoints([square.centerLeft, square.centerBottom, square.bottomRight, square.topRight, square.topLeft])
		
		15:
			meshFromPoints([square.topLeft, square.bottomLeft, square.bottomRight, square.topRight])
			checkedVerts[square.topLeft.vertexIndex] = true
			checkedVerts[square.topRight.vertexIndex] = true
			checkedVerts[square.bottomRight.vertexIndex] = true
			checkedVerts[square.bottomLeft.vertexIndex] = true

func meshFromPoints(points):
	assignVertices(points)
	
	if points.size() >= 3:
		createTri(points[0], points[1], points[2])
	if points.size() >= 4:
		createTri(points[0], points[2], points[3])
	if points.size() >= 5:
		createTri(points[0], points[3], points[4])
	if points.size() >= 6:
		createTri(points[0], points[4], points[5])

func assignVertices(points):
	for i in range(points.size()):
		if points[i].vertexIndex == -1:
			points[i].vertexIndex = vertices.size()
			vertices.append(points[i].position)

func createTri(a, b, c):
	triangles.append(a.vertexIndex)
	triangles.append(b.vertexIndex)
	triangles.append(c.vertexIndex)
	
	var tri = Triangle.new(a.vertexIndex, b.vertexIndex, c.vertexIndex)
	addTriToDictionary(tri.indexA, tri)
	addTriToDictionary(tri.indexB, tri)
	addTriToDictionary(tri.indexC, tri)

func addTriToDictionary(vertIndexKey, tri):
	if !triDictionary.has(vertIndexKey):
		triDictionary[vertIndexKey] = []
	triDictionary[vertIndexKey].append(tri)

func isOutlineEdge(vertexA, vertexB):
	var trisWithVertA = triDictionary[vertexA]
	var sharedCount = 0
	
	for i in range(trisWithVertA.size()):
		if trisWithVertA[i].contains(vertexB):
			sharedCount += 1
			if sharedCount > 1:
				break
	return sharedCount == 1

func getConnectedOutlineVertex(vertexIndex):
	if triDictionary.has(vertexIndex):
		var trisWithVertex = triDictionary[vertexIndex]
		for i in range(trisWithVertex.size()):
			var triangle = trisWithVertex[i]
			for n in range(3):
				var vertexB = triangle.get(n)
				if vertexB != vertexIndex and !checkedVerts.has(vertexB):
					if isOutlineEdge(vertexIndex, vertexB):
						return vertexB
	return -1

func calculateMeshOutlines():
	for vertIndex in range(vertices.size()):
		done = false
		if vertIndex % 200 == 0: print("vert " + String(vertIndex) + " reached")
		if !checkedVerts.has(vertIndex):
			var newOutlineVert = getConnectedOutlineVertex(vertIndex)
			if newOutlineVert != -1:
				checkedVerts[vertIndex] = true
				var newOutline = []
				newOutline.append(vertIndex)
				outlines.append(newOutline)
				followOutline(newOutlineVert, outlines.size() - 1) 
				while !done:
					yield(get_tree().create_timer(8.0), "timeout")
					print("Calc method checking")
				
				outlines[outlines.size() - 1].append(vertIndex)
	outerDone = true

func followOutline(vertIndex, outlineIndex):
	followCount += 1
	if followCount >= followLimit:
		yield(get_tree().create_timer(0.0002), "timeout")
	outlines[outlineIndex].append(vertIndex)
	checkedVerts[vertIndex] = true
	var nextVertIndex = getConnectedOutlineVertex(vertIndex)
	if nextVertIndex != -1:
		followOutline(nextVertIndex, outlineIndex)
	else:
		done = true
	

func createWallMesh():
	print ("# of verts: " + String(vertices.size()))
	calculateMeshOutlines()
	while !outerDone:
		yield(get_tree().create_timer(10.0), "timeout")
		print("create method checking")
	
	print("mesh outlines calculated")
	
	var wallArrays = []
	var wallVerts = PoolVector3Array()
	var wallTriangles = PoolIntArray()
	var wallNorms = PoolVector3Array()
	var wallUVs = PoolVector2Array()
	var mesh = ArrayMesh.new()
	var wallHeight = 5
	
	wallArrays.resize(Mesh.ARRAY_MAX)
	
	for outline in outlines:
		for i in range(outline.size() - 1):
			var startIndex = wallVerts.size()
			wallVerts.append(vertices[outline[i]]) #topleft
			wallVerts.append(vertices[outline[i+1]]) #topRight
			wallVerts.append(vertices[outline[i]] - Vector3.UP * wallHeight) #bottLeft
			wallVerts.append(vertices[outline[i+1]] - Vector3.UP * wallHeight) #bottRight
			
			wallTriangles.append(startIndex + 0)
			wallTriangles.append(startIndex + 2)
			wallTriangles.append(startIndex + 3)
			
			wallTriangles.append(startIndex + 0)
			wallTriangles.append(startIndex + 3)
			wallTriangles.append(startIndex + 1)
			
			for i in range(4): 
				wallNorms.append(Vector3.DOWN)
				wallUVs.append(Vector2.ZERO)
	wallArrays[Mesh.ARRAY_VERTEX] = wallVerts
	wallArrays[Mesh.ARRAY_NORMAL] = wallNorms
	wallArrays[Mesh.ARRAY_TEX_UV] = wallUVs
	wallArrays[Mesh.ARRAY_INDEX] = wallTriangles
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, wallArrays)
	var meshNode = MeshInstance.new()
	meshNode.call_deferred("set_name", "WallMesh")
	meshNode.call_deferred("set_translation", Vector3(-10, 0, 0))
	meshNode.call_deferred("set_mesh", mesh)
	get_tree().current_scene.call_deferred("add_child", meshNode)




