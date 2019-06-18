# gsmatlab
This project contains MATLAB functions for working with GelSight scans and data. 

## Getting Started

This package assumes that you have MATLAB 2016 or newer. While the functions are likely to work in almost any version of MATLAB and Octave, they have only been tested on MATLAB 2016.

### Installing

Download the package and add the folder to your MATLAB path.

## Functions

 * **readScanFile** reads the scan.yaml file into a struct. 0-based coordinates are converted into 1-based coordinates.
 * **writeScanFile** saves a scan struct in YAML format, readable by GelSight software.
 * **readTmd** reads the 3D data in the TMD file into a matrix where the values are in millimeters
 * **writeTmd** save a matrix in TMD format


## Authors
 * **Kimo Johnson**
 * **Janos Rohaly**
 
 ## License
 
 This project is licensed uner the MIT license - see the [LICENSE](LICENSE) for details.
