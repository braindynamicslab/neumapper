%% Configure paths
addpath(genpath('../../code/'));


%% Load the data
X = create_trefoil_knot(1000,'euclidean');


%% Use default options
options = struct();
options.resolution = 40;


%% Run NeuMapper
res = neumapper(X, options);


%% Save outputs
save('trefoil_knot_neumapper.mat','res');
saveas(gcf, 'trefoil_knot_neumapper.png');
