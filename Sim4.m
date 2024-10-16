function [PLd ,PLv ,APDd ,APDv ,MPDd ,MPDv , TT] = Sim4(lambda,C,f,P,n)
% INPUT PARAMETERS:
%  lambda - packet rate (packets/sec)
%  C      - link bandwidth (Mbps)
%  f      - queue size (Bytes)
%  P      - number of packets (stopping criterium)
%  n      - VoIP Packet flows
% OUTPUT PARAMETERS:
%  PLd   - packet loss of data packets (%)
%  PLv   - packet loss of VoIP packets (%)
%  APDd  - average packet delay of data packets (milliseconds)
%  APDv  - average packet delay of VoIP packets (milliseconds)
%  MPDd  - maximum packet delay of data packets (milliseconds)
%  MPDv  - maximum packet delay of VoIP packets  (milliseconds)
%  TT   - transmitted throughput (data + VoIP)(Mbps)

%Events:
ARRIVAL= 0;       % Arrival of a packet            
DEPARTURE= 1;     % Departure of a packet

%Packet type
DATA = 0;
VOIP = 1;
%State variables:
STATE = 0;          % 0 - connection is free; 1 - connection is occupied
QUEUEOCCUPATION= 0; % Occupation of the queue (in Bytes)
QUEUE= [];          % Size and arriving time instant of each packet in the queue

%Statistical Counters:
TOTALPACKETSd= 0;     % No. of data packets arrived to the system
TOTALPACKETSv= 0;     % No. of VoIP packets arrived to the system
LOSTPACKETSd= 0;      % No. of data packets dropped due to buffer overflow
LOSTPACKETSv= 0;      % No. of VoIP packets dropped due to buffer overflow
TRANSPACKETSd= 0;     % No. of transmitted data packets
TRANSPACKETSv= 0;     % No. of transmitted VoIP packets
TRANSBYTESd= 0;       % Sum of the Bytes of transmitted data packets
TRANSBYTESv= 0;       % Sum of the Bytes of transmitted VoIP packets
DELAYSd= 0;           % Sum of the delays of transmitted data packets
DELAYSv= 0;           % Sum of the delays of transmitted VoIP packets
MAXDELAYd= 0;         % Maximum delay among all transmitted data packets
MAXDELAYv= 0;         % Maximum delay among all transmitted VoIP packets

% Initializing the simulation clock:
Clock= 0;

% Initializing the List of Events with the first ARRIVAL:
tmp= Clock + exprnd(1/lambda);
EventList = [ARRIVAL, tmp, GeneratePacketSize(), tmp,DATA];

% Initializing the List of Events with the first ARRIVAL:
for i = 1:n
    tmp= Clock + 0.02*rand();    % time instant of the first packet arrival of each VoIP flow must be randomly generated with a uniform distribution between 0 and 20 milliseconds.
    EventList = [EventList;ARRIVAL, tmp, randi([110,130]), tmp,VOIP];
end

%Similation loop:
while (TRANSPACKETSd+TRANSPACKETSv)<P               % Stopping criterium
    EventList= sortrows(EventList,2);  % Order EventList by time
    Event= EventList(1,1);              % Get first event 
    Clock= EventList(1,2);              %    and all
    PacketSize= EventList(1,3);        %    associated
    ArrInstant= EventList(1,4);    %    parameters.
    PacketType= EventList(1,5);     % Packet Type
    EventList(1,:)= [];                 % Eliminate first event
    switch Event
        case ARRIVAL         % If first event is an ARRIVAL
            if(PacketType==DATA)

                TOTALPACKETSd= TOTALPACKETSd+1;
                tmp= Clock + exprnd(1/lambda);
                EventList = [EventList; ARRIVAL, tmp, GeneratePacketSize(), tmp,DATA];
                if STATE==0
                    STATE= 1;
                    EventList = [EventList; DEPARTURE, Clock + 8*PacketSize/(C*10^6), PacketSize, Clock, DATA];
                else
                    if QUEUEOCCUPATION + PacketSize <= f
                        QUEUE= [QUEUE;PacketSize , Clock,DATA];
                        QUEUEOCCUPATION= QUEUEOCCUPATION + PacketSize;
                    else
                        LOSTPACKETSd= LOSTPACKETSd + 1;
                    end
                end

            else
                TOTALPACKETSv= TOTALPACKETSv+1;
                tmp= Clock + 0.016+0.008*rand(); 
                EventList = [EventList; ARRIVAL, tmp, randi([110,130]), tmp,VOIP];
                if STATE==0
                    STATE= 1;
                    EventList = [EventList; DEPARTURE, Clock + 8*PacketSize/(C*10^6), PacketSize, Clock, VOIP];
                else
                    if QUEUEOCCUPATION + PacketSize <= f
                        QUEUE= [QUEUE;PacketSize , Clock,VOIP];
                        QUEUEOCCUPATION= QUEUEOCCUPATION + PacketSize;
                    else
                        LOSTPACKETSv= LOSTPACKETSv + 1;
                    end
                end

            end
        case DEPARTURE          % If first event is a DEPARTURE
            if(PacketType==DATA)
                TRANSBYTESd= TRANSBYTESd + PacketSize;
                DELAYSd= DELAYSd + (Clock - ArrInstant);
                if Clock - ArrInstant > MAXDELAYd
                    MAXDELAYd= Clock - ArrInstant;
                end
                TRANSPACKETSd= TRANSPACKETSd + 1;
            
            else
                TRANSBYTESv= TRANSBYTESv + PacketSize;
                DELAYSv= DELAYSv + (Clock - ArrInstant);
                if Clock - ArrInstant > MAXDELAYv
                    MAXDELAYv= Clock - ArrInstant;
                end
                TRANSPACKETSv= TRANSPACKETSv + 1;

            end
            if QUEUEOCCUPATION > 0
                QUEUE = sortrows(QUEUE,-3);         % VoIP packets are given higher priority than data packets in the queue because 1 > 0
                EventList = [EventList; DEPARTURE, Clock + 8*QUEUE(1,1)/(C*10^6), QUEUE(1,1), QUEUE(1,2), QUEUE(1,3)];
                QUEUEOCCUPATION= QUEUEOCCUPATION - QUEUE(1,1);
                QUEUE(1,:)= [];
            else
                STATE= 0;
            end
           
    end
end

%Performance parameters determination:
PLd= 100*LOSTPACKETSd/TOTALPACKETSd;  % in percentage
PLv= 100*LOSTPACKETSv/TOTALPACKETSv;  % in percentage
APDd= 1000*DELAYSd/TRANSPACKETSd;     % in milliseconds
APDv= 1000*DELAYSv/TRANSPACKETSv;     % in milliseconds
MPDd= 1000*MAXDELAYd;                % in milliseconds
MPDv= 1000*MAXDELAYv;                % in milliseconds
TT= 1e-6*(TRANSBYTESd+TRANSBYTESv)*8/Clock;    % in Mbps

end

function out= GeneratePacketSize()
    aux= rand();
    aux2= [65:109 111:1517];
    if aux <= 0.19
        out= 64;
    elseif aux <= 0.19 + 0.23
        out= 110;
    elseif aux <= 0.19 + 0.23 + 0.17
        out= 1518;
    else
        out = aux2(randi(length(aux2)));
    end
end