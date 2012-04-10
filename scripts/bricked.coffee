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

bricked.isBodyInContact = (contact, body) ->
	bodyA = contact.GetFixtureA().GetBody()
	bodyB = contact.GetFixtureB().GetBody()

	if (bodyA is body or bodyB is body)
		return true
	else
		return false



bricked.TRAINING_DATA_SIZE = 1000
bricked.PADDLE_X_FORCE = 10
bricked.TRAINING_OFFSET = bricked.scaleToPhys bricked.WIDTH
bricked.TRAINING_SCALE = bricked.TRAINING_OFFSET * 2
bricked.MAX_PREDICTIONS = 200
bricked.MARGIN = 0.1

bricked.X_POS = 0
bricked.PADDLE_POS = 1
bricked.RELATIVE_POS = 2
bricked.VX_POS = 3
#bricked.Y_POS = 1
#bricked.VY_POS = 3

###
# Createbricked.TRAINING_OFFSET * 2
###
class PaddleAi
	###
	# Constructor
	###
	constructor: (@paddle) ->
		@trainingWorker = new Worker bricked.paths.TRAINER_WORKER
		@trainingWorker.onmessage = this.onTrainerWorkerMessage

		@trainedLearner = new brain.NeuralNetwork()

		@trainingData = []
		@recentData = []
		@prevRecentData = []
		@isWaitingForWorker = false
		@isTrained = false
		@wasRecentDataTrained = false

	###
	# Contact event handler for the physics world.
	###
	beginContact: (contact) ->
		if (bricked.isBodyInContact(contact, bricked.ball))
			# Clear out the recent data when the ball hits something
			# so we don't train for superflous stuff
			#
			# Only hold on to prev recent data if
			# this is a side wall (the intention of it is to train off of
			# data including up to one side wall bounce)
			if (bricked.isBodyInContact(contact, bricked.leftWall) or
			bricked.isBodyInContact(contact, bricked.rightWall))
				@prevRecentData = @recentData
			else
				@prevRecentData = []

			# Now clear prev
			@recentData = []

	###
	# Callback for the onmessage of the trainingWorker
	###
	onTrainerWorkerMessage: (event) =>
		@trainedLearner.fromJSON event.data
		@isWaitingForWorker = false
		@isTrained = true

		console.log "Got prediction function"

	###
	# Applies a horizontal force to the paddle
	###
	applyXForce: (xForce) ->
		bricked.applyXForce(@paddle, xForce)

	###
	# Moves the paddle to the left
	###
	moveLeft: ->
		this.applyXForce -1 * bricked.PADDLE_X_FORCE

	###
	# Moves the paddle to the right
	###
	moveRight: ->
		this.applyXForce bricked.PADDLE_X_FORCE

	###
	# Updates the goal X position 
	updateGoalX: ->
		# Let's cheat for now and try follow the ball's position
		@goalX = bricked.ball.GetPosition().x

		if @isTrained
			finalY = @paddle.GetPosition().y
			curY = bricked.ball.GetPosition().y
			inputData = this.buildCurrentBallData()
			count = 0
			while curY < finalY and count < bricked.MAX_PREDICTIONS
				inputData = @trainedLearner.run inputData
				@goalX = this.scaleFromTraining inputData[0]
				curY = this.scaleFromTraining inputData[1]
				count++
	###

	###
	# TODO
	###
	scaleToTraining: (value) ->
		return (value+bricked.TRAINING_OFFSET) / bricked.TRAINING_SCALE

	###
	# TODO
	###
	scaleFromTraining: (value) ->
		return (value * bricked.TRAINING_SCALE) - bricked.TRAINING_OFFSET


	###
	# TODO
	###
	buildCurrentBallData: ->
		ballPosition = bricked.ball.GetPosition()
		ballLinearVelocity = bricked.ball.GetLinearVelocity()
		paddlePosition = @paddle.GetPosition()
		relativeHorizontalPos = paddlePosition.x - ballPosition.x
		relativeVerticalPos = ballPosition.y - paddlePosition.y
		
		# Figure out left/right position
		distanceLeft = 0
		distanceRight = 0
		if (relativeHorizontalPos < 0)
			distanceLeft = Math.abs(relativeHorizontalPos)
		else
			distanceRight = relativeHorizontalPos

		# Figure out left/right velocity
		velocityLeft = 0
		velocityRight = 0
		if (ballLinearVelocity.x < 0)
			velocityLeft = Math.abs(ballLinearVelocity.x)
		else
			velocityRight = ballLinearVelocity.x

		data = [
			this.scaleToTraining(ballPosition.x), 
			this.scaleToTraining(paddlePosition.x),
			this.scaleToTraining(distanceLeft),
			this.scaleToTraining(distanceRight),
			this.scaleToTraining(velocityLeft),
			this.scaleToTraining(velocityRight)
			this.scaleToTraining(relativeVerticalPos)
		]
		return data

	###
	# Execute training related work for each loop
	###
	updateTraining: ->
		if (@trainingData.length > bricked.TRAINING_DATA_SIZE)
			console.log 'Training full'
			return

		if (Math.random() > .5)
			@recentData.push this.buildCurrentBallData()

		if (@recentData.length > bricked.TRAINING_DATA_SIZE)
			# Remove the oldest data off the front
			@recentData.shift()

		@prevBallPos = bricked.ball.GetPosition()
		@prevBallVelocity =  bricked.ball.GetLinearVelocity()

		# See if the ball is past the paddle
		# TODO - this should probably be a little smarter since it could
		#		become true many steps after the ball is below the paddle
		if (bricked.ball.GetPosition().y > (@paddle.GetPosition().y + .1))
			this.trainRecentData()

	###
	# Execute when the ball dies
	###
	ballDied: ->
		@wasRecentDataTrained = false
	
	###
	# TODO
	###
	trainRecentData: ->
		if (@isWaitingForWorker or @wasRecentDataTrained)
			return

		# Combine in prev recent data if there is any
		if (@prevRecentData.length > 0)
			@recentData = @recentData.concat(@prevRecentData)
		
		@wasRecentDataTrained = true

		addedCount = 0
		while (@recentData.length > 0)
			addedCount++
			if addedCount > 5 then break

			dataPoint = @recentData.shift()
			leftVal = 0
			rightVal = 0
			stayVal = 0

			currentBallX = bricked.ball.GetPosition().x
			dataBallX = this.scaleFromTraining dataPoint[bricked.PADDLE_POS]

			stayMargin = 1
			if (Math.abs(currentBallX - dataBallX) < stayMargin)
				stayVal = 1
			else if (currentBallX < dataBallX)
				leftVal = 1
			else
				rightVal = 1

			trainingDataPoint = {
				input: dataPoint

				output: {
					left: leftVal,
					right: rightVal,
					stay: stayVal
				}
			}

			@trainingData.push trainingDataPoint

		console.log "Sending data to training worker"
		@isWaitingForWorker = true
		@trainingWorker.postMessage @trainingData

	###
	# Execute everything to be done during each game loop
	###
	update: ->
		this.updateTraining()
		#this.updateGoalX()
		#currentX = @paddle.GetPosition().x

		if (@isTrained)
			inputData = this.buildCurrentBallData()
			output = @trainedLearner.run inputData
			
			if (output.stay > output.right and output.stay > output.left)
				# Stay
			else if (output.left > output.right)
				this.moveLeft()
			else
				this.moveRight()


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

	# Create two walls in the top corners to make the ball bounce off at an angle
	# (really tired of ball getting stuck)
	# Top Left
	bodyDef.position.x = bricked.scaleToPhys(1)
	bodyDef.position.y = bricked.scaleToPhys(1)
	bodyDef.angle = Math.PI / 4
	topLeftWidth = bricked.scaleToPhys(15)
	topLeftHeight = bricked.scaleToPhys(15)
	fixDef.shape.SetAsBox(topLeftWidth, topLeftHeight)
	bricked.world.CreateBody(bodyDef).CreateFixture(fixDef)
	# Top right
	bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH - 1)
	bodyDef.position.y = bricked.scaleToPhys(1)
	bodyDef.angle = Math.PI / 4
	topRightWidth = bricked.scaleToPhys(15)
	topRightHeight = bricked.scaleToPhys(15)
	fixDef.shape.SetAsBox(topRightWidth, topRightHeight)
	bricked.world.CreateBody(bodyDef).CreateFixture(fixDef)
	

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
	fixDef.restitution = 1.02
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
	bricked.paddleAi.beginContact(contact)

	if (bricked.isBodyInContact(contact, bricked.ball))
		if (bricked.isBodyInContact(contact, bricked.paddle))
			bricked.ballStartTime = bricked.getCurrentTime()

		# See if the ball hit the bottom wall, and thus is dead
		if (bricked.isBodyInContact(contact, bricked.bottomWall))
			bricked.didBallDie = true

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

	bricked.paddleAi = new PaddleAi(bricked.paddle, bricked.ball)

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
#

###
 Gives the ball its initial push
###
bricked.startBall = ->
	bricked.ballStartTime = bricked.getCurrentTime()
	b2Vec2 = Box2D.Common.Math.b2Vec2

	# Randomize magnitude of forces between 100 - 150
	xForce = Math.random() * 50 + 100
	yForce = Math.random() * 50 + 100
	# Randomize x direction 
	if Math.random() > 0.5 then xForce *= -1
	# Always start upwards
	yForce *= -1
	initialForce = new b2Vec2(xForce, yForce)

	# Apply the force to the center of the ball
	centerPoint = bricked.ball.GetPosition()
	bricked.ball.ApplyForce(initialForce, centerPoint)

###
# Kill the ball
###
bricked.killBall = ->
	bricked.paddleAi.ballDied()
	bricked.didBallDie = false
	bricked.world.DestroyBody(bricked.ball)
	bricked.ball = bricked.createBall()
	bricked.startBall()

###
 Does all the work we need to do at each tick of the
 game clock.
###
bricked.update = -> 
	bricked.world.Step( bricked.FRAME_RATE, bricked.VELOCITY_ITERATIONS, bricked.POSITION_ITERATIONS )
	bricked.world.DrawDebugData()
	bricked.world.ClearForces()

	if (bricked.didBallDie)
		bricked.killBall()
	else if (bricked.getCurrentTime() - bricked.ballStartTime) > (60 * 1000)
		bricked.killBall()

	# Make sure the ball isn't stuck
	#if (Math.abs(bricked.ball.GetLinearVelocity().x) < 0.2)
		# Give it a slight nudge
		#bricked.applyXForce bricked.ball, 1
	#else if (Math.abs(bricked.ball.GetLinearVelocity().y) < 0.2)
		# Give it a slight nudge
		#bricked.applyYForce bricked.ball, 1

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

