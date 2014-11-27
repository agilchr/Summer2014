function runSOM(usingGM)

    if (~exist('usingGM', 'var'))
        usingGM = 1;
    end
    
    ADLoadDir = ['/sonigroup/ADNI_SPM_Tissues/AD/'];
    CNLoadDir = ['/sonigroup/ADNI_SPM_Tissues/CN/'];
    diffDir = '/sonigroup/ADNI_SPM_Tissues/diff/';
    
    if (usingGM)
        diffName = [diffDir, 'AD_CN_GM_differenceImage.nii'];
    else
        diffName = [diffDir, 'AD_CN_WM_differenceImage.nii'];
    end

    fprintf('Loading AD Images from: %s\n', ADLoadDir);
    fprintf('Loading CN Images from: %s\n', CNLoadDir);
    if (usingGM)
        fprintf('Using GM Tissues\n');
    else
        fprintf('Using WM Tissues\n');
    end
    
    [ADbrains, CNbrains] = loadADandCNBrains(ADLoadDir, ...
                                             CNLoadDir, usingGM);
    diffBrain = load_nifti(diffName);
    
    FDR = getFDR(ADbrains, CNbrains);

    if (usingGM)
        fprintf('Saving FDR to %s\n',['/sonigroup/ADNI_SPM_Tissues/diff/FDRGM.nii']);
        FDRnii = make_nii(FDR);
        save_nii(FDRnii, ['/sonigroup/ADNI_SPM_Tissues/diff/FDRGM.nii']);
    else
        fprintf('Saving FDR to %s\n',['/sonigroup/ADNI_SPM_Tissues/diff/FDRWM.nii']);
        FDRnii = make_nii(FDR);
        save_nii(FDRnii, ['/sonigroup/ADNI_SPM_Tissues/diff/' ...
                          'FDRWM.nii']);
    end
    
    %clear ADbrains;
    %clear CNbrains;
    
    fprintf('Splitting the diff image into vectors\n');
    vectorList = makeVectorList(diffBrain);

    clear diffBrain;

    if (usingGM)
        diffClusterNetName = [diffDir, 'diffClusterNetGM.mat'];
    else
        diffClusterNetName = [diffDir, 'diffClusterNetWM.mat'];
    end
    
    if ~exist(diffClusterNetName, 'file')
        
        fprintf('Making the self organizing map\n');
        net = selforgmap([4 8]);
        fprintf('Training the self organizing map\n');
        net = train(net,vectorList);
        fprintf('Viewing the self organizing map\n');
        view(net);
        figure('Visible','off');
        plotsompos(net,vectorList);
        saveas(gcf,'sompos.fig','fig')
        fprintf('MATLAB net class: %s\n', class(net));
        save(diffClusterNetName, 'net');
        disp(net);
    else
        fprintf('Self Organized Map Already Exists In %s. Loading...\n', ...
                [diffDir, diffClusterNetName]);
        net = load([diffDir, diffClusterNetName]);
        net = net.net;
    end

    dataDir = '/sonigroup/ADNI_SPM_Tissues/data/';
    
    for i=1:length(ADbrains)

        if (usingGM)
            fprintf('Clustering AD GM brain %d\n', i);
        else
            fprintf('Clustering AD WM brain %d\n', i);
        end
        
        curBrain = ADbrains{i};

        curVectorList = makeVectorList(curBrain);
        y = net(curVectorList);
        classes = vec2ind(y);


        fprintf('\tSaving net\n');
        if (usingGM)
            curFileName = [dataDir, 'ADGMbrain', sprintf('%03d',i), ...
                           'array.mat'];
        else
            curFileName = [dataDir, 'ADWMbrain', sprintf('%03d',i), ...
                           'array.mat'];
        end
        save(curFileName, 'y');


        
        fprintf('\tSaving classes\n');
        if (usingGM)
            curFileName = [dataDir, 'ADGMbrain', sprintf('%03d',i), ...
                           'classes.mat'];
        else
            curFileName = [dataDir, 'ADWMbrain', sprintf('%03d',i), ...
                           'classes.mat'];
        end
        save(curFileName, 'classes');

        regions = cell(max(classes),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(classes == ...
                                                   region_i));
        end
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [dataDir, 'ADGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [dataDir, 'ADWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear y;
        clear classes;
        clear curBrain;

        clear ADbrains(i);
    end

    
    for i=1:length(CNbrains)

        if (usingGM)
            fprintf('Clustering CN GM brain %d\n', i);
        else
            fprintf('Clustering CN WM brain %d\n', i);
        end
        
        curBrain = CNbrains{i};

        curVectorList = makeVectorList(curBrain);
        y = net(curVectorList);
        classes = vec2ind(y);


        fprintf('\tSaving net\n');
        if (usingGM)
            curFileName = [dataDir, 'CNGMbrain', sprintf('%03d',i), ...
                           'array.mat'];
        else
            curFileName = [dataDir, 'CNWMbrain', sprintf('%03d',i), ...
                           'array.mat'];
        end
        save(curFileName, 'y');


        
        fprintf('\tSaving classes\n');
        if (usingGM)
            curFileName = [dataDir, 'CNGMbrain', sprintf('%03d',i), ...
                           'classes.mat'];
        else
            curFileName = [dataDir, 'CNWMbrain', sprintf('%03d',i), ...
                           'classes.mat'];
        end
        save(curFileName, 'classes');

        regions = cell(max(classes),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(classes == ...
                                                   region_i));
        end
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [dataDir, 'CNGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [dataDir, 'CNWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear y;
        clear classes;
        clear curBrain;

        clear CNbrains(i);
    end

    
    % to open: openfig('sompos.fig','new','visible')
    
    % y = net(allbrains);
    % classes = vec2ind(y);
end

function saveClusteringAsNifti(curBrain, classes, curVectorList, ...
                               fileName)

    classBrain = curBrain;
    for i=1:length(curVectorList)
        curVec = curVectorList(1:3, i);
        x = curVec(1);
        y = curVec(2);
        z = curVec(3);
        classBrain(x, y, z) = classes(i);
    end

    % disp(classBrain);
    disp(max(classBrain(:)));
    nii = make_nii(classBrain);
    save_nii(nii, fileName);

    clear classBrain;
end
    
function vectorList = makeVectorList(brain)

    [l w h] = size(brain);
    
    vectorList = zeros(4,l*w*h);
    
    vector_i = 1;
    
    for x_i = 1:l
        for y_i = 1:w
            for z_i = 1:h
                vectorList(:,vector_i) = [x_i;y_i;z_i;brain(x_i, ...
                                                            y_i,z_i)];

                if (vectorList(1, vector_i) == 0 || ...
                    vectorList(2, vector_i) == 0 || ...
                    vectorList(3, vector_i) == 0)
                    disp('Bad Vector!');
                    disp(vectorList(:, vector_i));
                    disp([x_i, y_i, z_i]);
                end
                
                vector_i = vector_i + 1;
            end
        end
    end
end

function [X] = load_nifti(fullFileName)


    fprintf('Loading Nifti Image: %s\n',fullFileName);
        
    %Image
    I_t1uncompress = wfu_uncompress_nifti(fullFileName);
    I_uncompt1 = spm_vol(I_t1uncompress);
    I_T1 = spm_read_vols(I_uncompt1);
    X = I_T1;
    
end

function [ADbrains CNbrains] = loadADandCNBrains(ADDirectory, ...
                                                 CNDirectory, usingGM)
    
    direc = dir(ADDirectory);
    
    ADbrains = {};
    CNbrains = {};

    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'rAD')
            continue
        end
        if (filename(5) == '1' && ~usingGM)
            continue
        elseif (filename(5) == '2' && usingGM)
            continue
        end
        
        ADimage = load_nifti([ADDirectory,filename]);
        ADbrains{end+1} = ADimage;
    end

    
    direc = dir(CNDirectory);
    
    for i = 1:length(direc)
        filename = direc(i).name;
        if direc(i).isdir || ~strcmp(filename(1:3),'rCN')
            continue
        end
        if (filename(5) == '1' && ~usingGM)
            continue
        elseif (filename(5) == '2' && usingGM)
            continue
        end
        
        CNimage = load_nifti([CNDirectory,filename]);
        CNbrains{end+1} = CNimage;
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