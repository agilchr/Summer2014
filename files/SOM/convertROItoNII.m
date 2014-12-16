function convertROItoNII()

    ROIfilename = ['/sonigroup/ADNI_SPM_Tissues/diff/' ...
                   'AD_CN_GM_differenceImage.niiROI.mat'];

    file1name = ['/sonigroup/ADNI_SPM_Tissues/AD/' ...
                 'rADc1patient001.nii'];
    file2name = '/sonigroup/ADNI_SPM_Tissues/CN/rCNc2patient004.nii';


    file1brain = load_nifti(file1name);
    file2brain = load_nifti(file2name);

    disp(size(file1brain));
    disp(size(file2brain));

    fprintf('Loading ROIs\n');
    ROIs = load(ROIfilename);
    ROIs = ROIs.regions;

    fprintf('Converting ROIs\n');
    newROIs = zeros(size(file1brain));
    for i = 1:length(ROIs)
        for j = 1:length(ROIs{i})
            curVec = ROIs{i}(:, j);
            %disp([i,j])
            
            x = curVec(1);
            y = curVec(2);
            z = curVec(3);
            
            if (x == 0 || y == 0 || z == 0)
                continue
            end

            %            disp([x, y, z]);
            %newROIs(curVec(1:3)) = i*10;
            newROIs(x, y, z) = i*10;
            %            disp(newROIs(curVec(1:3)));
            %            disp(newROIs(x, y, z));
            %            pause;
            %            disp(i*10);
        end
    end

    newROIfilename = ['/sonigroup/ADNI_SPM_Tissues/data/' ...
                      'AD_CN_diffImageROI.nii'];

    %    disp(newROIs);
    ROInii = make_nii(newROIs);
    save_nii(ROInii, newROIfilename);
end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end