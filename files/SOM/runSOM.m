function runSOM()
    
    loadDir = ['/scratch/tgelles1/summer2014/ADNI_cropped/' ...
               'coregistered/'];
    diffName = ['/scratch/tgelles1/summer2014/ADNI_cropped/' ...
                'coregistered/AD_CN_differenceImage.nii'];

    [~, ADbrains, CNbrains] = loadADandCNBrains(loadDir);
    diffBrain = load_nifti(diffName);
    
    FDR = getFDR(ADbrains, CNbrains);
    
    dataDir = '/scratch/tgelles1/summer2014/SOM/'
    
    fprintf('Saving FDR to %s\n',[dataDir,'FDR.nii']);
    FDRnii = make_nii(FDR);
    save_nii(FDRnii, [dataDir,'FDR.nii']);
    
    %clear ADbrains;
    %clear CNbrains;
    
    fprintf('Splitting the diff image into vectors\n');
    

    vectorList = makeVectorList(diffBrain);

    clear diffBrain;

    
    if ~exist([dataDir, 'diffClusterNet.mat'], 'file')
        
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
        save diffClusterNet.mat net;
        disp(net);
    else
        fprintf(['Self Organized Map Already Exists in /scratch/tgelles1/summer204/SOM/diffClusterNet.mat. ' ...
                 'Loading...\n']);
        net = load([dataDir, 'diffClusterNet.mat']);
        net = net.net;
    end

    for i=1:length(ADbrains)

        fprintf('Clustering AD brain %d\n', i);
        curBrain = ADbrains{i};

        curVectorList = makeVectorList(curBrain);
        y = net(curVectorList);
        classes = vec2ind(y);


        fprintf('\tSaving net\n');
        curFileName = [dataDir, 'ADbrain', sprintf('%03d',i), 'array.mat'];
        save(curFileName, 'y');

        fprintf('\tSaving classes\n');
        curFileName = [dataDir, 'ADbrain', sprintf('%03d',i), 'classes.mat'];
        save(curFileName, 'classes');

        fprintf('\tSaving clusters\n');
        % clusteringFileName = [dataDir, 'ADbrain', sprintf('%03d',i), 'clusters.nii'];
        % saveClusteringAsNifti(curBrain, classes, curVectorList, ...
        %                       clusteringFileName);

        regions = cell(max(classes),1);
        disp('Size of classes')
        disp(size(classes))
        disp('Size of curVectorList')
        disp(size(curVectorList))
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(classes == ...
                                                   region_i));
        end
        fprintf('\tSaving ROIs\n');
        regionFilename = [dataDir, 'ADbrain', sprintf('%03d',i), ...
                          'ROI.mat'];
        save(regionFilename,'regions');
        
        clear curVectorList;
        clear y;
        clear classes;
        clear curBrain;

        clear ADbrains(i);
    end

    
    for i=1:length(CNbrains)

        fprintf('Clustering brain %d\n', i);
        curBrain = CNbrains{i};

        curVectorList = makeVectorList(curBrain);
        y = net(curVectorList);
        classes = vec2ind(y);


        fprintf('\tSaving net\n');
        curFileName = [dataDir, 'CNbrain', sprintf('%03d',i), 'array.mat'];
        save(curFileName, 'y');

        fprintf('\tSaving classes\n');
        curFileName = [dataDir, 'CNbrain', sprintf('%03d',i), 'classes.mat'];
        save(curFileName, 'classes');

        fprintf('\tSaving clusters\n');
        % clusteringFileName = [dataDir, 'CNbrain', sprintf('%03d',i), 'clusters.nii'];
        % saveClusteringAsNifti(curBrain, classes, curVectorList, ...
        %                       clusteringFileName);

        regions = cell(max(classes),1);
        for region_i = 1:length(regions)
            regions{region_i} = curVectorList(:,find(classes == ...
                                                   region_i));
        end
        
        fprintf('\tSaving ROIs\n');
        regionFilename = [dataDir, 'CNbrain', sprintf('%03d',i), ...
                          'ROI.mat'];
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

    disp(classBrain);
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