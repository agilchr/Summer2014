function runSLIConDiff(usingGM)
% runSLIConDiff
% Code is implemented to complete the process of creating a SLIC
% clustering of a difference image then applying that clustering to
% all of the other brains within our dataset
%
% @param usingGM - controls whether or not we will be testing on GM images or WM
% images, since Ortiz et al did better on gray matter, this is our default
%   
% Written by Teo Gelles and Andrew Gilchrist-Scott
% Last edited on December 17, 2014
    
    if (~exist('usingGM', 'var'))
        usingGM = 1;
    end
    
    checkFiles(usingGM);
    
    ADLoadDir = ['/sonigroup/ADNI_SPM_Tissues/AD/'];
    CNLoadDir = ['/sonigroup/ADNI_SPM_Tissues/CN/'];
    diffDir = '/sonigroup/ADNI_SPM_Tissues/diff/';
    
    if (usingGM)
        diffName = [diffDir, 'AD_CN_GM_differenceImage.nii'];
    else
        diffName = [diffDir, 'AD_CN_WM_differenceImage.nii'];
    end

    fprintf('Loading AD Images from: %s\n', ADLoadDir);
    fprintf('Loading CN Images from: %s\n', CNLoadDir);
    if (usingGM)
        fprintf('Using GM Tissues\n');
    else
        fprintf('Using WM Tissues\n');
    end

    clusters = getSLICclusters(diffName, usingGM);
    
    [ADbrains, CNbrains] = loadADandCNBrains(ADLoadDir, ...
                                             CNLoadDir, usingGM);

    makeFDR(ADbrains, CNbrains, usingGM, diffDir);

    clusterBrains(ADbrains, CNbrains, clusters, usingGM, diffName);
end

function saveClusteringAsNifti(curBrain, classes, curVectorList, ...
                               fileName)
    % Takes a brain that has a curtain class clusering and a vector
    % list representation of the brain and transforms that into a
    % three dimensional matrix comaptible with nifit standards
    %
    % @param curbrain - the brain to be converted, makes for an
    % easy size template
    % @param classses - the list of the all of the class labels for
    % each of the vectors in the list
    % @param curVectorList - vector list representation of the
    % brain where each vector is the x,y,z position of the voxel
    % and the intensity there
    % @param filename - where we want the nifti file to be saved
    

    classBrain = curBrain;
    for i=1:length(curVectorList)
        curVec = curVectorList(1:3, i);
        x = curVec(1);
        y = curVec(2);
        z = curVec(3);
        classBrain(x, y, z) = classes(i);
    end

    % disp(classBrain);
    % disp(max(classBrain(:)));
    nii = make_nii(classBrain);
    save_nii(nii, fileName);

    clear classBrain;
end
    
function vectorList = makeVectorList(brain, isDiffImage)
% Makes a brain into a vector list, or a list of 4d vectors which
% have the x,y,z and intensity of each voxel in the brain
%
% @param brain - 3d matrix of the brain MRI voxels
% @param isDiffImage - boolean determining if we're dealing with
% the difference image or not
%
% @return vectorList - the brain broken down into a list of
% vectors, note that this is quadruple the size of the original brain

    if (~exist('isDiffImage', 'var'))
        isDiffImage = 0;
    end
    
    [l w h] = size(brain);
    
    vectorList = zeros(4,l*w*h);
    
    vector_i = 1;
    
    for x_i = 1:l
        for y_i = 1:w
            for z_i = 1:h
                
                % when transforming the difference image into a
                % vector list, somehow the vector [0,0,0,0] sneaks
                % in there, this is to prevent that from affecting
                % the loop
                if (brain(x_i, y_i, z_i) == 0 && isDiffImage)
                    continue;
                end
                
                % append the new vector to the list
                vectorList(:,vector_i) = [x_i;y_i;z_i;brain(x_i, ...
                                                            y_i,z_i)];

                % checks if there are any other bad vectors
                if (vectorList(1, vector_i) == 0 || ...
                    vectorList(2, vector_i) == 0 || ...
                    vectorList(3, vector_i) == 0)
                    disp('Bad Vector!');
                    disp(vectorList(:, vector_i));
                    disp([x_i, y_i, z_i]);
                end
                
                vector_i = vector_i + 1;
            end
        end
    end
end

function [X] = load_nifti(fullFileName)
% loads a given nifti file into a 3d matrix
%
% @param fullFileName - file name to be loaded
%
% @return X - the 3d matrix of the nifti image
    
    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image processing, done by SPM
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end

function [ADbrains CNbrains] = loadADandCNBrains(ADDirectory, ...
                                                 CNDirectory, ...
                                                 usingGM)
    % by taking the proper directory and brain tissue typesm this
    % function loads in a cell array containing all of the AD and
    % CN brains
    %
    % @param ADDirectory - directory for AD files
    % @param CNDirectory - directory for CN files
    % @param usingGM - tells whether to gather the gray matter
    % files or the white matter files
    %
    % @return ADbrains - cell array of the 3d matrices of all of
    % the AD brains
    % @return CNbrains - cell array of the 3d matrices of all of
    % the CN brains
    
    direc = dir(ADDirectory);
    
    ADbrains = {};
    CNbrains = {};

    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'rAD')
            continue
        end
        
        % ignore files of the wrong brain type
        if (filename(5) == '1' && ~usingGM)
            continue
        elseif (filename(5) == '2' && usingGM)
            continue
        end
        
        ADimage = load_nifti([ADDirectory,filename]);
        ADbrains{end+1} = ADimage;
    end

    
    direc = dir(CNDirectory);
    
    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'rCN')
            continue
        end
        if (filename(5) == '1' && ~usingGM)
            continue
        elseif (filename(5) == '2' && usingGM)
            continue
        end
        
        CNimage = load_nifti([CNDirectory,filename]);
        CNbrains{end+1} = CNimage;
    end
end

function vectorList = splitBrainToVector(allbrains)
% create a cell array for every single vector in every single brain
% 
% @param allbrains - cell array containing the 3d matrices for all
% of our brains
%
% @return vectorList - cell array of all of the vectors from all of
% the brains
    
    n = length(allbrains);
    [l w h] = size(allbrains{1});
    
    vectorList = cell(n*l*w*h,1);
    
    vector_i = 1;
    
    for brain_i = 1:length(allbrains)
        brain = allbrains{brain_i};
        for x_i = 1:l
            for y_i = 1:w
                for z_i = 1:h
                    vectorList{vector_i} = [x_i,y_i,z_i,brain(x_i,y_i,z_i)];
                    % if brain_i == 1
                    %     disp(vectorList{vector_i});
                    % end
                    vector_i = vector_i + 1;
                end
            end
        end
        clear brain;
        clear allbrains{brain_i};
    end
end

function checkFiles(usingGM)
% checks that all the necessary files exist
%
% @param usingGM - determines whether to check for gray matter
% files or white matter files
    

    ADLoadDir = ['/sonigroup/ADNI_SPM_Tissues/AD/'];
    CNLoadDir = ['/sonigroup/ADNI_SPM_Tissues/CN/'];
    diffDir = '/sonigroup/ADNI_SPM_Tissues/diff/';
    
    if (usingGM)
        diffName = [diffDir, 'AD_CN_GM_differenceImage.nii'];
    else
        diffName = [diffDir, 'AD_CN_WM_differenceImage.nii'];
    end

    if (~exist(ADLoadDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', ADLoadDir);
        exit;
    end
    if (~exist(CNLoadDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', CNLoadDir);
        exit;
    end
    if (~exist(diffDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', diffDir);
        exit;
    end
    if (~exist(diffName, 'file'))
        fprintf('ERROR: Difference Image File %s Does Not Exist\n', ...
                diffName);
        exit;
    end
end

function makeFDR(ADbrains, CNbrains, usingGM, diffDir)
% makes the FDR image for all the difference between AD and CN
% brains
%
% @param AD/CNbrains - cell array of all AD/CN brains
% @param usingGM - determines whether we're looking at GM or WM
% brains
% @param diffDir - directory in which we can find and store the
% class difference images
    

    if (usingGM)
        fdrName = [diffDir, 'FDRGM.nii'];
    else
        fdrName = [diffDir, 'FDRWM.nii'];
    end
    if (exist(fdrName, 'file'))
        fprintf('FDR File Exists at %s\n', fdrName);
    else
        
        FDR = getFDR(ADbrains, CNbrains);
    
        fprintf('Saving FDR to %s\n',fdrName);
        FDRnii = make_nii(FDR);
        save_nii(FDRnii, fdrName);
    end
end

function clusterBrains(ADbrains, CNbrains, clusters, usingGM, diffName)
% take the regions of interes generated by the SLIC algo and apply
% them to every brain, then save the results
    
    slicDir = '/sonigroup/ADNI_SPM_Tissues/SLIC/';
    
    fprintf(['Clustering the difference image for visualization ' ...
             'purposes\n'])

    diff = load_nifti(diffName);
    diffvecs = makeVectorList(diff,1);
    regions = clusters;
    
    save([diffName,'ROI.mat'],'regions')
    
    
    for i=1:length(ADbrains)

        if (usingGM)
            fprintf('Clustering AD GM brain %d\n', i);
        else
            fprintf('Clustering AD WM brain %d\n', i);
        end
        
        curBrain = ADbrains{i};

        curVectorList = makeVectorList(curBrain);

        regions = cell(max(clusters(:)),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(clusters == region_i));
        end
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [slicDir, 'ADGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [slicDir, 'ADWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear curBrain;

        clear ADbrains(i);
    end

    
    for i=1:length(CNbrains)

        if (usingGM)
            fprintf('Clustering CN GM brain %d\n', i);
        else
            fprintf('Clustering CN WM brain %d\n', i);
        end
        
        curBrain = CNbrains{i};

        curVectorList = makeVectorList(curBrain);

        regions = cell(max(clusters(:)),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(clusters == region_i));
        end
        
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [slicDir, 'CNGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [slicDir, 'CNWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear curBrain;

        clear CNbrains(i);
    end
end

function labels = getSLICclusters(diffName, usingGM)
    
    X = load_nifti(diffName);
    
    numSuperVoxels = 150;
    shapeParam = .1;
    numIters = 18;
    
    labels = SLIC_3D(X,numSuperVoxels, shapeParam, numIters);
end    