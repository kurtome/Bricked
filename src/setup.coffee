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

###
 Converts screen points (pixels) to points the 
 physics engine works with
###
bricked.scaleToPhys = (x) -> return (x / bricked.SCALE)

###
 Converts screen points (pixels) vector to points 
 the physics engine works with
###
bricked.scaleVecToPhys = (vec) ->
	vec.Multiply(1 / bricked.SCALE)
	return vec

###
 Converts physics points to points the screen points
 (pixels)
###
bricked.scaleToScreen = (x) -> return (x * bricked.SCALE)

###
# Applies a horizontal force to a body
###
bricked.applyXForce = (body, xForce) ->
	b2Vec2 = Box2D.Common.Math.b2Vec2
	centerPoint = body.GetPosition()
	force = new b2Vec2(xForce, 0)
	body.ApplyForce(force, centerPoint)

###
# Applies a vertical force to a body
###
bricked.applyYForce = (body, yForce) ->
	b2Vec2 = Box2D.Common.Math.b2Vec2
	centerPoint = body.GetPosition()
	force = new b2Vec2(0, yForce)
	body.ApplyForce(force, centerPoint)
