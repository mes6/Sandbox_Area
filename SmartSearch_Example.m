clear;clc
%Variable Parameter Order
F_parms = {'hole radius','hole position','ledge hight'};
%Nominal Values
Nom_parms = [3 25 25];
%Search Space
uB = [19 66 66];%Upper Bound
lB = [ 1  7  7];%Lower Bound
%(Realitive) Importance of Each Parameter / 
    %        Difficulty to Implement Change
P_Imp = [1 1 1];


%% Automated Change Request Search Criteria

%Set up Fesiblity Tests - This would typically be handled by external
    %software
FeasiblityTests = @(f_parms) GrabFeasiblity(f_parms);
    
                   
%%Cost of Change Function - This should be a reflection of the cost or
    %difficulty of changing the total set of variable parameters. Not all
    %papamteres need to have the same 'cost' associated with them 
%   Total Cost of Change
Cost = @(f_parms) ...
    (1/sum(P_Imp))*abs(f_parms-repmat(Nom_parms,size(f_parms,1),1))*diag(P_Imp);

        

%% Initial Feasiblity Test

%Trial Counter
ti = 1;
%First Trial Should be the Nominal Parameter Set
    t_parms = [];
t_parms(ti,:) = Nom_parms;

%Initial Trial Performance Values
    %Perfom Fesiblity Test
    t_feasiblity = [];
t_feasiblity(ti,:) = FeasiblityTests(t_parms(ti,:));
    %Calculate Cost ('Difficulty') of Change
    t_cost = [];
t_cost(ti,:) = Cost(t_parms(ti,:));


%% Perform Feasiblity Search
    %Final Stopping Criteria
MaxTrials = 10000;
MaxTime = 60/(24*3600);
    myTic = now;
EdgesTested = false;
    %Loop Till Solution or Stoppage
while ~all(t_feasiblity(ti,:)) && ti < MaxTrials && now-myTic < MaxTime
    
    
    %%% Create Search Plan
    
    %Pair Good Performers
    N = 10;
      %Find top N Tests
       %Sort on Feasibility then cost
    [s,si] = sortrows([-sum(t_feasiblity,2) sum(t_cost,2)]);
        %Remove Entries with 0 passed tests
     si(s(:,1)==0) = [];
     %Find random 'Mate' which 'completes feasiblity'
     goodkids = zeros(0,size(Nom_parms,2));
    for ni = 1:min(N,length(si))
        %Match with top performer that gives max feasiblity
        X = sum(repmat(t_feasiblity(si(ni),:),size(t_feasiblity(si,:),1),1) ...
            & t_feasiblity(si,:),2);
%             X(ni) = -1;
        [~,xi] = max(X);
        %Randomly permute pair
        parents = t_parms([si(ni),si(xi)],:);
        goodkids(ni,:) = diag(parents(randi(2,1,size(t_parms,2)),:));
    end
            
    %Perterb Around Children
    jitter = randn(size(goodkids))*.01* diag(range([uB; lB])) ...
             .* repmat(range([lB;uB]),size(goodkids,1),1);
    neighborkids = goodkids + jitter;
    
    %Random Search Expanding from Nominal
    R = 10;
        %Search Spead (Bounded [.01,1])
    spread = 2*ti/MaxTrials;
    spread = min(max(spread,.01),1);
    
    jitter = randn(R,size(t_parms,2)) * spread * diag(range([uB; lB]));
    randomkids = repmat(Nom_parms,R,1) + jitter;
    
    %Combine New Tests
    children = [goodkids;neighborkids;randomkids];
    
    %Enforce Upper and Lower Bounds
    UB = repmat(max([uB;lB]),size(children,1),1);
    LB = repmat(min([uB;lB]),size(children,1),1);
    children(children>UB) = UB(children>UB);
    children(children<LB) = LB(children<LB);
    
    %Special Case! Look at Extremes
    if ti > .1*MaxTrials && ~EdgesTested
        EdgesTested = true;
        B = [uB;lB];
        x = ones(1,size(B,2));
        eN = size(B,1)^size(B,2);
        Edge = repmat(uB,eN,1);
        ni = 1;
        while ~all(x == size(B,1))
            x(1) = x(1)+1;
            for xi = 1:(length(x)-1)
                if x(xi) > size(B,1)
                    x(xi) = 1;
                    x(xi+1) = x(xi+1) + 1;
                end
            end
            ni = ni+1;
            Edge(ni,:) = B(sub2ind(size(B),x,1:size(B,2)));
        end
        children = [children; Edge];
    end
    %Sort By Cost
    KidsCost = Cost(children);
    [s,si] = sort(sum(KidsCost,2));
    
    KidsCost = KidsCost(si,:);
    children = children(si,:);
    
    %Loop Space - Perform Feasiblity Test
    ci = 0;
    while  ~all(t_feasiblity(ti,:)) && ci < size(children,1) && ti < MaxTrials
        %Index Child Counter
        ci = ci+1;
        %Skip Duplications
        if ~any(ismember(t_parms,children(ci,:)))
        %Index Test Counter
        ti = ti+1;
        %Store Parameters
        t_parms(ti,:) = children(ci,:);
        %Perform Tests
        t_feasiblity(ti,:) = FeasiblityTests(t_parms(ti,:));
        %Store Cost ('Difficulty') of Change
        t_cost(ti,:) = KidsCost(ci,:);
        end
    end
    
end

%% Final Result
clc
fprintf('Final Parameter Set After %i Tests\n',ti)
fprintf('\t%s>',F_parms{:})
fprintf('\n')
fprintf('\t\t\t%4.2f',t_parms(ti,:))
fprintf('\n')
fprintf('Feasiblity Test Results: < ')
fprintf('%i ',t_feasiblity(ti,:))
fprintf('>\n')
fprintf('Final Test Cost: < ')
fprintf('%4.2f ',t_cost(ti,:))
fprintf('>\n')
