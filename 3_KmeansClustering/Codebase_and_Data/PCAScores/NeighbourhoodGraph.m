function f=NeighbourhoodGraph(GeogMatrix,bw)

% Step 1: calculate distance matrix of points in geographic space
% for bw no. of neighbours

% Read geog coordinates from the data - 
%GeogMatrix=DataMatrix(:,2:3);

[rows cols]=size(GeogMatrix);

% Define original adj.matrix Inf - unconnected points will have infinity
% distance between them
OriginalAdjMatrix=Inf(rows);

for i=1:rows
	for j=i:rows
        if i~=j 
            x1=GeogMatrix(i,1);
            x2=GeogMatrix(j,1);
            y1=GeogMatrix(i,2);
            y2=GeogMatrix(j,2);
            d=sqrt((x1-x2)^2+(y1-y2)^2); %Eucl distance between points
            %put d on both positions in the matrix, on each side of the
            %diagonal
            OriginalAdjMatrix(i,j)=d;
            OriginalAdjMatrix(j,i)=d;
        else
            % put zeroes on the diagonal
            OriginalAdjMatrix(i,j)=0;
        end % if i==j
    end % for j=1:i
end % for i=1:rows

% Plot the full graph defined by OriginalAdjMatrix, to check if it
% works.
%disp('Full graph on all points.');
%figure
%for i=1:rows
%	for j=1:rows %(i-1)
%		if OriginalAdjMatrix(i,j)~=0 && OriginalAdjMatrix(i,j)~=Inf
%			Graphx=[GeogMatrix(i,1) GeogMatrix(j,1)];
%			Graphy=[GeogMatrix(i,2) GeogMatrix(j,2)];
%			plot(Graphx,Graphy,'-ok',...
%               'LineWidth',1,...
%                'MarkerEdgeColor','k',...
%                'MarkerFaceColor','g',...
%                'MarkerSize',5),hold on
%		end;
%	end;
%end;

% Now take only the nearest bw neighbours for each point and also build up
% a vector of max_distances for each point, which will be used for
% geographic weighting later on.

AdjMatrix=zeros(rows);
zerosToAdd=AdjMatrix(1,1:rows-(bw+1));

for i=1:rows 
    rowToBeSorted=OriginalAdjMatrix(i,:);
    [sortedRow,permutation]=sort(rowToBeSorted,'ascend');
    % take bw+1 smallest values (each point itself + bw closest neighbours)
    newSortedRow=[sortedRow(1:bw+1) zerosToAdd];
    % add both rows and transpose
    Temp2MatrixToBeSorted=[newSortedRow;permutation]';
    % sort rows according to 2nd column=permutation and transpose back
    TempSorted2Matrix=sortrows(Temp2MatrixToBeSorted,2)';
    % sortedRow is now the first row of this temp sorted matrix, so we
    % put this in row i of the the NewAdjMatrix 
    AdjMatrix(i,:)=TempSorted2Matrix(1,:);
end

% Read the largest of the distance values in each row (that is why I 
% need to transpose the AdjMatrix first, as max works per column) into 
% max_distance vector
max_distance=max(AdjMatrix')';
%pause

% Plot the bw-neighbourhood graph defined by AdjMatrix, to check if it
% works.
disp('Neighbourhood graph with k nearest neighbours.');
figure
for i=1:rows
	for j=1:rows %(i-1)
		if AdjMatrix(i,j)~=0
			Graphx=[GeogMatrix(i,1) GeogMatrix(j,1)];
			Graphy=[GeogMatrix(i,2) GeogMatrix(j,2)];
			plot(Graphx,Graphy,'-ok',...
                'LineWidth',1,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','g',...
                'MarkerSize',5),hold on
		end;
	end;
end;

%Return the adjacency matrix
f=AdjMatrix;
end
