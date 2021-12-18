%% Configure paths
addpath(genpath('../../code/'));


%% Load the data
X = create_trefoil_knot(1000,'euclidean');


%% Use default options
options = struct();


%% Run NeuMapper
res = neumapper(X, options);