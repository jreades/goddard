%% Urska's interpretation of Goddard
% The main O/D matrix is given as data.
% We have origins in rows and destinations in columns.

clear;clc;

currPath   = regexp(pwd, '^(.+?/\d+_[A-Z]+)/(.+)$', 'tokens');
outputPath = [currPath{1}{1},'/Results/'];

% Need savefig & appendToShapeFile
addpath('../../support');
addpath('./Input_Data');

%% ================
% This is how to process a new raw
% data matrix contained in a txt file
% colnames = cellstr(num2str(data(1,:)'))';
% rownames = { rowheaders{2:length(rowheaders)} }';
% data     = data(2:length(data),:);
% clear rowheaders;
% save('/Data/Academic/Output/Articles/Goddard/matlab/taz-XXX.mat','colnames','rownames','data');

% Useful for outputting things reliably
%direction = 'Origins';
direction = 'Destinations';

% 20 Dec 2012: edited to allow the chance of loading each of three
% different data sets
frame = 'Central';
%frame = 'CentralAndInner';
%frame = 'All';
datafile  = 'taz-weekday-';

% Where to read data from
load([datafile,frame,'.mat']);

destinations = colnames;
origins      = rownames;

%% Checking for origins with no paths to any destinations 
% 6 Feb 2012
% These are the rows that consists fully of zeros and are the ones that are
% messing up the correlation matrix in the origin analysis.
% This is because, if a row here has all zeroes, then when we transpose
% this, the column has all zeroes. Covariance of this column is therefore 0
% and when correlation is calculated, this means division by 0, resulting
% in a NaN.
% To solve this, I will remove the origins with zero flows to anywhere else
% before starting the origin analysis. 

% First let's see if we can visually see if there are rows with only zeros.
% Using the sparse matrix visualisation.
%spy(data);

% Step 1: find rows with only zeros
%data=[1 1 1; 0 0 0; 1 -1 0; 0 0 4; 0 0 0] %for testing the loop
rowsWithZeros=[];
[rowNo,colNo]=size(data);
for i=1:rowNo
    allZeros=1;
    for j=1:colNo
        if data(i,j)~=0 
            allZeros=0;
        end    
    end
    if allZeros==1
       %disp('row with all zeroes!');
       rowsWithZeros=[rowsWithZeros i]; 
    end
end
%rowsWithZeros

% Step 2: remove rows with only zeros, including the appropriate rownames
% First keep a copy of original data
fullRowNames=rownames;
fullData=data;
% Remove those rows that are listed in rowsWithZeros
%rownames=(1:5)'; % for testing
[data,ps]=removerows(data,rowsWithZeros);

% Return and export in a csv file the list of names of origins that are
% excluded.
excludedRownames=str2num(char(rownames(rowsWithZeros,1)));
csvwrite([outputPath,direction,'-',frame,'-','Excluded_Rownames.csv'],excludedRownames);

% Export also the list or origin names that are included - the results
% should be mapped only for these origins!
[keptRownames,ps1]=removerows(str2num(char(rownames)),rowsWithZeros);
csvwrite([outputPath,direction,'-',frame,'-','Kept_Rownames_InProperOrderForMapping.csv'],keptRownames);

% Variable data now to be used in the origin analysis, as
% intended: we took away those origins that didn't feed into any
% destinations, but keep all destinations, which are now data points. In
% terms of origin analysis this means that we have less attributes in the
% data matrix (the transposed O/D matrix).
%% Rows with zeroes will be added back in when defining regions from destinations
% and origins. 

%% Origin-based analysis
% 6 Feb 2012
% The main O/D matrix is given as data.
% We have origins in rows and destinations in columns. This is then
% transposed, so that we have:
% - origins = columns/attributes
% - destinations = rows/data points
%
%% Step 0: Perform the same analysis on *origins*, not destinations
% Transpose the OD matrix

if strmatch(direction, 'Origins')
    disp('Transposing!');
    data1=data;
    data=data1';
end

%% Step 1: calculate the correlation matrix C from data matrix
C=corrcoef(data);

if (~ isempty(find(isnan(C))) )
    disp('Problem: Correlation matrix C contains NaNs!');
end

%% Step 2: run PCA on the correlation matrix C 

[PCs,eigenvalues] = pcacov(C);

% Calculate Scores by multiplying data1 with resorted loadings.
Scores=data*PCs;

%% Step 2.1. Examine percentage of variance and decide how many PCs to take
% Calculate percentage of variance
percVar=eigenvalues/sum(eigenvalues);

% Heuristic decision for dimensionality reduction:
% Cut off variance of less than 1 percent with Jon's handy trick
x = 1:find(percVar > 0.01,1,'last');

% Create a screenplot of variance > 0.005: 
% index on the x axis and eigenvalue values on the y axis
% Figure 1
figure
plot(x,percVar(1:length(x)),'-ko',...
                'LineWidth',2,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',8);
hold on
%h=legend('Original Eigenvalues');
yTop = 0.5
xlabel('Eigenvalue Rank (i)','FontSize',12);
ylabel('\lambda_i','FontSize',14);
set(gca,'YLimMode','manual','YLim',[0,yTop],'YTick',[0:0.05:yTop],'YTickLabel',{'0%','5%','10%','15%','20%','25%','30%','35%','40%','45%','50%','55%','60%'});
title('Original Eigenvalues (Percentage of Variance Explained)');
savefig([outputPath,direction,'-',frame,'-','Fig1_ScreeplotOfVarianceMoreThan1Perc'],'pdf');

%% Step 2.2: Interpretation of loadings of retained PCs

% Here we only use retained PCs, which we got by cutting the
% variance at 1% -> vector x. 

NoOfRetainedPCs=length(x);
RetainedPCs=PCs(:,1:NoOfRetainedPCs);
[NoOfRows NoOfColumns]=size(data)

% CHECKING VALUES OF LOADINGS FOR EACH PC
% According to Goddard we now have to check the absolute values of loadings
% on each PC and take only those attributes which have the highest loading
% values (positive or negative). 
% From this we somehow have to decide on the cut-off value for loadings, to
% define each PC as per table 2 in Goddard. This is really vague in 
% Goddard, so the next bit of code is just looking at PCs, trying to see 
% if there is anything obvious about these loadings to define the cut-off 
% value.
% A reminder: loadings = PCs matrix, each PC is one column.

% First, let's produce box plots of absolute loading values for each PC.
% Figure 2
figure
figureCols=ceil(NoOfRetainedPCs./3);
for i=1:NoOfRetainedPCs
    subplot(3,figureCols,i); boxplot(abs(RetainedPCs(:,i)),'colors','k','outliersize',4,'symbol','+r');
    hold on;
    title(sprintf('PC%d',i),'fontsize',10);
    %xlabel(sprintf('PC%d',i),'fontsize',8);
    ylim([0 0.4])
    ylabel('Abs. Loadings');
    set(gca,'YTick',0:0.1:0.4)
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
end 
savefig([outputPath,direction,'-',frame,'-','Fig2_Boxplots_AbsLoadingsOnContributingVariables_LookForOutliers'],'pdf');

% Now we need to define a heuristics to choose those attributes that have
% the hightest absolute values to define regions. 
% Goddard had some specific values to cut, but according to his email he
% does not remember how he defined it. 
% I propose a decision based on looking at the boxplots.
% My suggestion is to use the top outliers from each PC: 
% there are few of those in PC1, because the distrbution of loadings 
% seems nicely normal, but for all other PCs, there are many outliers.
% To do this, we cut off at mean + 1.5 intraquartile range for each column.
% (this is the value of the top whisker in the boxplot).

q=quantile(abs(RetainedPCs),[0.25 0.75]);
intraquartRange=q(2,:)-q(1,:);
cutoffLoadings=mean(abs(RetainedPCs))+1.5*intraquartRange;

% Plot the scatterplots of abs loadings vs. no. of attributes (origins) and a cutoff
% line over each of the plots.

% Scatterplots of  attr. number (destination number) vs. respective 
% absolute loading value.
% Figure 3
figure
for i=1:NoOfRetainedPCs
    subplot(3,figureCols,i); scatter(1:NoOfColumns,abs(RetainedPCs(:,i))',2,'.','k');
    hold on;
    plot(1:NoOfColumns,cutoffLoadings(i)*ones(1,NoOfColumns),'-r')
    hold on
    title(sprintf('Loadings of PC%d',i),'fontsize',10);
    axis([1 NoOfColumns min(abs(RetainedPCs(:,i))) max(abs(RetainedPCs(:,i)))]);
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{});
    ylim([0 0.4])
    yticks  = get(gca,'YTick');
    ylabels = {};
    for i=1:length(yticks)
        ylabels{i} = sprintf('%0.2f',yticks(i));
    end
    set(gca,'YTickLabel',ylabels);
end 
savefig([outputPath,direction,'-',frame,'-','Fig3_Scatterplots_NumbersVsLoadings'],'pdf');

% This seems to work for all PCs, except for PC1, which has a nice Gaussian
% distribution -> I'll define the cutoff there by taking top 5% of data.
% NOTE: This is only for this particular case, may not be necessary for
% rotated PCs.

cutoffLoadings(1)=quantile(abs(RetainedPCs(:,1)),.96);

% Replot the scatterplots with this correction for PC1
% Figure 4
figure
for i=1:NoOfRetainedPCs
    subplot(3,figureCols,i); scatter(1:NoOfColumns,abs(RetainedPCs(:,i))',2,'.','k');
    hold on;
    plot(1:NoOfColumns,cutoffLoadings(i)*ones(1,NoOfColumns),'-r')
    hold on
    title(sprintf('PC%d',i),'fontsize',10);
    axis([1 NoOfColumns min(abs(RetainedPCs(:,i))) max(abs(RetainedPCs(:,i)))]);
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{});
    yticks  = get(gca,'YTick');
    ylabels = {};
    for i=1:length(yticks)
        ylabels{i} = sprintf('%0.2f',yticks(i));
    end
    set(gca,'YTickLabel',ylabels);
end 
savefig([outputPath,direction,'-',frame,'-','Fig4_Scatterplots_NumbersVsLoadings_PC1corrected'],'pdf');

% Now take only those origins that have the absolute values of
% loadings more than the cut off value at each PC -> these define the core
% of each region according to Goddard.
% CoreRegions - a matrix where in each column you have values 1 for those
% origins that fit the region defined by that particular PC (PC=column).

CoreRegions=zeros(size(RetainedPCs));
[rows cols]=size(RetainedPCs);
for i=1:rows
    for j=1:cols
        if abs(RetainedPCs(i,j))>cutoffLoadings(j)
            CoreRegions(i,j)=1;
        end
    end
end

%% Step 2.2: Interpretation of scores of retained PCs
%
% GODDARD USES SCORES TO DEFINE FEEING AREAS INTO CORE REGIONS
% CoreRegions from above define the centre of each reagion. Goddard then
% takes the origins (data points) and looks at their scores - he somehow
% defines a cut off value (1) and takes the origins with absolute score values 
% higher than this threshold as those that define the total region together 
% with their respective CoreRegions.
%
% We do the same here, but he uses some set value, which we don't know what
% it is, so we try to find the cut off value in a similar way as above for
% loadings, but now with scores.
%
% Also we do this on transposed data, so origins are now destinations.

% First, take only as many PCs in scores are we took above:

ScoresRetainedPCs=Scores(:,1:NoOfRetainedPCs);

% First, box plots of absolute score values for each PC.
% Figure 5
figure
for i=1:NoOfRetainedPCs
    subplot(3,figureCols,i); boxplot(abs(ScoresRetainedPCs(:,i)),'colors','k','outliersize',4,'symbol','+r');
    hold on;
    title(sprintf('Boxplot Score PC%d',i),'fontsize',10);
    %xlabel(sprintf('PC%d',i),'fontsize',8);
    ylabel('Abs. Scores');
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{' '});
end 
savefig([outputPath,direction,'-',frame,'-','Fig5_Boxplots_ScoresOnContributingVariables_LookForOutliers'],'pdf');

% Now calculate cut off values as above, as outliers from 1.5 intraquartile
% ranges of absolute scores

qq=quantile(abs(ScoresRetainedPCs),[0.25 0.75]);
intraquartRangeScores=qq(2,:)-qq(1,:);
cutoffScores=mean(abs(ScoresRetainedPCs))+1.5*intraquartRangeScores
min(abs(ScoresRetainedPCs))
max(abs(ScoresRetainedPCs))

% Plot the score scatterplots with their cut off values
% Figure 6
figure
for i=1:NoOfRetainedPCs
    subplot(3,figureCols,i); scatter(1:NoOfRows,abs(ScoresRetainedPCs(:,i))',2,'.','k');
    hold on;
    plot(1:NoOfColumns,cutoffScores(i)*ones(1,NoOfColumns),'-r')
    hold on
    title(sprintf('Scores of PC%d',i),'fontsize',10);
    axis([1 NoOfColumns min(abs(ScoresRetainedPCs(:,i))) max(abs(ScoresRetainedPCs(:,i)))]);
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',{});
    yticks  = get(gca,'YTick');
    ylabels = {};
    for i=1:length(yticks)
        ylabels{i} = sprintf('%0.0f',yticks(i));
    end
    set(gca,'YTickLabel',ylabels);
end 
savefig([outputPath,direction,'-',frame,'-','Fig6_Scatterplots_NumbersVsScores'],'pdf');

% Create a matrix of SupportiveRegions - destinations with highest scores on
% each PC, in the same format as CoreRegions above.

SupportiveRegions=zeros(size(RetainedPCs));
for i=1:rows
    for j=1:cols
        if abs(ScoresRetainedPCs(i,j))>cutoffScores(j)
            SupportiveRegions(i,j)=2;
        end
    end
end

%% Step 2.3. Define total regions from core (loadings) and supportive
%(scores) regions

% This is the final result:
% TotalRegions is a matrix with as many rows as there are areas
% (origins/destinatons), and with as many columns as we retained PCs. 
% Each PC (column) defines one region, and the values in each row in one
% particular column mean the following:
% - value = 1 -> important origin in this region
% - value = 2 -> important destination in this region
% - value = 3 -> important origin AND destination in this region
% - value = 0 -> not in this region

TotalRegions=CoreRegions+SupportiveRegions;

% Let's check how many origins/destinations define each region:
l=zeros(1,NoOfRetainedPCs);
for i=1:NoOfRetainedPCs
    l(i)=length(nonzeros(TotalRegions(:,i)));
end
l

% Around 200 places in each region, looks reasonable. Now the next step
% would be to plot these gegraphically, but I don't have the coordinates,
% so this is something for Jon&Ed.

% Finally, export the resulting total regions into a csv file.
csvwrite([outputPath,direction,'-',frame,'-','RegionsUnrotated.csv'],TotalRegions);


%% Step 3: added on 16 Jan 2012
% Export absolute loadings of retained PCs, to be able to see a map of the
% scores for PC1 and why it is so different than the rest.
AbsRetainedPCs=abs(RetainedPCs)
%pause
csvwrite([outputPath,direction,'-',frame,'-','AbsoluteLoadings.csv'],AbsRetainedPCs);
%pause

% Also export percentage of explained variance and cumulative percentage of
% explained variance - for producing tables in the paper.
cumulativePercVar=percVar;
for i=2:length(percVar)
    cumulativePercVar(i,1)=cumulativePercVar(i-1,1)+cumulativePercVar(i,1);
end
%cumulativePercVar
%pause
% plot cumulative variance
figure
plot(1:NoOfColumns,cumulativePercVar,'-k',...
                'LineWidth',2,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',8)
hold on
title(sprintf('Cumulative Variance - All PCs'),'fontsize',10);
axis([1 NoOfColumns 0 1]);
savefig([outputPath,direction,'-',frame,'-','Fig7_CumulativeVariance_AllPCs'],'pdf');

% plot cumulative variance for retained PCs only
figure
plot(1:NoOfRetainedPCs,cumulativePercVar(1:NoOfRetainedPCs,1),'-ko',...
                'LineWidth',2,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',8')
hold on
title(sprintf('Cumulative Variance - Retained PCs'),'fontsize',10);
axis([1 NoOfRetainedPCs 0 1]);
savefig([outputPath,direction,'-',frame,'-','Fig8_CumulativeVariance_RetainedPCs'],'pdf');

%Export the explained variance (column1) and cumulative explained variance (column2) into csv files - for tables.
csvwrite([outputPath,direction,'-',frame,'-','ExplainedVariance.csv'],[percVar(1:NoOfRetainedPCs,1) cumulativePercVar(1:NoOfRetainedPCs,1)]);

% Added on 17 Jan 2012
% Export scores of retained PCs for hierarchical clustering (second part of
% Goddard's paper)
csvwrite([outputPath,direction,'-',frame,'-','ScoresRetainedPCs.csv'],ScoresRetainedPCs);

%% Note on size of exports: 
% 7 Feb 2012
% The two csv files with loadings and regions have 1140 elements -> that is
% because this is for origins and we excluded the 25 origins that had zeros
% in the original O/D matrix.
% The csv file with scores however is calculated on the transposed O/D
% matrix, therefore it has as many rows as there are data points in the
% transposed O/D matrix = no. of destinations = 1165.
