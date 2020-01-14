# Following https://www.youtube.com/watch?v=v7yyZZjF1z4&t=124s
# Video by Sebastian Lague

extends Node

export var width = 100
export var height = 100
export var randomFillPercent = 0.50
#warning-ignore:unused_class_variable
export var rngLimit = 7
export var smoothing = 4

var rng = [RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new(), RandomNumberGenerator.new()]
var rngCounter = 0
var map = []
var generated = false

onready var meshGen = get_node("MeshGenerator")

class Coord:
	var tileX
	var tileY
	
	func _init(x, y):
		tileX = x
		tileY = y

class Room:
	var tiles
	var edgeTiles
	var connectedRooms
	var roomSize
	var isAccessibleFromMain
	var isMain
	
	func _init(roomTiles, map):
		tiles = roomTiles
		roomSize = tiles.size()
		connectedRooms = []
		edgeTiles = []
		isMain = false
		isAccessibleFromMain = false
		
		for tile in tiles:
			var x = tile.tileX - 1
			while x <= tile.tileX + 1:
				var y = tile.tileY - 1
				while y <= tile.tileY + 1:
					if x == tile.tileX or y == tile.tileY:
						if map[x][y]:
							edgeTiles.append(tile)
					y += 1
				x += 1
	
	static func connectRooms(roomA, roomB):
		if roomA.isAccessibleFromMain:
			roomB.setAccessibleFromMain()
		if roomB.isAccessibleFromMain:
			roomA.setAccessibleFromMain()
		roomA.connectedRooms.append(roomB)
		roomB.connectedRooms.append(roomA)
	
	func isConnected(room):
		return connectedRooms.has(room)
	
	func setAccessibleFromMain():
		if !isAccessibleFromMain:
			isAccessibleFromMain = true
			for room in connectedRooms:
				room.setAccessibleFromMain()
	
	static func compare(roomA, roomB):
		return roomA.roomSize > roomB.roomSize
	


func _ready():
	rng[0].randomize()
	rng[1].randomize()
	rng[2].randomize()
	rng[3].randomize()
	rng[4].randomize()
	rng[5].randomize()
	rng[6].randomize()
	rng[7].randomize()
	rng[8].randomize()
	rng[9].randomize()
	generateMap()

func generateMap():
	var waitTime = width * height * 0.000325
	
	
	if !generated:
		for x in range(width):
			map.append([])
			#warning-ignore:unused_variable
			for y in range(height):
				map[x].append(false)
	randomFillMap()
	
	#warning-ignore:unused_variable
	for x in range(smoothing):
		smoothMap()
	
	processMap()
	
	print("wait for " + String(waitTime) + " seconds")
	yield(get_tree().create_timer(waitTime), "timeout")
	
	var borderSize = 3
	var borderedMap = []
	for x in range (width + borderSize * 2):
		borderedMap.append([])
		for y in range(height + borderSize * 2):
			if x >= borderSize and x < width + borderSize and y >= borderSize and y < height + borderSize:
				borderedMap[x].append(map[x - borderSize][y-borderSize])
			else :
				borderedMap[x].append(true)
	
	print("border done")
	
	meshGen.generateMesh(borderedMap, 1)
	

func randomFillMap():
	for x in range(width):
		for y in range(height):
			if x == 0 or x == width-1 or y == 0 or y == height-1:
				map[x][y] = true
			else:
				var fill = false
				var check = rng[rngCounter].randf()
				if check < randomFillPercent: 
					fill = true
				map[x][y] = fill
				rngCounter = (rngCounter + 1) if rngCounter < rngLimit else 0

func smoothMap():
	for x in range(width):
		for y in range(height):
			var surrounding = getSurroundingCount(x,y)
			
			if surrounding > 4:
				map[x][y] = true
			elif surrounding < 4:
				map[x][y] = false

func getSurroundingCount(x, y):
	var count = 0
	for xOff in range(-1, 2):
		for yOff in range (-1, 2):
			if isInMapRange(x+xOff, y+yOff):
				if (xOff != 0 or yOff != 0) and map[x+xOff][y+yOff]:
					count += 1
			else:
				count += 1
	return count

func getRegionTiles(startX, startY):
	var tiles = []
	var mapFlags = []
	var tileType = map[startX][startY]
	var queue = []
	
	mapFlags.resize(width)
	for x in range(mapFlags.size()):
		mapFlags[x] = []
		for y in range(height):
			mapFlags[x].append(false)
			
	queue.push_back(Coord.new(startX, startY))
	mapFlags[startX][startY] = true
	
	while !queue.empty():
		var tile = queue.pop_front()
		tiles.append(tile)
		
		var x = tile.tileX - 1
		while x <= tile.tileX + 1:
			var y = tile.tileY - 1
			while y <= tile.tileY + 1:
				if isInMapRange(x, y) and (y == tile.tileY or x == tile.tileX):
					if !mapFlags[x][y] and map[x][y] == tileType:
						mapFlags[x][y] = true
						queue.push_back(Coord.new(x,y))
				y += 1
			x += 1
	
	return tiles

func isInMapRange(x, y):
	return x >= 0 and x < width and y >=0 and y < height

func getRegions(tileType):
	var regions = []
	var mapFlags = []
	
	mapFlags.resize(width)
	for x in range(mapFlags.size()):
		mapFlags[x] = []
		for y in range(height):
			mapFlags[x].append(false)
	
	for x in range(width):
		for y in range(height):
			if !mapFlags[x][y] and map[x][y] == tileType:
				var newRegion = getRegionTiles(x,y)
				regions.append(newRegion)
				for tile in newRegion:
					mapFlags[tile.tileX][tile.tileY] = true
	
	return regions

func processMap():
	var walls = getRegions(true)
	var wallThreshold = 40
	for region in walls:
		if region.size() < wallThreshold:
			for tile in region:
				map[tile.tileX][tile.tileY] = false
	
	var rooms = getRegions(false)
	var roomThreshold = 40
	var survivingRooms = []
	for region in rooms:
		if region.size() < roomThreshold:
			for tile in region:
				map[tile.tileX][tile.tileY] = true
		else:
			survivingRooms.append(Room.new(region, map))
	
	survivingRooms.sort_custom(Room, "compare")
	survivingRooms[0].isMain = true
	survivingRooms[0].isAccessibleFromMain = true
	connectClosestRooms(survivingRooms, false)

func connectClosestRooms(allRooms, forceMainAccessible):
	var roomListA = []
	var roomListB = []
	
	if forceMainAccessible:
		for room in allRooms:
			if room.isAccessibleFromMain:
				roomListB.append(room)
			else:
				roomListA.append(room)
	else:
		roomListA = allRooms
		roomListB = allRooms
	
	var bestDistance = 0
	var bestTileA
	var bestTileB
	var bestRoomA
	var bestRoomB
	var possibleConnectionFound = false
	
	for roomA in roomListA:
		if !forceMainAccessible:
			possibleConnectionFound = false
			if roomA.connectedRooms.size() > 0:
				continue
		for roomB in roomListB:
			if roomA == roomB or roomA.isConnected(roomB): 
				continue
			
			for indexA in range(roomA.edgeTiles.size()):
				for indexB in range(roomB.edgeTiles.size()):
					var tileA = roomA.edgeTiles[indexA]
					var tileB = roomB.edgeTiles[indexB]
					var distBetweenRooms = int(pow(tileA.tileX - tileB.tileX, 2) + pow(tileA.tileY - tileB.tileY, 2))
					
					if distBetweenRooms < bestDistance or !possibleConnectionFound:
						bestDistance = distBetweenRooms
						possibleConnectionFound = true
						bestTileA = tileA
						bestTileB = tileB
						bestRoomA = roomA
						bestRoomB = roomB
		if possibleConnectionFound and !forceMainAccessible:
			createPassage(bestRoomA, bestRoomB, bestTileA, bestTileB)
	if possibleConnectionFound and forceMainAccessible:
		createPassage(bestRoomA, bestRoomB, bestTileA, bestTileB)
		connectClosestRooms(allRooms, true)
	if !forceMainAccessible:
		connectClosestRooms(allRooms, true)

func createPassage(roomA, roomB, tileA, tileB):
	Room.connectRooms(roomA, roomB)
	var line = getLine(tileA, tileB)
	for coord in line:
		drawCircle(coord, 2)

func drawCircle(coord, radius):
	var x = -radius
	while x <= radius:
		var y = -radius
		while y <= radius:
			if x*x + y*y <= radius*radius:
				var realX = coord.tileX + x
				var realY = coord.tileY + y
				if isInMapRange(realX, realY):
					map[realX][realY] = false
			y += 1
		
		x += 1

func getLine(from, to):
	var line = []
	var x = from.tileX
	var y = from.tileY
	var dx = to.tileX - from.tileX
	var dy = to.tileY - from.tileY
	var inverted = false
	var step = sign(dx)
	var gradientStep = sign(dy)
	var longest = abs(dx)
	var shortest = abs(dy)
	
	if longest < shortest:
		inverted = true
		longest = abs(dy)
		shortest = abs(dx)
		step = sign(dy)
		gradientStep = sign(dx)
	
	var gradientAccum = int(longest / 2)
	for i in range(longest):
		line.append(Coord.new(x,y))
		if inverted: y += step
		else: x += step
		
		gradientAccum += shortest
		if gradientAccum >= longest:
			if inverted: x += gradientStep
			else: y += gradientStep
			gradientAccum -= longest
	
	return line



