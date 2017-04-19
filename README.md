# LabellingTool

To use this tool:
-----------------
1. Hit run
2. Load a file, the data will display on the axes
3. You can zoom in/out and pan to view the data.  
4. Select the "Label" option, click on the plot, and use the apply mark buttons to mark two time points.
4. Choose the labels from the drop down menu and hit apply to label the marked interval.
5. Continue marking until you have labelled the file (use the unknown option to cover extraneous data).
6. Use the fill gaps button to ensure all data is labelled.
7. Export the data with the given labels

Data I/O:
----------------------------
Input: (.xls file)  
Column 1: Time              (numeric/datetime)  
Column 2: Data stream 1     (numeric)  
Column 3: Data stream 2     (numeric)  
Column 4: Data stream 3     (numeric)  
Column N: Data stream N-1   (numeric)  

Output: (.xlsx file)  
Column 1:   Time            (numeric/datetime)  
Column 2:   Data stream 1   (numeric)  
Column 3:   Data stream 2   (numeric)  
Column 4:   Data stream 3   (numeric)  
Column N:   Data stream N-1 (numeric)  
Column N+1: Label 1         (text)  
Column N+2: Label 2         (text)  

Notes:
------
The LabellingTool can handle more than 3 data streams, but it will only plot the first 3 on the axes.

The current version requires at least 3 data streams because I mainly use tri-axial accelerometer data, but can be modified to require less.

You can modify the labels you would like to use within the popupmenu initializations.  

If you want to read file types other than xls, you can modify how the data is loaded/written in "buttonLoad" and "buttonExport", respectively.
