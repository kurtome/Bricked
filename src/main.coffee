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
bricked.paths.TRAINER_WORKER = 'trainerWorker.min.js'

###
 Function that animates the 
###
window.requestAnimFrame = do -> 
	return window.requestAnimationFrame ||
		window.webkitRequestAnimationFrame ||
		window.mozRequestAnimationFrame ||
		window.oRequestAnimationFrame ||
		window.msRequestAnimationFrame ||
		(callback, element) -> 
			window.setTimeout(callback, 1000 / 60)

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
 Creates wall boundaries fo the game
###
bricked.createWalls = ->
	b2BodyDef = Box2D.Dynamics.b2BodyDef
	b2Body = Box2D.Dynamics.b2Body
	b2FixtureDef = Box2D.Dynamics.b2FixtureDef
	b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape

	fixDef = new b2FixtureDef
	fixDef.density = 1.0
	fixDef.friction = 0
	fixDef.restitution = 0.2

	bodyDef = new b2BodyDef
	bodyDef.type = b2Body.b2_staticBody

	# Create walls
	fixDef.shape = new b2PolygonShape
	# Left wall
	bodyDef.position.x = 0
	bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2)
	leftWidth = bricked.scaleToPhys(10 / 2)
	leftHeight = bricked.scaleToPhys((bricked.HEIGHT + (10 * bricked.BALL_RADIUS)) / 2)
	fixDef.shape.SetAsBox(leftWidth, leftHeight)
	bricked.leftWall = bricked.world.CreateBody(bodyDef)
	bricked.leftWall.CreateFixture(fixDef)

	# Top wall
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2)
	bodyDef.position.y = 0
	topWidth = bricked.scaleToPhys(bricked.WIDTH / 2)
	topHeight = bricked.scaleToPhys(10 / 2)
	fixDef.shape.SetAsBox(topWidth, topHeight)
	bricked.world.CreateBody(bodyDef).CreateFixture(fixDef)

	# Right wall
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH)
	bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2)
	rightWidth = leftWidth
	rightHeight = leftHeight
	fixDef.shape.SetAsBox(rightWidth, leftHeight)
	bricked.world.CreateBody(bodyDef).CreateFixture(fixDef)

	# Bottom wall (off screen)
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2)
	bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT + (5 * bricked.BALL_RADIUS))
	bottomWidth = topWidth
	bottomHeight = topHeight
	fixDef.shape.SetAsBox(bottomWidth, topHeight)
	bricked.bottomWall = bricked.world.CreateBody(bodyDef)
	bricked.bottomWall.CreateFixture(fixDef)

###
 Creates a ball
	Returns: the ball
###
bricked.createBall = ->
	b2BodyDef = Box2D.Dynamics.b2BodyDef
	b2Body = Box2D.Dynamics.b2Body
	b2FixtureDef = Box2D.Dynamics.b2FixtureDef
	b2CircleShape = Box2D.Collision.Shapes.b2CircleShape

	fixDef = new b2FixtureDef
	fixDef.density = 1.0
	fixDef.friction = 0
	fixDef.restitution = 1
	radius = bricked.scaleToPhys(bricked.BALL_RADIUS)
	fixDef.shape = new b2CircleShape(radius)

	bodyDef = new b2BodyDef
	bodyDef.type = b2Body.b2_dynamicBody
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2)
	bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2)

	ball = bricked.world.CreateBody(bodyDef)
	ball.CreateFixture(fixDef)
	ball.SetBullet(true)

	return ball

###
 Creates a paddle in the bricked.world
	Returns: The paddle
###
bricked.createPaddle = ->
	b2Vec2 = Box2D.Common.Math.b2Vec2
	b2BodyDef = Box2D.Dynamics.b2BodyDef
	b2Body = Box2D.Dynamics.b2Body
	b2FixtureDef = Box2D.Dynamics.b2FixtureDef
	b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape

	fixDef = new b2FixtureDef
	fixDef.density = 1.0
	fixDef.friction = 0
	fixDef.restitution = 1
	fixDef.shape = new b2PolygonShape
	paddleVertices = [
		bricked.scaleVecToPhys(new b2Vec2(0, 0)), 

		bricked.scaleVecToPhys(new b2Vec2(-40, 0)), 
		bricked.scaleVecToPhys(new b2Vec2(-35, -4)), 
		bricked.scaleVecToPhys(new b2Vec2(-20, -8)), 
		bricked.scaleVecToPhys(new b2Vec2(-10, -10)), 
		bricked.scaleVecToPhys(new b2Vec2(10, -10)), 
		bricked.scaleVecToPhys(new b2Vec2(20, -8)), 
		bricked.scaleVecToPhys(new b2Vec2(35, -4)), 
		bricked.scaleVecToPhys(new b2Vec2(40, 0))
	]
	fixDef.shape.SetAsArray(paddleVertices, paddleVertices.Length)

	bodyDef = new b2BodyDef
	bodyDef.type = b2Body.b2_dynamicBody
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2)
	bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT - 20)
	# Apply a linear dampening so that it will stop unless force is 
	# continually supplied
	bodyDef.linearDamping = 2.0

	paddle = bricked.world.CreateBody(bodyDef)
	paddle.CreateFixture(fixDef)

	# Create a joint to keep it horizontal
	prisJointDef = new Box2D.Dynamics.Joints.b2PrismaticJointDef
	prisJointDef.Initialize(paddle, bricked.bottomWall, paddle.GetPosition(), new b2Vec2(1,0))
	bricked.world.CreateJoint(prisJointDef)

	return paddle

###
 Handles the BeginContact event from the physics 
 world.
###

bricked.beginContact = (contact) ->
	bodyA = contact.GetFixtureA().GetBody()
	bodyB = contact.GetFixtureB().GetBody()

	# See if the ball hit the bottom wall, and thus is dead
	if (bodyA == bricked.ball and bodyB == bricked.bottomWall or
	bodyA == bricked.bottomWall and bodyB == bricked.ball)
		bricked.didBallDie = true

###
 Creates the neural network for learning.
###
bricked.createNn = ->
	options = {
		hidden: [16],
		growthRate: 1.0,
		learningRate: 0.8
	}
	net = new brain.NeuralNetwork(options)
	return net


###
 Initalizes everything we need to get started, should
 only be called once to set up.
###
bricked.init = ->
	b2DebugDraw = Box2D.Dynamics.b2DebugDraw

	allowSleep = true
	bricked.world = new Box2D.Dynamics.b2World(bricked.GRAVITY, allowSleep)

	bricked.createWalls()

	bricked.ball = bricked.createBall()
	bricked.paddle = bricked.createPaddle()

	neuralNet = bricked.createNn()
	bricked.paddleAi = new PaddleAi(bricked.paddle, neuralNet)

	# Contact listener for collision detection
	listener = new Box2D.Dynamics.b2ContactListener
	listener.BeginContact = bricked.beginContact
	bricked.world.SetContactListener(listener)

	# setup debug draw
	debugDraw = new b2DebugDraw()
	debugDraw.SetSprite(bricked.ctx)
	debugDraw.SetDrawScale(bricked.SCALE)
	debugDraw.SetFillAlpha(0.4)
	debugDraw.SetLineThickness(1.0)
	debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)
	bricked.world.SetDebugDraw(debugDraw)
# ~init() 

###
 Gives the ball its initial push
###
bricked.startBall = ->
	b2Vec2 = Box2D.Common.Math.b2Vec2

	# Randomize magnitude of forces between 50 - 250
	xForce = Math.random() * 200 + 50
	yForce = Math.random() * 200 + 50
	# Randomize direction of forces
	if Math.random() > 0.5 then xForce *= -1
	if Math.random() > 0.5 then yForce *= -1
	initialForce = new b2Vec2(xForce, yForce)

	# Apply the force to the center of the ball
	centerPoint = bricked.ball.GetPosition()
	bricked.ball.ApplyForce(initialForce, centerPoint)

###
 Does all the work we need to do at each tick of the
 game clock.
###
bricked.update = -> 
	bricked.world.Step( bricked.FRAME_RATE, bricked.VELOCITY_ITERATIONS, bricked.POSITION_ITERATIONS )
	bricked.world.DrawDebugData()
	bricked.world.ClearForces()

	if (bricked.didBallDie)
		bricked.didBallDie = false
		bricked.world.DestroyBody(bricked.ball)
		bricked.ball = bricked.createBall()
		bricked.startBall()

	# Update paddle
	bricked.paddleAi.update()

	# Update the stats for FPS info
	bricked.stats.update()

	# Kick off the next loop
	requestAnimFrame(bricked.update)
# update()


# Set everything up.
bricked.init()
# Begin the animation loop.
requestAnimFrame(bricked.update)

bricked.startBall()
