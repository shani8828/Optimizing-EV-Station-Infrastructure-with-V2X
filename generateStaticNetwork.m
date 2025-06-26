function [station, G, shortestDist] = generateStaticNetwork(existingLocations, car, pathsToDest, paths)
% ==== Load station data ====
if nargin < 1 || isempty(existingLocations)
    station = data();  % load from separate file
else
    station = data();  % still load all data but overwrite location
    station.location = existingLocations;
end

numStations = length(station.ids);


% ==== Graph creation ====
edges = [];
for i = 1:numStations
    dists = vecnorm(station.location - station.location(i,:), 2, 2);
    [~, neighbors] = sort(dists);
    numNeighbors = randi([3, 5]);
    neighbors = neighbors(2:(1 + numNeighbors));
    for j = neighbors'
        dist = norm(station.location(i,:) - station.location(j,:));
        edges = [edges; i j dist];
    end
end

G = graph(edges(:,1), edges(:,2), edges(:,3), numStations);
shortestDist = distances(G);

% ==== Plotting ====
figure; hold on; axis equal; grid on;
title('EV Station Network with Availability Color Coding');

% Color code by % availability
availabilityPct = (station.capacity - station.occupied) ./ station.capacity;
colors = availabilityPct;

% Draw base network
plot(G, 'XData', station.location(:,1), 'YData', station.location(:,2), ...
     'NodeLabel', {}, 'EdgeAlpha', 0.2, 'EdgeColor', [0.7 0.7 0.9]);

% Scatter stations
scatter(station.location(:,1), station.location(:,2), ...
    60, colors, 'filled');

colormap(jet); colorbar;
caxis([0 1]);
ylabel(colorbar, 'Availability %');

% Station labels
for i = 1:numStations
    avail = station.capacity(i) - station.occupied(i);
    pct = availabilityPct(i) * 100;
    label = sprintf('ID:%d | %d/%d | %.0f%%', ...
        station.ids(i), avail, station.capacity(i), pct);
    text(station.location(i,1)+1, station.location(i,2)+1, label, 'FontSize', 7);
end

% ==== Overlay paths if provided ====
if nargin >= 3 && ~isempty(car)
    numCars = length(car.location);
    colors = lines(numCars);
    for i = 1:numCars
        % Dotted line: Full shortest path
        pathToDest = pathsToDest{i};
        for j = 1:(length(pathToDest)-1)
            p1 = station.location(pathToDest(j),:);
            p2 = station.location(pathToDest(j+1),:);
            plot([p1(1), p2(1)], [p1(2), p2(2)], '--', 'Color', colors(i,:), 'LineWidth', 1);
        end

        % Bold line: Final assigned path (if any)
        if ~isempty(paths{i})
            p = paths{i};
            for j = 1:(length(p)-1)
                p1 = station.location(p(j),:);
                p2 = station.location(p(j+1),:);
                plot([p1(1), p2(1)], [p1(2), p2(2)], '-', 'Color', colors(i,:), 'LineWidth', 2);
            end
        end
    end
end

end
