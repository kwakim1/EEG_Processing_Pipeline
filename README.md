# EEG_Processing_Pipeline
A pipeline to clean and epoch EEG data collected using a Biosemi ActiveTwo EEG system. This pipeline is designed to process 64 channel, 128 channel, and 160 channel data. If you have any questions, feel free to email them to me at kamywakim@gmail.com!

## Processing Steps Performed

1. Initialize / load data
2. Resample
   - Optional step
4. Remove externall channels
5. Get channel locations
6. Line noise removal
7. Filtering (high and low pass)
8. Re-reference to common average
9. ICA
   - Optional step
10. Epoch
11. Baseline
12. Trial Rejection
13. Generate plots for quality control and manual inspection
14. Finalize
15. Save data
16. Generate log file

## Requirements
1. MATLAB
2. EEGLab Toolbox
  - Download from here: https://sccn.ucsd.edu/eeglab/download.php

## Before running this code, edit these lines

### Script: **RUNME.m**

```
addpath(genpath('PATH/TO/CODE/DIRECTORY'));
dirpath.ParentDir='PATH/TO/DATA/DIR'; 
FolderEnding='_OPTIONAL_DESCRIPTION_OF_ANALYSIS'; 
dirpath.EEGLabDir='PATH/TO/EEGLAB'; 
```

**PATH/TO/CODE/DIRECTORY**: The full path to the unzipped .zip file downloaded from this repository

  - **Example for Mac**: '/Users/me/Desktop/Preprocessing_Code'
  - **Example for PC**: 'C:\Users\me\Desktop\Preprocessing_Code'

**PATH/TO/DATA/DIR**: The full path to the parent directory containing your subject-level folders

  - **Example for Mac**: '/Users/me/Desktop/My_Data'
  - **Example for PC**: 'C:\Users\me\Desktop\My_Data'


**OPTIONAL_DESCRIPTION_OF_ANALYSIS**: An optional string to be appended to the end of your folder names. This can be helpful for organizing different analyses. Please include an underscore in the optional string. May also be left blank.

  - **Example 1**: '_Stimulus_Locked_Analysis'
  - **Example 2**: '_HighPassFilter2Hz'
  - **Example 3**: '_Processed_By_Jane_Doe'
  - **Example 4**: '' 


**PATH/TO/EEGLAB**: The full path to where EEGLab is installed.

  - **Example for Mac**: '/Users/me/Documents/MATLAB/eeglab2022.1'
  - **Example for PC**: 'C:\Users\me\Documents\MATLAB\eeglab2022.1'






### Script: **GetParams.m**

**GetParams.m: Parameters pertaining to experiment name**

```
params.expname=' '; 
params.trig_names={' ', ' ', ' ', ' '}; 
```
 - *Example experiment naming parameters*: 

     ```
     params.expname='Audio-Visual Speeded Reaction Time Task'; 
     params.trig_names={'All Stimului', 'Auditory', 'Visual', 'AudioVisual'}; 
     ```
**GetParams.m: Filtering parameters**

```
params.desFs = []; %sampling rate in Hz, e.g. 512
params.hPass = []; %high pass filter in Hz, e.g. 1
params.lPass = []; %low pass filter in Hz, e.g. 45
params.hPass_ica = []; %high pass filter to be applied to data before ICA in Hz, e.g. 2
```

 - *Example filtering parameters*: 

     ```
     params.desFS = 512; %in Hz
     params.hPass = 1 %in Hz
     params.lPass = 45 %in Hz
     params.hPass_ica = 2; in Hz
     ```
     
**GetParams.m: Timing parameters**

```
params.tmin=[]; 
params.tmax=[]; 
params.blmin=[]; 
params.blmax=[]; 
params.trigs={{'','',''},'','','}; 
params.ResponseCond=[]; 
params.Analysis=' '; 
params.additional_erp_str='';
```

 - *Example timing parameters*: 

     ```
     params.tmin=-100; %in ms
     params.tmax=1000; %in ms
     params.blmin=-99; %in ms
     params.blmax=0; %in ms
     params.trigs={{'condition 3','condition 4','condition 5'},'condition 3','condition 4','condition 5'}; %triggers to be epoched as they appear in   your data. Should correspond to params.trigs set above.
     params.ResponseCond = 1; %trigger corresponding to button press response, e.g. 1
     params.Analysis='stimulus_locked'; %must be set to 'stimulus_locked' or 'response_locked' depending on the desired analysis
     params.additional_erp_str='_baseline50ms';
    ```

**GetParams.m: Channel rejection parameters**

```
params.thr1=[]; 
params.ChanRejThresh=[]; 
params.BadChanThresh=[]; 
params.NumTrialsRemaining_thresh=[];
```

 - *Example channel rejection parameters*: 
     

     ```
     params.thr1=150; %in microvolts 
     params.ChanRejThresh=5; %in standard deviations 
     params.BadChanThresh=.15; %in percentage (1=100%, .5 = 50%) 
     params.NumTrialsRemaining_thresh=150; %will flag a particpant if they have fewer than this number of trials after all rejection procedures
     ```

**GetParams.m: Misc. parameters**

```
params.RunICA=' '; 
params.deschan=' ';
params.descond= [];
```

 - *Example misc. parameters*: 

     ```
     params.RunICA='y'; %set to 'y' or 'n' depending on whether or not you want to run ICA for data cleaning 
     params.deschan='A1'; %desired channel for QC plotting. Must be named according to your cap's montage
     params.descond= 1; %desired condition for QC plotting
     ```


## Folder Structure

### Input 
- My_Data **[Parent Directory]**
  - 1001 **[Subject ID]**
    - 1001_1.bdf [BDF file]
    - 1001_2.bdf [BDF file]
    - 1001_3.bdf [BDF file]
  - 1002 **[Subject ID]**
    - 1002_1.bdf [BDF file]
    - 1002_2.bdf [BDF file]
    - 1002_3.bdf [BDF file]
    - 1002_4.bdf [BDF file]
  - 1003 **[Subject ID]**
    - 1003_1.bdf [BDF file]

### Output

- My_Data **[Parent Directory]**
  - 1001 **[Subject ID]**
    - 1001_bdf
      - 1001_1.bdf [BDF file]
      - 1001_2.bdf [BDF file]
      - 1001_3.bdf [BDF file]
    - 1001_mat
      - 1001.mat [MAT file, continuous raw data]
      - 1001.set [SET file, continuous raw data]
    - 1001_mat_OptionalString
      - 1001_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej.mat [MAT file, fully processed continuous data]
      - 1001_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej.set [SET file, fully processed continuous data]
      - 1001_resample_filter_chanrej_reref_ICAweightTransfer.mat
      - 1001_resample_filter_chanrej_reref.mat
      - 1001_resample_filter_chanrej.mat
      - 1001_resample_filter.mat
      - 1001_resample_filter4ica_chanrej_reref_ICA.mat
      - 1001_resample_filter4ica_chanrej_reref.mat
      - 1001_resample_filter4ica_chanrej.mat
      - 1001_resample_filter4ica.mat
      - 1001.mat
      - 1001.set
    - 1001_erps_OptionalString
      - 1001_epoched_OptionalString.mat [MAT file, fully processed epoched data]
    - 1001_plots
      - 1001_electrode-name_condX.png
      - 1001_all_ICs_topos_OptionalString.png
      - 1001_bad_ICs_topos_OptionalString.png
      - 1001_hpf_eeg.fig
      - 1001_hpf_ica.fig
      - 1001_IndivSubTopo.png
      - 1001_lpf.fig
- 1002 **[Subject ID]**
  - ...
  - ...
- LogFiles
  - DATE_ProcessingLog_EXPRIMENT_NAME_Xsubs_OptionalString.txt [contents of command window]
  - Log_Xsubs_OptionalString_DATE.mat [multi-sub log file]


### Notes

- Subject-level folder names must include only digits
  - **Valid folder name**: 12345
  - **Invalid folder name**: Sub12345
- BDF files will be concatenated in alphebetical order into a single .mat file
- Each subject is allowed to have a different number of BDF files (minimum of 1)

## Technical Information
This pipeline was coded in MATLAB (R2021b) on a PC platform running Windows 10 . The pipeline was also tested for Mac compatibility in MATLAB (R2022b) on a Mac Mini running Monterey (v 12.5.1). This pipeline has not been tested on Linux.

## Acknowledgements

Inspired by pipelines by @mickcrosse and @DouweHorsthuis!
