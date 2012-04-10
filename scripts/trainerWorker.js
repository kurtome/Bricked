var createNn, trainer;

importScripts('../lib/brain/brain-0.3.5.js');

/*
# Creates the neural network for learning.
*/

createNn = function() {
  var net, options;
  options = {
    hidden: [16, 16, 16, 16],
    growthRate: 1.0,
    learningRate: 0.3
  };
  net = new brain.NeuralNetwork(options);
  return net;
};

trainer = createNn();

this.onmessage = function(event) {
  var iterations, threshold, trainingData;
  trainingData = event.data;
  iterations = 2000;
  threshold = 0.01;
  trainer.train(trainingData, iterations, threshold);
  return postMessage(trainer.toJSON());
};
