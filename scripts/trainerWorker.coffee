###
 Creates the neural network for learning.
###
createNn = ->
	options = {
		hidden: [16],
		growthRate: 1.0,
		learningRate: 0.8
	}
	net = new brain.NeuralNetwork(options)
	return net

trainer = createNn()


@onmessage = (event) ->
	trainingData = event.data.trainingData
	iterations = 2000
	threshold = 0.01
	trainer.train(trainingData, iterations, threshold)

	postMessage trainer.toFunction()
