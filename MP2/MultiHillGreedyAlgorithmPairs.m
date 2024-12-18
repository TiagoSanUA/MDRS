function [bestTime, bestCicleNum, bestSol, bestObjective, noCycles, avObjective] = MultiHillGreedyAlgorithmPairs(nNodes, Links, T, sP, nSP, timeLimit)
    t = tic;
    bestTime = 0;
    bestCicleNum = 0;
    nFlows = size(T, 1);
    bestObjective = inf;
    noCycles = 0;
    aux = 0;
    
    while toc(t) < timeLimit
        % Generate initial solution with Greedy Randomized
        [sol, load] = GR(nFlows, nSP, nNodes, Links, T, sP);
        
        % Improve solution using Multi-Hill Climbing Refinement
        [sol, load] = MHR(nFlows, nSP, nNodes, Links, T, sP, sol, load);
        
        % Track best solution and its objective value
        noCycles = noCycles + 1;
        aux = aux + load;
        if load < bestObjective
            bestSol = sol;
            bestObjective = load;
            bestTime = toc(t);
            bestCicleNum = noCycles;
        end
    end
    avObjective = aux / noCycles;
end

% Greedy Randomized function
function [sol, load] = GR(nFlows, nSP, nNodes, Links, T, sP)
    sol = zeros(1, nFlows);
    randFlows = randperm(nFlows);
    for f = randFlows
        temp = inf;
        best_p = 1; % Initialize best_p with a default path index
        for p = 1:nSP(f)
            sol(f) = p;
            
            Loads = calculateLinkBand1to1(nNodes, Links, T, sP, sol);
         
            load = max(max(Loads(:, 3:4)));
            if load < temp
                temp = load;
                best_p = p;
            end
        end
        sol(f) = best_p;
    end
   
    Loads = calculateLinkBand1to1(nNodes, Links, T, sP, sol);
    
    load = max(max(Loads(:, 3:4)));
end

% Multi-Hill Climbing Refinement function
function [sol, load] = MHR(nFlows, nSP, nNodes, Links, T, sP, sol, load)
    BestLoad = load;
    BestSol = sol;
    improved = true;
    while improved
        for flow = 1:nFlows
            for path = 1:nSP(flow)
                if path ~= sol(flow)
                    auxSol = sol;
                    auxSol(flow) = path;
                    Loads = calculateLinkBand1to1(nNodes, Links, T, sP, auxSol);
                    auxLoad = max(max(Loads(:, 3:4)));
                    if auxLoad < BestLoad
                        BestLoad = auxLoad;
                        BestSol = auxSol;
                    end
                end
            end
        end
        if BestLoad < load
            load = BestLoad;
            sol = BestSol;
        else
            improved = false;
        end
    end
end
