function pts_in_smallBin = pc_avel_hist(pts_in_bigBin,distMat, ...
                            sl_histo_bins)
    pts_in_smallBin = pc_sl_hist(pts_in_bigBin, distMat, sl_histo_bins, 'average');
end
