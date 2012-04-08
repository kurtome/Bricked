var PaddleAi, bricked;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

bricked = {};

bricked.stats = new Stats();

document.body.appendChild(bricked.stats.domElement);

bricked.canvas = document.getElementById("c");

bricked.ctx = bricked.canvas.getContext("2d");

bricked.SCALE = 30;

bricked.FRAME_RATE = 1 / 60;

bricked.VELOCITY_ITERATIONS = 10;

bricked.POSITION_ITERATIONS = 10;

bricked.GRAVITY = new Box2D.Common.Math.b2Vec2(0, 0);

bricked.WIDTH = bricked.canvas.width;

bricked.HEIGHT = bricked.canvas.height;

bricked.BALL_RADIUS = 10;

bricked.paths = {};

bricked.paths.TRAINER_WORKER = 'scripts/trainerWorker.js';

bricked.getCurrentTime = function() {
  var currentTime;
  currentTime = new Date();
  return currentTime.getTime();
};

/*
 Converts screen points (pixels) to points the 
 physics engine works with
*/

bricked.scaleToPhys = function(x) {
  return x / bricked.SCALE;
};

/*
 Converts screen points (pixels) vector to points 
 the physics engine works with
*/

bricked.scaleVecToPhys = function(vec) {
  vec.Multiply(1 / bricked.SCALE);
  return vec;
};

/*
 Converts physics points to points the screen points
 (pixels)
*/

bricked.scaleToScreen = function(x) {
  return x * bricked.SCALE;
};

/*
# Applies a horizontal force to a body
*/

bricked.applyXForce = function(body, xForce) {
  var b2Vec2, centerPoint, force;
  b2Vec2 = Box2D.Common.Math.b2Vec2;
  centerPoint = body.GetPosition();
  force = new b2Vec2(xForce, 0);
  return body.ApplyForce(force, centerPoint);
};

/*
# Applies a vertical force to a body
*/

bricked.applyYForce = function(body, yForce) {
  var b2Vec2, centerPoint, force;
  b2Vec2 = Box2D.Common.Math.b2Vec2;
  centerPoint = body.GetPosition();
  force = new b2Vec2(0, yForce);
  return body.ApplyForce(force, centerPoint);
};

bricked.TRAINING_DATA_SIZE = 1000;

bricked.PADDLE_X_FORCE = 10;

bricked.TRAINING_OFFSET = bricked.scaleToPhys(bricked.WIDTH);

bricked.TRAINING_SCALE = bricked.TRAINING_OFFSET * 2;

bricked.MAX_PREDICTIONS = 200;

bricked.MARGIN = 0.1;

bricked.X_POS = 0;

bricked.PADDLE_POS = 1;

bricked.RELATIVE_POS = 2;

bricked.VX_POS = 3;

/*
# Createbricked.TRAINING_OFFSET * 2
*/

PaddleAi = (function() {

  /*
  	# Constructor
  */

  function PaddleAi(paddle) {
    this.paddle = paddle;
    this.onTrainerWorkerMessage = __bind(this.onTrainerWorkerMessage, this);
    this.trainingWorker = new Worker(bricked.paths.TRAINER_WORKER);
    this.trainingWorker.onmessage = this.onTrainerWorkerMessage;
    this.trainedLearner = new brain.NeuralNetwork();
    this.trainingData = [];
    this.recentData = [];
    this.isWaitingForWorker = false;
    this.isTrained = false;
    this.wasRecentDataTrained = false;
  }

  /*
  	# Contact event handler for the physics world.
  */

  PaddleAi.prototype.beginContact = function(contact) {
    var bodyA, bodyB;
    bodyA = contact.GetFixtureA().GetBody();
    bodyB = contact.GetFixtureB().GetBody();
    if (bodyA === bricked.ball || bodyB === bricked.ball) {
      this.recentData = [];
      if (bodyA === this.paddle || bodyB === this.paddle) {} else {

      }
    }
  };

  /*
  	# Callback for the onmessage of the trainingWorker
  */

  PaddleAi.prototype.onTrainerWorkerMessage = function(event) {
    this.trainedLearner.fromJSON(event.data);
    this.isWaitingForWorker = false;
    this.isTrained = true;
    return console.log("Got prediction function");
  };

  /*
  	# Applies a horizontal force to the paddle
  */

  PaddleAi.prototype.applyXForce = function(xForce) {
    return bricked.applyXForce(this.paddle, xForce);
  };

  /*
  	# Moves the paddle to the left
  */

  PaddleAi.prototype.moveLeft = function() {
    return this.applyXForce(-1 * bricked.PADDLE_X_FORCE);
  };

  /*
  	# Moves the paddle to the right
  */

  PaddleAi.prototype.moveRight = function() {
    return this.applyXForce(bricked.PADDLE_X_FORCE);
  };

  /*
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
  */

  /*
  	# TODO
  */

  PaddleAi.prototype.scaleToTraining = function(value) {
    return (value + bricked.TRAINING_OFFSET) / bricked.TRAINING_SCALE;
  };

  /*
  	# TODO
  */

  PaddleAi.prototype.scaleFromTraining = function(value) {
    return (value * bricked.TRAINING_SCALE) - bricked.TRAINING_OFFSET;
  };

  /*
  	# TODO
  */

  PaddleAi.prototype.buildCurrentBallData = function() {
    var ballLinearVelocity, ballPosition, data, distanceLeft, distanceRight, paddlePosition, relativeHorizontalPos, relativeVerticalPos, velocityLeft, velocityRight;
    ballPosition = bricked.ball.GetPosition();
    ballLinearVelocity = bricked.ball.GetLinearVelocity();
    paddlePosition = this.paddle.GetPosition();
    relativeHorizontalPos = paddlePosition.x - ballPosition.x;
    relativeVerticalPos = ballPosition.y - paddlePosition.y;
    distanceLeft = 0;
    distanceRight = 0;
    if (relativeHorizontalPos < 0) {
      distanceLeft = Math.abs(relativeHorizontalPos);
    } else {
      distanceRight = relativeHorizontalPos;
    }
    velocityLeft = 0;
    velocityRight = 0;
    if (ballLinearVelocity.x < 0) {
      velocityLeft = Math.abs(ballLinearVelocity.x);
    } else {
      velocityRight = ballLinearVelocity.x;
    }
    data = [this.scaleToTraining(ballPosition.x), this.scaleToTraining(paddlePosition.x), this.scaleToTraining(distanceLeft), this.scaleToTraining(distanceRight), this.scaleToTraining(velocityLeft), this.scaleToTraining(velocityRight), this.scaleToTraining(relativeVerticalPos)];
    return data;
  };

  /*
  	# Execute training related work for each loop
  */

  PaddleAi.prototype.updateTraining = function() {
    if (this.trainingData.length > bricked.TRAINING_DATA_SIZE) {
      console.log('Training full');
      return;
    }
    if (Math.random() > .5) this.recentData.push(this.buildCurrentBallData());
    if (this.recentData.length > bricked.TRAINING_DATA_SIZE) {
      this.recentData.shift();
    }
    this.prevBallPos = bricked.ball.GetPosition();
    this.prevBallVelocity = bricked.ball.GetLinearVelocity();
    if (bricked.ball.GetPosition().y > (this.paddle.GetPosition().y + .1)) {
      return this.trainRecentData();
    }
  };

  /*
  	# Execute when the ball dies
  */

  PaddleAi.prototype.ballDied = function() {
    return this.wasRecentDataTrained = false;
  };

  /*
  	# TODO
  */

  PaddleAi.prototype.trainRecentData = function() {
    var addedCount, currentBallX, dataBallX, dataPoint, leftVal, rightVal, stayMargin, stayVal, trainingDataPoint;
    if (this.isWaitingForWorker || this.wasRecentDataTrained) return;
    this.wasRecentDataTrained = true;
    addedCount = 0;
    while (this.recentData.length > 0) {
      addedCount++;
      if (addedCount > 5) break;
      dataPoint = this.recentData.shift();
      leftVal = 0;
      rightVal = 0;
      stayVal = 0;
      currentBallX = bricked.ball.GetPosition().x;
      dataBallX = this.scaleFromTraining(dataPoint[bricked.PADDLE_POS]);
      stayMargin = .20;
      if (Math.abs(currentBallX - dataBallX) < stayMargin) {
        stayVal = 1;
      } else if (currentBallX < dataBallX) {
        leftVal = 1;
      } else {
        rightVal = 1;
      }
      trainingDataPoint = {
        input: dataPoint,
        output: {
          left: leftVal,
          right: rightVal,
          stay: stayVal
        }
      };
      this.trainingData.push(trainingDataPoint);
    }
    console.log("Sending data to training worker");
    this.isWaitingForWorker = true;
    return this.trainingWorker.postMessage(this.trainingData);
  };

  /*
  	# Execute everything to be done during each game loop
  */

  PaddleAi.prototype.update = function() {
    var inputData, output;
    this.updateTraining();
    if (this.isTrained) {
      inputData = this.buildCurrentBallData();
      output = this.trainedLearner.run(inputData);
      if (output.stay > output.right && output.stay > output.left) {} else if (output.left > output.right) {
        return this.moveLeft();
      } else {
        return this.moveRight();
      }
    }
  };

  return PaddleAi;

})();

/*
 Function that animates the
*/

window.requestAnimFrame = (function() {
  return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
    return window.setTimeout(callback, 1000 / 60);
  };
})();

/*
 Creates wall boundaries fo the game
*/

bricked.createWalls = function() {
  var b2Body, b2BodyDef, b2FixtureDef, b2PolygonShape, bodyDef, bottomHeight, bottomWidth, fixDef, leftHeight, leftWidth, rightHeight, rightWidth, topHeight, topWidth;
  b2BodyDef = Box2D.Dynamics.b2BodyDef;
  b2Body = Box2D.Dynamics.b2Body;
  b2FixtureDef = Box2D.Dynamics.b2FixtureDef;
  b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape;
  fixDef = new b2FixtureDef;
  fixDef.density = 1.0;
  fixDef.friction = 0;
  fixDef.restitution = 0.2;
  bodyDef = new b2BodyDef;
  bodyDef.type = b2Body.b2_staticBody;
  fixDef.shape = new b2PolygonShape;
  bodyDef.position.x = 0;
  bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2);
  leftWidth = bricked.scaleToPhys(10 / 2);
  leftHeight = bricked.scaleToPhys((bricked.HEIGHT + (10 * bricked.BALL_RADIUS)) / 2);
  fixDef.shape.SetAsBox(leftWidth, leftHeight);
  bricked.leftWall = bricked.world.CreateBody(bodyDef);
  bricked.leftWall.CreateFixture(fixDef);
  bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2);
  bodyDef.position.y = 0;
  topWidth = bricked.scaleToPhys(bricked.WIDTH / 2);
  topHeight = bricked.scaleToPhys(10 / 2);
  fixDef.shape.SetAsBox(topWidth, topHeight);
  bricked.world.CreateBody(bodyDef).CreateFixture(fixDef);
  bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH);
  bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2);
  rightWidth = leftWidth;
  rightHeight = leftHeight;
  fixDef.shape.SetAsBox(rightWidth, leftHeight);
  bricked.world.CreateBody(bodyDef).CreateFixture(fixDef);
  bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2);
  bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT + (5 * bricked.BALL_RADIUS));
  bottomWidth = topWidth;
  bottomHeight = topHeight;
  fixDef.shape.SetAsBox(bottomWidth, topHeight);
  bricked.bottomWall = bricked.world.CreateBody(bodyDef);
  return bricked.bottomWall.CreateFixture(fixDef);
};

/*
 Creates a ball
	Returns: the ball
*/

bricked.createBall = function() {
  var b2Body, b2BodyDef, b2CircleShape, b2FixtureDef, ball, bodyDef, fixDef, radius;
  b2BodyDef = Box2D.Dynamics.b2BodyDef;
  b2Body = Box2D.Dynamics.b2Body;
  b2FixtureDef = Box2D.Dynamics.b2FixtureDef;
  b2CircleShape = Box2D.Collision.Shapes.b2CircleShape;
  fixDef = new b2FixtureDef;
  fixDef.density = 1.0;
  fixDef.friction = 0;
  fixDef.restitution = 1.1;
  radius = bricked.scaleToPhys(bricked.BALL_RADIUS);
  fixDef.shape = new b2CircleShape(radius);
  bodyDef = new b2BodyDef;
  bodyDef.type = b2Body.b2_dynamicBody;
  bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2);
  bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT / 2);
  ball = bricked.world.CreateBody(bodyDef);
  ball.CreateFixture(fixDef);
  ball.SetBullet(true);
  return ball;
};

/*
 Creates a paddle in the bricked.world
	Returns: The paddle
*/

bricked.createPaddle = function() {
  var b2Body, b2BodyDef, b2FixtureDef, b2PolygonShape, b2Vec2, bodyDef, fixDef, paddle, paddleVertices, prisJointDef;
  b2Vec2 = Box2D.Common.Math.b2Vec2;
  b2BodyDef = Box2D.Dynamics.b2BodyDef;
  b2Body = Box2D.Dynamics.b2Body;
  b2FixtureDef = Box2D.Dynamics.b2FixtureDef;
  b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape;
  fixDef = new b2FixtureDef;
  fixDef.density = 1.0;
  fixDef.friction = 0;
  fixDef.restitution = 1;
  fixDef.shape = new b2PolygonShape;
  paddleVertices = [bricked.scaleVecToPhys(new b2Vec2(0, 0)), bricked.scaleVecToPhys(new b2Vec2(-40, 0)), bricked.scaleVecToPhys(new b2Vec2(-35, -4)), bricked.scaleVecToPhys(new b2Vec2(-20, -8)), bricked.scaleVecToPhys(new b2Vec2(-10, -10)), bricked.scaleVecToPhys(new b2Vec2(10, -10)), bricked.scaleVecToPhys(new b2Vec2(20, -8)), bricked.scaleVecToPhys(new b2Vec2(35, -4)), bricked.scaleVecToPhys(new b2Vec2(40, 0))];
  fixDef.shape.SetAsArray(paddleVertices, paddleVertices.Length);
  bodyDef = new b2BodyDef;
  bodyDef.type = b2Body.b2_dynamicBody;
  bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2);
  bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT - 20);
  bodyDef.linearDamping = 2.0;
  paddle = bricked.world.CreateBody(bodyDef);
  paddle.CreateFixture(fixDef);
  prisJointDef = new Box2D.Dynamics.Joints.b2PrismaticJointDef;
  prisJointDef.Initialize(paddle, bricked.bottomWall, paddle.GetPosition(), new b2Vec2(1, 0));
  bricked.world.CreateJoint(prisJointDef);
  return paddle;
};

/*
 Handles the BeginContact event from the physics 
 world.
*/

bricked.beginContact = function(contact) {
  var bodyA, bodyB;
  bricked.paddleAi.beginContact(contact);
  bodyA = contact.GetFixtureA().GetBody();
  bodyB = contact.GetFixtureB().GetBody();
  if (bodyA === bricked.ball || bodyB === bricked.ball) {
    if (bodyA === bricked.paddle || bodyB === bricked.paddle) {
      bricked.ballStartTime = bricked.getCurrentTime();
    }
    if (bodyA === bricked.bottomWall || bodyB === bricked.bottomWall) {
      return bricked.didBallDie = true;
    }
  }
};

/*
 Initalizes everything we need to get started, should
 only be called once to set up.
*/

bricked.init = function() {
  var allowSleep, b2DebugDraw, debugDraw, listener;
  b2DebugDraw = Box2D.Dynamics.b2DebugDraw;
  allowSleep = true;
  bricked.world = new Box2D.Dynamics.b2World(bricked.GRAVITY, allowSleep);
  bricked.createWalls();
  bricked.ball = bricked.createBall();
  bricked.paddle = bricked.createPaddle();
  bricked.paddleAi = new PaddleAi(bricked.paddle, bricked.ball);
  listener = new Box2D.Dynamics.b2ContactListener;
  listener.BeginContact = bricked.beginContact;
  bricked.world.SetContactListener(listener);
  debugDraw = new b2DebugDraw();
  debugDraw.SetSprite(bricked.ctx);
  debugDraw.SetDrawScale(bricked.SCALE);
  debugDraw.SetFillAlpha(0.4);
  debugDraw.SetLineThickness(1.0);
  debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
  return bricked.world.SetDebugDraw(debugDraw);
};

/*
 Gives the ball its initial push
*/

bricked.startBall = function() {
  var b2Vec2, centerPoint, initialForce, xForce, yForce;
  bricked.ballStartTime = bricked.getCurrentTime();
  b2Vec2 = Box2D.Common.Math.b2Vec2;
  xForce = Math.random() * 50 + 100;
  yForce = Math.random() * 50 + 100;
  if (Math.random() > 0.5) xForce *= -1;
  yForce *= -1;
  initialForce = new b2Vec2(xForce, yForce);
  centerPoint = bricked.ball.GetPosition();
  return bricked.ball.ApplyForce(initialForce, centerPoint);
};

/*
# Kill the ball
*/

bricked.killBall = function() {
  bricked.paddleAi.ballDied();
  bricked.didBallDie = false;
  bricked.world.DestroyBody(bricked.ball);
  bricked.ball = bricked.createBall();
  return bricked.startBall();
};

/*
 Does all the work we need to do at each tick of the
 game clock.
*/

bricked.update = function() {
  bricked.world.Step(bricked.FRAME_RATE, bricked.VELOCITY_ITERATIONS, bricked.POSITION_ITERATIONS);
  bricked.world.DrawDebugData();
  bricked.world.ClearForces();
  if (bricked.didBallDie) {
    bricked.killBall();
  } else if ((bricked.getCurrentTime() - bricked.ballStartTime) > (60 * 1000)) {
    bricked.killBall();
  }
  if (Math.abs(bricked.ball.GetLinearVelocity().x) < 0.2) {
    bricked.applyXForce(bricked.ball, 1);
  } else if (Math.abs(bricked.ball.GetLinearVelocity().y) < 0.2) {
    bricked.applyYForce(bricked.ball, 1);
  }
  bricked.paddleAi.update();
  bricked.stats.update();
  return requestAnimFrame(bricked.update);
};

bricked.init();

requestAnimFrame(bricked.update);

bricked.startBall();
