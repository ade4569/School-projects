% Calcul d'une mosaique d'image à partir de 3 images : I1, I2 et I3
% connaissant les homographies H12 entre I1 et I2 et H32 entre I3 et I2. 
% L'image resultat est stockee dans Imos. 
% On choisit de projeter I1 et I3 dans I2 pour construire la mosaique. 
% Attention !!!
% On suppose un axe de rotation parallèle aux colonnes. 
% C'est la raison pour laquelle on inverse les lignes et les colonnes 
% dans la reconstruction de la mosaique. 

function Imos3 = mosaique3(Im1,Im2,Im3,TailleFenetre,NbPoints,k,seuil)
    % Tailles des images
    [nbl1, nbc1, ~] = size(Im1);
    [nbl2, nbc2, ~] = size(Im2);
    [nbl3, nbc3, ~] = size(Im3);

    % Images en couleur ou en noir et blanc
    img_couleur = false;
    taille = size(Im1);
    if length(taille) == 3 && taille(3) == 3
        img_couleur = true;
    end

    % Mosaique d'images en couleur ou en noir et blanc
    Im1NB = im2gray(Im1);
    Im2NB = im2gray(Im2);
    Im3NB = im2gray(Im3);

    % Détection des points d'intérêt
    [XY_1,~] = harris(Im1NB,TailleFenetre,NbPoints,k);
    [XY_2,~] = harris(Im2NB,TailleFenetre,NbPoints,k);
    [XY_3,~] = harris(Im3NB,TailleFenetre,NbPoints,k);

    % Appariement des points d'intérêt
        % Points d'intérêts entre I1 et I2
    [XY_C1_12,XY_C2_12] = apparier_POI(Im1NB,XY_1,Im2NB,XY_2,TailleFenetre,seuil); 
        % Points d'intérêts entre I2 et I3
    [XY_C1_32,XY_C2_32] = apparier_POI(Im2NB,XY_2,Im3NB,XY_3,TailleFenetre,seuil);

    % Estimation (et verification) de l'homographie
        % entre I1 et I2
    H12 = homographie(XY_C2_12,XY_C1_12);
        % entre I2 et I3
    H32 = homographie(XY_C1_32,XY_C2_32);

    Hinv12 = inv(H12);
    Hinv12 = Hinv12./Hinv12(3,3);

    Hinv32 = inv(H32);
    Hinv32 = Hinv32./Hinv32(3,3);

    % Calcul des coins projetés dans le repère de Im2
    coinsI1 = [1 1; nbc1 1; nbc1 nbl1; 1 nbl1];
    coinsI3 = [1 1; nbc3 1; nbc3 nbl3; 1 nbl3];
    
    coinsI1_R2 = appliquerHomographie(Hinv12, coinsI1);
    coinsI3_R2 = appliquerHomographie(Hinv32, coinsI3);
    
    % Détermination des bornes de la mosaïque
    xmin = floor(min([1, coinsI1_R2(:,1)', coinsI3_R2(:,1)']));
    ymin = floor(min([1, coinsI1_R2(:,2)', coinsI3_R2(:,2)']));
    xmax = ceil(max([nbc2, coinsI1_R2(:,1)', coinsI3_R2(:,1)']));
    ymax = ceil(max([nbl2, coinsI1_R2(:,2)', coinsI3_R2(:,2)']));
    
    % Initialisation de la mosaïque
    nblImos = ymax - ymin + 1;
    nbcImos = xmax - xmin + 1;
    if img_couleur
        Imos3 = zeros(nblImos, nbcImos, 3);
    else
        Imos3 = zeros(nblImos, nbcImos);
    end

    % Origine de Im2 dans le repère mosaïque
    O2x = 1 - (xmin - 1);
    O2y = 1 - (ymin - 1);
    
    % Copie de l'image Im2
    if img_couleur
        Imos3(O2y:O2y+nbl2-1, O2x:O2x+nbc2-1, :) = Im2;
    else
        Imos3(O2y:O2y+nbl2-1, O2x:O2x+nbc2-1) = Im2;
    end

    % Copie des images I1 et I3 transformées par les homographies H12 et H32 
    for x = 1:nbcImos
        for y = 1:nblImos
            % Coordonnées du point dans le repère de Im2
            x_R2 = x - O2x;
            y_R2 = y - O2y;
    
            % Initialisation
            val_total = 0;
            poids_total = 0;
    
            % Im2 (image au centre de la mosaïque)
            if x_R2 >= 1 && x_R2 <= nbc2 && y_R2 >= 1 && y_R2 <= nbl2
                val2 = Im2(y_R2, x_R2, :);
                w2 = nbc2 - round(abs(x_R2 - nbc2/2));
                val_total = val_total + w2 * double(val2);
                poids_total = poids_total + w2;
            end
    
            % Im1
            xy1 = appliquerHomographie(H12, [x_R2, y_R2]);
            x1 = round(xy1(1));
            y1 = round(xy1(2));
            if x1 >= 1 && x1 <= nbc1 && y1 >= 1 && y1 <= nbl1
                val1 = Im1(y1, x1, :);
                w1 = nbc1 - x1;
                val_total = val_total + w1 * double(val1);
                poids_total = poids_total + w1;
            end
    
            % Im3
            xy3 = appliquerHomographie(H32, [x_R2, y_R2]);
            x3 = round(xy3(1));
            y3 = round(xy3(2));
            if x3 >= 1 && x3 <= nbc3 && y3 >= 1 && y3 <= nbl3
                val3 = Im3(y3, x3, :);
                w3 = x3;
                val_total = val_total + w3 * double(val3);
                poids_total = poids_total + w3;
            end
    
            % Combinaison des 3 images
            if poids_total > 0
                Imos3(y, x, :) = val_total / poids_total;
            end
        end
    end
    Imos3 = uint8(Imos3);
end
