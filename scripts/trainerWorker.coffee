importScripts '../lib/brain/brain-0.3.5.js'

###
# Creates the neural network for learning.
###
createNn = ->
	options = {
		hidden: [16,16],
		growthRate: 1.0,
		learningRate: 0.3
	}
	net = new brain.NeuralNetwork(options)
	return net

trainer = createNn()



@onmessage = (event) ->
	trainingData = event.data
	iterations = 2000
	threshold = 0.01
	#console.log "Beginning training..."
	trainer.train(trainingData, iterations, threshold)
	#console.log "Training complete."

	postMessage trainer.toJSON()
