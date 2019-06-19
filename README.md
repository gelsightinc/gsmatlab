# gsmatlab
This project contains MATLAB functions for working with GelSight scans and data. 

## Getting Started

This package assumes that you have MATLAB 2016 or newer. While the functions are likely to work in almost any version of MATLAB and Octave, they have only been tested on MATLAB 2016.

Download the package and add the folder to your MATLAB path. Run the demo
program to get started:
~~~
>> gsdemo
~~~

## Functions

Type `help gsmatlab` to see the available functions
~~~
>> help gsmatlab

  Files
    getprofile    - Get a profile from a heightmap
    getshape      - Get a shape from an annotations list
    gsdemo        - Demo script
    levelprofile  - Level a profile
    plotshape     - Plot a shape on current axes
    readnrm       - Read a normal map in PNG format
    readscan      - Read scan.yaml file into struct
    readtmd       - Read 3D file in TMD format into array
    writenrm      - Save normal map to PNG file
    writescan     - Save struct in YAML format
    writetmd      - Save height array in TMD format
~~~





## Authors
 * **Kimo Johnson**
 * **Janos Rohaly**
 
 ## License
 
 This project is licensed uner the MIT license - see the [LICENSE](LICENSE) for details.
