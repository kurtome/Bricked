# global object to hold the data and methods for this game
bricked = { }

# Create a stats object for tracking FPS
bricked.stats = new Stats()

# Put the stats visual in the body.
document.body.appendChild(bricked.stats.domElement)

bricked.canvas = document.getElementById("c")
bricked.ctx = bricked.canvas.getContext("2d")

# Constants
bricked.SCALE = 30
bricked.FRAME_RATE = 1 / 60
bricked.VELOCITY_ITERATIONS = 10
bricked.POSITION_ITERATIONS = 10
bricked.GRAVITY = new Box2D.Common.Math.b2Vec2(0, 0)
bricked.WIDTH = bricked.canvas.width
bricked.HEIGHT = bricked.canvas.height
bricked.BALL_RADIUS = 10
# Path constants
bricked.paths = { }
bricked.paths.TRAINER_WORKER = 'scripts/trainerWorker.js'


bricked.getCurrentTime = ->
	currentTime = new Date()
	return currentTime.getTime()
