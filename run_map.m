%% --- GEOSPATIAL MAPPING SCRIPT ---
clear; clc; close all;

disp('1. Loading your saved pipeline results...');
% This loads the file we created earlier, which contains your 
% final 'ctmfScore' and your thresholded 'binaryMask'
load('proposed_results.mat'); 

disp('2. Feeding the data into the mapping function...');
% We pass the score map and the hotspot mask directly into your function
map_geospatial_overlay(ctmfScore, binaryMask);

disp('3. Success! Your satellite map is generating...');