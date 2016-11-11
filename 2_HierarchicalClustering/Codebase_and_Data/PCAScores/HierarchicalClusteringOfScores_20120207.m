%% Hierarchical clustering of scores of retained components, based on
% Goddard, part 2
% Goddard does this clustering first including contiguity constraint, then
% without contiguity constraint. We reverse this procedure.
%
% Functions used (Statistics toolbox): pdist, linkage, cluster -> all three
% together produce a hierarchical clustering 

clear; clc;

% Need savefig & appendToShapeFile
addpath('../../../support');

currPath   = regexp(pwd, '^(.+?/\d+_[A-Za-z]+)/(.+)$', 'tokens');
outputPath = [currPath{1}{1},'/Results/'];

% Where to read/write data
inPath  = '../Input_Data/';
prefix  = 'PCAScores-';

% Read retained scores from the respective csv file for both
% destination-based and origin-based analysis and for both extents (total
% dataset and central&inner).
% Destinations:
scoresD_Total=csvread([inPath,'ScoresRetainedPCs.csv']);
scoresD_CandI=csvread([inPath,'ScoresRetainedPCs_central_and_inner.csv']);
% Origins
scoresO_Total=csvread([inPath,'Origins_ScoresRetainedPCs.csv']);
scoresO_CandI=csvread([inPath,'Origins_ScoresRetainedPCs_central_and_inner.csv']);
% TAZ numbers of areas
TAZnumbers_Total=csvread([inPath,'Rownames_Total.csv']);
TAZnumbers_CandI=csvread([inPath,'Rownames_Central_and_inner.csv']);

%% Calcuations are in a loop that goes through all the above
% datasets and calculate cluster results for several levels, then export
% those in an appropriate csv file. 

for i=1:4
    
    if i==1
        name='All_Destinations';
        scores=scoresD_Total;
        rownames=TAZnumbers_Total;  
    end
    if i==2
        name='All_Origins';
        scores=scoresO_Total;
        rownames=TAZnumbers_Total;   
    end
    if i==3
        name='CentralAndInner_Destinations';
        scores=scoresD_CandI;
        rownames=TAZnumbers_CandI;  
    end
    if i==4
        name='CentralAndInner_Origins';
        scores=scoresO_CandI;
        rownames=TAZnumbers_CandI;   
    end

    %% Step 1: hierarchical clustering of scores
    % This clustering is in the noOfAttributes-dimensional data space of
    % principal components and we group noOfDataPoints into clusters.
    % 
    % Similarity measure: Euclidean distance in the data space of components
    % Single-linkage mtethod for hierarchical groupings: the new similarity
    % measure of two new groups is defined as the shortest distance between
    % all the members in two new groups (default setting in linkage function).

    [noOfDataPoints noOfAttributes]=size(scores);

    % Similarity calculation
    similarity=pdist(scores);
    simMatrix=squareform(similarity);
    %pause

    % Linkage calculation
    groupings=linkage(similarity);

    % Show the results as a dendrogram
    figure
    H = dendrogram(groupings,0);
    set(H,'LineWidth',0.5);
    set(H,'Color','k');
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
    savefig([outputPath,prefix,name,'-Dendrogram'],gcf,'pdf');

    % Construct clusters at different levels of detail from linkage result,
    % using the follwing:
    % cluster(Z,'maxclust',n) constructs a maximum of n clusters. cluster 
    % finds the smallest height at which a horizontal cut through the tree 
    % leaves n or fewer clusters.
    % Creating from 5 to 30 clusters in each case.
    clusters=cluster(groupings,'maxclust',[5 10 15 20 25 30]);

    %% Step 2: export cluster results in a csv file

    finalresult=[rownames clusters];
    csvwrite([outputPath,prefix,name,'-Clusters.csv'],finalresult);

end