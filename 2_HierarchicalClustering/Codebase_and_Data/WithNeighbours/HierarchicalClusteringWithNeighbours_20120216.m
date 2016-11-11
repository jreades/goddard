%% Hierarchical clustering of scores of retained components, based on
% Goddard, part 2
% Goddard does this clustering first including contiguity constraint, then
% without contiguity constraint. We reverse this procedure.
%
% Functions used (Statistics toolbox): pdist, linkage, cluster -> all three
% together produce a hierarchical clustering 

% 16 Feb 2012:
% This is a version of geographic clustering with k nearest neighbours (NN). It
% is to replace the contiguity based clustering from Goddard, if it works.

clear; clc;

% Need savefig & appendToShapeFile
addpath('../../../support');

currPath   = regexp(pwd, '^(.+?/\d+_[A-Za-z]+)/(.+)$', 'tokens');
outputPath = [currPath{1}{1},'/Results/'];

% Where to read/write data
inPath  = '../Input_Data/';
prefix  = 'Neighbours-';

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

map50   ='50_Clusters';
map40   ='40_Clusters';
map20   ='20_Clusters';
map5    ='05_Clusters';
geomap50=[map50,'-Geo'];
geomap40=[map40,'-Geo'];
geomap20=[map20,'-Geo'];
geomap5 =[map5,'-Geo'];
        
for ii=2:2

% clear cluster results from previous runs
clear clusters geoclusters similarity geosimilarity mask geomask

    % The All Destinations and All Origins
    % may not run or may cause serious problems
    if ii==1
        name='All_Destinations';
        scores=scoresD_Total;
        rownames=TAZnumbers_Total;
%         filename='clusters_Total_Destinations_NN.csv';
%         filenameGeo='clusters_geo_Total_Destinations_NN.csv';
        coords=coords_Total;
    end
    if ii==2
        name='All_Origins';
        scores=scoresO_Total;
        rownames=TAZnumbers_Total;
%         filename='clusters_Total_Origins_NN.csv'; 
%         filenameGeo='clusters_geo_Total_Origins_NN.csv';
        coords=coords_Total;
    end
    if ii==3
        name='CentralAndInner_Destinations';
        scores=scoresD_CandI;
        rownames=TAZnumbers_CandI;
        coords=coords_CandI;
    end
    if ii==4
        name='CentralAndInner_Origins';
        scores=scoresO_CandI;
        rownames=TAZnumbers_CandI;
        %filename='clusters_CandI_Origins_NN.csv';   
        %filenameGeo='clusters_geo_CandI_Origins_NN.csv';
        coords=coords_CandI;
    end
   
    % 16 Feb 2012
    % Set number of nearest neighbours (for now 5) of each TAZ area
    k=5;

    %% Step 1: hierarchical clustering of scores with k nearest neighbours (NN)
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

    % 16 Feb 2012
    % Calculate the mask for k nearest neighbours, i.e. build a neighbouhood
    % graph from coordinates of TAZ areas for k nearest neighbours. The
    % adjacency matrix of this graph will be the mask for similarity measure:
    % the new similarity will be equal to the old similarity everywhere where
    % adj matrix is 1 and equal to Inf elsewhere.
    NearestNeighbourAdjMatrix=NeighbourhoodGraph(coords(:,2:3),k);
    [rows cols]=size(NearestNeighbourAdjMatrix);

    % 16 Feb 2012
    % Convert adj matrix into a vector of distances, to be used in linkage,
    % such that 1) elements are only from the upper triangle, diagonal excluded
    % and 2) all zeroes are replaced by Inf (for the single linkage to work).
    % The vector of distances is called a mask.
    mask=[]; 
    for i=1:rows
        for j=i+1:cols
            if NearestNeighbourAdjMatrix(i,j)==0
               mask=[mask Inf];
            else
               mask=[mask simMatrix(i,j)];
            end   
        end
    end
    %mask(1:100,:)
    %pause;

    % Linkage calculation
    groupings=linkage(mask);

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

    % 16 Feb 2012
    % make some images, so Jon doesn't have to map all these
    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,10),'filled')
    title('Map with 50 clusters');
    savefig([outputPath,prefix,name,'-',map50],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,8),'filled')
    title('Map with 40 clusters');
    savefig([outputPath,prefix,name,'-',map40],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,4),'filled')
    title('Map with 20 clusters');
    savefig([outputPath,prefix,name,'-',map20],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,1),'filled')
    title('Map with 5 clusters');
    savefig([outputPath,prefix,name,'-',map5],gcf,'pdf');


    %% Step 2: hierarchical clustering of scores with geography

    % Same as above, but we add the two geo dimensions, x and y as two new
    % attributes of the clustering space

    % Similarity calculation, add the x and y coordinate from the coords table
    % into the dataset
    geosimilarity=pdist([scores coords(:,2:3)]);
    geoSimMatrix=squareform(geosimilarity);
    %simMatrix(1:20,1:20)
    %pause

    % 16 Feb 2012
    % Convert adj matrix into a vector of distances, to be used in linkage,
    % such that 1) elements are only from the upper triangle, diagonal excluded
    % and 2) all zeroes are replaced by Inf (for the single linkage to work).
    % The vector of distances is called a geomask.
    geomask=[]; 
    for i=1:rows
        for j=i+1:cols
            if NearestNeighbourAdjMatrix(i,j)==0
               geomask=[geomask Inf];
            else
               geomask=[geomask geoSimMatrix(i,j)];
            end   
        end
    end
    %geomask
    %pause;

    % Linkage calculation
    groupings=linkage(geomask);

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

    % 16 Feb 2012
    % make some images, so Jon doesn't have to map all these
    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,10),'filled')
    title('Map with 50 clusters');
    savefig([outputPath,prefix,name,'-',geomap50],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,8),'filled')
    title('Map with 40 clusters');
    savefig([outputPath,prefix,name,'-',geomap40],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,4),'filled')
    title('Map with 20 clusters');
    savefig([outputPath,prefix,name,'-',geomap20],gcf,'pdf');

    figure
    scatter(coords(:,2),coords(:,3),30,clusters(:,1),'filled')
    title('Map with 5 clusters');
    savefig([outputPath,prefix,name,'-',geomap5],gcf,'pdf');

    close all;

end