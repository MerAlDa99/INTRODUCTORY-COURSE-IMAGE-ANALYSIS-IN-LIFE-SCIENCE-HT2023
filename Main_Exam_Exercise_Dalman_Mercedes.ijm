/*
FINAL EXAM INTRODUCTORY COURSE IMAGE ANALYSIS IN LIFE SCIENCE HT2023 
Author: Mercedes Dalman
Mail: mercedes.dalman@gu.se
Date: 2023-09-10

Main goal:

Develop an image analysis workflow that measures the:

1) Mean intensity of the green marker (protein) present in the
nucleus on a band around the nuclear membrane.

2) Mean intensity of the green marker (protein) present in the
nucleus without considering the band closest to the nuclear
membrane.

3) Mean intensity of the microtubules (magenta) on a band (e.g.,
width 20 pixels) outside of the nuclear membrane.

4) Calculate the ratio between the green marker inside the nucleus
and in its periphery.

The image data will be that presented by Elnaz and available via the repo:
https://github.com/elnazfazeli/CCI2023_ImageJMacro/tree/master/CellAtlas_Subset

*/
// Open the directory with images to be analysed (called CellAtlas_Subset)
input_path = getDirectory("input files"); 

// OBS! Make sure to not save into this directory, as fileList will contain all file names.
fileList = getFileList(input_path); 

// Choose where to save results
results_path = getDirectory("result files"); 

// Set parameters
radius = getNumber("Set Radius", 8);
min_size = getNumber("Set Minimum Size", 2000);

/////////////////////////////////// Macro for all tasks in one ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Set band sizes - band 1 is for task 3 (microtubules), band 2 for the other measurements
band_size1 = getNumber("Set Band Size Task 3", 20);
band_size2 = getNumber("Set Band Size Task 1 and 2", 10);
for (i = 0; i < fileList.length; i++) {
	roiManager("reset");
	run("Clear Results");
	
	open(input_path+fileList[i]);
	
	// Get title for naming
	ImageID = getTitle();
	title = substring(ImageID,0,lengthOf(ImageID)-4);
	
	// Split channels to and rename for easier navigation
	run("Split Channels");
	selectWindow("C1-"+ImageID);
	rename("nuclei");
	selectWindow("C2-"+ImageID);
	rename("signal");
	selectWindow("C3-"+ImageID);
	rename("microtubules");
	
	// Select blue channel for segmentation 
	selectWindow("nuclei");
	run("Median...", "radius=" + radius);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	
	// Analyse particles
	run("Analyze Particles...", "size=" + min_size + "-Infinity add"); 
	run("Clear Results");
	
	// Loop over each cell to select each element in ROI manager
	numberOfNuclei = roiManager("count");
	for(j=0; j<numberOfNuclei; j++){
		// Task 3 - calculate mean intensity of magenta channel in band around membrane
		selectWindow("microtubules");
		roiManager("Select", j);
		run("Make Band...", "band=" + band_size1);
		// Get the statistics of the magenta channel - mean intensity microtubules is saved as meanMicrotubules
		getStatistics(area, meanMicrotubules, min, max, std, histogram); 
		
		// Task 1, 2 and 4 - calculate mean intensity band, nucleus without membrane and ratio for green channel
		selectWindow("signal");
		roiManager("Select", j);
		// Deselect membrane (rescale to not contain band) 
		run("Enlarge...", "enlarge=-" + band_size2);
		// Get the statistics of the nucleus - mean intensity nucleus is saved as meanNuclei
		getStatistics(area, meanNuclei, min, max, std, histogram); 
		// Make band 
		run("Make Band...", "band=" + band_size2);
		roiManager("Update");
		// Get statistics of the band - mean intensity membrane is saved as meanNucRim
		getStatistics(area, meanNucRim, min, max, std, histogram); 
		
		// Make results with columns: title, mean intensity nucleus, mean intensity membrane, mean intensity microtubules
		setResult("image", nResults, title);
		setResult("mean Int nuclei", nResults-1, meanNuclei);
		setResult("mean Int nuclear membrane", nResults-1, meanNucRim);
		setResult("mean Int microtubules", nResults-1, meanMicrotubules);
		// Calculate ratio membrane/nucleus mean intensity and save as separate column
		ratio = meanNucRim / meanNuclei;
		setResult("ratio", nResults-1, ratio);
		// Also add the nucleus size
		setResult("minimum size nuclei", nResults-1, min_size);
	}
	updateResults();
	
	// Saved as all_{image_title}.xls
	saveAs("Results", results_path + "all_"+title+".xls");
	run("Close All");
}
exit

/////////////////////////////////// Macro for all tasks one by one ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
band_size = getNumber("Set Band Size", 10);


// TASK 1
for (i = 0; i < fileList.length; i++) {
	roiManager("reset");
	run("Clear Results");
	
	open(input_path+fileList[i]);
	
	// Get title
	ImageID = getTitle();
	title = substring(ImageID,0,lengthOf(ImageID)-4);;
	
	// Split channels and rename windows
	run("Split Channels");
	selectWindow("C1-"+ImageID);
	rename("nuclei");
	selectWindow("C2-"+ImageID);
	rename("signal");
	
	// Select blue channel and segment nuclei
	selectWindow("nuclei");
	run("Median...", "radius="+radius);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	
	// Analyse particles
	run("Analyze Particles...", "size=" + min_size + "-Infinity add");
	roiManager("Show None");
	
	// Loop over ROI manager to select all cell
	numberOfNuclei = roiManager("count");
	for(j=0; j<numberOfNuclei; j++){
		roiManager("Select", j);
		// Make band
		run("Enlarge...", "enlarge=-" + band_size);
		run("Make Band...", "band=" + band_size);
		roiManager("Update"); 
	}
	
	// Set measurements to analyse mean gray value (intensity)
	run("Set Measurements...", "mean display redirect=None decimal=3");
	
	// Go to window with actual signal (green channel)
	selectWindow("signal");
	
	// Loop over ROI manager to measure signal for each cell
	for(k=0; k<numberOfNuclei; k++){
		roiManager("Select", k);
		roiManager("Measure");	
	}
	// Save ROI manager results (signal) - saved as band_{image_title}.xls
	saveAs("Results", results_path + "band_" + title + ".xls");
	run("Close All");
	
}

// TASK 2 - same as task 1 but nucleus without band instead
for (i = 0; i < fileList.length; i++) {
	roiManager("reset");
	run("Clear Results");
	
	open(input_path+fileList[i]);
	
	ImageID = getTitle();
	title = substring(ImageID,0,lengthOf(ImageID)-4);

	run("Split Channels");
	selectWindow("C1-"+ImageID);
	rename("nuclei");
	selectWindow("C2-"+ImageID);
	rename("signal");

	selectWindow("nuclei");
	run("Median...", "radius=" + radius);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
		
	run("Analyze Particles...", "size=" + min_size + "-Infinity add");
	roiManager("Show None");
	
	numberOfNuclei = roiManager("count");
	for(j=0; j<numberOfNuclei; j++){
		roiManager("Select", j);
		
		// NOTE: I was suuuper lazy - the only thing I changed from previous is that I now only rescale the boundary to not contain membrane band.
		run("Enlarge...", "enlarge=-" + band_size);
		roiManager("Update");
	}
	
	run("Set Measurements...", "mean display redirect=None decimal=3");
	selectWindow("signal");
	
	
	for(k=0; k<numberOfNuclei; k++){
		roiManager("Select", k);
		roiManager("Measure");	
	}
	
	// Saved as nucleus_{image_title}.xls
	saveAs("Results", results_path + "nucleus_" + title + ".xls");
	run("Close All");
	
}

// TASK 3 - same as task 2 but create band outside membrane instead and analyse channel 3 (microtubules/magenta)
band_size = getNumber("Set Band Size", 20);
for (i = 0; i < fileList.length; i++) {
	roiManager("reset");
	run("Clear Results");
	
	open(input_path+fileList[i]);
	
	ImageID = getTitle();
	title = substring(ImageID,0,lengthOf(ImageID)-4);
	
	run("Split Channels");
	selectWindow("C1-"+ImageID);
	rename("nuclei");
	selectWindow("C2-"+ImageID);
	rename("signal");
	// Now we are also interested in magenta channel
	selectWindow("C3-"+ImageID);
	rename("microtubules");
	
	// Same as task 1 and 2
	selectWindow("nuclei");
	run("Median...", "radius=" + radius);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
		
	run("Analyze Particles...", "size=" + min_size + "-Infinity add");
	roiManager("Show None");
	
	numberOfNuclei = roiManager("count");
	for(j=0; j<numberOfNuclei; j++){
		roiManager("Select", j);
		// Now we are interested in band outside membrane instead 
		run("Make Band...", "band=" + band_size);
		roiManager("Update");
	}
	
	run("Set Measurements...", "mean display redirect=None decimal=3");
	
	// Measure intensity in microtubules window
	selectWindow("microtubules");
	
	for(k=0; k<numberOfNuclei; k++){
		roiManager("Select", k);
		roiManager("Measure");	
	}
	// Saved as microtubules_{image_title}.xls
	saveAs("Results", results_path + "microtubules_" + title + ".xls");
	run("Close All");
	
}

// TASK 4 - want to compute ratio of task 1 and task 2 intensities 
band_size = getNumber("Set Band Size", 10);
for (i = 0; i < fileList.length; i++) {
	roiManager("reset");
	run("Clear Results");
	
	open(input_path+fileList[i]);

	ImageID = getTitle();
	title = substring(ImageID,0,lengthOf(ImageID)-4);title = substring(ImageID,0,lengthOf(ImageID)-4);
	
	// This part is same as task 1 and 2
	run("Split Channels");
	selectWindow("C1-"+ImageID);
	rename("nuclei");
	selectWindow("C2-"+ImageID);
	rename("signal");
	
	selectWindow("nuclei");
	run("Median...", "radius=" + radius);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
		
	run("Analyze Particles...", "size=" + min_size + "-Infinity add"); 
	run("Clear Results");
	
	numberOfNuclei = roiManager("count");
	selectWindow("signal");
	
	for(j=0; j<numberOfNuclei; j++){
		roiManager("Select", j);
		// Deselect membrane (rescale to not contain band) as in task 2
		run("Enlarge...", "enlarge=-" + band_size);
		// Get the statistics of the nucleus - mean intensity nucleus is saved as meanNuclei
		getStatistics(area, meanNuclei, min, max, std, histogram); 
		
		// Make band as in task 1
		run("Make Band...", "band=" + band_size);
		roiManager("Update");
		
		// Get statistics of the band - mean intensity membrane is saved as meanNucRim
		getStatistics(area, meanNucRim, min, max, std, histogram); 
		
		// Make results with columns: title, mean intensity nucleus, mean intensity membrane
		setResult("image", nResults, title);
		setResult("mean Int nuclei", nResults-1, meanNuclei);
		setResult("mean Int nuclear membrane", nResults-1, meanNucRim);
		// Calculate ratio membrane/nucleus mean intensity and save as separate column
		ratio = meanNucRim / meanNuclei;
		setResult("ratio", nResults-1, ratio);
		// Also add the nucleus size
		setResult("minimum size nuclei", nResults-1, min_size);
	}
	updateResults();
	
	// Saved as ratio_{image_title}.xls
	saveAs("Results", results_path + "ratio_"+title+".xls");
	run("Close All");
}



