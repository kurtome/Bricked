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
		@isWaitingForWorker = false
		@isTrained = false
		@wasRecentDataTrained = false

	###
	# Contact event handler for the physics world.
	###
	beginContact: (contact) ->
		bodyA = contact.GetFixtureA().GetBody()
		bodyB = contact.GetFixtureB().GetBody()

		if (bodyA == bricked.ball or bodyB == bricked.ball)
			# Clear out the recent data when the ball hits something
			# so we don't train for superflous stuff
			@recentData = []

			if (bodyA == @paddle or bodyB == @paddle)
				#this.trainRecentData()
			else
				
				#if (Math.random() > .5)
				#@recentData = []

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

		# Create training data by using all the recent data
		# and assigning an correct output action for it
		#@trainingData = []
		
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
