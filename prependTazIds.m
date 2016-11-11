dimension = 'all';
name = ['Origins_Regions_',dimension];

addpath('/Data/Academic/Dropbox/Goddard/matlab/');

% Creates a variable with the same
% name as the imported CSV file 
% (minus the .csv part)
importRegionsCSV([name, '.csv']);

% Copy the data to a handle we can 
% reference directly instead of via
% eval
myData = eval(name);

% Now we need to grab the row names
% so taht we can prepend the actual 
% TAZ ID to the data set
load(['taz-weekday-',dimension,'.mat']);

% Preallocate for speed
rows = zeros(size(rownames));
cols = zeros(size(colnames));

% Copy the values and convert so that
% we can use an array
for i=1:length(rownames)
    rows(i) = str2num(rownames{i});
end

for i=1:length(colnames)
    cols(i) = str2num(colnames{i});
end

% And here's the final data
regionData = [ rows myData ];

% But we're missing a header
header = 'TAZ,';

for i=2:size(regionData,2)
    txt = sprintf('Factor_%d',(i-1));
    header = strcat(header,txt);
    if (i < size(regionData,2))
        header = strcat(header,',');
    end
end

outid = fopen([name,'-mapped.csv'],'w+');
fprintf(outid,'%s',header);
fclose(outid);
dlmwrite([name,'-mapped.csv'],regionData,'roffset',1,'-append');
