function  savemystruct(name,var,version)
% Function writemyfile
% Used to save files in parfor loop
  if ~exist('version', 'var')
    version = '-v7';
  end
  save(name, '-struct', 'var', version);
end

