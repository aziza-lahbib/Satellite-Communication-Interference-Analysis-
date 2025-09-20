close all; % Ferme toutes les figures ouvertes
clc ;
startTime = datetime(2020,5,1,11,36,0);
stopTime = startTime + days(1); %la fin du scénario, soit 1 jour après le startTime.
sampleTime = 60;
sc = satelliteScenario(startTime,stopTime,sampleTime);

% Station considérée comme le point boresight vers lequel le satellite est dirigé
lat = 10;
lon = -30;
% Coordonnées géographiques de la station au sol
gs = groundStation(sc,lat,lon);

semiMajorAxis = 7000000; 
eccentricity = 0.001;
inclination = 0; 
rightAscensionOfAscendingNode = 0; 
argumentOfPeriapsis = 0; 
trueAnomaly = 0;

sat1 = satellite(sc,semiMajorAxis,eccentricity,inclination, ...
        rightAscensionOfAscendingNode,argumentOfPeriapsis,trueAnomaly);

% Station terrestre d'interférence (TSI) en coordonnées géographiques fixes
lat_TSI = 20;  % Position lat de la station terrestre d'interférence
lon_TSI = -35; % Position lon de la station terrestre d'interférence

gs_TS = groundStation(sc,lat_TSI,lon_TSI);

% Calcul de l'accès entre le satellite et la station principale
ac = access(sat1,gs);
intvls = accessIntervals(ac);

% Paramètres
c = 3e8;  % Vitesse de la lumière (m/s)
frequence = 14e9;  % Fréquence de 14 GHz (bande ku)
lambda = c / frequence; % Longueur d'onde

EIRP = 50;       % dB
G_Rx = 30;       % Gain de l'antenne réceptrice pour le signal utile

% Paramètres de la station terrestre d'interférence (TSI)
EIRP_TSI = 30;   % EIRP de la station terrestre d'interférence (dB)
G_Rx_TSI = 8;   % Gain de l'antenne réceptrice pour l'interférence (dB)

currentTime = startTime;  % Heure actuelle


% Initialisation des résultats
times = [];  % Tableau pour enregistrer les instants de temps
C_I_values = [];  % Tableau pour enregistrer les valeurs du rapport C/I

while currentTime <= stopTime
    % Calcul des positions des satellites et de la station
    [satPos, ~] = states(sat1, currentTime, "CoordinateFrame", "ecef"); 
    gsPos = lla2ecef([lat, lon, 0]); 

    % Position de la station terrestre d'interférence
    gsPos_TSI = lla2ecef([lat_TSI, lon_TSI, 0]); 

    fprintf('Temps (UTC)     | C/I (dB)\n');
    fprintf('--------------------------\n');

    % Calcul de la distance entre le satellite et la station principale
    distance = norm(satPos - gsPos);  % Distance en mètres

    % Calcul de la distance entre la station principale et la station terrestre d'interférence (TSI)
    distance_TSI = norm(gsPos_TSI - gsPos);  % Distance en mètres

    % Calcul des pertes en espace libre
    L_current = 20*log10(4 * pi * distance / lambda);  
    L_TSI = 20*log10(4 * pi * distance_TSI / lambda);  

    % Calcul du rapport C/I 
    C_I = (EIRP + G_Rx - L_current) - (EIRP_TSI + G_Rx_TSI - L_TSI);

    fprintf('%s | %.2f dB\n', datestr(currentTime, 'HH:MM:SS'), C_I);

    % Enregistrement des résultats
    times = [times; currentTime];
    C_I_values = [C_I_values; C_I];  

    % Mise à jour du temps
    currentTime = currentTime + seconds(sampleTime);  % Passage à l'instant suivant
end

% Affichage du graphique
figure;
plot(times, C_I_values);
xlabel('Temps');
ylabel('Rapport C/I (dB)');
title('Evolution du rapport C/I au cours du temps');
grid on;
