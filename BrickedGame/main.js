(function() {
  var FRAME_RATE, POSITION_ITERATIONS, SCALE, VELOCITY_ITERATIONS, canvas, ctx, init, stats, update, world;

  window.requestAnimFrame = (function() {
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
      return window.setTimeout(callback, 1000 / 60);
    };
  })();

  stats = new Stats();

  document.body.appendChild(stats.domElement);

  canvas = document.getElementById("c");

  ctx = canvas.getContext("2d");

  world = null;

  SCALE = 30;

  init = function() {
    var b2Body, b2BodyDef, b2CircleShape, b2DebugDraw, b2Fixture, b2FixtureDef, b2MassData, b2PolygonShape, b2Vec2, b2World, bodyDef, debugDraw, fixDef, i, _fn;
    b2Vec2 = Box2D.Common.Math.b2Vec2;
    b2BodyDef = Box2D.Dynamics.b2BodyDef;
    b2Body = Box2D.Dynamics.b2Body;
    b2FixtureDef = Box2D.Dynamics.b2FixtureDef;
    b2Fixture = Box2D.Dynamics.b2Fixture;
    b2World = Box2D.Dynamics.b2World;
    b2MassData = Box2D.Collision.Shapes.b2MassData;
    b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape;
    b2CircleShape = Box2D.Collision.Shapes.b2CircleShape;
    b2DebugDraw = Box2D.Dynamics.b2DebugDraw;
    world = new b2World(new b2Vec2(0, 10), true);
    fixDef = new b2FixtureDef;
    fixDef.density = 1.0;
    fixDef.friction = 1.5;
    fixDef.restitution = 0.2;
    bodyDef = new b2BodyDef;
    bodyDef.type = b2Body.b2_staticBody;
    bodyDef.position.x = canvas.width / 2 / SCALE;
    bodyDef.position.y = canvas.height / SCALE;
    fixDef.shape = new b2PolygonShape;
    fixDef.shape.SetAsBox((600 / SCALE) / 2, (10 / SCALE) / 2);
    world.CreateBody(bodyDef).CreateFixture(fixDef);
    bodyDef.type = b2Body.b2_dynamicBody;
    _fn = function() {
      var halfHeight, halfWidth, radius;
      if (Math.random() > 0.5) {
        fixDef.shape = new b2PolygonShape;
        halfHeight = Math.random() + 0.1;
        halfWidth = Math.random() + 0.1;
        return fixDef.shape.SetAsBox(halfHeight, halfWidth);
      } else {
        radius = Math.random() + 0.1;
        return fixDef.shape = new b2CircleShape(radius);
      }
    };
    for (i = 1; i <= 150; i++) {
      _fn();
      bodyDef.position.x = Math.random() * 25;
      bodyDef.position.y = Math.random() * 10;
      world.CreateBody(bodyDef).CreateFixture(fixDef);
    }
    debugDraw = new b2DebugDraw();
    debugDraw.SetSprite(document.getElementById("c").getContext("2d"));
    debugDraw.SetDrawScale(SCALE);
    debugDraw.SetFillAlpha(0.3);
    debugDraw.SetLineThickness(1.0);
    debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
    return world.SetDebugDraw(debugDraw);
  };

  FRAME_RATE = 1 / 60;

  VELOCITY_ITERATIONS = 10;

  POSITION_ITERATIONS = 10;

  update = function() {
    world.Step(FRAME_RATE, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
    world.DrawDebugData();
    world.ClearForces();
    stats.update();
    return requestAnimFrame(update);
  };

  init();

  requestAnimFrame(update);

}).call(this);
