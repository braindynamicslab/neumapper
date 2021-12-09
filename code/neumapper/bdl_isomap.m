function [embed_X, mapping] = bdl_isomap(distMat,dim_embed,num_k,pknng)
% Function bdl_isomap

% Two key procedural differences between this code and van der Maaten's
% isomap.m:
% -- this code builds a penalized knn graph, instead of a standard knn
% graph
% -- if there are multiple components in the knn graph, connections are
% forced to produce a single component. In contrast, van der Maaten's
% isomap will retain only the largest component and drop the others

% Input: 
% distMat   -- distances computed on Dataset.
% num_k     -- k parameter for knn graph 
% dim_embed -- embedding dimension
% pknng     -- use weighted PKNNG


% Output: 
% embed_X   -- data matrix embedded in dim_embed dimensions
% mapping   -- struct containing knn graph and geodesic distances




% Build distance matrix from X (default is Euclidean)
%if nargin < 5
%    dist = 'euclidean'; 
%end
%
%distMat = pdist2(X,X,dist);

% create penalized knn graph
% slight change here from bdl_isomap_v0 to current version: now using the
% binary adjacency matrix instead of the weighted adj matrix for more
% interpretability
%
% nevermind, this is now an option as of September 27, 2019
%
[~,~,~,knn_g_bin,knn_g_wtd] = createPKNNG(distMat, num_k);
if ~pknng    
    knn_g = graph(knn_g_bin);   % build graph from binary adj matrix
else
    knn_g = graph(knn_g_wtd);   % build graph from weighted adj matrix
end

% estimate geodesic distances
%dist_geo_bin = round(distances(knn_g_bin,'Method','positive'));
%dist_geo_wtd = round(distances(knn_g_wtd,'Method','positive'));
%dist_geo_wtd = round(distances(knn_g_bin));


%dist_geo = round(distances(knn_g,'Method','positive')); %edited 10/22/2019
dist_geo = knn_g.distances;

% symmetrize to prevent rounding error 
dist_geo = (dist_geo + dist_geo')/2;

% set mapping
mapping.graph       = knn_g;
mapping.graphDist   = dist_geo;

% embed using cmdscale
[y,E] = cmdscale(dist_geo);

mapping.mdsEvals    = E;

% get embedding in dimensions specified by dim_embed

%embed_X = y(:,1:3);

embed_X = y(:,1:dim_embed);

%maxerr = max(max(abs(distMat - pdist2(embed_X,embed_X))))


end

