% this file is intended to calculate the difference image between
% AD and CN by finding the mean of each and taking the difference
% Note: we assume that the directory was of our own creation, thus
% we can assume things about the file naming convention
% we also assume that all of the files have been successfully
% coregistered, so the size of the images should be identical

function makeDifferenceImage()
    
    directory_name = ['/scratch/tgelles1/summer2014/ADNI_cropped/' ...
                      'coregistered/'];
    
    direc = dir(directory_name);
    
    numAD = 0;
    numCN = 0;
    
    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'co_')
            continue
        end
        if filename(4) == 'M'
            % continues if we're dealing with an MCI file
            continue
        elseif filename(4) == 'A'
            ADimage = load_nifti([directory_name,filename]);
            if exist('meanADimage','var')
                meanADimage = meanADimage + ADimage;
            else
                meanADimage = ADimage;
            end
            numAD = numAD + 1;
            if (any(isnan(ADimage(:))))
                disp(filename)
            end
            if any(isnan(meanADimage(:)))
                disp(filename)
            end
        elseif filename(4) == 'C'
            CNimage = load_nifti([directory_name,filename]);
            if exist('meanCNimage','var')
                meanCNimage = meanCNimage + CNimage;
            else
                meanCNimage = CNimage;
            end
            numCN = numCN + 1;
            if any(isnan(CNimage(:)))
                disp(filename)
            end
            if any(isnan(meanCNimage(:)))
                disp(filename)
            end

        end
    end
    %disp(meanADimage);
    disp(any(isnan(ADimage)));
    if (any(isnan(meanADimage(:))))
        disp('Bad bad meanADimage. It is a pooopy head')
    end
    meanADimage = meanADimage / numAD;
    meanCNimage = meanCNimage / numCN;
    
    diffImage = meanCNimage - meanADimage;
    
    diffNii = make_nii(diffImage);
    save_nii(diffNii, [directory_name,'AD_CN_differenceImage.nii'])
    
end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end
