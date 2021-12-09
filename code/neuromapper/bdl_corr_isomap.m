function embed_fX = bdl_corr_isomap(X, L, num_k, dim_embed)
% Function bdl_corr_isomap
% Inputs:
% X is an n x p data matrix. Rows are observations, columns are
% variables/features
% L is a subset of {1,2,...,p} -- the collection of landmarks. It is a
% subset of the features of X.
% num_k is the number of nearest neighbors used for the isomap portion
% dim_embed is the embedding dimension used in the isomap portion

% Procedure:
% - Compute p x p matrix of correlations between features of X
% - For each feature, create a vector listing its correlations to the
% landmark features. This is an |L| x 1 vector.
% - Compute the "landmark-correlated" distance between the features.
% Specifically, given the p x |L| matrix constructed above, compute a p x p
% distance matrix using pdist2. 
% - According to this distance matrix, two points are "close" if they have
% the same correlations to all the landmark points. Note that two highly
% correlated points may be "far apart" in this lens, if they have different
% correlations to the landmarks. 
% - The landmarks form a "trusted set" -- they decide which features are
% similar

% - Next the p x p distance matrix is passed to isomap for dimension
% reduction

% Output:
% embed_fX -- a p x dim_embed matrix giving an embedding of the features of
% the data matrix X

cX                  = corr(X);
corr_to_landmarks   = cX(:,L);
landmark_corr_dist  = pdist2(corr_to_landmarks,corr_to_landmarks);

embed_fX            = isomap(landmark_corr_dist, dim_embed, num_k);

end




