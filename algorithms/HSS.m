clear
close all;

load phydatarate_100users_10BSs.mat
N = 5000;                      % Number of interactions                        t = 1..N
u = zeros(S,N,M);              % Utility payoff of players                     u(j,t,i)
unoise = zeros(S,N,M);
a = zeros(N,M);                % Action of players                             a(t,i)
x = zeros(S,N+1,M);            % Probability player i choose action j at t     x(j,t,i)
avgP = zeros(N,M);             % Average payoff of user i at t                 avgP(t,i)
realP = zeros(N,M);            % Real payoff of user i at t                    realP(t,i)
count = zeros(N,S);            % Number of users connecting to j at t          count(t,j)
countweight = zeros(N,S);
avgcount = zeros(N,S);         % Avg number of users connecting to j at t      avgcount(t,j)
no = zeros(S,M);               % Number of times i connected to j untill t     no(j,t,i)
capacity = zeros(S,M);         % Estimated capacity of j by i                  capacity(j,i)
sumCapacity = zeros(S,M);      % Sum estimated capacity of j by i
number = zeros(S,M);           % Estimated no of user on j by i                number(j,i)
sumNumber = zeros(S,M);        % Sum estimated no of user on j by i
switching = zeros(N,M);        % Number of switching of user i at t            switching(t,i)
maxSwitchingT = zeros(1,N);    % Max switching number per user at t            maxSwitchingT(1,t)
avgSwitchingT = zeros(1,N);    % Avg switching number per user at t            avgSwitchingT(1,t)
overhead = zeros(N,1);
action = zeros(M,1);           % Number of available action of user i          action(i,1)
sumPayoff = zeros(N,1);
fairness = zeros(N,1);
xisquare = zeros(N,M);
actionWifi = zeros(M,1);
actionLTE = zeros(M,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:M
    [Q1,~] = max(datarate(1:S/2,i));
    [Q2,~] = max(datarate(S/2+1:S,i));
    for j = 1:S
        if (j <= S/2) && (datarate(j,i) < Q1)
            datarate(j,i) = 0;
        end
        if (j > S/2) && (datarate(j,i) < Q2)
            datarate(j,i) = 0;
        end
    end
end

for i = 1:M
    action(i,1) = S - sum(datarate(:,i)==0,1);
    if action(i,1) ~= 0       
        actionWifi(i,1) = S/2 - sum(datarate(1:S/2,i)==0,1);
        actionLTE(i,1) = S/2 - sum(datarate(S/2+1:S,i)==0,1);
        temp = rand;
        if temp <= 1/2 % user prefer to choose highest RSS among Wifi BSs
            if actionWifi(i,1) ~= 0
                for j = 1:S/2
                    if datarate(j,i) ~= 0
                        x(j,:,i) = 1/actionWifi(i,1);
                    end
                end
            else       % prefer Wifi but Wifi base stations not available
                for j = S/2+1:S
                    if datarate(j,i) ~= 0
                        x(j,:,i) = 1/actionLTE(i,1);
                    end
                end
            end
        else           % user prefer to choose highest RSS among LTE BSs
            if actionLTE(i,1) ~= 0
                for j = S/2+1:S
                    if datarate(j,i) ~= 0
                        x(j,:,i) = 1/actionLTE(i,1);
                    end
                end
            else       % prefer LTE but LTE base stations not available
                for j = 1:S/2
                    if datarate(j,i) ~= 0
                        x(j,:,i) = 1/actionWifi(i,1);
                    end
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main--algorithm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for t = 1:N
   %%%%%%%%%%%%%%%%%%%%%%%%%% Action choosing %%%%%%%%%%%%%%%%%%%%%%%%%% 
   for i = 1:M
       if t == 1
           if action(i,1) ~= 0
               temp = rand;
               j = 1;
               k = x(j,t,i);
               while (temp > k && j < S)
                   j = j+1;
                   k = k + x(j,t,i);
               end
               a(t,i) = j;
           end
       else
           a(t,i) = a(t-1,i);
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% Count user of j %%%%%%%%%%%%%%%%%%%%%%%%%%   
   for j = 1:S
       count(t,j) = sum(a(t,:)==j,2); % Number of users connecting to j at time t
       if t == 1
           avgcount(t,j) = count(t,j);
       else
           avgcount(t,j) = (avgcount(t-1,j)*(t-1)+count(t,j))/t;
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% Payoff learning %%%%%%%%%%%%%%%%%%%%%%%%%%   
   for i = 1:M
       if a(t,i) ~= 0
           %%%%%%%%%% If user i chooses LTE (BS1)
           if a(t,i) > S/2
               %%%%%% Real payoff by connecting to LTE
               u(a(t,i),t,i) = datarate(a(t,i),i)/count(t,a(t,i));
           %%%%%%%%%% If user i chooses WiFi (BS2:S)
           else
               %%%%%% Real payoff by connecting to WiFi
               temp = (a(t,:)==a(t,i)).*datarate(a(t,i),:);
               u(a(t,i),t,i) = 1/sum(1./temp(temp~=0));
           end
           realP(t,i) = u(a(t,i),t,i);       % Real payoff of user i at t
%            unoise(:,t,i) = abs(normrnd(u(:,t,i),noise.*u(:,t,i)));
           if t == 1
               avgP(t,i) = realP(t,i);
           else
               avgP(t,i) = (avgP(t-1,i)*(t-1)+realP(t,i))/t;
           end 
           xisquare(t,i) = realP(t,i)^2;
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% Fairness -- PoA %%%%%%%%%%%%%%%%%%%%%%%%%%   
   fairness(t,1) = (sum(realP(t,1:M),2))^2/sum(xisquare(t,1:M),2)/M;
   sumPayoff(t,1) = sum(realP(t,1:M),2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main--algorithm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
hold on
plot(1:N,avgP(:,:),'-','LineWidth',3)
ylabel('Average payoff')
xlabel('Iteration')

figure(2)
hold on
plot(1:N,realP(:,:),'-','LineWidth',3)
ylabel('Real payoff')
xlabel('Iteration')

figure(3)
hold on
plot(1:N,count(:,:),'-','LineWidth',3)
ylabel('Number of users connecting to each networks')
xlabel('Iteration')
axis([0 N 0 25])

figure(4)
hold on
plot(1:N,avgcount(:,:),'-','LineWidth',3)
ylabel('Average number of users connecting to each networks')
xlabel('Iteration')
axis([0 N 0 25])

figure(5)
hold on
plot(1:N,sumPayoff(:,1),'-x')
ylabel('Total payoffs of all users')
xlabel('Iteration')
legend('sumPayoff')

figure(6)
hold on
plot(1:N,fairness(:,1),'-x')
ylabel('System Fairness Index')
xlabel('Iteration')
legend('fairness')