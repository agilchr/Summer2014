% slicFeatures
% Authors: Andrew Gilchrist-Scott & Teo Gelles
%
% This file contains the code for runSLIC, which is the main
% wrapper used in MATLAB in order to run experiments with SLIC_3D
% and getSLICFeatures.

function slicFeatures = runSLIC(imageNum, imageType, res, numSuperVoxels, ...
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
    
    if ~exist('imageType','var')
        imageType = 'IBSR';
    end
    
    if ~exist('imageNum','var')
        imageNum = 1;
    end
    
    %For the entropy runs, we don't want the images saved
    saveFiles = false;
    
    % base directory
    saveDir = '/scratch/tgelles1/summer2014/slic/';
    
    % file addressing specific to each of the different type of
    % file we may choose to run
    slicAddr=strcat(saveDir,'slic','-',imageType,'-', ...
                    num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                    '-',num2str(res),'-',num2str(imageNum),'-', ...
                    num2str(numIters),'.nii');
    borderAddr=strcat(saveDir,'border','-',imageType,'-', ...
                      num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                      '-',num2str(res),'-',num2str(imageNum), ...
                      '-',num2str(numIters),'.nii');
    xAddr=strcat(saveDir,'x','-',imageType,'-', ...
                 num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                 '-',num2str(res),'-',num2str(imageNum), '-', ...
                 num2str(numIters),'.nii');
    centerinfoAddr=strcat(saveDir,'centerinfo','-',imageType,'-', ...
                          num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                          '-',num2str(res),'-',num2str(imageNum), ...
                          '-',num2str(numIters),'.mat');
    cropAddr=strcat(saveDir,'cropoffset','-',imageType,'-', ...
                    num2str(numSuperVoxels),'-',num2str(shapeParam), ...
                    '-',num2str(res),'-',num2str(imageNum), ...
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
        
        [X cropOffset] = load_nifti(imageType,imageNum,res);
        
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
    
    
    if (strcmp(imageType, 'IBSR'))
        tissues = NaN;

    else
        tissueFilename = strcat('/sonigroup/summer2014/ADNI_tissues/', ...
                                imageType, sprintf('%03d',imageNum), ...
                                '_tissueSeg.nii');
        
        fprintf('Loading tissues from: %s\n', tissueFilename);
        tissues = load_tissues(tissueFilename, cropOffset, res);
    end
    
    if strcmp(imageType, 'AD')
        id = imageNum;
    elseif strcmp(imageType, 'MCI')
        id = imageNum + 92;
    elseif strcmp(imageType, 'CN')
        id = imageNum + 92 + 203;
    else
        id = imageNum+1000;
    end
    
    featureFilename = strcat(saveDir, 'features/', imageType, ...
                             sprintf('%03d',imageNum),'.txt');
    
    fprintf('Saving feature file to: %s\n', featureFilename);
    
    slicFeatures = getSLICFeatures(X, labels, tissues, centerInfo, ...
                                      cropOffset,featureFilename, id);
end


function [X, indexList] = load_nifti(imageType,imageNum, res)


    fprintf('Loading Nifti Image...\n');
    
    imageName = '';
    if (strcmp(imageType, 'IBSR'))
        
        if (imageNum < 10)
            imageName = strcat('/sonigroup/fmri/IBSR_nifti_stripped/IBSR_0', ...
                               num2str(imageNum), '_ana_strip.nii');
        else
            imageName = strcat('/sonigroup/fmri/IBSR_nifti_stripped/IBSR_', ...
                               num2str(imageNum), '_ana_strip.nii');
        end
        
    elseif (strcmp(imageType, 'AD')) || (strcmp(imageType,'MCI')) || ...
            (strcmp(imageType,'CN'))
        imageName = strcat('/sonigroup/fmri/ADNI_Stripped/', ...
                           imageType, sprintf('%03d',imageNum),'.nii'); ...
            
            
        % The below code is only good for the original, non
        % skull-stripped images
        % imageName = strcat('/sonigroup/fmri/AD_T1/patient', ...
        %                        num2str(imageNum), '.nii');
        % elseif (strcmp(imageType, 'CN'))
        %     imageName = strcat('/sonigroup/fmri/CN_T1/patient', ...
        %                        num2str(imageNum), '.nii');
        % elseif (strcmp(imageType, 'MCI'))
        %     imageName = strcat('/sonigroup/fmri/MCI_T1/patient', ...
        %                        num2str(imageNum), '.nii');
    else
        imageName = imageType;
    end
    
    if (~exist(imageName, 'file'))
        exception = MException('file:dne', ['file %s does not exist ' ...
                            'or you do not have proper permissions'], ...
                               imageName);
        throw(exception);
    end
    

    fprintf('ImageName: %s\n', imageName);
    
    %Image
    I_t1uncompress = wfu_uncompress_nifti(imageName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
    
    X = X(1:res:end,1:res:end,1:res:end);
    [X indexList] = cropBlack(X);
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