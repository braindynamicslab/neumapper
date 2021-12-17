function h = plot_mapper_graph(res)
% Function plot_mapper_graph
% 
% Inputs:
% res       : struct containing several field. 
%       - filter_X          : first few coordinates of data   
%       - adjacency         : mapper graph adjacency matrix
%       - pts_in_clusterBins: points in mapper graph nodes
%       - labels            : (num_obs,1) vector of data point labels.
%                               Labels are expected to be integers 1,2,...
% 
% Outputs:
% h         : Figure handle

g = graph(res.adjacency);

%% Set up colors for plotting
cmap_timing = zeros(size(res.filter_X,1),3);
color_vals = res.labels;
unique_colors = unique(color_vals, 'rows');

% optimize colormap 
num_timing_colors = numel(unique_colors);
timing_colors = turbo(num_timing_colors+2);
timing_colors = timing_colors(2:end-1,  :);     % drop darker end colors

% finish mapping colors
for n = 1:1:length(res.filter_X) %length(color_vals)
    cmap_timing(n,:) = timing_colors(color_vals(n),:);
end

fig = figure('Position', [0 0 1000 400]);
% plot embedding
subplot(1,2,1)
plot_embedding(res.filter_X,cmap_timing);

% plot mapper graph
subplot(1,2,2)
[h, node_sizes, node_colors] = plot_mapper(g, res.pts_in_clusterBins, cmap_timing, 'force');
    
        
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