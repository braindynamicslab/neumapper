function [Z, cutoff] = find_cluster_cutoff(distMat, num_bins_clustering, linkage_method)
   Z = linkage(distMat(tril(true(length(distMat)),-1))', linkage_method);
   
   lkg_vals = unique(Z(:,3));
   
   if length(lkg_vals) == 1 % Equidistant points, hence one linkage value
       %fprintf(1,'Equidistant points found for clustering\n');
       cutoff = Inf;
   else
       lens = [Z(:,3)' max(max(distMat))];
       [numBins, bc] = hist(lens, num_bins_clustering);
       z = find(numBins==0);
       if (sum(z) == 0)
           cutoff = Inf;
           return;
       else
           cutoff = bc(z(1)); % pick up the smallest index of z
       end   
   end


end