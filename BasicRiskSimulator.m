clc;clear;%close all
% figure(4);clf

%Simulation Length
maxTime = 8*5*52;

%Number of Work Cells/Production Lines
nPLines = 10;

%Mean Time Between Failures per Line
MTBF = 100;
MTBFs = 50;

%- Normal Opperations
%Production Rate Per Line
ProductRate = 100;
%Opperation Cost per unit Time 
optCost = 10;

%- Reactive Action
%Repair Time 
rMTTR = 4;
%Total Cost
rmCost = 1000;

%- Preventative Action
%Repair Time
pMTTR = 1;
%Total Cost
pmCost = 250;



% % %Set up Tests % % % % % % % % % % % % % % % % % % % % % % % % % % %
%Test 1 - no Monitoring System 
%       - no Calender Based Maintenance
%Monitoring System Stats
Tests(1).FalseAlarmRate = 0;
Tests(1).MissedAlarmRate = 1;
Tests(1).CalenderMaint = inf;

%Test 2 - perfect Monitoring System 
%       - no Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = 0;
Tests(ti).MissedAlarmRate = 0;
Tests(ti).CalenderMaint = inf;

%Test 3 - no Monitoring System 
%       - too much Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = 0;
Tests(ti).MissedAlarmRate = 1;
Tests(ti).CalenderMaint = 5;

%Test 4 - no Monitoring System 
%       - Okay Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = .00;
Tests(ti).MissedAlarmRate = 1;
Tests(ti).CalenderMaint = 20;


%Test 5 - no Monitoring System 
%       - too little Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = 0;
Tests(ti).MissedAlarmRate = 01;
Tests(ti).CalenderMaint = 40;


%Test 6 - good Monitoring System 
%       - no Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = .05;
Tests(ti).MissedAlarmRate = .01;
Tests(ti).CalenderMaint = inf;


%Test 7 - Bad Monitoring System 
%       - no Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = .25;
Tests(ti).MissedAlarmRate = .1;
Tests(ti).CalenderMaint = inf;


%Test 8 - Okay Monitoring System 
%       - good Calender Based Maintenance
ti = length(Tests)+1;
%Monitoring System Stats
Tests(ti).FalseAlarmRate = .05;
Tests(ti).MissedAlarmRate = .1;
Tests(ti).CalenderMaint = 20;
 % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


 
 %Perform Tests
for Test_i = 1:length(Tests)
for trial = 1:100
    
%Initilize Lines
LineHealth = ones(1,nPLines)*MTBF;
MaintNeeded = zeros(1,nPLines);
TimeSinceRepair = zeros(1,nPLines);
Product = zeros(1,nPLines);
DownTime = zeros(1,nPLines);
RunningCost = zeros(1,nPLines);

%Loop Time
for t = 1:maxTime
    %Loop Production Lines
    for pl = 1:nPLines
        %If Line is Operating
        if MaintNeeded(pl) == 0
            %Operations Cost
            RunningCost(pl) = RunningCost(pl) + optCost;
            %Make Product
            Product(pl) = Product(pl) + ProductRate;
            %Count Operation Time
            TimeSinceRepair(pl) = TimeSinceRepair(pl) + 1;
            %Degrade Line
            LineHealth(pl) = LineHealth(pl) - 1;
            FailRisk = LineHealth(pl) - (randn*MTBFs);
            
            
            %Check if Calender Recommends Repair
            if TimeSinceRepair(pl) > Tests(Test_i).CalenderMaint
                %Add Maint
                MaintNeeded(pl) = MaintNeeded(pl) + pMTTR;
                %Add Maint Cost
                RunningCost(pl) = RunningCost(pl) + pmCost;
            else
                %Check if Line NEEDS Repair based on conditions
                if FailRisk < 0
                    %Check if Monitoring System Catches Fault
                    %   (i.e. No Missed Alarm)
                    if  Tests(Test_i).MissedAlarmRate <= rand
                        %Add Maint
                        MaintNeeded(pl) = MaintNeeded(pl) + pMTTR;
                        %Add Maint Cost
                        RunningCost(pl) = RunningCost(pl) + pmCost;

                    else%Line Breaks                    
                        %Add Maint
                        MaintNeeded(pl) = MaintNeeded(pl) + rMTTR;
                        %Add Maint Cost
                        RunningCost(pl) = RunningCost(pl) + rmCost;
                    end
                    
                %Line does NOT need repair    
                else 
                    %Check if False Alarm From Monitoring System
                    if Tests(Test_i).FalseAlarmRate >= rand
                        %Add Maint
                        MaintNeeded(pl) = MaintNeeded(pl) + pMTTR;
                        %Add Maint Cost
                        RunningCost(pl) = RunningCost(pl) + pmCost;
                    end
                end
            end
        
        else
            %Line is Under Repair
            DownTime(pl) = DownTime(pl)+1;
            MaintNeeded(pl) = MaintNeeded(pl) - 1;
            if MaintNeeded(pl) == 0
                LineHealth(pl) = MTBF;
                TimeSinceRepair(pl) = 0;
            end
        end
        
    end
    
    %Simulation Logs
    s_LineHealth(t,:) = 100*LineHealth./MTBF;
    s_MaintNeeded(t,:) = MaintNeeded;
    s_Product(t,:) = Product;
    s_DownTime(t,:) = DownTime;
    s_RunningCost(t,:) = RunningCost;
end



% figure(1)
% plot(s_LineHealth)
% title('Production Line Health')
% xlabel('Time (Hours)')
% ylabel('Health (% of Max)')
% 
% figure(2)
% plot(s_MaintNeeded)
% title('Maintenance Needed')
% xlabel('Time (Hours)')
% ylabel('Hours till Repair')
% 
% figure(3)
% subplot(211)
% plot(sum(s_Product,2))
% title('Total Production Across Lines')
% xlabel('Time (Hours)')
% ylabel('Products Produced')
% 
% subplot(212)
% plot(s_Product)
% title('Total Production by Line')
% xlabel('Time (Hours)')
% ylabel('Products Produced')
% 
% figure(4)
% if Test_i == 1;clf;end
% plot(sum(s_Product,2))
% title('Total Production Across Lines')
% xlabel('Time (Hours)')
% ylabel('Products Produced')
% hold on
% 

%Trial/Test Outcomes
Average_LineHealth(trial,Test_i) = mean(100*LineHealth./MTBF);

Total_Products(trial,Test_i) = sum(Product);
Total_RunningCost(trial,Test_i) = sum(RunningCost);
Total_DownTime(trial,Test_i) = sum(DownTime);


end

end


%% Outcome Reports
figure(5)
subplot(211)
boxplot(Total_Products)
xlabel('Test Number')
ylabel('Units Produced')
title('Total Units Produced')

subplot(212)
boxplot(Total_RunningCost)
xlabel('Test Number')
ylabel('Costs Incurred')
title('Total Operations and Maint Cost Produced')

figure(6)
subplot(211)
boxplot(Total_DownTime)
xlabel('Test Number')
ylabel('Down Time')
title('Total Down Time Across Lines')

subplot(212)
boxplot(Average_LineHealth)
xlabel('Test Number')
ylabel('Health (%)')
title('Average Line Health Across Lines')

figure(7)
boxplot(Total_Products - Total_RunningCost)
%      [0 length(Tests)],[0 0],'r--')
title({'Test Profitability:','^{Profits = Production - Costs}'})
xlabel('Test Number')
ylabel('Profit')