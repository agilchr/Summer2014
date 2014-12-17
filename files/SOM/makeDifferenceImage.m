%{
Authors: Teo Gelles & Andrew Gilchrist-Scott
Last Updated: 12/17/2014

This file is intended to calculate the difference image between
AD and CN by finding the mean of each and taking the difference
Note: we assume that the directory was of our own creation, thus
we can assume things about the file naming convention
we also assume that all of the files have been successfully
coregistered, so the size of the images should be identical.

Note: We use images from our testing dataset to make the difference
image.  We recognize that this may be experimentally unjustified,
but our goal was to recreate the pipeline described in
http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0093851#s1
which also did this.                                   
%}

function makeDifferenceImage()

    fprintf('Making AD and CN Difference Images\n');
    
    ad_dir_name = ['/sonigroup/ADNI_SPM_Tissues/AD/'];
    cn_dir_name = ['/sonigroup/ADNI_SPM_Tissues/CN/'];
    diff_dir_name = ['/sonigroup/ADNI_SPM_Tissues/diff/'];

    fprintf('Loading AD Images from: %s\n', ad_dir_name);
    fprintf('Loading CN IMages from: %s\n', cn_dir_name);
    fprintf('Saving Difference Images to: %s\n', diff_dir_name);
    
    numADGM = 0;
    numCNGM = 0;
    numADWM = 0;
    numCNWM = 0;

    ad_names = dir(ad_dir_name);
    cn_names = dir(cn_dir_name);

    fprintf('Constructing Mean AD Images\n');
    for i = 1:length(ad_names)

        filename = ad_names(i).name;
        if ad_names(i).isdir || ~strcmp(filename(1:3),'rAD')
            continue
        end
        
        if filename(5) == '1'
            ADimage = load_nifti([ad_dir_name,filename]);
            if exist('meanADGMimage','var')
                meanADGMimage = meanADGMimage + ADimage;
            else
                meanADGMimage = ADimage;
            end
            numADGM = numADGM + 1;
            if (any(isnan(ADimage(:))))
                disp(filename)
            end
            if any(isnan(meanADGMimage(:)))
                disp(filename)
            end
        elseif filename(5) == '2'
            ADimage = load_nifti([ad_dir_name,filename]);
            if exist('meanADWMimage','var')
                meanADWMimage = meanADWMimage + ADimage;
            else
                meanADWMimage = ADimage;
            end
            numADWM = numADWM + 1;
            if (any(isnan(ADimage(:))))
                disp(filename)
            end
            if any(isnan(meanADWMimage(:)))
                disp(filename)
            end
        end
    end

    fprintf('\n');
    fprintf('Constructing Mean CN Images\n');
    for i = 1:length(cn_names)

        filename = cn_names(i).name;
        if cn_names(i).isdir || ~strcmp(filename(1:3),'rCN')
            continue
        end
        
        if filename(5) == '1'
            CNimage = load_nifti([cn_dir_name,filename]);
            if exist('meanCNGMimage','var')
                meanCNGMimage = meanCNGMimage + CNimage;
            else
                meanCNGMimage = CNimage;
            end
            numCNGM = numCNGM + 1;
            if (any(isnan(CNimage(:))))
                disp(filename)
            end
            if any(isnan(meanCNGMimage(:)))
                disp(filename)
            end
        elseif filename(5) == '2'
            CNimage = load_nifti([cn_dir_name,filename]);
            if exist('meanCNWMimage','var')
                meanCNWMimage = meanCNWMimage + CNimage;
            else
                meanCNWMimage = CNimage;
            end
            numCNWM = numCNWM + 1;
            if (any(isnan(CNimage(:))))
                disp(filename)
            end
            if any(isnan(meanCNWMimage(:)))
                disp(filename)
            end
        end
    end

    fprintf('\n');

    fprintf('Finding Differences...\n');
    %disp(meanADimage);
    disp(any(isnan(ADimage)));
    if (any(isnan(meanADGMimage(:))))
        disp('Bad bad meanADimage. It is a pooopy head')
    end
    meanADGMimage = meanADGMimage / numADGM;
    meanCNGMimage = meanCNGMimage / numCNGM;
    meanADWMimage = meanADWMimage / numADWM;
    meanCNWMimage = meanCNWMimage / numCNWM;
    
    diffImageGM = meanCNGMimage - meanADGMimage;
    diffImageWM = meanCNWMimage - meanADWMimage;
    
    diffNiiGM = make_nii(diffImageGM);
    diffNiiWM = make_nii(diffImageWM);

    fprintf('Saving Files...\n');
    save_nii(diffNiiGM, [diff_dir_name,'AD_CN_GM_differenceImage.nii']);
    save_nii(diffNiiWM, [diff_dir_name,'AD_CN_WM_differenceImage.nii']);
    
end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end
