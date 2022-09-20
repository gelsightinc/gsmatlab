# gsmatlab
This project contains MATLAB functions for working with GelSight scans and data. 

## Getting Started

This package assumes that you have MATLAB 2016 or newer. While the functions are likely to work in almost any version of MATLAB and Octave, they have only been tested on MATLAB 2016.

Download the package and add the folder to your MATLAB path. Run the demo
program to get started:
~~~
>> gsdemo
~~~

You should get the following plot:

<img src="http://www.gelsight.com/downloads/demoplot.png" alt="gsdemo output plot" style="width:600px;" />

## Functions

Type `help gsmatlab` to see the available functions
~~~
>> help gsmatlab

  Files
    checkset      - Check all scans in a folder for images and heightmaps
    getprofile    - Extract a profile along a line from a height map.
    getshape      - Get a shape from an annotations list.
    gsdemo        - Simple demo script showing how to plot a profile from a GelSight scan.
    levelprofile  - Level a profile to make the specified regions horizontal.
    plotshape     - Plots a shape in the current axes.
    readnrm       - Reads a normal map saved in PNG format.
    readscan      - Reads a scan file.
    readtmd       - Reads a 3D measurement saved in TMD format.
    writenrm      - Save a normal map in PNG format.
    writescan     - Saves a scan struct in YAML format.
    writetmd      - Writes a 3D surface to a TMD file.
    findscans     - Reads a 3D measurement saved in TMD format.
    grranova      - Do a Gage R&R Analysis of Variance on a set of measurements.
    polydetrend   - Apply polynomial detrending to a surface.
    readimg       - Reads an image from a scan.
    shapemask     - Make a mask from the specified shape.
~~~


## Authors
 * **Kimo Johnson**
 * **Janos Rohaly**
 
 ## License
 
 This project is licensed uner the MIT license - see the [LICENSE](LICENSE) for details.
