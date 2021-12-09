function [g, h, node_sizes, node_colors] = replotGraph(res,color_vals,labels_arr,titleText,displayEmbed,useLayout,save_plot)
% Function replotGraph
% Reproduce a mapper graph from stored struct
% Inputs:
% res           -- a struct containing the following variables from
%                   neumapper:
%                   - filter_X
%                   - smallBinPruned
%                   - graph, or adja_pruned if graph is not available
% color_vals    -- an array containing categorical labels for each data
%                  point
% titleText     -- Figure caption
% displayEmbed  -- Boolean flag. True displays the embedding of the data

% Thanks to Oliver Xie for suggesting the logarithmic mapping for the node
% sizes

if ~exist('titleText','var')
    titleText = res.filename;
end

if ~exist('displayEmbed','var')
    displayEmbed = 0;
end

if ~exist('useLayout','var')
   useLayout = 'force';
end

% either 0/1,true/false, or filename for saving
if ~exist('save_plot','var')
    save_plot = 0;
elseif save_plot & ~ischar(save_plot) & ~isstring(save_plot)
    if isfield(res.options, 'save_to')
       [save_path,save_name] = fileparts(res.options.save_to);
    else
       [save_path,save_name] = fileparts(res.filename); 
    end
    save_plot = fullfile(save_path,strcat('plotGraph_',save_name,'.png'));
end


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
% timing_colors = [0 0 1; 0.078 1 0.2275; 1 1 0; 0.9290 0.6940 0.1250; 1 0 0]; %blue, green, yellow, orange, red

% As used by Dyneusr
% timing_colors = [44/255 18/255 245/255; 117/255 250/255 75/255; 249/255 231/255 91/255; 240/255 156/255 57/255; 235/255 51/255 38/255]; %blue, green, yellow, orange, red 
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

    %disp([unique_colors, timing_colors])
end

% quick hack to accept continuous valued colors
if ~all(any(unique_colors == 1:num_timing_colors)) 
    color_vals = discretize(color_vals, num_timing_colors);
end 

% finish mapping colors
for n = 1:1:length(filter_X) %length(color_vals)
    cmap_timing(n,:) = timing_colors(color_vals(n),:);
end

% process labels, if available
legend_groups =           1:num_timing_colors;
legend_labels = num2cell(1:num_timing_colors); 
if numel(unique(labels_arr)) == numel(unique(color_vals))
    legend_data = table();
    legend_data.groups = unique(color_vals,'rows','stable');
    legend_data.labels = unique(labels_arr,'rows','stable');
    legend_data.Row = string(legend_data.groups);
    legend_data = legend_data(sort(legend_data.Row),:);
    % get sorted (and aligned) groups, labels
    legend_groups = legend_data.groups;
    legend_labels = legend_data.labels;
end
    


%% Plot images
if displayEmbed
    
    % TODO: handle special case when filter_X has more than 3 dimensions
    if size(filter_X,2) > 3
        
        fig = figure('Position', [0 0 1000 400]);

        % plot embedding
        subplot(1,3,1)
        plot_embedding_heatmap(filter_X,cmap_timing);
          
        % plot mapper graph
        subplot(1,3,2)
        [h, node_sizes, node_colors] = plot_mapper(g, smallBins, cmap_timing, useLayout);

        % plot colors only (need this so we can show the timing labels)
        subplot(1,3,3)
        plot_embedding(color_vals,cmap_timing);

        % show colorbar next to embedding
        cmap = colormap(timing_colors); 
        cbar = colorbar;
        cbar.TickLabelInterpreter = 'none';
        cbar.Ticks = linspace(0, 1, numel(legend_labels));
        cbar.TickLabels = legend_labels';
     
    else
        
        fig = figure('Position', [0 0 1000 400]);
               
        % plot embedding
        subplot(1,3,1)
        plot_embedding(filter_X,cmap_timing);
       
        % plot mapper graph
        subplot(1,3,2)
        [h, node_sizes, node_colors] = plot_mapper(g, smallBins, cmap_timing, useLayout);
    
        % plot colors only (need this so we can show the timing labels)
        subplot(1,3,3)
        plot_embedding(color_vals,cmap_timing);

        % show colorbar next to embedding
        cmap = colormap(timing_colors); 
        cbar = colorbar;
        cbar.TickLabelInterpreter = 'none';
        cbar.Ticks = linspace(0, 1, numel(legend_labels));
        cbar.TickLabels = legend_labels';

    end 
    
       
else

    fig = figure('Position', [0 0 800 400], 'visible', 'off');    
    [h, node_sizes, node_colors] = plot_mapper(g, smallBins, cmap_timing, useLayout);
    
    % show colorbar next to the graph
    cmap = colormap(timing_colors); 
    cbar = colorbar;
    cbar.TickLabelInterpreter = 'none';
    cbar.Ticks = linspace(0, 1, numel(legend_labels));
    cbar.TickLabels = legend_labels';
   
end

sgtitle(titleText, 'Interpreter', 'none');


% 9.9.2020 TODO make sure this works with parpool
if ischar(save_plot) | isstring(save_plot)
    saveas(fig, save_plot);
    close(fig);
end

end


%% Helper functions

function plot_embedding(filter_X, cmap_timing)

    if size(filter_X,2) == 2
        
        % 2d scatter plot
        h = scatter(filter_X(:,1), filter_X(:,2),[], cmap_timing, 'filled');
        ax = get(h,'Parent');   % only keep tick labels at bounds and zeros
        xtick = get(ax,'XTick');
        ytick = get(ax,'YTick');
        set(ax,'XTick',sort(unique([xtick(1), 0, xtick(end)])));
        set(ax,'YTick',sort(unique([ytick(1), 0, ytick(end)])));
        xlabel('Filter 1', 'interpreter', 'none');
        ylabel('Filter 2', 'interpreter', 'none');
        
    elseif size(filter_X,2) == 3

        % 3d scatter plot
        h = scatter3(filter_X(:,1), filter_X(:,2), filter_X(:,3), [], cmap_timing, 'filled');
        ax = get(h,'Parent');   % only keep tick labels at bounds and zeros
        xtick = get(ax,'XTick');
        ytick = get(ax,'YTick');
        ztick = get(ax,'ZTick');
        set(ax,'XTick',sort(unique([xtick(1), 0, xtick(end)])));
        set(ax,'YTick',sort(unique([ytick(1), 0, ytick(end)])));
        set(ax,'ZTick',sort(unique([ztick(1), 0, ztick(end)])));
        xlabel('Filter 1', 'interpreter', 'none');
        ylabel('Filter 2', 'interpreter', 'none');
        zlabel('Filter 3', 'interpreter', 'none');

    elseif size(filter_X,2) > 3
        
        % heatmap (TODO: rugplot?)
        h = imagesc(filter_X);
        xlabel('Filters', 'interpreter', 'none');
        ylabel('Time frames (TR)', 'interpreter', 'none');
        cmap = colormap('turbo');
        cbar = colorbar;
         
    else
        
        % 1d scatter plot (hack to match heatmaps, plot top to bottom)
        h = scatter(filter_X(:,1), -[1:1:size(filter_X,1)], [], cmap_timing, 'filled');
        ax = get(h,'Parent');   % only keep tick labels at bounds and zeros
        
        % fix xtick lables
        xtick = get(ax,'XTick');
        xtick = sort(unique([xtick(1), 0, xtick(end)]));
        if numel(unique(filter_X(:,1))) < 10
            xtick = unique(filter_X(:,1));
        end
        set(ax,'XTick',xtick);
        
        % simulate TR labels (plot from top to bottom)
        set(ax, 'YLim',[-size(filter_X,1), 0]);
        ytick = get(ax,'YTick');
        %ytick = sort(unique([ytick, -size(filter_X,1)]));
        set(ax,'YTick', ytick);
        set(ax,'YTickLabels',abs(ytick(1:1:end)));
        ylabel('Time frames (TR)', 'interpreter', 'none');

    end
    
    %set(gcf,'Color','none');
    %set(gca,'Color','none');
    axis square;

end

function plot_embedding_heatmap(filter_X, cmap_timing)

    % heatmap (TODO: rugplot?)
    h = imagesc(filter_X);
    xlabel('Filters', 'interpreter', 'none');
    ylabel('Time frames (TR)', 'interpreter', 'none');
    cmap = colormap('turbo');
    cbar = colorbar;
    
    %set(gcf,'Color','none');
    %set(gca,'Color','none');
    axis square;

end


function [h, node_sizes, node_colors] = plot_mapper(g, smallBins, cmap_timing, useLayout)

if ~exist('useLayout','var')
  useLayout = 'force';
end

nodes = g.Nodes;
nn    = size(nodes,1);

node_colors = zeros(nn,3);

%% create a scaling parameter for the node sizes
smallBin_sizes = cellfun('size',smallBins,2);
%max_size = max(smallBin_sizes);
%node_sizes = 5+log(1+smallBin_sizes);
node_sizes = 1+log(1+smallBin_sizes);

%% Plot the graph and highlight nodes
for ii = 1:nn
    node_colors(ii,:) = mean(cmap_timing(smallBins{ii},:),1);
end

h = plot(g,'Layout', useLayout,'NodeLabel',{});
if strcmp(useLayout,'force') || strcmp(useLayout,'force3')
    layout(h,useLayout,'UseGravity',true,'WeightEffect','none');
end

h.MarkerSize = node_sizes;
h.NodeColor = node_colors;
h.EdgeColor = [0 0 0];
h.LineWidth = 1;

axis equal;
if strcmp(useLayout,'force3')
  view(gca, [-30, 15.0]);
else
  set(gca,'Visible','off');
end

end




