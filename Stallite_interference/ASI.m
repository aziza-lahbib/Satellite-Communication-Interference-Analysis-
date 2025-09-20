close all; % Ferme toutes les figures ouvertes
startTime = datetime(2020,5,1,11,36,0);
stopTime = startTime + days(1); %la fin du scénario, soit 1 jour après le startTime.
% La fonction days(1) ajoute 1 jour à startTime.

sampleTime = 60;
sc = satelliteScenario(startTime,stopTime,sampleTime);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%station est considérée comme le point boresight 
% vers lequel le satellite est dirigé
% vers lequel le satellite est dirigé
lat = 10;
lon = -30;
%coordonnées géographiques de la station au sol
gs = groundStation(sc,lat,lon);

semiMajorAxis = 7000000; 

semiMajorAxis2 = 36000000; 
eccentricity = 0.001;
eccentricity2 = 0.005;

inclination = 0; 
rightAscensionOfAscendingNode = 0; 
argumentOfPeriapsis = 0; 
trueAnomaly = 0; 
trueAnomaly2 = 180;
sat1 = satellite(sc,semiMajorAxis,eccentricity,inclination, ...
        rightAscensionOfAscendingNode,argumentOfPeriapsis,trueAnomaly);

sat2 = satellite(sc,semiMajorAxis2,eccentricity2,inclination, ...
        rightAscensionOfAscendingNode,argumentOfPeriapsis,trueAnomaly2);
ac = access(sat1,gs);

intvls = accessIntervals(ac);

ac2 = access(sat2, gs);

intvls2 = accessIntervals(ac2);
c = 3e8;

frequence = 14e9;  % 14 GHz bande ku


lambda = 3e8 / frequence; 




%paramètres

EIRP = 50;       % 
G_Rx = 30;        %  30 dB:Gain de l'antenne réceptrice pour le signal utile 


EIRP_ASI = 45;        
G_Rx_ASI = 25;         % Gain de l'antenne réceptrice de l'ASI (linéaire)

currentTime = startTime;  % Heure actuelle

% Initialisation des résultats
times = [];  % Tableau pour enregistrer les instants de temps
C_I_values = [];  % Tableau pour enregistrer les valeurs du rapport C/I
play(sc);

while currentTime <= stopTime
    % Calcul des positions des satellites et de la station
    [satPos, ~] = states(sat1, currentTime, "CoordinateFrame", "ecef"); 
    [satPos2, ~] = states(sat2, currentTime, "CoordinateFrame", "ecef");
    gsPos = lla2ecef([lat, lon, 0]); 

    fprintf('Temps (UTC)     | C/I (dB)\n');
    fprintf('--------------------------\n');
    % Calcul de la distance entre le satellite et la station
    distance = norm(satPos - gsPos);  % Distance en mètres
    distance_ASI = norm(satPos2 - gsPos);  % Distance en mètres

    % Calcul des pertes en espace libre
   
    L_current = 20*log10(4 * pi * distance / lambda);  % Pertes en espace libre à cet instant
    L_ASI = 20*log10(4* pi * distance_ASI / lambda);  % Pertes en espace libre pour l'ASI

    % Calcul du rapport C/I 
    C_I = (EIRP + G_Rx - L_current ) -(EIRP_ASI + G_Rx_ASI - L_ASI);

  
    fprintf('%s | %.2f dB\n', datestr(currentTime, 'HH:MM:SS'), C_I);

    % Enregistrement des résultats
    times = [times; currentTime];
    C_I_values = [C_I_values; C_I];  

    % Mise à jour du temps
    currentTime = currentTime + seconds(sampleTime);  % Passage à l'instant suivant
end

figure;
plot(times, C_I_values);
xlabel('Temps');
ylabel('Rapport C/I (dB)');
title('Evolution du rapport C/I au cours du temps');
grid on;





