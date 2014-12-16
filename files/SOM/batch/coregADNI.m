function coregADNI()
% List of open inputs
%nrun = X; % enter the number of runs here
    numAD = 92;
    numMCI = 203;
    numCN = 102;
    ADinputs = cell(0, numAD);
    CNinputs = cell(0, numMCI);
    MCIinputs = cell(0, numCN);
    parfor num = 1:numAD
        theJob = ADcoregistration(num);
        spm('defaults', 'FMRI');
        spm_jobman('serial', theJob, '', ADinputs{:});
    end
    parfor num = 1:numCN
        theJob = CNcoregistration(num);
        spm('defaults', 'FMRI');
        spm_jobman('serial', theJob, '', CNinputs{:});
    end
    parfor num = 1:numMCI
        theJob = MCIcoregistration(num);
        spm('defaults', 'FMRI');
        spm_jobman('serial', theJob, '', MCIinputs{:});
    end
end

function matlabbatch = ADcoregistration(imageNum)
    filename = ['/sonigroup/fmri/AD_T1/patient',sprintf('%d', imageNum),'.nii'];
    fprintf('Current file is %s\n',filename);
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {'/sonigroup/fmri/AD_T1/patient1.nii,1'};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[filename,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 1;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end

                        
function matlabbatch = CNcoregistration(imageNum)
    filename = ['/sonigroup/fmri/CN_T1/patient',sprintf('%d', imageNum),'.nii'];
    fprintf('Current file is %s\n',filename);
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {'/sonigroup/fmri/AD_T1/patient1.nii,1'};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[filename,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 1;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end

                            
function matlabbatch = MCIcoregistration(imageNum)
    filename = ['/sonigroup/fmri/MCI_T1/patient',sprintf('%d', imageNum),'.nii'];
    fprintf('Current file is %s\n',filename);
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {'/sonigroup/fmri/AD_T1/patient1.nii,1'};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[filename,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 1;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end
