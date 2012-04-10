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
	fixDef.restitution = 1.01
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

	bodyA = contact.GetFixtureA().GetBody()
	bodyB = contact.GetFixtureB().GetBody()

	if (bodyA == bricked.ball or bodyB == bricked.ball)
		if (bodyA == bricked.paddle or bodyB == bricked.paddle)
			bricked.ballStartTime = bricked.getCurrentTime()

		# See if the ball hit the bottom wall, and thus is dead
		if (bodyA == bricked.bottomWall or bodyB == bricked.bottomWall)
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
	if (Math.abs(bricked.ball.GetLinearVelocity().x) < 0.2)
		# Give it a slight nudge
		bricked.applyXForce bricked.ball, 1
	else if (Math.abs(bricked.ball.GetLinearVelocity().y) < 0.2)
		# Give it a slight nudge
		bricked.applyYForce bricked.ball, 1

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

