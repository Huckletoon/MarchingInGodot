extends Node

var noise0 = OpenSimplexNoise.new()
var noise1 = OpenSimplexNoise.new()
var noise2 = OpenSimplexNoise.new()
var warpNoise = OpenSimplexNoise.new()

export var size = 50
#export var cellSize = 2
export var densityThreshold = 1.0
export var rngSeed = 71797
export var noiseFreq0 = 1.0
export var noiseFreq1 = 1.0
export var noiseFreq2 = 1.0
export var noiseAmp0 = 1.0
export var noiseAmp1 = 1.0
export var noiseAmp2 = 1.0
export var warpFactor = 0.08
export var floorMod = 0.5
export var makeFloor = false
export var terraceLevel = 20.0

var map = []
var cubeConfigs = []
var triIndeces = PoolIntArray()
var triVertices = []
var triNorms = PoolVector3Array()
var triUVs = PoolVector2Array()

var iterCount = 0
var iterLimit = 10000
var iterWait = 0.000005
var chunkLimit = 30000

func getBinary(dec):
	var binary = 0
	var temp = dec
	if temp >= 128:
		binary += 10000000
		temp -= 128
	if temp >= 64:
		binary += 1000000
		temp -= 64 
	if temp >= 32:
		binary += 100000
		temp -= 32
	if temp >= 16:
		binary += 10000
		temp -= 16
	if temp >= 8:
		binary += 1000
		temp -= 8
	if temp >= 4:
		binary += 100
		temp -= 4
	if temp >= 2:
		binary += 10
		temp -= 2
	if temp == 1:
		binary += 1
	return binary

func loadCubeConfigs():
	cubeConfigs.resize(256)
	
	# All or none
	cubeConfigs[0] = [-1]
	cubeConfigs[255] = [-1]
	
	#-Single vertex-
	cubeConfigs[1] = [1, 9, 4]
	cubeConfigs[2] = [10, 1, 2]
	cubeConfigs[4] = [11, 2, 3]
	cubeConfigs[8] = [12, 3, 4]
	cubeConfigs[16] = [5, 8, 9]
	cubeConfigs[32] = [10, 6, 5]
	cubeConfigs[64] = [6, 11, 7]
	cubeConfigs[128] = [8, 7, 12]
	
	#-Two Vertices-
	# Node 1
	cubeConfigs[1+2] = [9, 4, 2, 9, 2, 10]
	cubeConfigs[1+4] = [1, 9, 4, 11, 2, 3]
	cubeConfigs[1+8] = [9, 3, 1, 9, 12, 3]
	cubeConfigs[1+16] = [4, 5, 8, 4, 1, 5]
	cubeConfigs[1+32] = [1, 9, 4, 10, 6, 5]
	cubeConfigs[1+64] = [1, 9, 4, 6, 11, 7]
	cubeConfigs[1+128] = [1, 9, 4, 8, 7, 12]
	# Node 2
	cubeConfigs[2+4] = [3, 11, 10, 3, 10, 1]
	cubeConfigs[2+8] = [10, 1, 2, 12, 3, 4]
	cubeConfigs[2+16] = [10, 1, 2, 5, 8, 9]
	cubeConfigs[2+32] = [5, 2, 6, 5, 1, 2]
	cubeConfigs[2+64] = [10, 1, 2, 6, 11, 7]
	cubeConfigs[2+128] = [10, 1, 2, 8, 7, 12]
	# Node 3
	cubeConfigs[4+8] = [12, 11, 2, 12, 2, 4]
	cubeConfigs[4+16] = [11, 2, 3, 5, 8, 9]
	cubeConfigs[4+32] = [11, 2, 3, 10, 6, 5]
	cubeConfigs[4+64] = [3, 7, 6, 3, 6, 2]
	cubeConfigs[4+128] = [11, 2, 3, 8, 7, 12]
	# Node 4
	cubeConfigs[8+16] = [12, 3, 4, 5, 8, 9]
	cubeConfigs[8+32] = [12, 3, 4, 10, 6, 5]
	cubeConfigs[8+64] = [12, 3, 4, 6, 11, 7]
	cubeConfigs[8+128] = [8, 7, 3, 8, 3, 4]
	# Node 5
	cubeConfigs[16+32] = [8, 9, 10, 8, 10, 6]
	cubeConfigs[16+64] = [5, 8, 9, 6, 11, 7]
	cubeConfigs[16+128] = [12, 9, 5, 12, 5, 7]
	# Node 6
	cubeConfigs[32+64] = [11, 7, 5, 11, 5, 10]
	cubeConfigs[32+128] = [10, 6, 5, 8, 7, 12]
	# Node 7
	cubeConfigs[64+128] = [12, 8, 6, 12, 6, 11]
	
	#-Three Vertices-
	# Node 1-2
	cubeConfigs[1+2+4] = [4, 3, 11, 4, 11, 10, 4, 10, 9]
	cubeConfigs[1+2+8] = [3, 2, 10, 3, 10, 9, 3, 9, 12]
	cubeConfigs[1+2+16] = [5, 8, 4, 5, 4, 2, 5, 2, 10]
	cubeConfigs[1+2+32] = [6, 5, 9, 6, 9, 4, 6, 4, 2]
	cubeConfigs[1+2+64] = [9, 4, 2, 9, 2, 10, 6, 11, 7]
	cubeConfigs[1+2+128] = [9, 4, 2, 9, 2, 10, 8, 7, 12]
	# Node 1-3
	cubeConfigs[1+4+8] = [1, 9, 12, 1, 12, 11, 1, 11, 2]
	cubeConfigs[1+4+16] = [4, 5, 8, 4, 1, 5, 11, 2, 3]
	cubeConfigs[1+4+32] = [1, 9, 4, 11, 2, 3, 10, 6, 5]
	cubeConfigs[1+4+64] = [1, 9, 4, 3, 7, 6, 3, 6, 2]
	cubeConfigs[1+4+128] = [1, 9, 4, 11, 2, 3, 8, 7, 12]
	# Node 1-4
	cubeConfigs[1+8+16] = [3, 1, 5, 3, 5, 8, 3, 8, 12]
	cubeConfigs[1+8+32] = [9, 3, 1, 9, 12, 3, 10, 6, 5]
	cubeConfigs[1+8+64] = [9, 3, 1, 9, 12, 3, 6, 11, 7]
	cubeConfigs[1+8+128] = [1, 9, 8, 1, 8, 7, 1, 7, 3]
	# Node 1-5
	cubeConfigs[1+16+32] = [10, 6, 8, 10, 8, 4, 10, 4, 1]
	cubeConfigs[1+16+64] = [4, 5, 8, 4, 1, 5, 6, 11, 7]
	cubeConfigs[1+16+128] = [1, 5, 7, 1, 7, 12, 1, 7, 4]
	# Node 1-6
	cubeConfigs[1+32+64] = [1, 9, 4, 11, 7, 5, 11, 5, 10]
	cubeConfigs[1+32+128] = [1, 9, 4, 10, 6, 5, 8, 7, 12]
	# Node 1-7
	cubeConfigs[1+64+128] = [1, 9, 4, 12, 8, 6, 12, 6, 11]
	# Node 2-3
	cubeConfigs[2+4+8] = [4, 12, 11, 4, 11, 10, 4, 10, 1]
	cubeConfigs[2+4+16] = [3, 11, 10, 3, 10, 1, 5, 8, 9]
	cubeConfigs[2+4+32] = [3, 11, 6, 3, 6, 5, 3, 5, 1]
	cubeConfigs[2+4+64] = [7, 6, 10, 7, 10, 1, 7, 1, 3]
	cubeConfigs[2+4+128] = [3, 11, 10, 3, 10, 1, 8, 7, 12]
	# Node 2-4
	cubeConfigs[2+8+16] = [10, 1, 2, 12, 3, 4, 5, 8, 9]
	cubeConfigs[2+8+32] = [12, 3, 4, 5, 2, 6, 5, 1, 2]
	cubeConfigs[2+8+64] = [10, 1, 2, 12, 3, 4, 6, 11, 7]
	cubeConfigs[2+8+128] = [10, 1, 2, 8, 7, 3, 8, 3, 4]
	# Node 2-5
	cubeConfigs[2+16+32] = [1, 2, 6, 1, 6, 8, 1, 8, 9]
	cubeConfigs[2+16+64] = [10, 1, 2, 5, 8, 9, 6, 11, 7]
	cubeConfigs[2+16+128] = [10, 1, 2, 12, 9, 5, 12, 5, 7]
	# Node 2-6
	cubeConfigs[2+32+64] = [2, 11, 7, 2, 7, 5, 2, 5, 1]
	cubeConfigs[2+32+128] = [5, 2, 6, 5, 1, 2, 8, 7, 12]
	# Node 2-7
	cubeConfigs[2+64+128] = [10, 1, 2, 12, 8, 6, 12, 6, 11]
	# Node 3-4
	cubeConfigs[4+8+16] = [12, 11, 2, 12, 2, 4, 8, 9, 5]
	cubeConfigs[4+8+32] = [12, 11, 2, 12, 2, 4, 6, 5, 10]
	cubeConfigs[4+8+64] = [7, 6, 2, 7, 2, 4, 7, 4, 12]
	cubeConfigs[4+8+128] = [11, 2, 4, 11, 4, 8, 11, 8, 7]
	# Node 3-5
	cubeConfigs[4+16+32] = [3, 11, 2, 8, 9, 10, 8, 10, 6]
	cubeConfigs[4+16+64] = [8, 9, 5, 3, 7, 6, 3, 6, 2]
	cubeConfigs[4+16+128] = [3, 11, 2, 8, 9, 5, 7, 12, 8]
	# Node 3-6
	cubeConfigs[4+32+64] = [2, 3, 7, 2, 7, 5, 2, 5, 10]
	cubeConfigs[4+32+128] = [3, 11, 2, 6, 5, 10, 7, 12, 8]
	# Node 3-7
	cubeConfigs[4+64+128] = [3, 12, 8, 3, 8, 6, 3, 6, 2]
	# Node 4-5
	cubeConfigs[8+16+32] = [12, 3, 4, 8, 9, 10, 8, 10, 6]
	cubeConfigs[8+16+64] = [12, 3, 4, 8, 9, 5, 7, 6, 11]
	cubeConfigs[8+16+128] = [4, 9, 5, 4, 5, 7, 4, 7, 3]
	# Node 4-6
	cubeConfigs[8+32+64] = [12, 3, 4, 11, 7, 5, 11, 5, 10]
	cubeConfigs[8+32+128] = [6, 5, 10, 8, 7, 3, 8, 3, 4]
	# Node 4-7
	cubeConfigs[8+64+128] = [3, 4, 8, 3, 8, 6, 3, 6, 11]
	# Node 5-6
	cubeConfigs[16+32+64] = [8, 9, 10, 8, 10, 11, 8, 11, 7]
	cubeConfigs[16+32+128] = [7, 12, 9, 7, 9, 10, 7, 10, 6]
	# Node 5-7
	cubeConfigs[16+64+128] = [11, 12, 9, 11, 9, 5, 11, 5, 6]
	# Node 6-7
	cubeConfigs[32+64+128] = [12, 8, 5, 12, 5, 10, 12, 10, 11]
	
	#-Four Vertices-
	# Node 1-2-3
	cubeConfigs[1+2+4+8] = [12, 11, 10, 12, 10, 9]
	cubeConfigs[1+2+4+16] = [4, 11, 5, 4, 3, 11, 11, 10, 5, 8, 4, 5]
	cubeConfigs[1+2+4+32] = [3, 11, 6, 3, 6, 4, 4, 6, 5, 4, 5, 9]
	cubeConfigs[1+2+4+64] = [7, 10, 4, 4, 3, 7, 7, 6, 10, 9, 4, 10]
	cubeConfigs[1+2+4+128] = [4, 3, 11, 4, 11, 10, 4, 10, 9, 8, 7, 12]
	# Node 1-2-4
	cubeConfigs[1+2+8+16] = [12, 3, 2, 12, 2, 8, 8, 2, 10, 8, 10, 5]
	cubeConfigs[1+2+8+32] = [12, 2, 5, 12, 5, 9, 12, 3, 2, 6, 5, 10]
	cubeConfigs[1+2+8+64] = [3, 2, 10, 3, 10, 9, 3, 9, 12, 6, 11, 7]
	cubeConfigs[1+2+8+128] = [7, 2, 9, 2, 10, 9, 7, 3, 2, 8, 7, 9]
	# Node 1-2-5
	cubeConfigs[1+2+16+32] = [4, 2, 6, 4, 6, 8]
	cubeConfigs[1+2+16+64] = [5, 8, 4, 5, 4, 2, 5, 2, 10, 6, 11, 7]
	cubeConfigs[1+2+16+128] = [10, 5, 7, 10, 7, 4, 10, 4, 2, 12, 4, 7]
	# Node 1-2-6
	cubeConfigs[1+2+32+64] = [9, 4, 2, 9, 2, 7, 9, 7, 5, 7, 2, 11]
	cubeConfigs[1+2+32+128] = [6, 5, 9, 6, 9, 4, 6, 4, 2, 8, 7, 12]
	# Node 1-2-7
	cubeConfigs[1+2+64+128] = [9, 4, 2, 9, 2, 10, 12, 8, 6, 12, 6, 11]
	# Nodes 1-3~
	cubeConfigs[1+4+8+16] = [2, 12, 11, 2, 5, 12, 2, 1, 5, 8, 12, 5]
	cubeConfigs[1+4+8+32] = [1, 9, 12, 1, 12, 11, 1, 11, 2, 10, 6, 5]
	cubeConfigs[1+4+8+64] = [1, 9, 12, 1, 12, 6, 1, 6, 2, 6, 12, 7]
	cubeConfigs[1+4+8+128] = [7, 11, 2, 7, 2, 8, 8, 2, 1, 8, 1, 9]
	cubeConfigs[1+4+16+32] = [10, 6, 8, 10, 8, 4, 10, 4, 1, 11, 2, 3]  # 1-3-5
	cubeConfigs[1+4+16+64] = [4, 5, 8, 4, 1, 5, 3, 7, 6, 3, 6, 2]
	cubeConfigs[1+4+16+128] = [1, 5, 7, 1, 7, 12, 1, 7, 4, 3, 11, 2]
	cubeConfigs[1+4+32+64] = [2, 3, 7, 2, 7, 5, 2, 5, 10, 9, 4, 1]  # 1-3-6
	cubeConfigs[1+4+32+128] = [9, 4, 1, 3, 11, 2, 6, 5, 10, 12, 8, 7]
	cubeConfigs[1+4+64+128] = [4, 1, 9, 3, 12, 8, 3, 8, 6, 3, 6, 2]
	# Nodes 1-4~
	cubeConfigs[1+8+16+32] = [10, 6, 8, 10, 8, 3, 10, 3, 1, 3, 8, 12]
	cubeConfigs[1+8+16+64] = [3, 1, 5, 3, 5, 8, 3, 8, 12, 11, 7, 6]
	cubeConfigs[1+8+16+128] = [7, 3, 1, 7, 1, 5]
	cubeConfigs[1+8+32+64] = [9, 3, 1, 9, 12, 3, 11, 7, 5, 11, 5, 10]
	cubeConfigs[1+8+32+128] = [6, 5, 10, 1, 9, 8, 1, 8, 7, 1, 7, 3]
	cubeConfigs[1+8+64+128] = [9, 3, 1, 9, 6, 3, 9, 8, 6, 11, 3, 6]
	# Nodes 1-5~6~
	cubeConfigs[1+16+32+64] = [1, 8, 4, 1, 11, 8, 1, 10, 11, 7, 8, 11]
	cubeConfigs[1+16+32+128] = [7, 12, 4, 7, 12, 6, 6, 4, 1, 6, 1, 10]
	cubeConfigs[1+16+64+128] = [6, 1, 5, 6, 12, 1, 6, 11, 12, 12, 4, 1]
	cubeConfigs[1+32+64+128] = [9, 4, 1, 12, 8, 5, 12, 5, 10, 12, 10, 11]
	# Nodes 2-3-4
	cubeConfigs[2+4+8+16] = [8, 9, 5, 4, 12, 11, 4, 11, 10, 4, 10, 1]
	cubeConfigs[2+4+8+32] = [6, 5, 1, 6, 1, 12, 6, 12, 11, 12, 1, 4]
	cubeConfigs[2+4+8+64] = [12, 7, 6, 12, 6, 4, 6, 10, 1, 6, 1, 4]
	cubeConfigs[2+4+8+128] = [1, 4, 8, 1, 8, 11, 1, 11, 10, 7, 11, 8]
	# Nodes 2-3~
	cubeConfigs[2+4+16+32] = [9, 1, 3, 9, 3, 6, 9, 6, 8, 11, 6, 3]
	cubeConfigs[2+4+16+64] = [8, 9, 5, 7, 6, 10, 7, 10, 1, 7, 1, 3]
	cubeConfigs[2+4+16+128] = [3, 11, 10, 3, 10, 1, 12, 9, 5, 12, 5, 7]
	cubeConfigs[2+4+32+64] = [3, 7, 5, 3, 5, 1]
	cubeConfigs[2+4+32+128] = [12, 8, 7, 3, 11, 6, 3, 6, 5, 3, 5, 1]
	cubeConfigs[2+4+64+128] = [10, 8, 6, 10, 3, 8, 10, 1, 3, 3, 12, 8]
	# Nodes 2-4~
	cubeConfigs[2+8+16+32] = [12, 3, 4, 1, 2, 6, 1, 6, 8, 1, 8, 9]
	cubeConfigs[2+8+16+64] = [12, 3, 4, 1, 2, 10, 8, 9, 5, 11, 7, 6]
	cubeConfigs[2+8+16+128] = [1, 2, 10, 4, 9, 5, 4, 5, 7, 4, 7, 3]
	cubeConfigs[2+8+32+64] = [12, 3, 4, 2, 11, 7, 2, 7, 5, 2, 5, 1]
	cubeConfigs[2+8+32+128] = [5, 2, 6, 5, 1, 2, 8, 7, 3, 8, 3, 4]
	cubeConfigs[2+8+64+128] = [1, 2, 10, 3, 4, 8, 3, 8, 6, 3, 6, 11]
	# Nodes 2-5~6~
	cubeConfigs[2+16+32+64] = [11, 7, 8, 11, 8, 2, 2, 8, 9, 2, 9, 1]
	cubeConfigs[2+16+32+128] = [1, 12, 9, 1, 6, 12, 1, 2, 6, 6, 7, 12]
	cubeConfigs[2+16+64+128] = [1, 2, 10, 11, 12, 9, 11, 9, 5, 11, 5, 6]
	cubeConfigs[2+32+64+128] = [2, 11, 12, 2, 12, 5, 2, 5, 1, 8, 5, 12]
	# Nodes 3-4~
	cubeConfigs[4+8+16+32] = [12, 11, 2, 12, 2, 4, 8, 9, 10, 8, 10, 6]
	cubeConfigs[4+8+16+64] = [8, 9, 5, 7, 6, 2, 7, 2, 4, 7, 4, 12]
	cubeConfigs[4+8+16+128] = [9, 2, 4, 9, 7, 2, 9, 5, 7, 7, 11, 2]
	cubeConfigs[4+8+32+64] = [10, 7, 5, 10, 4, 7, 10, 2, 4, 12, 7, 4]
	cubeConfigs[4+8+32+128] = [6, 5, 10, 11, 2, 4, 11, 4, 8, 11, 8, 7]
	cubeConfigs[4+8+64+128] = [4, 8, 6, 4, 6, 2]
	# Nodes 3-5~6~
	cubeConfigs[4+16+32+64] = [2, 3, 7, 2, 7, 9, 2, 9, 10, 9, 7, 8]
	cubeConfigs[4+16+32+128] = [3, 11, 2, 7, 12, 9, 7, 9, 10, 7, 10, 6]
	cubeConfigs[4+16+64+128] = [3, 6, 2, 3, 9, 6, 3, 12, 9, 5, 6, 9]
	cubeConfigs[4+32+64+128] = [12, 8, 5, 12, 5, 3, 5, 10, 2, 5, 2, 3]
	# Nodes 4~5~
	cubeConfigs[8+16+32+64] = [12, 3, 4, 8, 9, 10, 8, 10, 11, 8, 11, 7]
	cubeConfigs[8+16+32+128] = [6, 9, 10, 6, 3, 9, 6, 7, 3, 4, 9, 3]
	cubeConfigs[8+16+64+128] = [3, 6, 11, 4, 6, 3, 4, 5, 6, 4, 9, 5]
	cubeConfigs[8+32+64+128] = [11, 5, 6, 11, 3, 5, 3, 4, 9, 3, 9, 5]
	cubeConfigs[16+32+64+128] = [11, 12, 9, 11, 9, 10]
	
	#-Five Vertices-
	# Sans 1-2
	cubeConfigs[255-1-2-4] = reverseArray(cubeConfigs[1+2+4])
	cubeConfigs[255-1-2-8] = reverseArray(cubeConfigs[1+2+8])
	cubeConfigs[255-1-2-16] = reverseArray(cubeConfigs[1+2+16])
	cubeConfigs[255-1-2-32] = reverseArray(cubeConfigs[1+2+32])
	cubeConfigs[255-1-2-64] = reverseArray(cubeConfigs[1+2+64])
	cubeConfigs[255-1-2-128] = reverseArray(cubeConfigs[1+2+128])
	# Sans 1-3
	cubeConfigs[255-1-4-8] = reverseArray(cubeConfigs[1+4+8])
	cubeConfigs[255-1-4-16] = reverseArray(cubeConfigs[1+4+16])
	cubeConfigs[255-1-4-32] = reverseArray(cubeConfigs[1+4+32])
	cubeConfigs[255-1-4-64] = reverseArray(cubeConfigs[1+4+64])
	cubeConfigs[255-1-4-128] = reverseArray(cubeConfigs[1+4+128])
	# Sans 1-4
	cubeConfigs[255-1-8-16] = reverseArray(cubeConfigs[1+8+16])
	cubeConfigs[255-1-8-32] = reverseArray(cubeConfigs[1+8+32])
	cubeConfigs[255-1-8-64] = reverseArray(cubeConfigs[1+8+64])
	cubeConfigs[255-1-8-128] = reverseArray(cubeConfigs[1+8+128])
	# Sans 1-5
	cubeConfigs[255-1-16-32] = reverseArray(cubeConfigs[1+16+32])
	cubeConfigs[255-1-16-64] = reverseArray(cubeConfigs[1+16+64])
	cubeConfigs[255-1-16-128] = reverseArray(cubeConfigs[1+16+128])
	# Sans 1-6
	cubeConfigs[255-1-32-64] = reverseArray(cubeConfigs[1+32+64])
	cubeConfigs[255-1-32-128] = reverseArray(cubeConfigs[1+32+128])
	# Sans 1-7
	cubeConfigs[255-1-64-128] = reverseArray(cubeConfigs[1+64+128])
	# Sans 2-3
	cubeConfigs[255-2-4-8] = reverseArray(cubeConfigs[2+4+8])
	cubeConfigs[255-2-4-16] = reverseArray(cubeConfigs[2+4+16])
	cubeConfigs[255-2-4-32] = reverseArray(cubeConfigs[2+4+32])
	cubeConfigs[255-2-4-64] = reverseArray(cubeConfigs[2+4+64])
	cubeConfigs[255-2-4-128] = reverseArray(cubeConfigs[2+4+128])
	# Sans 2-4
	cubeConfigs[255-2-8-16] = reverseArray(cubeConfigs[2+8+16])
	cubeConfigs[255-2-8-32] = reverseArray(cubeConfigs[2+8+32])
	cubeConfigs[255-2-8-64] = reverseArray(cubeConfigs[2+8+64])
	cubeConfigs[255-2-8-128] = reverseArray(cubeConfigs[2+8+128])
	# Sans 2-5
	cubeConfigs[255-2-16-32] = reverseArray(cubeConfigs[2+16+32])
	cubeConfigs[255-2-16-64] = reverseArray(cubeConfigs[2+16+64])
	cubeConfigs[255-2-16-128] = reverseArray(cubeConfigs[2+16+128])
	# Sans 2-6
	cubeConfigs[255-2-32-64] = reverseArray(cubeConfigs[2+32+64])
	cubeConfigs[255-2-32-128] = reverseArray(cubeConfigs[2+32+128])
	# Sans 2-7
	cubeConfigs[255-2-64-128] = reverseArray(cubeConfigs[2+64+128])
	# Sans 3-4
	cubeConfigs[255-4-8-16] = reverseArray(cubeConfigs[4+8+16])
	cubeConfigs[255-4-8-32] = reverseArray(cubeConfigs[4+8+32])
	cubeConfigs[255-4-8-64] = reverseArray(cubeConfigs[4+8+64])
	cubeConfigs[255-4-8-128] = reverseArray(cubeConfigs[4+8+128])
	# Sans 3-5
	cubeConfigs[255-4-16-32] = reverseArray(cubeConfigs[4+16+32])
	cubeConfigs[255-4-16-64] = reverseArray(cubeConfigs[4+16+64])
	cubeConfigs[255-4-16-128] = reverseArray(cubeConfigs[4+16+128])
	# Sans 3-6
	cubeConfigs[255-4-32-64] = reverseArray(cubeConfigs[4+32+64])
	cubeConfigs[255-4-32-128] = reverseArray(cubeConfigs[4+32+128])
	# Sans 3-7
	cubeConfigs[255-4-64-128] = reverseArray(cubeConfigs[4+64+128])
	# Sans 4-5
	cubeConfigs[255-8-16-32] = reverseArray(cubeConfigs[8+16+32])
	cubeConfigs[255-8-16-64] = reverseArray(cubeConfigs[8+16+64])
	cubeConfigs[255-8-16-128] = reverseArray(cubeConfigs[8+16+128])
	# Sans 4-6
	cubeConfigs[255-8-32-64] = reverseArray(cubeConfigs[8+32+64])
	cubeConfigs[255-8-32-128] = reverseArray(cubeConfigs[8+32+128])
	# Sans 4-7
	cubeConfigs[255-8-64-128] = reverseArray(cubeConfigs[8+64+128])
	# Sans 5-6
	cubeConfigs[255-16-32-64] = reverseArray(cubeConfigs[16+32+64])
	cubeConfigs[255-16-32-128] = reverseArray(cubeConfigs[16+32+128])
	# Sans 5-7
	cubeConfigs[255-16-64-128] = reverseArray(cubeConfigs[16+64+128])
	# Sans 6-7-8
	cubeConfigs[255-32-64-128] = reverseArray(cubeConfigs[32+64+128])
	
	#-Six Vertices-
	# Sans 1
	cubeConfigs[255-1-2] = reverseArray(cubeConfigs[1+2])
	cubeConfigs[255-1-4] = reverseArray(cubeConfigs[1+4])
	cubeConfigs[255-1-8] = reverseArray(cubeConfigs[1+8])
	cubeConfigs[255-1-16] = reverseArray(cubeConfigs[1+16])
	cubeConfigs[255-1-32] = reverseArray(cubeConfigs[1+32])
	cubeConfigs[255-1-64] = reverseArray(cubeConfigs[1+64])
	cubeConfigs[255-1-128] = reverseArray(cubeConfigs[1+128])
	# Sans 2
	cubeConfigs[255-2-4] = reverseArray(cubeConfigs[2+4])
	cubeConfigs[255-2-8] = reverseArray(cubeConfigs[2+8])
	cubeConfigs[255-2-16] = reverseArray(cubeConfigs[2+16])
	cubeConfigs[255-2-32] = reverseArray(cubeConfigs[2+32])
	cubeConfigs[255-2-64] = reverseArray(cubeConfigs[2+64])
	cubeConfigs[255-2-128] = reverseArray(cubeConfigs[2+128])
	# Sans 3
	cubeConfigs[255-4-8] = reverseArray(cubeConfigs[4+8])
	cubeConfigs[255-4-16] = reverseArray(cubeConfigs[4+16])
	cubeConfigs[255-4-32] = reverseArray(cubeConfigs[4+32])
	cubeConfigs[255-4-64] = reverseArray(cubeConfigs[4+64])
	cubeConfigs[255-4-128] = reverseArray(cubeConfigs[4+128])
	# Sans 4
	cubeConfigs[255-8-16] = reverseArray(cubeConfigs[8+16])
	cubeConfigs[255-8-32] = reverseArray(cubeConfigs[8+32])
	cubeConfigs[255-8-64] = reverseArray(cubeConfigs[8+64])
	cubeConfigs[255-8-128] = reverseArray(cubeConfigs[8+128])
	# Sans 5
	cubeConfigs[255-16-32] = reverseArray(cubeConfigs[16+32])
	cubeConfigs[255-16-64] = reverseArray(cubeConfigs[16+64])
	cubeConfigs[255-16-128] = reverseArray(cubeConfigs[16+128])
	# Sans 6
	cubeConfigs[255-32-64] = reverseArray(cubeConfigs[32+64])
	cubeConfigs[255-32-128] = reverseArray(cubeConfigs[32+128])
	# Sans 7
	cubeConfigs[255-64-128] = reverseArray(cubeConfigs[64+128])
	
	#-Seven Vertices-
	cubeConfigs[255-1] = reverseArray(cubeConfigs[1])
	cubeConfigs[255-2] = reverseArray(cubeConfigs[2])
	cubeConfigs[255-4] = reverseArray(cubeConfigs[4])
	cubeConfigs[255-8] = reverseArray(cubeConfigs[8])
	cubeConfigs[255-16] = reverseArray(cubeConfigs[16])
	cubeConfigs[255-32] = reverseArray(cubeConfigs[32])
	cubeConfigs[255-64] = reverseArray(cubeConfigs[64])
	cubeConfigs[255-128] = reverseArray(cubeConfigs[128])
	
	
	#Track progress
	var unfinished = []
	var wrong = []
	for i in range(cubeConfigs.size()):
		if cubeConfigs[i] == null:
			var binary = 0
			binary = getBinary(i)
			unfinished.append(binary)
			if cubeConfigs[i].size() % 3 != 0:
				wrong.append(binary)
	print(unfinished)
	print("Cases left: " + String(unfinished.size()))
	print("Wrong: " + String(wrong.size()))
	print(wrong)

func loadPresetConfigs():
	cubeConfigs = [[-1],
		[0, 8, 3],
		[0, 1, 9],
		[1, 8, 3, 9, 8, 1],
		[1, 2, 10],
		[0, 8, 3, 1, 2, 10],
		[9, 2, 10, 0, 2, 9],
		[2, 8, 3, 2, 10, 8, 10, 9, 8],
		[3, 11, 2],
		[0, 11, 2, 8, 11, 0],
		[1, 9, 0, 2, 3, 11],
		[1, 11, 2, 1, 9, 11, 9, 8, 11],
		[3, 10, 1, 11, 10, 3],
		[0, 10, 1, 0, 8, 10, 8, 11, 10],
		[3, 9, 0, 3, 11, 9, 11, 10, 9],
		[9, 8, 10, 10, 8, 11],
		[4, 7, 8],
		[4, 3, 0, 7, 3, 4],
		[0, 1, 9, 8, 4, 7],
		[4, 1, 9, 4, 7, 1, 7, 3, 1],
		[1, 2, 10, 8, 4, 7],
		[3, 4, 7, 3, 0, 4, 1, 2, 10],
		[9, 2, 10, 9, 0, 2, 8, 4, 7],
		[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
		[8, 4, 7, 3, 11, 2],
		[11, 4, 7, 11, 2, 4, 2, 0, 4],
		[9, 0, 1, 8, 4, 7, 2, 3, 11],
		[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
		[3, 10, 1, 3, 11, 10, 7, 8, 4],
		[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
		[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
		[4, 7, 11, 4, 11, 9, 9, 11, 10],
		[9, 5, 4],
		[9, 5, 4, 0, 8, 3],
		[0, 5, 4, 1, 5, 0],
		[8, 5, 4, 8, 3, 5, 3, 1, 5],
		[1, 2, 10, 9, 5, 4],
		[3, 0, 8, 1, 2, 10, 4, 9, 5],
		[5, 2, 10, 5, 4, 2, 4, 0, 2],
		[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
		[9, 5, 4, 2, 3, 11],
		[0, 11, 2, 0, 8, 11, 4, 9, 5],
		[0, 5, 4, 0, 1, 5, 2, 3, 11],
		[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
		[10, 3, 11, 10, 1, 3, 9, 5, 4],
		[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
		[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
		[5, 4, 8, 5, 8, 10, 10, 8, 11],
		[9, 7, 8, 5, 7, 9],
		[9, 3, 0, 9, 5, 3, 5, 7, 3],
		[0, 7, 8, 0, 1, 7, 1, 5, 7],
		[1, 5, 3, 3, 5, 7],
		[9, 7, 8, 9, 5, 7, 10, 1, 2],
		[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
		[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
		[2, 10, 5, 2, 5, 3, 3, 5, 7],
		[7, 9, 5, 7, 8, 9, 3, 11, 2],
		[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
		[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
		[11, 2, 1, 11, 1, 7, 7, 1, 5],
		[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
		[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
		[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
		[11, 10, 5, 7, 11, 5],
		[10, 6, 5],
		[0, 8, 3, 5, 10, 6],
		[9, 0, 1, 5, 10, 6],
		[1, 8, 3, 1, 9, 8, 5, 10, 6],
		[1, 6, 5, 2, 6, 1],
		[1, 6, 5, 1, 2, 6, 3, 0, 8],
		[9, 6, 5, 9, 0, 6, 0, 2, 6],
		[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
		[2, 3, 11, 10, 6, 5],
		[11, 0, 8, 11, 2, 0, 10, 6, 5],
		[0, 1, 9, 2, 3, 11, 5, 10, 6],
		[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
		[6, 3, 11, 6, 5, 3, 5, 1, 3],
		[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
		[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
		[6, 5, 9, 6, 9, 11, 11, 9, 8],
		[5, 10, 6, 4, 7, 8],
		[4, 3, 0, 4, 7, 3, 6, 5, 10],
		[1, 9, 0, 5, 10, 6, 8, 4, 7],
		[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
		[6, 1, 2, 6, 5, 1, 4, 7, 8],
		[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
		[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
		[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],
		[3, 11, 2, 7, 8, 4, 10, 6, 5],
		[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
		[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
		[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
		[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
		[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
		[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
		[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
		[10, 4, 9, 6, 4, 10],
		[4, 10, 6, 4, 9, 10, 0, 8, 3],
		[10, 0, 1, 10, 6, 0, 6, 4, 0],
		[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
		[1, 4, 9, 1, 2, 4, 2, 6, 4],
		[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
		[0, 2, 4, 4, 2, 6],
		[8, 3, 2, 8, 2, 4, 4, 2, 6],
		[10, 4, 9, 10, 6, 4, 11, 2, 3],
		[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
		[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
		[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
		[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
		[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
		[3, 11, 6, 3, 6, 0, 0, 6, 4],
		[6, 4, 8, 11, 6, 8],
		[7, 10, 6, 7, 8, 10, 8, 9, 10],
		[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
		[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
		[10, 6, 7, 10, 7, 1, 1, 7, 3],
		[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
		[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
		[7, 8, 0, 7, 0, 6, 6, 0, 2],
		[7, 3, 2, 6, 7, 2],
		[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
		[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
		[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
		[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
		[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
		[0, 9, 1, 11, 6, 7],
		[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
		[7, 11, 6],
		[7, 6, 11],
		[3, 0, 8, 11, 7, 6],
		[0, 1, 9, 11, 7, 6],
		[8, 1, 9, 8, 3, 1, 11, 7, 6],
		[10, 1, 2, 6, 11, 7],
		[1, 2, 10, 3, 0, 8, 6, 11, 7],
		[2, 9, 0, 2, 10, 9, 6, 11, 7],
		[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
		[7, 2, 3, 6, 2, 7],
		[7, 0, 8, 7, 6, 0, 6, 2, 0],
		[2, 7, 6, 2, 3, 7, 0, 1, 9],
		[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
		[10, 7, 6, 10, 1, 7, 1, 3, 7],
		[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
		[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
		[7, 6, 10, 7, 10, 8, 8, 10, 9],
		[6, 8, 4, 11, 8, 6],
		[3, 6, 11, 3, 0, 6, 0, 4, 6],
		[8, 6, 11, 8, 4, 6, 9, 0, 1],
		[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
		[6, 8, 4, 6, 11, 8, 2, 10, 1],
		[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
		[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
		[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
		[8, 2, 3, 8, 4, 2, 4, 6, 2],
		[0, 4, 2, 4, 6, 2],
		[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
		[1, 9, 4, 1, 4, 2, 2, 4, 6],
		[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
		[10, 1, 0, 10, 0, 6, 6, 0, 4],
		[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
		[10, 9, 4, 6, 10, 4],
		[4, 9, 5, 7, 6, 11],
		[0, 8, 3, 4, 9, 5, 11, 7, 6],
		[5, 0, 1, 5, 4, 0, 7, 6, 11],
		[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
		[9, 5, 4, 10, 1, 2, 7, 6, 11],
		[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
		[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
		[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
		[7, 2, 3, 7, 6, 2, 5, 4, 9],
		[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
		[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
		[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
		[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
		[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
		[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
		[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
		[6, 9, 5, 6, 11, 9, 11, 8, 9],
		[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
		[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
		[6, 11, 3, 6, 3, 5, 5, 3, 1],
		[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
		[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
		[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
		[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
		[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
		[9, 5, 6, 9, 6, 0, 0, 6, 2],
		[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
		[1, 5, 6, 2, 1, 6],
		[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
		[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
		[0, 3, 8, 5, 6, 10],
		[10, 5, 6],
		[11, 5, 10, 7, 5, 11],
		[11, 5, 10, 11, 7, 5, 8, 3, 0],
		[5, 11, 7, 5, 10, 11, 1, 9, 0],
		[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
		[11, 1, 2, 11, 7, 1, 7, 5, 1],
		[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
		[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
		[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
		[2, 5, 10, 2, 3, 5, 3, 7, 5],
		[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
		[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
		[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
		[1, 3, 5, 3, 7, 5],
		[0, 8, 7, 0, 7, 1, 1, 7, 5],
		[9, 0, 3, 9, 3, 5, 5, 3, 7],
		[9, 8, 7, 5, 9, 7],
		[5, 8, 4, 5, 10, 8, 10, 11, 8],
		[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
		[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
		[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
		[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
		[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
		[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
		[9, 4, 5, 2, 11, 3],
		[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
		[5, 10, 2, 5, 2, 4, 4, 2, 0],
		[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
		[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
		[8, 4, 5, 8, 5, 3, 3, 5, 1],
		[0, 4, 5, 1, 0, 5],
		[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
		[9, 4, 5],
		[4, 11, 7, 4, 9, 11, 9, 10, 11],
		[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
		[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
		[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
		[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
		[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
		[11, 7, 4, 11, 4, 2, 2, 4, 0],
		[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
		[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
		[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
		[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
		[1, 10, 2, 8, 7, 4],
		[4, 9, 1, 4, 1, 7, 7, 1, 3],
		[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
		[4, 0, 3, 7, 4, 3],
		[4, 8, 7],
		[9, 10, 8, 10, 11, 8],
		[3, 0, 9, 3, 9, 11, 11, 9, 10],
		[0, 1, 10, 0, 10, 8, 8, 10, 11],
		[3, 1, 10, 11, 3, 10],
		[1, 2, 11, 1, 11, 9, 9, 11, 8],
		[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
		[0, 2, 11, 8, 0, 11],
		[3, 2, 11],
		[2, 3, 8, 2, 8, 10, 10, 8, 9],
		[9, 10, 2, 0, 9, 2],
		[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
		[1, 10, 2],
		[1, 3, 8, 9, 1, 8],
		[0, 9, 1],
		[0, 3, 8],
		[-1]]

func reverseArray(array):
	var temp = array.duplicate()
	temp.invert()
	return temp

func _ready():
	#loadCubeConfigs()
	loadPresetConfigs()
	
	noise0.seed = rngSeed
	noise0.octaves = 2
	noise0.period = 20.0
	noise0.persistence = 0.7
	
	noise1.seed = rngSeed
	noise1.octaves = 4
	noise1.period = 30.0
	noise1.persistence = 0.6
	
	noise2.seed = rngSeed
	noise2.octaves = 6
	noise2.period = 35.0
	noise2.persistence = 0.5
	
	warpNoise.seed = rngSeed
	warpNoise.octaves = 1
	warpNoise.period = 5
	warpNoise.persistence = 0.9
	
	generateMap()
	generateMesh()

func getDensity(x, y, z):
	var position = Vector3(x,y,z)
	var warp = warpNoise.get_noise_3dv(position * warpFactor)
	position = (1 + warp) * position
	var density = noise0.get_noise_3dv(position * noiseFreq0) * noiseAmp0
	density += noise1.get_noise_3dv(position * noiseFreq1) * noiseAmp1
	density += noise2.get_noise_3dv(position * noiseFreq2) * noiseAmp2
	if makeFloor:
		var yMod = floor((40-position.y)/terraceLevel) * floorMod
		density += yMod
		if y == 0 or y == 1:
			density += 2
	return density

func generateMap():
	var highest = 0
	var lowest = 0
	var checked = false
	var count = 0
	var total = 0.0
	
	for x in range(size):
		map.append([])
		for y in range(size):
			map[x].append([])
			for z in range(size):
				map[x][y].append(getDensity(x,y,z))
				count += 1
				total += map[x][y][z]
				
				if !checked:
					highest = map[x][y][z]
					lowest = map[x][y][z]
					checked = true
				if map[x][y][z] > highest:
					highest = map[x][y][z]
				if map[x][y][z] < lowest:
					lowest = map[x][y][z]
	

func generateMesh():
	var startTime = OS.get_system_time_msecs()
	for x in range(map.size() - 1):
		print(String(x) + " @ " + String((OS.get_system_time_msecs()-startTime)/1000.0))
		if (x % 5 == 0): 
			yield(get_tree().create_timer(0.05), "timeout")
			pass
		for y in range(map[x].size() - 1):
			for z in range(map[x][y].size() - 1):
				
				var node1 = map[x][y][z]
				var node2 = map[x][y][z+1]
				var node3 = map[x][y+1][z+1]
				var node4 = map[x][y+1][z]
				var node5 = map[x+1][y][z]
				var node6 = map[x+1][y][z+1]
				var node7 = map[x+1][y+1][z+1]
				var node8 = map[x+1][y+1][z]
				
				# Calculate configuration
				var configuration = 0
				if node1 > densityThreshold:
					configuration += 1
				if node2 > densityThreshold:
					configuration += 2
				if node3 > densityThreshold:
					configuration += 4
				if node4 > densityThreshold:
					configuration += 8
				if node5 > densityThreshold:
					configuration += 16
				if node6 > densityThreshold:
					configuration += 32
				if node7 > densityThreshold:
					configuration += 64
				if node8 > densityThreshold:
					configuration += 128
				
				# Calculate edge positions
				var edges = []
				edges.resize(12)
				edges[0] = Vector3(x, y, z+getLerp(node1, node2))
				edges[1] = Vector3(x, y+getLerp(node2, node3), z+1)
				edges[2] = Vector3(x, y+1, z+getLerp(node4, node3))
				edges[3] = Vector3(x, y+getLerp(node1, node4), z)
				edges[4] = Vector3(x+1, y, z+getLerp(node5, node6))
				edges[5] = Vector3(x+1, y+getLerp(node6, node7), z+1)
				edges[6] = Vector3(x+1, y+1, z+getLerp(node8, node7))
				edges[7] = Vector3(x+1, y+getLerp(node5, node8), z)
				edges[8] = Vector3(x+getLerp(node1, node5), y, z)
				edges[9] = Vector3(x+getLerp(node2, node6), y, z+1)
				edges[10] = Vector3(x+getLerp(node3, node7), y+1, z+1)
				edges[11] = Vector3(x+getLerp(node4, node8), y+1, z)
				
				if cubeConfigs[configuration][0] != -1:
					var iter = cubeConfigs[configuration].size() - 1
					while iter >= 0:
						var index = cubeConfigs[configuration][iter]
						var edge = edges[index]
						var existing = triVertices.find(edge, int(max(0, triIndeces.size() - (size*size))))
						if existing != -1:
							triIndeces.append(existing)
						else:
							# NORMAL ESTIMATION
							var normX = getDensity(edge.x + 1, edge.y, edge.z) - getDensity(edge.x - 1, edge.y, edge.z)
							var normY = getDensity(edge.x, edge.y + 1, edge.z) - getDensity(edge.x, edge.y - 1, edge.z)
							var normZ = getDensity(edge.x, edge.y, edge.z + 1) - getDensity(edge.x, edge.y, edge.z - 1)
							triNorms.append(Vector3(normX, normY, normZ).normalized() * -1)
							triIndeces.append(triVertices.size())
							triVertices.append(edge)
							triUVs.append(Vector2.ZERO)
						iter -= 1
	
	var endTime = OS.get_system_time_msecs()
	var timeTaken = endTime - startTime
	print("Configurations complete")
	print("Time Taken: " + String(timeTaken/1000.0))
	print(triIndeces.size())
	var triVertPool = PoolVector3Array(triVertices)
	
	if triIndeces.size() <= chunkLimit:
		# Mesh in one go
		addMesh(triVertPool, triUVs, triNorms, triIndeces)
	else:
		# Multiple meshes in chunks
		var chunks = ceil(triIndeces.size() / float(chunkLimit))
		var arrays = []
		for x in range (chunks):
			arrays.append([])
			var tier = x * chunkLimit
			for y in range(chunkLimit):
				var index = tier + y
				if index < triIndeces.size():
					arrays[x].append(triIndeces[index])
				else:
					break
		
		for array in arrays:
			addMesh(triVertPool, triUVs, triNorms, PoolIntArray(array))
			yield(get_tree().create_timer(0.01), "timeout")
	print("Mesh loading complete")
	

func getLerp(firstNode, secondNode):
	return 1.0 / (secondNode - firstNode) * (densityThreshold - firstNode)

func addMesh(verts, uvs, norms, index):
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = index
	
	var mesh = ArrayMesh.new()
	mesh.call_deferred("add_surface_from_arrays", Mesh.PRIMITIVE_TRIANGLES, arrays)
	var meshNode = MeshInstance.new()
	meshNode.call_deferred("set_name", "TopMesh")
	meshNode.call_deferred("set_mesh", mesh)
	get_tree().current_scene.call_deferred("add_child", meshNode)
	
	pass

