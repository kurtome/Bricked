	window.requestAnimFrame = ->
        return window.requestAnimationFrame ||
            window.webkitRequestAnimationFrame ||
            window.mozRequestAnimationFrame ||
            window.oRequestAnimationFrame ||
            window.msRequestAnimationFrame ||
            (callback, element) ->
                window.setTimeout(callback, 1000 / 60)
            

	# Create a stats object for tracking FPS
	stats = new Stats();
	# Put the stats visual in the body.
	document.body.appendChild(stats.domElement);
	
	canvas = document.getElementById("c");
	ctx = canvas.getContext("2d");

	world = null

	# Constants
	SCALE = 30;
		
	#-----------------------------------------------------
    # Initalizes everything we need to get started, should
    #  only be called once to set up.
    #-----------------------------------------------------
	init = ->
		b2Vec2 = Box2D.Common.Math.b2Vec2
	    b2BodyDef = Box2D.Dynamics.b2BodyDef
		b2Body = Box2D.Dynamics.b2Body
		b2FixtureDef = Box2D.Dynamics.b2FixtureDef
		b2Fixture = Box2D.Dynamics.b2Fixture
		b2World = Box2D.Dynamics.b2World
		b2MassData = Box2D.Collision.Shapes.b2MassData
		b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
		b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
		b2DebugDraw = Box2D.Dynamics.b2DebugDraw

		world = new b2World(
			new b2Vec2(0, 10), #gravity
			true #allow sleep
		)

		fixDef = new b2FixtureDef;
		fixDef.density = 1.0;
		fixDef.friction = 1.5;
		fixDef.restitution = 0.2;

		bodyDef = new b2BodyDef;

		# create ground
		bodyDef.type = b2Body.b2_staticBody;

		# positions the center of the object (not upper left!)
		bodyDef.position.x = canvas.width / 2 / SCALE;
		bodyDef.position.y = canvas.height / SCALE;

		fixDef.shape = new b2PolygonShape;

		# half width, half height. eg actual height here is 1 unit
		fixDef.shape.SetAsBox((600 / SCALE) / 2, (10 / SCALE) / 2);
		world.CreateBody(bodyDef).CreateFixture(fixDef);

		# create some objects
		bodyDef.type = b2Body.b2_dynamicBody;
		for (i = 0; i < 150; i++) {
			# Randomize the shape created.
			if (Math.random() > 0.5) {
				fixDef.shape = new b2PolygonShape;
				halfHeight = Math.random() + 0.1;
				halfWidth = Math.random() + 0.1;
				fixDef.shape.SetAsBox(halfHeight, halfWidth);
			}
			else {
				radius = Math.random() + 0.1;
				fixDef.shape = new b2CircleShape(radius);
			}
			bodyDef.position.x = Math.random() * 25;
			bodyDef.position.y = Math.random() * 10;
			world.CreateBody(bodyDef).CreateFixture(fixDef);
		}

	    # setup debug draw
		debugDraw = new b2DebugDraw();
		debugDraw.SetSprite(document.getElementById("c").getContext("2d"));
		debugDraw.SetDrawScale(SCALE);
		debugDraw.SetFillAlpha(0.3);
		debugDraw.SetLineThickness(1.0);
		debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
		world.SetDebugDraw(debugDraw);
	# init()

	FRAME_RATE = 1 / 60;
    VELOCITY_ITERATIONS = 10;
    POSITION_ITERATIONS = 10;

    # ----------------------------------------------------
	# Does all the work we need to do at each tick of the
	# game clock.
	# ----------------------------------------------------
	update = -> 
		world.Step(
			FRAME_RATE,
			VELOCITY_ITERATIONS,
			POSITION_ITERATIONS
		);
		world.DrawDebugData();
		world.ClearForces();

		# Update the stats for FPS info
		stats.update();

		# Kick off the next loop
		requestAnimFrame(update);
	# update()

	# Set everything up.
	init();
	# Begin the animation loop.
	requestAnimFrame(update);
	
