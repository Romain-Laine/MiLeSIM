function [ net ] = NeuralNetworkModel( Learners_values, annotation )

% Reshape data
Class_list = unique(annotation);
Target = zeros(length(Class_list),length(annotation));
for i = 1:length(annotation)
    Target(strcmp(Class_list,annotation{i}),i) = 1;
end
Input = Learners_values';

performFcn = 'crossentropy';  % Cross-Entropy
trainFcn = 'trainscg';        % Scaled conjugate gradient backpropagation.

% Create a Pattern Recognition Network
hiddenLayerSize = 10;
net = patternnet(hiddenLayerSize, trainFcn, performFcn );

net.input.processFcns = {'removeconstantrows','mapminmax'};
net.output.processFcns = {'removeconstantrows','mapminmax'};
net.divideFcn = 'dividerand';  % Divide data randomly
net.divideMode = 'sample';  % Divide up every sample
net.divideParam.trainRatio = 75/100;
net.divideParam.valRatio = 5/100;
net.divideParam.testRatio = 20/100;


net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
    'plotconfusion', 'plotroc'};

% Train the Network
[net,tr] = train(net,Input,Target);

% Test the Network
Y = net(Input);
errors = gsubtract(Target,Y);
performance = perform(net,Target,Y)
tind = vec2ind(Target);
yind = vec2ind(Y);
percentErrors = sum(tind ~= yind)/numel(tind)

% Recalculate Training, Validation and Test Performance
trainTargets = Target .* tr.trainMask{1};
valTargets = Target .* tr.valMask{1};
testTargets = Target .* tr.testMask{1};
trainPerformance = perform(net,trainTargets,Y)
valPerformance = perform(net,valTargets,Y)
testPerformance = perform(net,testTargets,Y)

% View the Network
view(net)


end

