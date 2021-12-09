function memberMat = construct_cover(X,resolution,gain,k,dfXtype)

%% Build knn graph with reciprocal connections.
[nnid,~] = knnsearch(X,X,'K',k,'Distance',dfXtype);
n = size(nnid,1);
g = graph;
g = addnode(g,n);
for ii = 1:size(nnid,1)
    v = nnid(ii,:); %get vertices that ii points to
    w = max(nnid(v,:)==ii,[],2); %get vertices that also point back to ii
    e = [repmat(ii,sum(w),1),v(w)']; %build edges
    g = addedge(g,e(:,1),e(:,2));
end
g = simplify(g); % remove self loops

%% Now create a cover. 
% The number of landmarks is divided proportional to 
% the size of each connected component.

[cc,ccs] = conncomp(g);
binAlloc = ceil((ccs/n)*resolution); %grab extra landmarks if needed

memberMat = zeros(sum(binAlloc),n); %membership Matrix
landmk_idx_in_g = zeros(size(memberMat,1),1);

curr_row = 1;curr_col = 1;
% Loop over connected components
for ii = 1:size(ccs,2)
   sg = subgraph(g,cc==ii);
   dX = sg.distances;
   memberSubMat = zeros(binAlloc(ii),ccs(ii));
   
   % FPS
   [landmk_idx, dist_to_landmk, epsilon] = px_maxmin(dX,'metric',binAlloc(ii),'n', 1,'seeds');
   for jj = 1:binAlloc(ii)
        tmp = dist_to_landmk(jj,:);
        pt_idx = tmp <= max((gain/100)*(4*epsilon), eps);
        % Gain should be at least 25 to make sure we're covering the dataset
        memberSubMat(jj,:) = pt_idx;
   end
   next_row = curr_row + binAlloc(ii) -1;
   next_col = curr_col+ccs(ii) -1;
   
   memberMat(curr_row:next_row,curr_col:next_col) = memberSubMat;
   landmk_idx_in_g(curr_row : next_row) = curr_col -1 + landmk_idx;
   
   curr_row = next_row + 1;
   curr_col = next_col + 1;
end


end