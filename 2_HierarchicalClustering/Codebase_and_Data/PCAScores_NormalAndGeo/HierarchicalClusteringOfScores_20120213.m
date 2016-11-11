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
prefix  = 'GeoPCAScores-';


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
% Coordinates for geoclustering, these are tables with 3 attributes, TAZ
% number, x coordinate and y coordinate
coords_Total=csvread([inPath,'Coordinates_Total.csv'],1,0);
coords_CandI=csvread([inPath,'Coordinates_Central_and_inner.csv'],1,0);

%% Calcuations are in a loop that goes through all the above
% datasets and calculate cluster results for several levels, then export
% those in an appropriate csv file. 

for i=1:4
    
   if i==1
        name='All_Destinations';
        scores=scoresD_Total;
        rownames=TAZnumbers_Total;
        coords=coords_Total;
   end
   if i==2
        name='All_Origins';
        scores=scoresO_Total;
        rownames=TAZnumbers_Total;
        coords=coords_Total;
   end
   if i==3
        name='CentralAndInner_Destinations';
        scores=scoresD_CandI;
        rownames=TAZnumbers_CandI;
        coords=coords_CandI;
   end
   if i==4
        name='CentralAndInner_Origins';
        scores=scoresO_CandI;
        rownames=TAZnumbers_CandI;
        coords=coords_CandI;
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
    clusters=cluster(groupings,'maxclust',[5 10 15 20 25 30 35 40 45 50]);

    % Export cluster results in a csv file

    finalresult=[rownames clusters];
    csvwrite([outputPath,prefix,name,'-Clusters.csv'],finalresult);

    %% Step 2: hierarchical clustering of scores with geography

    % Same as above, but we add the two geo dimensions, x and y as two new
    % attributes of the clustering space

    % Similarity calculation, add the x and y coordinate from the coords table
    % into the dataset
    geosimilarity=pdist([scores coords(:,2:3)]);
    simMatrix=squareform(geosimilarity);
    %simMatrix(1:20,1:20)
    %pause

    % Linkage calculation
    geogroupings=linkage(geosimilarity);

    % Show the results as a dendrogram
    figure
    H = dendrogram(geogroupings,0);
    set(H,'LineWidth',0.5);
    set(H,'Color','k');
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
    savefig([outputPath,prefix,name,'-Dendrogram-Geo'],gcf,'pdf');

    % Construct clusters at different levels of detail from linkage result,
    % using the follwing:
    % cluster(Z,'maxclust',n) constructs a maximum of n clusters. cluster 
    % finds the smallest height at which a horizontal cut through the tree 
    % leaves n or fewer clusters.
    % Creating from 5 to 30 clusters in each case.
    geoclusters=cluster(geogroupings,'maxclust',[5 10 15 20 25 30 35 40 45 50]);
    %geoclusters(1:20,:)
    %pause

    % Export cluster results in a csv file

    geofinalresult=[rownames geoclusters];
    csvwrite([outputPath,prefix,name,'-Clusters-Geo.csv'],geofinalresult);

    %% Step 3: hierarchical clustering of scores, no PC1

    % Same as step 1, but only for PC2-PCk

    [noOfDataPoints noOfAttributes]=size(scores);

    % Similarity calculation - take out PC1 from this, i.e. 1st column from the
    % scores matrix is not used anymore.
    similarity_noPC1=pdist(scores(:,2:noOfAttributes));
    simMatrix=squareform(similarity_noPC1);
    %pause

    % Linkage calculation
    groupings_noPC1=linkage(similarity_noPC1);

    % Show the results as a dendrogram
    figure
    H = dendrogram(groupings_noPC1,0);
    set(H,'LineWidth',0.5);
    set(H,'Color','k');
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
    savefig([outputPath,prefix,name,'-Dendrogram-NoPC1'],gcf,'pdf');

    % Construct clusters at different levels of detail from linkage result,
    % using the follwing:
    % cluster(Z,'maxclust',n) constructs a maximum of n clusters. cluster 
    % finds the smallest height at which a horizontal cut through the tree 
    % leaves n or fewer clusters.
    % Creating from 5 to 30 clusters in each case.
    clusters_noPC1=cluster(groupings_noPC1,'maxclust',[5 10 15 20 25 30]);

    % Export cluster results in a csv file

    finalresult_noPC1=[rownames clusters_noPC1];
    csvwrite([outputPath,prefix,name,'-Clusters-NoPC1.csv'],finalresult_noPC1);

    %% Step 4: hierarchical clustering of scores with geography, but no PC1

    % Same as step 2, except we take out PC1, as in step 3

    % Similarity calculation, add the x and y coordinate from the coords table
    % into the dataset and PCs 2-k (no PC1, which is 1st column of scores
    % matrix)
    geosimilarity_noPC1=pdist([scores(:,2:noOfAttributes) coords(:,2:3)]);
    simMatrix=squareform(geosimilarity_noPC1);
    %simMatrix(1:20,1:20)
    %pause

    % Linkage calculation
    geogroupings_noPC1=linkage(geosimilarity_noPC1);

    % Show the results as a dendrogram
    figure
    H = dendrogram(geogroupings_noPC1,0);
    set(H,'LineWidth',0.5);
    set(H,'Color','k');
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
    savefig([outputPath,prefix,name,'-Dendrogram-Geo-NoPC1'],gcf,'pdf');

    % Construct clusters at different levels of detail from linkage result,
    % using the follwing:
    % cluster(Z,'maxclust',n) constructs a maximum of n clusters. cluster 
    % finds the smallest height at which a horizontal cut through the tree 
    % leaves n or fewer clusters.
    % Creating from 5 to 30 clusters in each case.
    geoclusters_noPC1=cluster(geogroupings_noPC1,'maxclust',[5 10 15 20 25 30]);
    %geoclusters(1:20,:)
    %pause

    % Export cluster results in a csv file

    geofinalresult_noPC1=[rownames geoclusters_noPC1];
    csvwrite([outputPath,prefix,name,'-Clusters-Geo-NoPC1.csv'],geofinalresult_noPC1);
    
    close all;

end