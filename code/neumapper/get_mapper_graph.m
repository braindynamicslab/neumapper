function [adjacency, memberMat, pts_in_clusterBins] = get_mapper_graph(memberMat)
% Function get_mapper_graph
% 
% Inputs:
% memberMat      : membership matrix of cluster bins
% 
% Outputs:
% adjacency      : adjacency matrix of Mapper graph
% memberMat      : cluster bin membership matrix; identical rows removed
% pts_in_clusterBins : points in cluster bins with identical bins removed
% 


%% Find identical rows
memberMat = unique(memberMat,'rows');

%% Create weighted adjacency matrix
n = size(memberMat,1);

adjacency = double(memberMat) * double(memberMat)' ; 
adjacency = adjacency .* (1-eye(n));               % zero-out diagonal

pts_in_clusterBins = cellfun(@find,num2cell(memberMat,2),'UniformOutput',false);

end