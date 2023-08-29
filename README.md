# Lapse-Causes
 




## Installation & requirements



### to run fooof scripts on windows

1. (Browser) install fooof for matlab: https://github.com/fooof-tools/fooof_mat
2. (Powershell / Windows search) make sure your computer has a version of python that works for your version of matlab (3.8 to 2.10 atm)
    - To install an older version, you need to go to the python release that includes a binary exectuable, which will be called `Windows installer (64-bit)`, like here: https://www.python.org/downloads/release/python-31011/. Not all releases come with it.
3. (Powershell), create a virtual enviroment ` python3.exe -m venv C:\Users\colas\Code\Lapse-Causes\.env` (use your own path to code directory)
4. (Powershell) activate that enviromentment `C:\Users\colas\Code\Lapse-Causes\.env\Scripts\Activate.ps1`
5. (env Powershell) install fooof package `pip install fooof`
6. (MATLAB) set up the python enviroment for your current session `pyenv('Version', 'C:\Users\colas\Code\Lapse-Causes\.env\Scripts\python', 'ExecutionMode','OutOfProcess')`
7. (MATLAB) Add the fooof scripts to matlab path `C:\Users\colas\Code\fooof_mat\fooof_mat`