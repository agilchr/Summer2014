%% getWMLFeatures
% Authors: Teo Gelles & Andrew Gilchrist-Scott
%
% This file contains the code for obtaining a list of statistical
% features about a brain given various sources of information about
% the brain.  This program also writes the features to a file

function avgEntropy = getWMLFeatures(im,labels,groundTruth, ...
                                          centerInfo,cropOffset,filename,id)
    % getSLICFeatures - Get the list of features for the brain
    %
    % @param im - Matrix representation of an MRI of the brain
    % @param labels - Matrix representation of the SLIC labels of
    % the brain
    % @param tissues - Matrix representation of the 3 main tissue
    % types of the brain (Grey Matter, White Matter, and Cerebral
    % Spinal Fluid)
    % @param centerInfo - Collection of data about the centers used
    % in the SLIC supervoxelation of the image.  Main items of
    % interest are the total intensity of a superVoxel of given
    % center and the total number of voxels in each superVoxel
    % @param cropOffset - The dimensions by which the original
    % image was cut in order to remove the black margins around the
    % brain in cropBlack()
    % @param filename - The filename to write the features to
    % @param id - An identification number for the brain whose
    % features are being obtained
    %
    % @returns featureList - Matrix of the names of all obtained
    % feature in one column and values of the features in second
    % column.
    
    shouldPrint = true;
    fprintf('Getting SLIC Features for Patient %d\n', id);

    [avgEntropy varEntropy entropy] = getEntropyStats(im, labels, ...
                                                          centerInfo);
    
    if (~shouldPrint)
        return
    end

    
    avgIntensity = mean(centerInfo(:, 4));
    
    [varIntensity varIntensitysv] = getVarIntensity(centerInfo,im,labels);
        
    %get the neighbors
    numNeb = 4;
    neighbors = getNeighbors(centerInfo,numNeb);

    % get whether each SV has part of a WML in it to append to end
    % of vector
    groundTruth = cropTruth(groundTruth, cropOffset);
    truth = getTruthFeature(groundTruth, labels, length(centerInfo));
        
    csvfilename = strcat(filename(1:end-4),'.csv');
    outCSV = fopen(csvfilename, 'w');
    
    
    %fprintf('Printing graph of average intensities');
    %graphIntensities(centerInfo);
    
    for i = 1:size(centerInfo,1)
        % x,y,z,avgintensity,varintensity,entropy,avgnebintensity,avgnebentropy
        fprintf(outCSV,'%f,%f,%f,%f,%f,%f', ...
                centerInfo(i,1),centerInfo(i,2),centerInfo(i,3), ...
                centerInfo(i,4), varIntensitysv(i),entropy(i));
        % calculate the average intensity and entropy of the neighbors
        avgI = 0;
        avgE = 0;
        for neb = 1:numNeb
            neb_i = neighbors(i,neb);
            avgI = avgI + centerInfo(neb_i,4);
            avgE = avgE + entropy(neb_i);
        end
        avgI = avgI / numNeb;
        avgE = avgE / numNeb;
        fprintf(outCSV,',%f,%f',avgI,avgE);
        % finally, append the ground truth result to the vector
        fprintf(outCSV,',%d',truth(i));
        fprintf(outCSV,'\n');
    end

    fprintf('This patient had %d SV with WML\n',nnz(truth));
    
    fclose(outCSV);
end

function graphIntensities(centerInfo)
    figure
    plot(centerInfo(:,4),'x');
    title('Average supervoxel intensities');
    ylabel('Intensity');
    xlabel('Supervoxel intensity');
end


function [varIntensity varIntensitysv] = getVarIntensity(centerInfo,im,labels)

    varIntensitysv = zeros(size(centerInfo,1));
    
    for i = 1:size(centerInfo,1)
        varIntensitysv(i) = var(im(labels==i));
    end
    
    varIntensity = var(centerInfo(:, 4));
end

function [avgEntropy varEntropy entropy] = getEntropyStats(im, labels, centerInfo)
    
    entropy = zeros(size(centerInfo,1),1);
    
    for i = 1:size(centerInfo,1)
        numCenters = centerInfo(i,5);
        entropySpread = (hist(double(im(labels==i)),255)./ numCenters) ...
            .*log(hist(double(im(labels==i)),255)./numCenters);
        entropy(i) = -1 * sum(entropySpread(~isnan(entropySpread))); 
    end
    
    avgEntropy = mean(entropy);
    varEntropy = var(entropy);
end


function neighbors = getNeighbors(centerInfo,numNeb)
   
    neighbors = zeros(size(centerInfo,1),numNeb);
    centers = centerInfo(:, 1:3)';
    numSV = size(centerInfo,1);
    
    for i = 1:numSV
        dist = distEuclidean(repmat(centers(:, i), 1, numSV),centers);
        
        [s, O] = sort(dist, 'ascend');
        
        neighbors(i,:) = O(2:numNeb+1);
    end
end

function truth = cropTruth(truth,crop)

    xStart = crop(1,1);
    xEnd = crop(1,2);
    yStart = crop(2,1);
    yEnd = crop(2,2);
    zStart = crop(3,1);
    zEnd = crop(3,2);

    truth = truth(xStart:xEnd, yStart:yEnd, zStart:zEnd);
end

function featTruth = getTruthFeature(truth,labels, numSV)

    featTruth = zeros(1,numSV);

    for i = 1:numSV
        SV = (labels == i);
        if any(truth(SV))
            featTruth(i) = true;
        end
    end
end