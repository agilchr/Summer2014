% The following code is using an SVM to attempt to classify our
% brains with White Matter Lesions
%
% Written by Andrew Gilchrist-Scott
%
% Note: this uses the binary decision tree which is only
% implemented in MATLAB 2014 or later

function accuracy = decisionTreeWML(fileName, numFolds)
    
    if ~exist('numFolds','var')
        numFolds = 5;
    end

    if ~exist('fileName','var')
        fileName = ['/sonigroup/brain/data/WhiteMatterLesion/' ...
                    'T1_SLIC_500/features/allSV.csv'];
    end
    
    fullSVvectors = csvread(fileName);
    
    % strip the label from feature vector
    SVvectors = fullSVvectors(:,1:end-1);
    labels = fullSVvectors(:,end);
    
    SVvectors = normalizeVectors(SVvectors);
    
    % disp(brainVectors(:,1:15))
    % pause;
    
    [trainCell testCell trainLabelCell testLabelCell] = ...
        getTrainingAndTesting(SVvectors,labels, numFolds);

    totalAcc = zeros(numFolds,1);
    for fold = 1:numFolds
        train = trainCell{fold};
        test = testCell{fold};
        trainID = trainLabelCell{fold};
        testID = testLabelCell{fold};
        
        tree = fitctree(train,trainID);
        
        predictions = predict(tree,test);
        
        makeConfusionMatrix(predictions,testID)
        
        %        disp([predictions, testID]);        
        
        acc = sum(testID == predictions)/length(testID);
        
        totalAcc(fold) = acc;
    end
    
    fprintf('\n');

    accuracy = mean(totalAcc);
    maxaccuracy = max(totalAcc);
    minaccuracy = min(totalAcc);
    sdaccuracy = std(totalAcc);
    
    fprintf('Accuracy = %f\n',accuracy);
    fprintf('Max Accuracy = %f\n', maxaccuracy);
    fprintf('Min Accuracy = %f\n', minaccuracy);
    fprintf('SD Accuracy = %f\n', sdaccuracy);
end

function [trainCell testCell trainLabelCell testLabelCell] = ...
        getTrainingAndTesting(SVvectors,labels, numFolds)
    
    
    numSV = length(labels);
    randOrder = randperm(numSV);
    
    randVecs = SVvectors(randOrder,:);
    randLabels = labels(randOrder,:);
    
    trainCell = cell(numFolds,1);
    testCell = cell(numFolds,1);
    trainLabelCell = cell(numFolds,1);
    testLabelCell = cell(numFolds,1);
    
    for fold = 1:numFolds
        %upper and lower fold ratios
        lfr = (fold-1)/numFolds;
        ufr = fold/numFolds;
        
        testInd = zeros(numSV,1);
        testInd(floor(lfr*numSV)+1:floor(ufr*numSV)) = true;
        testInd(testInd == 0) = false;
        
        %make training index as not testing
        trainInd = ~testInd;
        
        % change bools to indices
        testInd = find(testInd);
        trainInd = find(trainInd);
        
        % get testing
        testCell{fold} = randVecs(testInd,:);
        testLabelCell{fold} = randLabels(testInd);
        
        % get training
        trainCell{fold} = randVecs(trainInd,:);
        trainLabelCell{fold} = randLabels(trainInd);
    end
end 

function makeConfusionMatrix(predictions,testID)
    k = length(unique(testID));
    options = unique(testID);
    conf = zeros(k);
    for i = 1:k
        for j = 1:k
            conf(i,j) = sum((predictions == options(i)) ...
                            .* (testID  == options(j)));
        end
    end
    fprintf('Confusion matrix:\n')
    fprintf('Labels: ')
    disp(options')
    disp(conf)
end

    
function SVvectors = normalizeVectors(SVvectors)
   
    % These lines make sure that the data is normalized such that
    % each column is on a range of 0 to 1
    SVvectors = (SVvectors - repmat(min(SVvectors,[],1), ...
                           size(SVvectors,1),1))*spdiags(1./ ...
                                                      (max(SVvectors,[],1)-min(SVvectors,[],1))',0,size(SVvectors,2),size(SVvectors,2));
    SVvectors = SVvectors(:,all(~isnan(SVvectors))); 
end