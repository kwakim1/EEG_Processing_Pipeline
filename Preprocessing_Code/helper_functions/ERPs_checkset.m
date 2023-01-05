function [ERPs] = ERPs_checkset(ERPs)
%9/26/22 - runs eeg_checkset for all cells in the ERPs data struct

for i=1:size(ERPs,1)
    for j=1:size(ERPs,2)
        ERPs{i,j}=eeg_checkset(ERPs{i,j});
    end
end

end