function res = neumapper(X,options)
% Function neumapper
% authors: Samir Chowdhury, Caleb Geniesse, Manish Saggar
% 
% Inputs:
% (0) X is the data (rows are observations, columns are variables)
% (1) options contains the different parameters 

% Notes on input options:
% - An important idea in Mapper is that there are two metric spaces
% involved: (X,dX) and (fX,dfX). Here X is the original data, and is the
% only object supplied to the user. 

% - The user chooses dX, the metric with
% which to endow the original data. Choices include: lp-metrics,
% correlation, cosine, etc. For each of these choices, the user can 
% additionally choose to build a knn-graph to approximate 
% geodesic distances. 
% - The choice of dX is necessary in the partial clustering step, which
% happens at the level of (X,dX).

% - The user chooses how to obtain fX, which is a "filtered" version of the
% data. One method would be to apply a dimension reduction technique to X
% to get fX.

% - Finally, the user chooses dfX, the metric on the filtered data. The
% choices here are the same as those encountered when choosing dX. 
% - The choice of dfX is necessary in the binning stage. 

% Choices of dXtype/dfXtype:

    % 'euclidean'        - Euclidean distance (default)
    % 'squaredeuclidean' - Squared Euclidean distance
    % 'seuclidean'       - Standardized Euclidean distance. Each
    %                      coordinate difference between rows in X and Y
    %                      is scaled by dividing by the corresponding
    %                      element of the standard deviation computed
    %                      from X, S=NANSTD(X). To specify another value
    %                      for S, use
    %                      D = pdist2(X,Y,'seuclidean',S).
    % 'cityblock'        - City Block distance
    % 'minkowski'        - Minkowski distance. The default exponent is 2.
    %                      To specify a different exponent, use
    %                      D = pdist2(X,Y,'minkowski',P), where the
    %                      exponent P is a scalar positive value.
    % 'chebychev'        - Chebychev distance (maximum coordinate
    %                      difference)
    % 'mahalanobis'      - Mahalanobis distance, using the sample
    %                      covariance of X as computed by NANCOV.  To
    %                      compute the distance with a different
    %                      covariance, use
    %                      D = pdist2(X,Y,'mahalanobis',C), where the
    %                      matrix C is symmetric and positive definite.
    % 'cosine'           - One minus the cosine of the included angle
    %                      between observations (treated as vectors)
    % 'correlation'      - One minus the sample linear correlation
    %                      between observations (treated as sequences of
    %                      values).
    % 'spearman'         - One minus the sample Spearman's rank
    %                      correlation between observations (treated as
    %                      sequences of values)
    % 'hamming'          - Hamming distance, percentage of coordinates
    %                      that differ
    % 'jaccard'          - One minus the Jaccard coefficient, the
    %                      percentage of nonzero coordinates that differ


% Implementation notes:
% (0) Start with dataset X (rows are observations, columns are variables). 
% A distance matrix is needed for clustering, although this condition can 
% be relaxed (ask Samir)

% (1) Optionally perform dimension reduction (see (2a) below).

% (2) Define a filter function on the data. Here are some ways to do this:
% (2a) Dimension filtration: embed the data into a lower dimensional space,
% e.g. 2d space, and then compose the dimension reduction with the identity
% function. The composed map has the form X --> R^2.
% -- this can be viewed as time x space


% (3) First partitioning step/"big" binning: Use a cover of the codomain to
% obtain a relaxed partition of (the rows of) X into bigBins. Each row of X
% can belong to multiple bigBins. Here a "relaxed" partition means that
% overlaps are allowed. 
% -- the resolution and gain parameters are used here


% (4) Second partitioning step/"small" binning: for each bigBin, restrict
% the distance matrix and do some clustering step to obtain a refined (but
% still relaxed) partition into smallBins. Each row of X can belong to
% multiple smallBins
% -- the pcparam parameter is used here

% (*) Pruning step: if two smallBins are identical, remove one of them

% (5) Graph creation: 
% (5a) Nodes are rows
% (5b) Two nodes form an edge if they belong to the same smallBin
% (5c) Color by the colors parameter


%% Obtain options. If a parameter is missing, switch to a default value.

filename    = getoptions(options,'filename','Unspecified data');
dimreduce   = getoptions(options,'dimreduce','none');    % 'bdl_isomap'
filter      = getoptions(options,'filter','identity');
binning     = getoptions(options,'binning','cball');     % 'Nd'
resolution  = getoptions(options,'resolution',nan);
gain        = getoptions(options,'gain',nan);
clustering  = getoptions(options,'clustering','sl_histo');
colors      = getoptions(options,'colors', X(:,1));
labels      = getoptions(options,'labels', []);
lens        = getoptions(options,'lens', []);

save_to     = getoptions(options,'save_to',['res_',filename]);

% 9.30.2020 plotting options to save memory and speed up
low_mem    = getoptions(options,'low_mem',true);
plot_graph = getoptions(options,'plot_graph',true);
show_embed = getoptions(options,'show_embed',true);
use_layout = getoptions(options,'use_layout','force');
save_plot  = getoptions(options,'save_plot',false);

% Options for metrics
dXtype      = getoptions(options,'dXtype','euclidean');
dXgeod      = getoptions(options,'dXgeod',true);
dfXtype     = getoptions(options,'dfXtype','euclidean');
dfXgeod     = getoptions(options,'dfXgeod',true);
pknng       = getoptions(options,'pknng',true);


% Parameters for dimension reduction techniques
num_k       = getoptions(options,'knnparam',nan);
maxiter     = getoptions(options,'maxiter',200);
perplexity  = getoptions(options,'perplexity',30);
dim_embed   = getoptions(options,'dim_embed',2);

% If clustering using 'sl_histo', specify number of bins for histogram
sl_histo_bins = getoptions(options,'sl_histo_bins',10);


% New options for preprocessing
preprocess   = getoptions(options,'preprocess','none'); 
initial_dims = getoptions(options,'initial_dims', size(X,2));
if (initial_dims < 1) || isnan(initial_dims)
    initial_dims = size(X,2);
end

lens_preprocess   = getoptions(options,'lens_preprocess','none'); 
lens_initial_dims = getoptions(options,'lens_initial_dims', size(lens,2));
if (lens_initial_dims < 1) || isnan(lens_initial_dims)
    lens_initial_dims = max([size(lens,2),initial_dims]);
end



%% Preprocess data (output will be used for partial clustering)
% Output: a preprocessed version of X, with dim_init

switch preprocess
        
    case 'none'
        disp('No preprocessing')
        preprocessed_X = X;
        
    case 'MDS'
        disp('Performing MDS')
        preprocessed_X = compute_mapping(X,preprocess,initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);  
        
    case 'nMDS'
        % compute distance matrix based on input X
        metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
        metric_options.dXgeod       = getoptions(options,'dXgeod',false);
        metric_options.knnparam     = getoptions(options,'knnparam',6);
        metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?
        dX_input = buildDist(X,metric_options);

        disp('Performing non-metric MDS')
        % remove dimension reduction path; force matlab to use pca from
        % stats toolbox (this is a subroutine in mdscale)
        rmpath(genpath('../../dimReducMethods/'));
        preprocessed_X = mdscale(dX_input, initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims); 
        
    case 'PCA'
        disp('Performing PCA')
        preprocessed_X = compute_mapping(X,preprocess,initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
    case 'DiffusionMaps'
        disp('Performing diffusion map embedding')
        preprocessed_X = compute_mapping(X,preprocess,initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
    case 'ManifoldChart'
        disp('Performing manifold charting')
        preprocessed_X = compute_mapping(X,preprocess,initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        

 
%   Methods using k nearest neighbors 
        
    case 'bdl_isomap'
        
        % compute distance matrix based on input X
        metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
        metric_options.dXgeod       = getoptions(options,'dXgeod',false);
        metric_options.knnparam     = getoptions(options,'knnparam',6);
        metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?
        dX_input = buildDist(X,metric_options);

        fprintf(1,'Performing bdl_isomap with %d nearest neighbors \n',num_k)
        preprocessed_X = bdl_isomap(dX_input,initial_dims,num_k,pknng); % Oct 8, 2019
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
    case 'Isomap'
        fprintf(1,'Performing Isomap with %d nearest neighbors \n',num_k)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,num_k);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
    case 'LLE'
        fprintf(1,'Performing locally linear embedding with %d nearest neighbors \n',num_k)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,num_k);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
  
    case 'HessianLLE'
        fprintf(1,'Performing Hessian locally linear embedding with %d nearest neighbors \n',num_k)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,num_k);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);

    case 'Laplacian'
        fprintf(1,'Performing Laplacian eigenmap embedding with %d nearest neighbors \n',num_k)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,num_k);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
 
    case 'LTSA'
        fprintf(1,'Performing local tangent space alignment embedding with %d nearest neighbors \n',num_k)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,num_k);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
 
        
%   Iterative methods

    case 'ProbPCA'
        fprintf(1,'Performing Probabilistic PCA using %d iterations \n',options.maxiter)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,options.maxiter);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
%   SNE-type methods

    case 'SNE'
        fprintf(1,'Performing stochastic neighborhood embedding with perplexity %d \n',perplexity)
        preprocessed_X = compute_mapping(X,preprocess,initial_dims,perplexity);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
    case 'tSNE'
        fprintf(1,'Performing tSNE with perplexity %d \n',perplexity)
        %embed_X = compute_mapping(X,dimreduce,initial_dims,perplexity);
        preprocessed_X = tsne(X, [], initial_dims, size(X,2), perplexity);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
 
%   Trajectory-focused methods
    case 'bdl_corr_isomap'
        % currently this is specialized to the winding trefoil case
        %landmarks = 1:size(X,1);
        landmarks = [200;1500;1800];
        fprintf(1,'Performing bdl_corr_isomap with %d nearest neighbors and %d landmarks \n',num_k,length(landmarks))
        X = X';
        preprocessed_X = bdl_corr_isomap(X,landmarks,num_k, initial_dims);
        fprintf(1,'Data has been preprocessed (initial_dims = %d) \n',initial_dims);
        
        
    otherwise
        error('Did not recognize dimension reduction method')
end








%% Obtain metric at the data level
% Output: distance matrix dX on original data space, eventually 
% used for partial clustering
metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
metric_options.dXgeod       = getoptions(options,'dXgeod',false);
metric_options.knnparam     = getoptions(options,'knnparam',6);
metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?

dX = buildDist(preprocessed_X,metric_options);





%% Prepare lens (i.e., data that will be embedded below)
%
% if user provided a lens, use that for dim reduction
% ... and compute new distance matrix based on the lens

% use preprocessed_X and dX as lens_X and dX_lens
lens_X = preprocessed_X;
dX_lens = dX;

% check for valid lens provided by the user
if ~isempty(lens)

    % use lens as lens_X
    disp('Using lens provided by the user');
    lens_X = lens;

end




%% Preprocess lens (output will be used for dim reduction and binning)
% Output: a preprocessed version of lens_X, with lens_initial_dims

switch lens_preprocess
        
    case 'none'
        disp('No lens preprocessing')
        lens_X = lens_X;
        
    case 'MDS'
        disp('Performing MDS on lens')
        lens_X = compute_mapping(lens_X,lens_preprocess,initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'nMDS'
        % compute distance matrix based on input X
        metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
        metric_options.dXgeod       = getoptions(options,'dXgeod',false);
        metric_options.knnparam     = getoptions(options,'knnparam',6);
        metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?
        dX_lens_input = buildDist(lens_X,metric_options);

        disp('Performing non-metric MDS on lens')
        % remove dimension reduction path; force matlab to use pca from
        % stats toolbox (this is a subroutine in mdscale)
        rmpath(genpath('../../dimReducMethods/'));
        lens_X = mdscale(dX_lens_input, lens_initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'PCA'
        disp('Performing PCA on lens')
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
            
    case 'DiffusionMaps'
        disp('Performing diffusion map embedding on lens')
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'ManifoldChart'
        disp('Performing manifold charting on lens')
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        

 
%   Methods using k nearest neighbors 
        
    case 'bdl_isomap'
        
        % compute distance matrix based on input X
        metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
        metric_options.dXgeod       = getoptions(options,'dXgeod',false);
        metric_options.knnparam     = getoptions(options,'knnparam',6);
        metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?
        dX_lens_input = buildDist(lens_X,metric_options);

        fprintf(1,'Performing bdl_isomap on lens with %d nearest neighbors \n',num_k)
        lens_X = bdl_isomap(dX_lens_input,lens_initial_dims,num_k,pknng); % Oct 8, 2019
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'Isomap'
        fprintf(1,'Performing Isomap on lens with %d nearest neighbors \n',num_k)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,num_k);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'LLE'
        fprintf(1,'Performing locally linear embedding on lens with %d nearest neighbors \n',num_k)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,num_k);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
  
    case 'HessianLLE'
        fprintf(1,'Performing Hessian locally linear embedding on lens with %d nearest neighbors \n',num_k)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,num_k);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  

    case 'Laplacian'
        fprintf(1,'Performing Laplacian eigenmap embedding on lens with %d nearest neighbors \n',num_k)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,num_k);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
 
    case 'LTSA'
        fprintf(1,'Performing local tangent space alignment embedding on lens with %d nearest neighbors \n',num_k)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,num_k);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
 
        
%   Iterative methods

    case 'ProbPCA'
        fprintf(1,'Performing Probabilistic PCA on lens using %d iterations \n',options.maxiter)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,options.maxiter);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
%   SNE-type methods

    case 'SNE'
        fprintf(1,'Performing stochastic neighborhood embedding on lens with perplexity %d \n',perplexity)
        lens_X = compute_mapping(lens_X,lens_preprocess,lens_initial_dims,perplexity);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);  
        
    case 'tSNE'
        fprintf(1,'Performing tSNE on lens with perplexity %d \n',perplexity)
        lens_X = tsne(lens_X, [], lens_initial_dims, size(lens_X,2), perplexity);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);
 
%   Trajectory-focused methods
    case 'bdl_corr_isomap'
        % currently this is specialized to the winding trefoil case
        %landmarks = 1:size(lens_X,1);
        landmarks = [200;1500;1800];
        fprintf(1,'Performing bdl_corr_isomap on lens with %d nearest neighbors and %d landmarks \n',num_k,length(landmarks))
        lens_X = lens_X';
        lens_X = bdl_corr_isomap(lens_X,landmarks,num_k, lens_initial_dims);
        fprintf(1,'Lens has been preprocessed (lens_initial_dims = %d) \n',lens_initial_dims);
        
        
    otherwise
        error('Did not recognize dimension reduction method')
end







%% compute new distance matrix based on the lens (unless no lens or lens_preprocess)
if ~(isempty(lens) && strcmp(lens_preprocess, 'none'))

    disp('Computing distance matrix based on the (preprocessed) lens');
    metric_options.dXtype       = getoptions(options,'dXtype','euclidean');
    metric_options.dXgeod       = getoptions(options,'dXgeod',false);
    metric_options.knnparam     = getoptions(options,'knnparam',6);
    metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?

    dX_lens = buildDist(lens_X,metric_options);

end








%% Dimension reduction
% Output: a low dimensional embedding, stored in embed_X

switch dimreduce
           
    case 'none'
        disp('No dimension reduction')
        embed_X = lens_X;
        
    case 'MDS'
        disp('Performing MDS')
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);  
        
    case 'nMDS'
        disp('Performing non-metric MDS')
        % remove dimension reduction path; force matlab to use pca from
        % stats toolbox (this is a subroutine in mdscale)
        rmpath(genpath('../../dimReducMethods/'));
        embed_X = mdscale(dX_lens, dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed); 
        
    case 'PCA'
        disp('Performing PCA')
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
    case 'DiffusionMaps'
        disp('Performing diffusion map embedding')
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
    case 'ManifoldChart'
        disp('Performing manifold charting')
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        

 
%   Methods using k nearest neighbors 
        
    case 'bdl_isomap'
        fprintf(1,'Performing bdl_isomap with %d nearest neighbors \n',num_k)
        embed_X = bdl_isomap(dX_lens,dim_embed,num_k,pknng); % Oct 8, 2019
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
    case 'Isomap'
        fprintf(1,'Performing Isomap with %d nearest neighbors \n',num_k)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,num_k);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
    case 'LLE'
        fprintf(1,'Performing locally linear embedding with %d nearest neighbors \n',num_k)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,num_k);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
  
    case 'HessianLLE'
        fprintf(1,'Performing Hessian locally linear embedding with %d nearest neighbors \n',num_k)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,num_k);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);

    case 'Laplacian'
        fprintf(1,'Performing Laplacian eigenmap embedding with %d nearest neighbors \n',num_k)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,num_k);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
 
    case 'LTSA'
        fprintf(1,'Performing local tangent space alignment embedding with %d nearest neighbors \n',num_k)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,num_k);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
 
        
%   Iterative methods

    case 'ProbPCA'
        fprintf(1,'Performing Probabilistic PCA using %d iterations \n',options.maxiter)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,options.maxiter);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
%   SNE-type methods

    case 'SNE'
        fprintf(1,'Performing stochastic neighborhood embedding with perplexity %d \n',perplexity)
        embed_X = compute_mapping(lens_X,dimreduce,dim_embed,perplexity);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
    case 'tSNE'
        fprintf(1,'Performing tSNE with perplexity %d \n',perplexity)
        %embed_X = compute_mapping(lens_X,dimreduce,dim_embed,perplexity);
        embed_X = tsne(lens_X, [], dim_embed, size(lens_X,2), perplexity);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
 
%   Trajectory-focused methods
    case 'bdl_corr_isomap'
        % currently this is specialized to the winding trefoil case
        %landmarks = 1:size(lens_X,1);
        landmarks = [200;1500;1800];
        fprintf(1,'Performing bdl_corr_isomap with %d nearest neighbors and %d landmarks \n',num_k,length(landmarks))
        lens_X = lens_X';
        embed_X = bdl_corr_isomap(lens_X,landmarks,num_k, dim_embed);
        fprintf(1,'Data has been embedded into %d dimensions \n',dim_embed);
        
        
    otherwise
        error('Did not recognize dimension reduction method')
end











%% Filter function
% Output: a (possibly lower) dimensional projection, stored in filter_X

switch filter
    case 'identity'
        disp('Using identity filtration')
        
        filter_X = embed_X;
        
    case 'time'
        disp('Incorporating time in the filtration')
        times = linspace(mean(min(embed_X)), mean(max(embed_X)), size(embed_X,1));
        %times = 1:size(embed_X,1);
        filter_X = [embed_X, times'];
        
    otherwise
        error('Did not recognize filter function')
end



%% Obtain metric at the filtered data level
% Output: distance matrix dfX on filtered data space,  
% used for partial clustering
if strcmp(binning, 'ball')
        metric_options.dXtype       = getoptions(options,'dfXtype','euclidean');
        metric_options.dXgeod       = getoptions(options,'dfXgeod',false);
        metric_options.knnparam     = getoptions(options,'knnparam',6);
        metric_options.pknng        = getoptions(options,'pknng',true); % TODO: should we accept dXpknng, dfXpknng ?
        
        disp('Computing dfX')
        dfX = buildDist(filter_X,metric_options);
end




%% Binning: first pass 
% Output: a cell array called pts_in_bigBin that comprises bins with 
% indices of observations in each bin

switch binning
    case 'Nd'
        disp('Using Nd binning')
        
        nsides = getoptions(options, 'nsides', 4);
        pts_in_bigBin = bdl_binning(filter_X, resolution, gain, nsides);
        fprintf(1,'First binning stage produced %d bigBins \n', ...
            length(pts_in_bigBin));
               
    case 'ball'
        disp('Using ball mapper')
        
        [pts_in_bigBin, ~] = ballMapper(dfX, options);
        
    case 'cball'
        disp('Using connected ball mapper with fixed values')
        [pts_in_smallBin, pts_in_bigBin, hrfdurstat] = cbMapper(filter_X,dX,options);
        
%         if ~isnan(resolution) && ~isnan(gain) && ~isnan(num_k)
%             disp('Using connected ball mapper with fixed values')
%             [pts_in_smallBin, pts_in_bigBin, hrfdurstat] = cbMapper(filter_X,dX,options);
%         else
%             disp('Using connected ball mapper with optimization')
%             [pts_in_smallBin, pts_in_bigBin, rkg, hrfdurstats] = optim_cbMapper(filter_X,dX,options);
%         end
        
    otherwise
        error('Did not recognize binning strategy')
end

%% Binning: second pass//partial clustering
% Output: a refined cell array called pts_in_smallBin comprising of bins 
% with indices of observations in each bin

if ~exist('pts_in_smallBin','var')

switch clustering
    case 'sl_histo'
        disp('Partial clustering with single linkage and histograms')
        pts_in_smallBin = pc_sl_hist(pts_in_bigBin,dX, ...
                            sl_histo_bins);
    case 'avel_histo'
        disp('Partial clustering with average linkage and histograms')
        pts_in_smallBin = pc_avel_hist(pts_in_bigBin,dX, ...
                            sl_histo_bins);
                        
    case 'cl_histo'
        disp('Partial clustering with complete linkage and histograms')
        pts_in_smallBin = pc_cl_hist(pts_in_bigBin,dX, ...
                            sl_histo_bins);
                        
    otherwise
        error('Did not recognize partial clustering method')
end
end

%% Create membership matrix prior to pruning
memberMat = false(length(pts_in_smallBin),size(lens_X,1));
for ii = 1:size(memberMat,1)
   memberMat(ii,pts_in_smallBin{ii}) = true; 
end

%% Pruned graph creation
% Output: 
% - remove smallBins that are identical
% - create weighted adjacency matrix where weights are proportional to size
% of intersection

fprintf(1,'Pruning Mapper nodes\n');
[adja_pruned, memberMat, pts_in_smallBin_pruned] = create_pruned_graph_fast(memberMat);


%% Start storing all results in a struct
% Output: a struct which contains the dataset name, all mapper parameters
% used in the analysis, as well as outputs in each layer of the mapper
% pipeline. 

res = struct;
res.filename        = filename;
res.options         = options;

% need to store filter_X for plotting
res.filter_X = filter_X;  

% store other variables here
% res.bigBin          = pts_in_bigBin;
% res.smallBin        = pts_in_smallBin;
res.smallBinPruned  = pts_in_smallBin_pruned;
res.memberMat       = sparse(memberMat);
res.adja_pruned     = adja_pruned;

% res.opt_gain        = opt_gain;
% res.opt_k           = opt_k;
if exist('hrfdurstat', 'var')
    res.hrfdurstat      = hrfdurstat;
end


%% Plot graphs
% 9.30.2020 plotting takes a lot of time, make it optional

if plot_graph | show_embed | save_plot
    
    % create filename for saving (and title)
    [save_path,save_name,~] = fileparts(save_to);
    title_text = save_name;
    
    if save_plot & ~ischar(save_plot) & ~isstring(save_plot)
        save_plot = fullfile(save_path,strcat('plotGraph_',save_name,'.png'));
        fprintf(1,['Figure saved as ',save_plot,'\n']);
    end
  
    % visualize
    fprintf(1,'Visualizing force layout of graph\n');
    [graph, h, node_sizes, node_colors] = replotGraph(res,colors,labels,title_text,show_embed,use_layout,save_plot);

else
   
    % skip plotting, but process graph, node_sizes, node-colors, etc.
    fprintf(1,"Processing graph (use plot_graph=true for visualization)\n");
    [graph, node_sizes, node_colors] = processGraph(res,colors);

end



%% 09.09.2021
if ~low_mem
    
    % store data matrices
    res.X = X;
    res.preprocessed_X = preprocessed_X;
    res.lens_X = lens_X;
    res.embed_X = embed_X;
    res.filter_X = filter_X;

    % distance matrices
    res.dX = dX;
    res.dX_lens = dX_lens;
    if exist('dfX','var')
        res.dfX = dfX;
    end

    % membership bins
    res.bigBin          = pts_in_bigBin;
    res.smallBin        = pts_in_smallBin;
    res.smallBinPruned  = pts_in_smallBin_pruned;
    
%     % membership matrices
%     res.bigBinMat = false(length(res.bigBin),size(res.lens_X,1));
%     res.smallBinMat = false(length(res.smallBin),size(res.lens_X,1));
%     res.smallBinPrunedMat = false(length(res.smallBinPruned),size(res.lens_X,1));
%     for ii = 1:size(res.smallBinMat,1) % only loop over biggest one for speed
%        if ii < size(res.bigBinMat,1) 
%            res.bigBinMat(ii, res.bigBin{ii}) = true; 
%        end
%        if ii < size(res.smallBinPruned,1) 
%            res.smallBinPrunedMat(ii, res.smallBinPruned{ii}) = true; 
%        end
%        res.smallBinMat(ii, res.smallBin{ii}) = true; 
%     end

end


%% Store graph in the struct
res.graph           = graph;
res.node_sizes      = node_sizes;
res.node_colors     = node_colors;
res = rmfield(res,'adja_pruned'); % this is stored in sparse form in res.graph

save(save_to,'res')
fprintf(1,['Result saved to ',save_to,'\n'])


end

