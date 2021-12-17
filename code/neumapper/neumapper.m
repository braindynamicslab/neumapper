function [res,h] = neumapper(X,options)
% Function neumapper
% authors: Samir Chowdhury, Caleb Geniesse, Manish Saggar
% 
% Inputs:
% X : (num_obs, num_features) data matrix.
%     Although not a requirement, NeuMapper is best used for data
%     with num_features > 5
% options : struct containing several parameters.
%       - metric     : 'euclidean', 'cityblock', etc (see choices for pdist)    
%       - k          : int, parameter for reciprocal nearest neighbor graphs
%       - resolution : int, resolution parameter used during farthest point sampling
%       - gain       : int, gain parameter used when building cover bins
%       - labels     : (num_obs,1) vector of data point labels
% 
% Outputs:
% res : struct containing the NeuMapper graph.
% h   : figure handle 

%% Set up options
if ~isfield(options,'metric')
    options.metric = 'cityblock'; % Default to Euclidean
end

if ~isfield(options,'k')
    options.k = 12; 
end

if ~isfield(options,'resolution')
    options.resolution = floor(0.25*size(X,1)); 
end

if ~isfield(options,'gain')
    options.gain = 50; 
end

if options.gain < 25
    fprintf('Gain should be at least 25, updating\n')
    options.gain = 25;
end

if ~isfield(options,'labels')
    options.labels = (1:size(X,1))'; 
end


%% Generate initial distance matrix
    
dX = pdist2(X,X,options.metric);
dX = (dX+dX')/2; % force symmetrization to avoid round-off errors

%% Generate rkNN graph
g = get_rknn(X,options);


%% Obtain cover and cluster bins
coverBins = get_cover_bins(g,options.resolution,options.gain);
pts_in_coverBins = cellfun(@find,num2cell(coverBins,2),'UniformOutput',false);

[pts_in_clusterBins, clusterBins] = get_cluster_bins(pts_in_coverBins,dX);

%% Construct mapper graph

[adjacency, clusterBins, pts_in_clusterBins] = get_mapper_graph(clusterBins);

res = struct;

max_dim_to_store        = min(size(X,2),3); % Store only up to 3 columns of data
res.filter_X            = X(:,1:max_dim_to_store);
res.clusterBins         = clusterBins;
res.pts_in_clusterBins  = pts_in_clusterBins;
res.adjacency           = adjacency;
res.labels              = options.labels;
res.options             = options;

h = plot_mapper_graph(res);

end

