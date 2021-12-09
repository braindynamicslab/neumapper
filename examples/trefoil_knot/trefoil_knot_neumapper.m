%% Configure paths
addpath(genpath('~/neumapper/code/neumapper'));
addpath(genpath('~/neumapper/code/tools'));


%% Load the data
X = create_trefoil_knot(1000,'euclidean');


%% Configure options
options = struct();
options.binning = 'cball';
options.dimreduce = 'none';
options.resolution = 100;
options.knnparam = 8;
options.gain = 40;

options.save_to = 'trefoil_knot_neumapper.mat';
options.save_plot = 'trefoil_knot_neumapper.png';
options.show_plot = true;
options.show_embed = true;


%% Run NeuMapper
res = neumapper(X, options);