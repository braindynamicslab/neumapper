%% Configure paths
addpath(genpath('~/neumapper/code/'));


%% Load the data
X = readNPY('SBJ02_mask_vt.npy');
timing = readtable('SBJ02_timing_labels.tsv','FileType','text','Delimiter','\t');
colors = timing.task;
labels = string(timing.task_name);


%% Configure options
options = struct();
options.metric = 'correlation';
options.k = 30;
options.resolution = 400;
options.gain = 40;
options.labels = timing.task + 1; %reindex to start from 1


%% Run NeuMapper
[c,X_] = pca(X,'NumComponents',50); % Preprocess with PCA
res = neumapper(X_, options);