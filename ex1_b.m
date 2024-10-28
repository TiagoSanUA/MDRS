%ex1.b

N = 20;                             % Times to run the simulation

P = 100000;                         % Number of packets to be transmitted (stopping criterium)
C = 10;                             % link bandwidth (Mbps)
f = 1e6;                            % Queue size (Bytes)
b = 10^-4;                          % Bit error rate


lambda = [1500 1600 1700 1800 1900]; % rate of arrival to the queue in pps

% Store graph data
APD_values = zeros(1, length(lambda));
APD_terms = zeros(1, length(lambda));
PL_values = zeros(1, length(lambda));
PL_terms = zeros(1, length(lambda));

% Store sim results
PL = zeros(1, N);
APD = zeros(1, N);
MPD = zeros(1, N);
TT = zeros(1, N);

alfa = 0.1;                         % 90% confidence interval for results

% Run simulation N

for i = 1:length(lambda)
    for x = 1:N
        [PL(x), APD(x), MPD(x), TT(x)] = Sim2(lambda(i), C, f, P, b);
    end

    fprintf('For lambda = %d\n', lambda(i));

    % Calculate avg. packet delay
    media = mean(APD);
    term = norminv(1-alfa/2)*sqrt(var(APD)/N);
    APD_values(i) = media;
    APD_terms(i) = term;
    fprintf('Avg. packet delay: %.5f\n', APD_values(i));
    
    % Calculate avg. Packet Loss
    media = mean(PL);
    term = norminv(1-alfa/2)*sqrt(var(PL)/N);
    PL_values(i) = media;
    PL_terms(i) = term;
    fprintf('Avg. packet loss: %.5f\n\n', PL_values(i));

end

% Figure to show the asked results for 1.b)
figure(1);
hold on;
grid on;
bar(lambda, APD_values');                            % Bar Graph
ylim([0 9]);                                       % Set y axis values
er = errorbar(lambda, APD_values', APD_terms);       % Set the error bar
er.Color = [0 0 0];
er.LineStyle = 'none';
xlabel('Packet Rate (pps)') 
ylabel('Avg. Packet Delay (ms)')
title('Average Packet Delay vs Packet Rate');
hold off;
saveas(gcf, 'Avg_Packet_Delay_vs_Packet_Rate.png');  % Save the graph as PNG

% Figure to show the asked results for 1.b)
figure(2);
hold on;
grid on;
bar(lambda, PL_values');                             % Bar Graph
er = errorbar(lambda, PL_values', PL_terms);         % Set the error bar
er.Color = [0 0 0];
er.LineStyle = 'none';
xlabel('Packet Rate (pps)')
ylabel('Packet Loss (%)')
title('Packet Loss vs Packet Rate');
hold off;
saveas(gcf, 'Packet_Loss_vs_Packet_Rate.png');       % Save the graph as PNG