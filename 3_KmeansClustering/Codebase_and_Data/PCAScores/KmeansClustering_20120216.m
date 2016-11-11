%% Kmeans clustering of scores of retained components

clear; clc;

currPath   = regexp(pwd, '^(.+?/\d+_[A-Za-z]+)/(.+)$', 'tokens');
outputPath = [currPath{1}{1},'/Results/'];

% Where to read/write data
inPath  = '../Input_Data/';
prefix  = 'KMeans-';

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

map40   ='-40-Clusters';
map20   ='-20-Clusters';
map10   ='-10-Clusters';
map5    ='-05-Clusters';
geomap40=[map40,'-Geo'];
geomap20=[map20,'-Geo'];
geomap10=[map10,'-Geo'];
geomap5 =[map5,'-Geo'];

for ii=1:4

% clear cluster results from previous runs
    
    if ii==1
        name='All_Destinations';
        scores=scoresD_Total;
        rownames=TAZnumbers_Total;
%         filename='clusters_Total_Destinations_NN.csv';
%         filenameGeo='clusters_geo_Total_Destinations_NN.csv';
%         filedendro='Dendrogram_Total_Destinations_NN.png';
%         filedendroGeo='Dendrogram_geo_Total_Destinations_NN.png';
        coords=coords_Total;
    end
    if ii==2
        name='All_Origins';
        scores=scoresO_Total;
        rownames=TAZnumbers_Total;
%         filename='clusters_Total_Origins_NN.csv'; 
%         filenameGeo='clusters_geo_Total_Origins_NN.csv';
%         filedendro='Dendrogram_Total_Origins_NN.png';
%         filedendroGeo='Dendrogram_geo_Total_Origins_NN.png';
        coords=coords_Total;
    end
   if ii==3
        name='CentralAndInner_Destinations';
        scores=scoresD_CandI;
        rownames=TAZnumbers_CandI;
%         filename='clusters_CandI_Destinations_Kmeans.csv';
%         filenameGeo='clusters_geo_CandI_Destinations_Kmeans.csv';
        coords=coords_CandI;
   end
   if ii==4
        name='CentralAndInner_Origins';
        scores=scoresO_CandI;
        rownames=TAZnumbers_CandI;
%         filename='clusters_CandI_Origins_Kmeans.csv';   
%         filenameGeo='clusters_geo_CandI_Origins_Kmeans.csv';
        coords=coords_CandI;
   end
   
   
    %% Step 1: Kmeans clustering of scores 

    [noOfDataPoints noOfAttributes]=size(scores);

    % K means clustering for various numbers of clusters: 5-40
    clusters=[];

    for j=5:5:40
        clusters=[clusters kmeans(scores,j)];
    end
    %clusters(1:20,:)
    %pause

    % Export cluster results in a csv file

    finalresult=[rownames clusters];
    csvwrite([outputPath,prefix,name,'-Clusters.csv'],finalresult);

    % 16 Feb 2012
    % make some images, so Jon doesn't have to map all these
    markerSize = 3;
    
    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,8),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 40 clusters');
    savefig([outputPath,prefix,name,map40],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,4),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 20 clusters');
    savefig([outputPath,prefix,name,map20],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,2),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 10 clusters');
    savefig([outputPath,prefix,name,map10],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,1),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 5 clusters');
    savefig([outputPath,prefix,name,map5],gcf,'pdf');


    %% Step 2: kmeans clustering of scores with geography

    % Same as above, but we add the two geo dimensions, x and y as two new
    % attributes of the clustering space


    % K means clustering for various numbers of clusters: 5-40
    geoclusters=[];

    for j=5:5:40
        geoclusters=[geoclusters kmeans([scores coords(:,2:3)],j)];
    end
    %clusters(1:20,:)
    %pause

    % Export cluster results in a csv file

    geofinalresult=[rownames geoclusters];
    csvwrite([outputPath,prefix,name,'-Clusters-Geo.csv'],geofinalresult);

    % 16 Feb 2012
    % make some images, so Jon doesn't have to map all these

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,8),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 40 clusters');
    savefig([outputPath,prefix,name,geomap40],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,4),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 20 clusters');
    savefig([outputPath,prefix,name,geomap20],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,2),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 10 clusters');
    savefig([outputPath,prefix,name,geomap10],gcf,'pdf');

    figure
    h=scatter(coords(:,2),coords(:,3),30,clusters(:,1),'filled');
    hChildren = get(h, 'Children');
    set(hChildren, 'Markersize', markerSize);
    title('Map with 5 clusters');
    savefig([outputPath,prefix,name,geomap5],gcf,'pdf');

    close all;

end