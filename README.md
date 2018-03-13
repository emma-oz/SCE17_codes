# SCE17_codes
I converted to sioread.m file into sioread.py for use in python 3.6, jupyter notebook.
Using the file RAVA02* in this folder, you can run the self-contained jupyter code "process_acoustic.ipynb". 
It will locally save the frequency domain data in a .npy file.

SHIP GPS DATA: https://drive.google.com/file/d/1YkQqeoLI2UFyd6lC3P3H9bH28VFJgjzT/view?usp=sharing. Matlab structure containing all ships data, organized by name, with fields for raw GPS (lat and lon), range, and azimuth and range and azimuth interpolated to a regular time vector.

The requirements file runs in Mac with batch mode enabled. After this you should be able to run "jupyter-notebook" to open and run the notebook.
