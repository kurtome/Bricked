###
 Creates the AI for the paddle
###
bricked.PaddleAi = class PaddleAi
	constructor: (@paddle, @learner) ->
		@trainingWorker = new Worker bricked.paths.TRAINER_WORKER
		@trainingWorker.onmessage = this.onTrainerWorkerMessage

		@predictWorld = ->
			return null

	onTrainerWorkerMessage: (event) ->
		@predictWorld = event.data

	applyXForce: (xForce) ->
		b2Vec2 = Box2D.Common.Math.b2Vec2
		centerPoint = @paddle.GetPosition()
		force = new b2Vec2(xForce, 0)
		@paddle.ApplyForce(force, centerPoint)

	moveLeft: ->
		this.applyXForce -5

	moveRight: ->
		this.applyXForce 5

	updateGoalX: ->
		# Let's cheat for now and try follow the ball's position
		@goalX = bricked.ball.GetPosition().x

	update: ->
		this.updateGoalX()

		currentX = @paddle.GetPosition().x
		if currentX < @goalX
			this.moveRight()
		else if currentX > @goalX
			this.moveLeft()
		else
			# In desired position, stop here.

