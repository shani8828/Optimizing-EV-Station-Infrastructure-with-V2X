clc; clear;

% Load static stations
station = data();
% Draw base network

[station, G, shortestDist] = generateStaticNetwork(station.location);
numStations = length(station.ids);

% Car input
numCars = input('Enter number of cars: ');
fprintf('Enter details for each car: [charging(mAh), mileage(km/mAh), maxDistance]\n');
fprintf('Also enter current station ID and destination station ID (1 to %d)\n', numStations);

car.data = zeros(numCars, 3);
car.location = zeros(numCars, 1);
car.routeDest = zeros(numCars, 1);

for i = 1:numCars
    fprintf('\nCar #%d\n', i);
    car.data(i,:) = input('Enter [charging, mileage, maxDistance]: ');
    car.location(i) = input('Enter current station ID: ');
    car.routeDest(i) = input('Enter destination station ID: ');
end
% Initialize allocation variables
allocations = -1 * ones(numCars, 1);      
paths = cell(numCars, 1);                 
pathsToDest = cell(numCars, 1);           

for i = 1:numCars
    currStation = car.location(i);       
    destStation = car.routeDest(i);       

    % Maximum driving range = min(charging × mileage, maxDistAllowed)
    maxRange = min(car.data(i,1) * car.data(i,2), car.data(i,3));
    routePath = shortestpath(G, currStation, destStation);
    pathsToDest{i} = routePath;

    reachable = [];

    for s = routePath
        if s == currStation
            continue;   % Skiping current location
        end

        dist = shortestDist(currStation, s);

        if dist > maxRange
            fprintf('Car %d: Station %d is %.2f units away but max range is %.2f — too far.\n', ...
                    i, s, dist, maxRange);
            
            break;
        end

        if station.occupied(s) >= station.capacity(s)
            fprintf('Car %d: Station %d within range (%.2f) but is full (capacity: %d, occupied: %d).\n', ...
                    i, s, dist, station.capacity(s), station.occupied(s));
            continue;
        end

        % otherwise condition
        reachable = [reachable; s];
    end

    % If no station is reachable, skip allocation for this car
    if isempty(reachable)
        fprintf('No reachable station for Car %d (max range = %.2f). Skipping allocation.\n', ...
                i, maxRange);
        continue;
    end

    % highest availability percentage station should selected 
    availabilities = arrayfun(@(x) ...
        (station.capacity(x) - station.occupied(x)) / station.capacity(x), ...
        reachable);

    [~, idx] = max(availabilities);
    bestStation = reachable(idx);

    % Handle conflicts – by taking giving priority to lesser cost car
    fightingCars = find(arrayfun(@(x) ...
        ismember(bestStation, shortestpath(G, car.location(x), car.routeDest(x))) && ...
        shortestDist(car.location(x), bestStation) <= ...
        min(car.data(x,1) * car.data(x,2), car.data(x,3)), 1:numCars));

    if station.occupied(bestStation) < station.capacity(bestStation)
        if ismember(i, fightingCars)
            costs = car.data(fightingCars,1) .* car.data(fightingCars,2);
            [~, bestIdx] = min(costs);
            chosenCar = fightingCars(bestIdx);

            if chosenCar == i
                allocations(i) = bestStation;
                station.occupied(bestStation) = station.occupied(bestStation) + 1;
                paths{i} = shortestpath(G, currStation, bestStation);
                fprintf('Car %d allocated to Station %d\n', i, bestStation);
            else
                fprintf('Car %d lost allocation for Station %d to Car %d (lower cost).\n', ...
                        i, bestStation, chosenCar);
            end
        end
    else
        fprintf('Car %d could not be allocated: Station %d is already full during conflict resolution.\n', ...
                i, bestStation);
    end
end


% Display allocations
fprintf('\n=== Final Allocations ===\n');
for i = 1:numCars
    if allocations(i) == -1
        fprintf('Car %d: Not Allocated\n', i);
    else
        fprintf('Car %d: Allocated to Station %d\n', i, allocations(i));
    end
end

% Final visual with highlighted paths
generateStaticNetwork(station.location, car, pathsToDest, paths);
