clear
close all;

load phydatarate_100users_10BSs.mat
N = 5000;                      % Number of interactions                        t = 1..N
u = zeros(S,M);                % Utility payoff of players                     u(j,t,i)
a = zeros(N,M);                % Action of players                             a(t,i)
x = zeros(S,M);                % Probability player i choose action j at t     x(j,t,i)
d = zeros(S,N,M);              % Difference in payoff of user i                d(k,t,i)
avgP = zeros(N,M);             % Average payoff of user i at t                 avgP(t,i)
realP = zeros(N,M);            % Real payoff of user i at t                    realP(t,i)
count = zeros(N,S);            % Number of users connecting to j at t          count(t,j)
avgcount = zeros(N,S);         % Avg number of users connecting to j at t      avgcount(t,j)
no = zeros(S,M);               % Number of times i connected to j untill t     no(j,i)
capacity = zeros(S,M);         % Estimated capacity of j by i                  capacity(j,i)
sumCapacity = zeros(S,M);      % Sum estimated capacity of j by i
number = zeros(S,M);           % Estimated no of user on j by i                number(j,i)
sumNumber = zeros(S,M);        % Sum estimated no of user on j by i
sumRegret = zeros(S,S,M);
switching = zeros(N,M);        % Number of switching of user i at t            switching(t,i)
action = zeros(M,1);           % Number of available action of user i          action(i,1)
sumPayoff = zeros(N,1);
fairness = zeros(N,1);
xisquare = zeros(N,M);
delta = 0.00001;               % 0 < delta << 1
gamma = 0.1;                   % 0 < gamma < 1/4
epsilon = 0.1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:M
    action(i,1) = S - sum(datarate(:,i)==0,1);
    for j = 1:S
        if datarate(j,i) ~= 0
            x(j,i) = 1/action(i,1);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main--algorithm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for t = 1:N
   
   %%%%%%%%%%%%%%%%%%%%%%%%%% Action choosing %%%%%%%%%%%%%%%%%%%%%%%%%%   
   for i = 1:M
       if t <= S
           if (action(i,1) ~= 0) && (datarate(t,i) ~= 0)
               a(t,i) = t;
               switching(t,i) = t-1;
           end
       else
           if action(i,1) ~= 0
               temp = rand;
               j = 1;
               k = x(j,i);
               while (temp > k && j < S)
                   j = j+1;
                   k = k + x(j,i);
               end
               a(t,i) = j;
               if a(t,i) ~= a(t-1,i)
                   switching(t,i) = switching(t-1,i)+1;
               else
                   switching(t,i) = switching(t-1,i);
               end
           end
       end
       if a(t,i) ~= 0
           no(a(t,i),i) = no(a(t,i),i)+1;
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
   %%%%%%%%%%%%%%%%%%%%%%%%%% Payoff function %%%%%%%%%%%%%%%%%%%%%%%%%%   
   for i = 1:M
       if a(t,i) ~= 0
           %%%%%%%%%% If user i chooses LTE (a(t,i)>S/2)
           if a(t,i) > S/2
               %%%%%% Real payoff by connecting to LTE
               u(a(t,i),i) = datarate(a(t,i),i)/count(t,a(t,i));
           %%%%%%%%%% If user i chooses WiFi (a(t,i)<=S/2)
           else
               %%%%%% Real payoff by connecting to WiFi
               temp = (a(t,:)==a(t,i)).*datarate(a(t,i),:);
               u(a(t,i),i) = 1/sum(1./temp(temp~=0));
           end
           realP(t,i) = u(a(t,i),i); % Real payoff of user i at t
           if t == 1
               avgP(t,i) = realP(t,i);
           else
               avgP(t,i) = (avgP(t-1,i)*(t-1)+realP(t,i))/t;
           end 
           xisquare(t,i) = realP(t,i)^2;
     %%%%%%%%%%%%%%%%%%%% Throughput estimation %%%%%%%%%%%%%%%%%%%%%%%           
           sumCapacity(a(t,i),i) = sumCapacity(a(t,i),i) + u(a(t,i),i)*count(t,a(t,i));
           capacity(a(t,i),i) = sumCapacity(a(t,i),i)/no(a(t,i),i);
           if t>S
               sumNumber(a(t,i),i) = sumNumber(a(t,i),i)+count(t,a(t,i));
               number(a(t,i),i) = sumNumber(a(t,i),i)/(no(a(t,i),i)-1);
           end           
       end
   end
   for i = 1:M
       if a(t,i) ~= 0
           for k = 1:S
               if (k ~= a(t,i)) && (datarate(k,i) ~= 0)
                   u(k,i) = capacity(k,i)/(number(k,i)+1);
               end
           end
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% RLNF learning %%%%%%%%%%%%%%%%%%%%%%%%%% 
   if t > S
       for i = 1:M
           if a(t,i) ~= 0
               x(a(t,i),i) = 0;
               for k = 1:S
                   if (k ~= a(t,i)) && (datarate(k,i) ~= 0)
                       sumRegret(k,a(t,i),i) = sumRegret(k,a(t,i),i) + u(k,i) - u(a(t,i),i);
                       d(k,t,i) = 1/t*sumRegret(k,a(t,i),i);
                   end
               end
               for k = 1:S
                   x(k,i) = (1-delta/t^gamma)*max(d(k,t,i),0)/(sum(max(d(:,t,i),0),1)+epsilon)+delta/t^gamma/S;
               end
               x(a(t,i),i) = 1 - sum(x(:,i),1);
           end
       end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%% Fairness -- PoA %%%%%%%%%%%%%%%%%%%%%%%%%%   
   fairness(t,1) = (sum(realP(t,1:M),2))^2/sum(xisquare(t,1:M),2)/M;
   sumPayoff(t,1) = sum(realP(t,1:M),2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main--algorithm %%%%%%%%%%%%%%%%%%%%%%%%%%
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
