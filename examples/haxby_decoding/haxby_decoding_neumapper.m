%% Configure paths
addpath(genpath('~/neumapper/code/neumapper'));
addpath(genpath('~/neumapper/code/dimReducMethods'));
addpath(genpath('~/neumapper/code/tools'));


%% Load the data
X = readNPY('SBJ02_mask_vt.npy');
timing = readtable('SBJ02_timing_labels.tsv','FileType','text','Delimiter','\t');
colors = timing.task;
labels = string(timing.task_name);


%% Configure options
options = struct();
options.binning = 'ball';
options.dimreduce = 'bdl_isomap';
options.dim_embed = 3;
options.resolution = 240;
options.knnparam = 50;
options.gain = 40;

options.dXtype = 'correlation';
options.dXgeod = false;
options.dfXtype = 'cityblock';
options.dfXgeod = true;

options.save_to = 'haxby_decoding_neumapper.mat';
options.save_plot = 'haxby_decoding_neumapper.png';
options.show_plot = true;
options.show_embed = true;
options.colors = colors;
options.labels = labels;


%% Run NeuMapper
res = neumapper(X, options);