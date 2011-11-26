(function() {
  var bricked;

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

  window.requestAnimFrame = (function() {
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
      return window.setTimeout(callback, 1000 / 60);
    };
  })();

  bricked.scaleToPhys = function(x) {
    return x / bricked.SCALE;
  };

  bricked.scaleVecToPhys = function(vec) {
    vec.Multiply(1 / bricked.SCALE);
    return vec;
  };

  bricked.scaleToScreen = function(x) {
    return x * bricked.SCALE;
  };

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

  bricked.createBall = function() {
    var b2Body, b2BodyDef, b2CircleShape, b2FixtureDef, ball, bodyDef, fixDef, radius;
    b2BodyDef = Box2D.Dynamics.b2BodyDef;
    b2Body = Box2D.Dynamics.b2Body;
    b2FixtureDef = Box2D.Dynamics.b2FixtureDef;
    b2CircleShape = Box2D.Collision.Shapes.b2CircleShape;
    fixDef = new b2FixtureDef;
    fixDef.density = 1.0;
    fixDef.friction = 0;
    fixDef.restitution = 1;
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
    paddleVertices = [bricked.scaleVecToPhys(new b2Vec2(0, 0)), bricked.scaleVecToPhys(new b2Vec2(20, -10)), bricked.scaleVecToPhys(new b2Vec2(60, -10)), bricked.scaleVecToPhys(new b2Vec2(80, 0))];
    fixDef.shape.SetAsArray(paddleVertices, paddleVertices.Length);
    bodyDef = new b2BodyDef;
    bodyDef.type = b2Body.b2_dynamicBody;
    bodyDef.position.x = bricked.scaleToPhys(bricked.WIDTH / 2);
    bodyDef.position.y = bricked.scaleToPhys(bricked.HEIGHT - 20);
    paddle = bricked.world.CreateBody(bodyDef);
    paddle.CreateFixture(fixDef);
    prisJointDef = new Box2D.Dynamics.Joints.b2PrismaticJointDef;
    prisJointDef.Initialize(paddle, bricked.bottomWall, paddle.GetPosition(), new b2Vec2(1, 0));
    bricked.world.CreateJoint(prisJointDef);
    return paddle;
  };

  bricked.beginContact = function(contact) {
    var bodyA, bodyB;
    bodyA = contact.GetFixtureA().GetBody();
    bodyB = contact.GetFixtureB().GetBody();
    if (bodyA === bricked.ball && bodyB === bricked.bottomWall || bodyA === bricked.bottomWall && bodyB === bricked.ball) {
      return bricked.didBallDie = true;
    }
  };

  bricked.init = function() {
    var allowSleep, b2DebugDraw, debugDraw, listener;
    b2DebugDraw = Box2D.Dynamics.b2DebugDraw;
    allowSleep = true;
    bricked.world = new Box2D.Dynamics.b2World(bricked.GRAVITY, allowSleep);
    bricked.createWalls();
    bricked.ball = bricked.createBall();
    bricked.paddle = bricked.createPaddle();
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

  bricked.startBall = function() {
    var b2Vec2, initialForce, point, xForce, yForce;
    b2Vec2 = Box2D.Common.Math.b2Vec2;
    xForce = Math.random() * 200 + 50;
    yForce = Math.random() * 200 + 50;
    if (Math.random() > 0.5) xForce *= -1;
    if (Math.random() > 0.5) yForce *= -1;
    initialForce = new b2Vec2(xForce, yForce);
    point = bricked.ball.GetPosition();
    return bricked.ball.ApplyForce(initialForce, point);
  };

  bricked.update = function() {
    bricked.world.Step(bricked.FRAME_RATE, bricked.VELOCITY_ITERATIONS, bricked.POSITION_ITERATIONS);
    bricked.world.DrawDebugData();
    bricked.world.ClearForces();
    if (bricked.didBallDie) {
      bricked.didBallDie = false;
      bricked.world.DestroyBody(bricked.ball);
      bricked.ball = bricked.createBall();
      bricked.startBall();
    }
    bricked.stats.update();
    return requestAnimFrame(bricked.update);
  };

  bricked.init();

  requestAnimFrame(bricked.update);

  bricked.startBall();

}).call(this);
