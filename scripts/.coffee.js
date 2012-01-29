var PaddleAi;

bricked.PaddleAi = PaddleAi = (function() {

  function PaddleAi(paddle, learner) {
    this.paddle = paddle;
    this.learner = learner;
    this.trainingWorker = new Worker(bricked.paths.TRAINER_WORKER);
    this.trainingWorker.onmessage = this.onTrainerWorkerMessage;
    this.predictWorld = function() {
      return null;
    };
  }

  PaddleAi.prototype.onTrainerWorkerMessage = function(event) {
    return this.predictWorld = event.data;
  };

  PaddleAi.prototype.applyXForce = function(xForce) {
    var b2Vec2, centerPoint, force;
    b2Vec2 = Box2D.Common.Math.b2Vec2;
    centerPoint = this.paddle.GetPosition();
    force = new b2Vec2(xForce, 0);
    return this.paddle.ApplyForce(force, centerPoint);
  };

  PaddleAi.prototype.moveLeft = function() {
    return this.applyXForce(-5);
  };

  PaddleAi.prototype.moveRight = function() {
    return this.applyXForce(5);
  };

  PaddleAi.prototype.updateGoalX = function() {
    return this.goalX = bricked.ball.GetPosition().x;
  };

  PaddleAi.prototype.update = function() {
    var currentX;
    this.updateGoalX();
    currentX = this.paddle.GetPosition().x;
    if (currentX < this.goalX) {
      return this.moveRight();
    } else if (currentX > this.goalX) {
      return this.moveLeft();
    } else {

    }
  };

  return PaddleAi;

})();
