function runSLIConDiff(usingGM)

    if (~exist('usingGM', 'var'))
        usingGM = 1;
    end

    checkFiles(usingGM);
    
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

    %net = getDiffClusterNet(diffName, usingGM, diffDir);
    
    clusters = getSLICclusters(diffName, usingGM);
    
    [ADbrains, CNbrains] = loadADandCNBrains(ADLoadDir, ...
                                             CNLoadDir, usingGM);

    makeFDR(ADbrains, CNbrains, usingGM, diffDir);

    clusterBrains(ADbrains, CNbrains, clusters, usingGM, diffName);
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
    
function vectorList = makeVectorList(brain, isDiffImage)

    if (~exist('isDiffImage', 'var'))
        isDiffImage = 0;
    end
    
    [l w h] = size(brain);
    
    vectorList = zeros(4,l*w*h);
    
    vector_i = 1;
    
    for x_i = 1:l
        for y_i = 1:w
            for z_i = 1:h

                if (brain(x_i, y_i, z_i) == 0 && isDiffImage)
                    continue;
                end
                
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

function checkFiles(usingGM)

    ADLoadDir = ['/sonigroup/ADNI_SPM_Tissues/AD/'];
    CNLoadDir = ['/sonigroup/ADNI_SPM_Tissues/CN/'];
    diffDir = '/sonigroup/ADNI_SPM_Tissues/diff/';
    
    if (usingGM)
        diffName = [diffDir, 'AD_CN_GM_differenceImage.nii'];
    else
        diffName = [diffDir, 'AD_CN_WM_differenceImage.nii'];
    end

    if (~exist(ADLoadDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', ADLoadDir);
        exit;
    end
    if (~exist(CNLoadDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', CNLoadDir);
        exit;
    end
    if (~exist(diffDir, 'dir'))
        fprintf('ERROR: Directory %s Does Not Exist\n', diffDir);
        exit;
    end
    if (~exist(diffName, 'file'))
        fprintf('ERROR: Difference Image File %s Does Not Exist\n', ...
                diffName);
        exit;
    end
end

function makeFDR(ADbrains, CNbrains, usingGM, diffDir)

    if (usingGM)
        fdrName = [diffDir, 'FDRGM.nii'];
    else
        fdrName = [diffDir, 'FDRWM.nii'];
    end
    if (exist(fdrName, 'file'))
        fprintf('FDR File Exists at %s\n', fdrName);
    else
        
        FDR = getFDR(ADbrains, CNbrains);
    
        fprintf('Saving FDR to %s\n',fdrName);
        FDRnii = make_nii(FDR);
        save_nii(FDRnii, fdrName);
    end
end

function net = getDiffClusterNet(diffName, usingGM, diffDir)

    diffBrain = load_nifti(diffName);
    % attempt to enhance the sensitivity to intensities
    diffBrain = diffBrain*10;
    fprintf('Splitting the diff image into vectors\n');
    vectorList = makeVectorList(diffBrain, 1);

    clear diffBrain;

    if (usingGM)
        diffClusterNetName = [diffDir, 'diffClusterNetGM.mat'];
    else
        diffClusterNetName = [diffDir, 'diffClusterNetWM.mat'];
    end
    
    if ~exist(diffClusterNetName, 'file')
        
        fprintf('Making the self organizing map\n');
        net = selforgmap([4 4 3]);
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
                diffClusterNetName);
        net = load(diffClusterNetName);
        net = net.net;
    end
end

function clusterBrains(ADbrains, CNbrains, clusters, usingGM, diffName)

    slicDir = '/sonigroup/ADNI_SPM_Tissues/SLIC/';
    
    fprintf(['Clustering the difference image for visualization ' ...
             'purposes\n'])

    diff = load_nifti(diffName);
    diffvecs = makeVectorList(diff,1);
    regions = clusters;
    
    save([diffName,'ROI.mat'],'regions')
    
    
    for i=1:length(ADbrains)

        if (usingGM)
            fprintf('Clustering AD GM brain %d\n', i);
        else
            fprintf('Clustering AD WM brain %d\n', i);
        end
        
        curBrain = ADbrains{i};

        curVectorList = makeVectorList(curBrain);

        regions = cell(max(clusters(:)),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(clusters == region_i));
        end
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [slicDir, 'ADGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [slicDir, 'ADWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
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

        regions = cell(max(clusters(:)),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(clusters == region_i));
        end
        
        fprintf('\tSaving ROIs\n');
        if (usingGM)
            regionFilename = [slicDir, 'CNGMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        else
            regionFilename = [slicDir, 'CNWMbrain', sprintf('%03d',i), ...
                              'ROI.mat'];
        end
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear curBrain;

        clear CNbrains(i);
    end
end

function labels = getSLICclusters(diffName, usingGM)
    
    X = load_nifti(diffName);
    
    numSuperVoxels = 500;
    shapeParam = .1;
    numIters = 18;
    
    labels = SLIC_3D(X,numSuperVoxels, shapeParam, numIters);
end    