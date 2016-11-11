%% Kmeans clustering of scores of retained components

clear; clc;

currPath   = regexp(pwd, '^(.+?/\d+_[A-Za-z]+)/(.+)$', 'tokens');
outputPath = [currPath{1}{1},'/Results/'];

% Where to read/write data
inPath  = '../Input_Data/';
prefix = 'Sihouette-';

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

for ii=1:2

% clear cluster results from previous runs
    
    if ii==1
        name='All_Destinations';
        scores=scoresD_Total;
        rownames=TAZnumbers_Total;
        coords=coords_Total;
        title1='Average Silhouette Index - Destinations';
        geotitle='Average Silhouette Index - Destinations & Geography';
    end
    if ii==2
        name='All_Origins';
        scores=scoresO_Total;
        rownames=TAZnumbers_Total;
        coords=coords_Total;
        title1='Average Silhouette Index - Origins';
        geotitle='Average Silhouette Index - Origins & Geography';
    end
    if ii==3
        name='CentralAndInner_Destinations';
        scores=scoresD_CandI;
        rownames=TAZnumbers_CandI;
        coords=coords_CandI;
        title1='Average Silhouette Index - Destinations';
        geotitle='Average Silhouette Index - Destinations & Geography';
    end
    if ii==4
        name='CentralAndInner_Origins';
        scores=scoresO_CandI;
        rownames=TAZnumbers_CandI;
        coords=coords_CandI;
        title1='Average Silhouette Index - Origins';
        geotitle='Average Silhouette Index - Origins & Geography';
    end
   

    %% Step 1: Kmeans clustering of scores 

    [noOfDataPoints noOfAttributes]=size(scores);

    % K means clustering for various numbers of clusters: 2-40
    clusters=[];
    Sil = [];
    NoOfClusters=2:40;

    for j=NoOfClusters 
        % kmeans clustering
        kmeansresult=kmeans(scores,j);
        clusters=[clusters kmeansresult];
        % calculate average silhouette index for j clusters
        R = silhouette(scores, kmeansresult,'Euclidean');
        Sil = [Sil mean(R)]; % builds a vector of average silhouette for j
    end

    % Find the highest index in Sil
    [high, ko] = max(Sil);

    % Produce a plot of silhouette index
    figure
    plot(NoOfClusters,Sil,'-bo',...
                    'LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor',[.49 1 .63],...
                    'MarkerSize',4);
    title(title1);
    xlabel('No. of Clusters');
    ylabel('Silhouette Index')
    % Draw a marker around the highest value
    hold on
    plot(NoOfClusters(ko),Sil(ko),'ks','MarkerSize',12);
    savefig([outputPath,prefix,name,'Silhouette'],gcf,'pdf');

    %pause

    % Export cluster results in a csv file
    finalresult=[rownames clusters];
    csvwrite([outputPath,prefix,name,'-Clusters.csv'],finalresult);


    %% Step 2: kmeans clustering of scores with geography

    % Same as above, but we add the two geo dimensions, x and y as two new
    % attributes of the clustering space

    % K means clustering for various numbers of clusters: 5-40
    geoclusters=[];
    geoSil = [];

    for j=NoOfClusters 
        % kmeans clustering
        kmeansresult=kmeans([scores coords(:,2:3)],j);
        geoclusters=[geoclusters kmeansresult];
        % calculate average silhouette index for j clusters
        R = silhouette(scores, kmeansresult,'Euclidean');
        geoSil = [geoSil mean(R)]; % builds a vector of average silhouette for j
    end

    % Produce a plot of silhouette index for geography

    % Find the highest index in Sil
    [high, ko] = max(geoSil);

    figure
    plot(NoOfClusters,geoSil,'-bo',...
                    'LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor',[.49 1 .63],...
                    'MarkerSize',4);
    title(geotitle);
    xlabel('No. of Clusters');
    ylabel('Silhouette Index')
    % Draw a marker around the highest value
    hold on
    plot(NoOfClusters(ko),geoSil(ko),'ks','MarkerSize',12);
    savefig([outputPath,prefix,name,'Silhouette-Geo'],gcf,'pdf');

    % Export cluster results in a csv file

    geofinalresult=[rownames geoclusters];
    csvwrite([outputPath,prefix,name,'-Clusters-Geo.csv'],geofinalresult);

    close all;


end