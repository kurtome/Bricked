
/*
 Creates the neural network for learning.
*/

var createNn, trainer;

createNn = function() {
  var net, options;
  options = {
    hidden: [16],
    growthRate: 1.0,
    learningRate: 0.8
  };
  net = new brain.NeuralNetwork(options);
  return net;
};

trainer = createNn();

this.onmessage = function(event) {
  var iterations, threshold, trainingData;
  trainingData = event.data.trainingData;
  iterations = 2000;
  threshold = 0.01;
  trainer.train(trainingData, iterations, threshold);
  return postMessage(trainer.toFunction());
};
