function zeroNan(directory_name)
% takes all of the nifti files in a given directory and converts
% all NaN values to zeros
%
% Written by Teo Gelles and Andrew Gilchrist-Scott
% Last edited on December 17, 2014

    direc = dir(directory_name);
    
    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(end-3:end),'.nii')
            continue
        end
        im = load_nifti([directory_name,filename]);
        if any(isnan(im(:)))
            fprintf('Fixing %s\n',filename);
            im(isnan(im)) = 0;
            imNii = make_nii(im);
            save_nii(imNii,[directory_name,filename]);
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
