%{
Authors: Teo Gelles & Andrew Gilchrist-Scott
Last Updated: 12/17/2014

This file checks whether any brain image in a given directory
contains NaN values, which was an issue early on in our work.
%}
function checkBrainNan(directory_name)

    direc = dir(directory_name);
    
    for i = 1:length(direc)
        filename = direc(i).name;
        disp(filename);
        if direc(i).isdir || ~strcmp(filename(end-3:end),'.nii')
            continue
        end
        im = load_nifti([directory_name,filename]);
        if any(isnan(im))
            disp('***************got some nans************************')
        end
    end
end

function [X] = load_nifti(fullFileName)


    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end
