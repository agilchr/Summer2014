%}{
Authors: Teo Gelles & Andrew Gilchrist-Scott
Last Updated: 12/17/2014

This file runs almost the entire classification pipeline, including making
the difference image, making the SOM clustering of the difference
image, and using SVMs to classify each brain based on the
clustering and relative importance.

Note: This file does not do tissue segmentation or image coregistration.
%}
function runAll(useSLIC)
    
    if ~exist('useSLIC','var')
        useSLIC = 1;
    end

    usingGM = 1;
    while (true)
        result = input('Use Grey Matter (g) or White Matter (w)?: ', ...
                       's');

        if (strcmp(result, 'g') || strcmp(result, '') || strcmp(result, ...
                                                          'gm'))
            disp('Using Grey Matter')
            usingGM = 1;
            break
        elseif (strcmp(result, 'w') || strcmp(result, 'wm'))
            disp('Using White Matter')
            usingGM = 0;
            break
        else
            disp('Invalid Input')
        end
    end

    makeDifferenceImage();
    
    if useSLIC
        runSLIConDiff(usingGM);
    else
        runSOM(usingGM);
    end
    runSVM(usingGM);
end
