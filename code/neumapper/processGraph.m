function [g, node_sizes, node_colors] = processGraph(res,color_vals)
% Return a graph, and node sizes and colors (modified from replotGraph.m)
% res           -- a struct containing the following variables from
%                   neumapper:
%                   - filter_X
%                   - smallBinPruned
%                   - graph, or adja_pruned if graph is not available
% color_vals    -- an array containing categorical labels for each data
%                  point



%% Extract necessary inputs from struct
filter_X    = res.filter_X;
smallBins   = res.smallBinPruned;

if isfield(res,'graph')
    g = res.graph;
elseif isfield(res,'adja_pruned')
    adja        = res.adja_pruned;
    g = graph(adja);
else
    error('Did not find graph information in input')
end



%% Set up colors for plotting
% Output:
% cmap_timing   -- an array coloring each data point according to the
% categorical labels provided in color_vals. Here we write "timing" because
% the labels often correspond to task labels, and the data points are
% coming from time series data in a continuous multitask experiment

cmap_timing = zeros(size(filter_X,1),3);
%timing_colors = [0 0 1; 0.078 1 0.2275; 1 1 0; 0.9290 0.6940 0.1250; 1 0 0]; %blue, green, yellow, orange, red
timing_colors = [44/255 18/255 245/255; 117/255 250/255 75/255; 249/255 231/255 91/255; 240/255 156/255 57/255; 235/255 51/255 38/255]; %blue, green, yellow, orange, red 

unique_colors = unique(color_vals, 'rows');
num_timing_colors = size(timing_colors,1);

% changes for non-CME timing labels 
if numel(unique_colors) ~= 5        % default behavior for CME
    
	% encode non-continuous values (e.g., 1,2,9 => 1,2,3)
    if any(diff(unique_colors) > 1)
    	[rows_,color_enc_] = find(color_vals==transpose(unique_colors));  
    	color_vals(rows_) = color_enc_;
    end
    
    % now get unique encoded values
    unique_colors = unique(color_vals, 'rows');

    % optimize colormap 
    num_timing_colors = numel(unique_colors);
    timing_colors = turbo(num_timing_colors+2);
    timing_colors = timing_colors(2:end-1,  :);     % drop darker end colors
    
end

% quick hack to accept continuous valued colors
if ~all(any(unique_colors == 1:num_timing_colors)) 
    color_vals = discretize(color_vals, num_timing_colors);
end 

% finish mapping colors
for n = 1:1:length(filter_X) %length(color_vals)
    cmap_timing(n,:) = timing_colors(color_vals(n),:);
end


%% get node sizes, colors
nodes = g.Nodes;
nn    = size(nodes,1);
node_colors = zeros(nn,3);

%% create a scaling parameter for the node sizes
smallBin_sizes = cellfun('size',smallBins,2);
%node_sizes = 5+log(1+smallBin_sizes);
node_sizes = 1+log(1+smallBin_sizes);

%% Compute node color as the mean color over members
for ii = 1:nn
    node_colors(ii,:) = mean(cmap_timing(smallBins{ii},:),1);
end


end




