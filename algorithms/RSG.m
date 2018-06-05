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
avgcount = zeros(N,S);         % Avg number of users connecting to j at t      avgcount(t,j)
no = zeros(S,M);               % Number of times i connected to j untill t     no(j,t,i)
switching = zeros(N,M);        % Number of switching of user i at t            switching(t,i)
action = zeros(M,1);           % Number of available action of user i          action(i,1)
sumPayoff = zeros(N,1);
fairness = zeros(N,1);
xisquare = zeros(N,M);
eta = 1.1;
p = 0.2;
threshold = 4;
mi = zeros(S,N,M);
noise = 0.3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:M
    action(i,1) = S - sum(datarate(:,i)==0,1);
    for j = 1:S
        if datarate(j,i) ~= 0 && action(i,1) ~= 0
            x(j,1:threshold+1,i) = 1/action(i,1);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main--algorithm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for t = 1:N
   
   %%%%%%%%%%%%%%%%%%%%%%%%%% Action choosing %%%%%%%%%%%%%%%%%%%%%%%%%% 
   for i = 1:M
       if action(i,1) ~= 0
           temp = rand;
           j = 1;
           k = x(j,t,i);
           while (temp > k && j < S)
               j = j+1;
               k = k + x(j,t,i);
           end
           a(t,i) = j;
           if t > 1
               if a(t,i) ~= a(t-1,i)
                   switching(t,i) = switching(t-1,i)+1;
               else
                   switching(t,i) = switching(t-1,i);
               end
           end
       end
   end
   if a(t,i) ~= 0
       no(a(t,i),i) = no(a(t,i),i)+1;
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
   for i = 1:M
       for k = 1:S
           if t > 1
               temp = count(t,k) - count(t-1,k);
               if temp >= 0
                   mi(k,t,i) = temp;
               end
           end
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% Payoff function %%%%%%%%%%%%%%%%%%%%%%%%%%   
   for i = 1:M
       if a(t,i) ~= 0
           %%%%%%%%%% If user i chooses WiFi
           if a(t,i) <= S/2
               %%%%%% Real payoff by connecting to WiFi
               temp = (a(t,:)==a(t,i)).*datarate(a(t,i),:);
               u(a(t,i),t,i) = 1/sum(1./temp(temp~=0));
               %%%%%% Expected payoff if connecting to Wifi
               for k = 1:S
                   if (k ~= a(t,i)) && (datarate(k,i) ~= 0)
                       if k <= S/2
                           temp = (a(t,:)==k).*datarate(k,:);
                           u(k,t,i) = 1/(sum(1./temp(temp~=0)) + 1/datarate(k,i));
               %%%%%% Expected payoff if connecting to LTE
                       else
                           u(k,t,i) = datarate(k,i)/(count(t,k)+1);
                       end
                   end
               end
           %%%%%%%%%% If user i chooses LTE
           else
               %%%%%% Real payoff by connecting to LTE
               u(a(t,i),t,i) = datarate(a(t,i),i)/count(t,a(t,i));
               %%%%%% Expected payoff if connecting to Wifi
               for k = 1:S
                   if (k ~= a(t,i)) && (datarate(k,i) ~= 0)
                       if k <= S/2
                           temp = (a(t,:)==k).*datarate(k,:);
                           u(k,t,i) = 1/(sum(1./temp(temp~=0)) + 1/datarate(k,i));                           
               %%%%%% Expected payoff if connecting to LTE
                       else
                           u(k,t,i) = datarate(k,i)/(count(t,k)+1);
                       end
                   end
               end
           end
           realP(t,i) = u(a(t,i),t,i);       % Real payoff of user i at t
           unoise(:,t,i) = abs(normrnd(u(:,t,i),noise.*u(:,t,i)));
           if t == 1
               avgP(t,i) = realP(t,i);
           else
               avgP(t,i) = (avgP(t-1,i)*(t-1)+realP(t,i))/t;
           end 
           xisquare(t,i) = realP(t,i)^2;
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% RSG learning %%%%%%%%%%%%%%%%%%%%%%%%%% 
   if t > threshold
       for i = 1:M
           if a(t,i) ~= 0
               for k = 1:S
                   if (k ~= a(t,i)) && (datarate(k,i) ~= 0)
                       if (u(k,t,i)/unoise(a(t,i),t,i) > eta) && (u(k,t-1,i)/unoise(a(t-1,i),t-1,i) > eta) && (u(k,t-2,i)/unoise(a(t-2,i),t-2,i) > eta) && (u(k,t-3,i)/unoise(a(t-3,i),t-3,i) > eta)
                           if ((a(t,i)==1)&&(k==1))||((a(t,i)>1)&&(k>1))
                               x(k,t+1,i) = p^(mi(k,t,i)+1);
                           else
                               if u(k,t,i) > max(unoise(k,1:t,i))
                                   x(k,t+1,i) = p^(mi(k,t,i)+1);
                               end
                           end
                       end
                   end
               end
               x(a(t,i),t+1,i) = 1 - sum(x(:,t+1,i),1);
           end
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