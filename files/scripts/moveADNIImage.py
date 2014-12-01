import subprocess
from os.path import isfile
import os

dir1 = "/sonigroup/fmri/AD_T1/"
dir2 = "/sonigroup/fmri/CN_T1/"
dir3 = "/sonigroup/fmri/MCI_T1/"


moveDir = "/scratch/tgelles1/summer2014/ADNI_SPM_Tissues/"


for filename in os.listdir(dir3):
    if (filename[:2] == "c2" and filename[-3:] == "nii" and filename
        != "c1c1c1patient1.nii" and filename != "c1c1patient1.nii"
        and filename != "c1spatient1.nii" and filename != "c2c1patient1.nii"
        and filename != "c2c1c1patient1.nii" and filename != "c2spatient1.nii"):
        
        print(filename)
        patientnum = int(filename[9:-4])
        patientnumstr = "%.3d" %patientnum
        print(patientnumstr)
        print(patientnum)
        newfilename = "MCIc2patient" + patientnumstr + ".nii"
        print(newfilename)

        commands = ["cp", dir3+filename, moveDir+newfilename]
        subprocess.call(commands)
