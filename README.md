# Lapse-Causes
This is the code for the publication {Title}.  
The EEG preprocessing was previously done with the scripts from this [other respository](https://github.com/snipeso/Theta-SD-vs-WM).
The Lateralized Attention Task (LAT) task code can be found [here](https://github.com/snipeso/LAT).

## The Code

### Analyses
The scripts need to be run in order, since most of them depend on some aspect of at least one of the previous ones.

- [analysisParameters.m](./Analysis/analysisParameters.m): This is where all the parameters and variables (e.g. paths, thresholds, frequency band ranges) are indicated that are common across multiple scripts.
- [Analysis1_Detect_Bursts.m](./Analysis/Analysis1_Detect_Bursts.m): This is the script that runs the toolbox I made, [Matcycle](https://github.com/HuberSleepLab/Matcycle), which detects bursts of oscillations. The exact criteria for detection can all be found in here.
- [Analysis2_SynchronizeEyeclosures.m](./Analysis/Analysis2_Synchronize_Eyeclosures.m): This script accesses the pupillometry data, synchronizes it to the EEG so I know when participants had their eyes closed.
- [Analysis3_AssembleTrial_Information.m](./Analysis/Analysis3_Assemble_Trial_Information.m): This script gets all the behavioral trial data for the LAT and PVT, and identifies trials during which eyes were closed. This is especially relevant for Figure 2.
- [Analysis4_EyeclosureTrials.m](./Analysis/Analysis4_Eyeclosure_Trials.m): This script epochs and averages the eye-closure data synchronized to the stimuli, split by trial outcome. If you wan't to directly see how the likelihood of an event in time was calculated for both eye closures and bursts, see the function [probability_of_event_by_outcome.m](./functions/general/probability_of_event_by_outcome.m).
- [Analysis5_Burst_Trials.m](./Analysis/Analysis5_Bursts_Trials.m): same as Analysis4, but for bursts.
- [Analysis6_TimeFrequency.m](./Analysis/Analysis6_TimeFrequency.m): this script runs a time-frequency analysis on each EEG recording. For the actual time-frequency function, see [time_frequency.m](./functions/eeg/time_frequency.m).
- [Analysis7_EpochTimeFrequency.m](./Analysis/Analysis7_EpochTimeFrequency.m): epochs the time-frequency data. Run twice, once for eyes-open trials, once all trials.
- [Analysis8_Amplitudes.m](./Analysis/Analysis8_Amplitudes.m): identifies information about amplitudes of bursts around stimuli.


### Plotting & statistics
- [Figure2_Behavior.m](./Analysis/Figure2_Behavior.m): plots all figures related to the tasks, and provides descriptive statistics of lapses and reaction times and such. relies on Analyses 2,3.
- [Figure3_Timecourses.m](./Analysis/Figure3_Timecourses.m): plots relationship between trial outcome and burst/eyeclosure likelihood. Relies on analyses 1-5.
- [Figure4_BurstTopographies.m](./Analysis/Figure4_BurstTopographies.m): plots topographies of burst likelihood. Relies on analyses 1-5.
- [Figure5_TimeFrequency.m](./Analysis/Figure5_TimeFrequency.m): plots all the exploratory analyses. Relies especially on analyses 6,7.

All the statistics are done with the function [paired_ttest.m](/functions/stats/paired_ttest.m). Whenever this function is called for a single plot, FDR correction is applied to all values.

## Installation & requirements
(TODO)



### to run fooof scripts on windows

1. (Browser) install fooof for matlab: https://github.com/fooof-tools/fooof_mat
2. (Powershell / Windows search) make sure your computer has a version of python that works for your version of matlab (3.8 to 2.10 atm)
    - To install an older version, you need to go to the python release that includes a binary exectuable, which will be called `Windows installer (64-bit)`, like here: https://www.python.org/downloads/release/python-31011/. Not all releases come with it.
3. (Powershell), create a virtual enviroment ` python3.exe -m venv C:\Users\colas\Code\Lapse-Causes\.env` (use your own path to code directory)
4. (Powershell) activate that enviromentment `C:\Users\colas\Code\Lapse-Causes\.env\Scripts\Activate.ps1`
5. (env Powershell) install fooof package `pip install fooof`
6. (MATLAB) set up the python enviroment for your current session `pyenv('Version', 'C:\Users\colas\Code\Lapse-Causes\.env\Scripts\python', 'ExecutionMode','OutOfProcess')`
7. (MATLAB) Add the fooof scripts to matlab path `C:\Users\colas\Code\fooof_mat\fooof_mat`


## How to run

1. Detect bursts with [A_Detect_Bursts.m](./Analysis/A_Detect_Bursts.m).
2. Assemble and synchronize eyetracking data to EEG data with[B_Synchronize_Eyeclosures.m](./Analysis/B_Synchronize_Eyeclosures.m).
3. Assemble trial information.