function runSOM()
    
    loadDir = ['/scratch/tgelles1/summer2014/ADNI_cropped/' ...
               'coregistered/'];

    [allbrains ADbrains CNbrains] = loadADandCNBrains(loadDir);
    
    FDR = getFDR(ADbrains, CNbrains);
    
    fprintf('Saving FDR to %s\n',[loadDir,'FDR.nii']);
    FDRnii = make_nii(FDR);
    save_nii(FDRnii, [loadDir,'FDR.nii']);
    
    clear ADbrains;
    clear CNbrains;
    
    fprintf('Splitting the brains into vectors\n');
    
    n = length(allbrains);
    [l w h] = size(allbrains{1});
    
    vectorList = cell(n*l*w*h,1);
    
    vector_i = 1;
    
    for brain_i = 1:length(allbrains)/5
        fprintf('On brain %d\n',brain_i);
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

    
    
    % vectorList = splitBrainToVector(allbrains);
    % clear allbrains;
        
    fprintf('Making the self organizing map\n');
    net = selforgmap([1 4]);
    fprintf('Training the self organizing map\n');
    net = train(net,vectorList);
    fprintf('Viewing the self organizing map\n');
    view(net);
    y = net(allbrains);
    classes = vec2ind(y);
    
    

end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end

function [allbrains ADbrains CNbrains] = loadADandCNBrains(directory)
    
    direc = dir(directory);
    
    ADbrains = {};
    CNbrains = {};
    allbrains = {};

    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'co_')
            continue
        end
        if filename(4) == 'M'
            % continues if we're dealing with an MCI file
            continue
        elseif filename(4) == 'A'
            ADimage = load_nifti([directory,filename]);
            ADbrains{end+1} = ADimage;
            allbrains{end+1} = ADimage;
        elseif filename(4) == 'C'
            CNimage = load_nifti([directory,filename]);
            CNbrains{end+1} = CNimage;
            allbrains{end+1} = CNimage;
        end
    end
end

function vectorList = splitBrainToVector(allbrains)
    
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