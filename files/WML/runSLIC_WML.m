% slicFeatures
% Authors: Andrew Gilchrist-Scott & Teo Gelles
%
% This file contains the code for runSLIC, which is the main
% wrapper used in MATLAB in order to run experiments with SLIC_3D
% and getSLICFeatures and the WML dataset
%
% Changed from ADNI to WML on 10-27

function slicFeatures = runSLIC_WML(imageNum, res, numSuperVoxels, ...
                                shapeParam, numIters)
    % slicFeatures - Returns the list of features obtained from
    % getSLICFeatures()
    %
    % @param imageNum - The numerical index of the image to use in
    % its given folder
    % @param imageType - The basic directory under which the image
    % can be found.  Currently recognizes 'CN', 'MCI', 'AD', or 'IBSR',
    % which refer to /sonigroup/fmri/CN_T1, /sonigroup/fmri/MCI_T1,
    % /sonigroup/fmri/AD_T1, and /sonigroup/fmri/IBSR_nifti_stripped
    % respectively.   Inputs which do not match one of these are
    % assumed to refer to the entire directory for the given image.
    % @param res - The inverse resolution of the image (1 for full,
    % 2 for half, etc.)
    % @param numSuperVoxels - The number of superVoxels to use in
    % SLIC
    % @param shapeParam - The weight to use for the distance metric
    % in SLIC
    % @param numIters - The number of iterations to run SLIC for
    
    % Handles if the user chooses to not input any of the arguments
    if ~exist('numIters','var')
        numIters = 18;
    end
    
    if ~exist('shapeParam','var')
        shapeParam = .1;
    end
    
    if ~exist('numSuperVoxels','var')
        numSuperVoxels = 500;
    end
    
    if ~exist('res','var')
        res = 1;
    end
        
    if ~exist('imageNum','var')
        imageNum = 1;
    end
    
    %For the entropy runs, we don't want the images saved
    saveFiles = true;
    
    % base directory
    saveDir = ['/sonigroup/brain/data/WhiteMatterLesion/T1_SLIC_', ...
               num2str(numSuperVoxels),'/'];
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    
    loadDir = '/sonigroup/brain/data/WhiteMatterLesion/T1_stripped/';
    truthDir = '/sonigroup/brain/data/WhiteMatterLesion/ground_truth/';
    
    imageName = imageNumToName(imageNum, loadDir)

    fullImageName = [loadDir, imageName]
    truthImageName = [truthDir, imageName]
    
    % file addressing specific to each of the different type of
    % file we may choose to run
    slicAddr=strcat(saveDir,'slic','-', ...
                    num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                    '-',num2str(res),'-',imageName,'-', ...
                    num2str(numIters),'.nii');
    borderAddr=strcat(saveDir,'border','-', ...
                      num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                      '-',num2str(res),'-',imageName, ...
                      '-',num2str(numIters),'.nii');
    xAddr=strcat(saveDir,'x','-', ...
                 num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                 '-',num2str(res),'-',imageName, '-', ...
                 num2str(numIters),'.nii');
    centerinfoAddr=strcat(saveDir,'centerinfo','-', ...
                          num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                          '-',num2str(res),'-',imageName, ...
                          '-',num2str(numIters),'.mat');
    cropAddr=strcat(saveDir,'cropoffset','-', ...
                    num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                    '-',num2str(res),'-',imageName, ...
                    '-',num2str(numIters),'.mat');
    
    fprintf('Saving slic file to: %s\n', slicAddr);
    fprintf('Saving border file to: %s\n', borderAddr);
    fprintf('Saving x file to: %s\n', xAddr);
    fprintf('Saving centerinfo file to: %s\n', centerinfoAddr);
    fprintf('Saving cropped file to: %s\n', cropAddr);
    if (~saveFiles)
        fprintf(['Note: saveFiles is false. Files will not be saved\' ...
                 'n']);
    end
    
    % checks if we've already run our primary SLIC code and thus
    % the file already exists
    if (exist(slicAddr, 'file') && exist(borderAddr, 'file') && ...
        exist(xAddr, 'file') && exist(centerinfoAddr, 'file') && ...
        exist(cropAddr, 'file'))
        
        fprintf('Relevant Files Already Exist, Loading...\n');
        
        labels = load_nifti(slicAddr, imageNum, 1);
        X = load_nifti(xAddr, imageNum, 1);
        
        centerInfo = load(centerinfoAddr);
        cropOffset = load(cropAddr);
        
        centerInfo = centerInfo.centerInfo;
        cropOffset = cropOffset.cropOffset;
    else
        
        [X cropOffset] = load_nifti(fullImageName,res, true);
        
        [labels border centerInfo] = SLIC_3D(X,numSuperVoxels, ...
                                             shapeParam, numIters);
        
        slicNii = make_nii(labels);
        borderNii = make_nii(border);
        xNii = make_nii(X);
        
        if saveFiles
            save_nii(slicNii, slicAddr);
            save_nii(borderNii, borderAddr);
            save_nii(xNii, xAddr);
            save(centerinfoAddr, 'centerInfo');
            save(cropAddr, 'cropOffset');
        end
    end

    truth = load_nifti(truthImageName, 1, false);

    featureDir = [saveDir, 'features/'];
    
    if ~exist(featureDir,'dir')
        mkdir(featureDir);
    end
    
    featureFilename = [featureDir,imageName,'.txt'];
    
    fprintf('Saving feature file to: %s\n', featureFilename);
    
    wmlFeatures = getWMLFeatures(X, labels, truth, centerInfo, ...
                                      cropOffset,featureFilename, imageNum);
end


function [X, indexList] = load_nifti(imageName, res, crop)


    fprintf('Loading WML Image...\n');
    
    fprintf('ImageName: %s\n', imageName);
    
    %Image
    I_t1uncompress = wfu_uncompress_nifti(imageName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
    if crop
        X = X(1:res:end,1:res:end,1:res:end);
        [X indexList] = cropBlack(X);
    end
end

function tissues = load_tissues(tissueFilename, cropOffset, res)
    
    tissues = load_nii(tissueFilename);
    tissues = tissues.img(1:res:end,1:res:end,1:res:end);
    tissues = tissues(cropOffset(1, 1):cropOffset(1, 2), cropOffset(2, ...
                                                      1):cropOffset(2, ...
                                                      2), cropOffset(3, ...
                                                      1):cropOffset(3, ...
                                                      2));
end

function imageName = imageNumToName(imageNum, loadDir)
    imageName = '';
    
    listing = dir(loadDir);
    
    fileNames = {};
    
    for i = 1:length(listing)
        %use the image num to reference a certain file in the directory
        if ~(listing(i).isdir) && ~any(listing(i).name  == '_') && ...
                ~strcmp(listing(i).name(end-2:end),'.py')
            % only accept files without _ in them
            fileNames{end+1} = listing(i).name;
        end
    end
    
    imageName = fileNames{imageNum}
        
    
    if (~exist([loadDir,imageName], 'file'))
        exception = MException('file:dne', ['file %s does not exist ' ...
                            'or you do not have proper permissions'], ...
                               imageName);
        throw(exception);
    end

end
    


    