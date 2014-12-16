function runSVM(usingGM)
    
    if ~exist('usingGM', 'var')
        usingGM = 1;
    end

    diffDir = '/sonigroup/ADNI_SPM_Tissues/diff/';
    dataDir = '/sonigroup/ADNI_SPM_Tissues/SLIC/';

    if (usingGM)
        FDR = load_nifti([diffDir, 'FDRGM.nii']);
    else
        FDR = load_nifti([diffDir, 'FDRWM.nii']);
    end

    listing = dir(dataDir);
    
    ADbrains = {};
    CNbrains = {};
    
    fprintf('Loading in clusterings\n');
    for i = 1:length(listing)
        if listing(i).isdir
            continue
        end
        filename = listing(i).name;
        if ~strcmp(filename(end-6:end),'ROI.mat')
            continue
        end
        if (usingGM && ~strcmp(filename(3:4), 'GM'))
            continue
        elseif (~usingGM && strcmp(filename(3:4), 'GM'))
            continue
        end
        
        fprintf('Loading the clusters %s\n',filename)

        ROIs = load([dataDir, filename]);
        ROIs = ROIs.regions;
        if filename(1) == 'C'
            %CNbrains{end+1} = ROIs;
            if ~exist('CNimportance','var')
                CNimportance = calcImportance({ROIs},FDR);
            else
                CNimportance(end+1,:) = calcImportance({ROIs},FDR);
            end
        else
            %ADbrains{end+1} = ROIs;
            if ~exist('ADimportance','var')
                ADimportance = calcImportance({ROIs},FDR);
            else
                ADimportance(end+1,:) = calcImportance({ROIs},FDR);
            end
        end
        clear ROIs;
    end
    
    YAD = [];
    YCN = [];
    for i = 1:size(ADimportance,1)
        YAD(end+1) = -1;
    end
    for i = 1:size(CNimportance,1)
        YCN(end+1) = 1;
    end
        
    % fprintf('Calculating importance\n');
    % ADimportance = calcImportance(ADbrains,FDR);
    % CNimportance = calcImportance(CNbrains,FDR);
    
    clear FDR;
    clear ADbrains;
    clear CNbrains;

    fprintf('Getting testing and training sets\n');
    numFolds = 5;
    [ADtrainCell ADtestCell ADtrainLabelCell ADtestLabelCell] = ...
        getTrainingAndTesting(ADimportance,YAD, numFolds);
    [CNtrainCell CNtestCell CNtrainLabelCell CNtestLabelCell] = ...
        getTrainingAndTesting(CNimportance,YCN, numFolds);
    
    clear ADimportance;
    clear CNimportance;
    clear YAD;
    clear YCN;
    
    totalYtest = [];
    totalYpreds = [];
    for fold = 1:numFolds
        fprintf('Running SVM, fold: %d\n',fold);
        Xtrain = [ADtrainCell{fold};CNtrainCell{fold}];
        Ytrain = [ADtrainLabelCell{fold}';CNtrainLabelCell{fold}'];
        Xtest = [ADtestCell{fold};CNtestCell{fold}];
        Ytest = [ADtestLabelCell{fold}';CNtestLabelCell{fold}'];
        
        model = svmtrain(Ytrain, Xtrain, '-t 2 -c 1000');
        
        [predictions, acc, probs] = svmpredict(Ytest, Xtest, model);
        
        % disp(fold)
        % disp(class(fold))
        fprintf('Accuracy for fold %f: %f\n',fold,acc);
        
        totalYtest = [totalYtest; Ytest];
        totalYpreds = [totalYpreds; predictions];
        
    end
    
    makeConfusionMatrix(totalYpreds,totalYtest);
    
end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end

function importance = calcImportance(brains, FDR)
    
    importance = zeros(length(brains),length(brains{1}));
    for brain_i = 1:length(brains)
        brain = brains{brain_i};
        for region_i = 1:length(brain)
            region = brain{region_i};
            R_RF_i = 0;
            for col = 1:size(region,2)
                x = region(1,col);
                y = region(2,col);
                z = region(3,col);
                I = region(4,col);
                R_RF_i = R_RF_i + I*FDR(x,y,z);
            end
        end
        importance(brain_i,region_i) = R_RF_i;
    end
end


function [trainCell testCell trainLabelCell testLabelCell] = ...
        getTrainingAndTesting(SVvectors,labels, numFolds)
    
    
    numSV = length(labels);
    randOrder = randperm(numSV);
    
    randVecs = SVvectors(randOrder,:);
    randLabels = labels(randOrder);
    
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
