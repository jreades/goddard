clear;clc;

% Useful for outputting things reliably
outputPath = [pwd,'/'];

% Need savefig & appendToShapeFile
addpath('./support');

% What we're doing
todo = 'Scores';
%todo = 'HierarchicalClusters';
%todo = 'LinkClusters';

if strcmp(todo,'Scores')
	% Field name for shape file: PCA_Group
	fieldNames    = {'mzne','PCA_Score'};
	%lookupKeys   = str2double(rownames(find(workingValues(:,1)>0.05)));
	%lookupValues = ones(size(lookupKeys,1),1);
	lookupKeys    = str2double(rownames);
	lookupValues  = workingValues(:,1);
	fieldValues   = [lookupKeys lookupValues];
elseif strcmp(todo,'LinkClusters')
	% Field name for shape file: PCA_Group
	fieldNames    = {'mzne','Cluster'};
	%lookupKeys   = str2double(rownames(find(workingValues(:,1)>0.05)));
	%lookupValues = ones(size(lookupKeys,1),1);
	lookupKeys    = str2double(rownames);
	lookupValues  = workingValues(:,1);
	fieldValues   = [lookupKeys lookupValues];
end

i=1;
format short;
appendDataToShape([outputPath,'shapes/TAZ_Points.shp'],[outputPath,'shapes/',todo,'-',num2str(i),'-TAZ_Points.shp'],fieldNames,fieldValues);
