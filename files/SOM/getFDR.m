%{
Authors: Teo Gelles & Andrew Gilchrist-Scott
Last Updated: 12/17/2014

This file calculates the Fischer-Discriminant-Ratio (FDR) for two
sets of brain images.  This is called in runSOM, and used in runSVM
to calculate the "relative importance" of each image, which is used
for learning.
%}

function FDR = getFDR(brainset1,brainset2)
    allBrains1 = concatImages(brainset1);
    allBrains2 = concatImages(brainset2);

    FDR = zeros(size(brainset1{1}));
    
    FDR = (mean(allBrains1,4) - mean(allBrains2,4)).^2./(var(allBrains1,1,4) ...
                                                      + ...
                                                      var(allBrains2,1,4));
    FDR(isnan(FDR)) = 0;

end

function concatenatedBrains = concatImages(brains)
    
   n = length(brains);
   [l w h] = size(brains{1});
   concatenatedBrains = zeros(l,w,h,n);
   
   for i = 1:n
       concatenatedBrains(:,:,:,i) = brains{i};
   end
end