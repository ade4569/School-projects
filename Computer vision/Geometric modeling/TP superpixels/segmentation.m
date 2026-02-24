clear
close all
% Nombre d'images utilisees
nb_images = 36; 

% chargement de l'image
nom = 'images/viff.001.ppm';
% im est une matrice de dimension 3 qui contient 
% une image couleur de taille : nb_lignes x nb_colonnes x nb_canaux 
% im est donc de dimension nb_lignes x nb_colonnes x nb_canaux
image_rgb(:,:,:) = imread(nom); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A COMPLETER                                             %
% Calculs des superpixels                                 % 
% Conseil : afficher les germes + les régions             %
% à chaque étape / à chaque itération                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ........................................................%
K = 400; % Nombre de superpixels
taille = size(image_rgb(:,:,1)); % Taille de l'image
N = taille(1)*taille(2); % Nombre de pixels dans l'image
S = round(sqrt(N/K)); % Taille d'un superpixel
C = []; % Liste des centres
m = 20; % Terme de compacité
% Critères d'arret de la segmentation
nb_iter_max = 10;
seuil = 10;

% Segmentation Matlab
figure
[L,num_lab] = superpixels(image_rgb,K);
BW = boundarymask(L);
imshow(imoverlay(image_rgb,BW,'cyan'),'InitialMagnification',67)
title('Segmentation Matlab');

% Conversion de l'image en LAB
image = rgb2lab(image_rgb);

% Affichage de l'image en LAB
figure
imshow(image)
title('Image LAB')

% Initialisation des centres
c_x = round(S/2);
c_y = round(S/2);
while taille(2) - c_y > 0
    while taille(1) - c_x > 0
        color = [image(c_x,c_y,1) image(c_x,c_y,2) image(c_x,c_y,3)];
        C = [C ; color c_x c_y];
        c_x = c_x + S;
    end
    c_y = c_y + S;
    c_x = round(S/2);
end

N_C = size(C,1);    % Nombre de centres

% Affichage des centres
figure
imshow(image_rgb) 
hold on;
plot(C(:,5),C(:,4),'*','color','r');
title('Initialisation des centres')

% Initialisation des labels et des distances
image = reshape(image,N,3);
labels = -1 * ones(N,1); % Labels
distances = Inf(N,1);  % Distances

% Kmeans
nb_iter = 0;
converge = false;
while ~converge && (nb_iter < nb_iter_max)
    for k = 1:size(C,1)
        x_c = C(k,4);
        y_c = C(k,5);
        for j = max(y_c-S,1):min(y_c+S,taille(2))
            for i = max(x_c-S,1):min(x_c+S,taille(1))  
                % Distance colorimétrique
                ind = sub2ind(taille,i,j);
                color = [image(ind,1) image(ind,2) image(ind,3)];
                dc = C(k,1:3) - color;
                dc = sqrt(sum(dc.^2));

                % Distance spatiale
                ds = C(k,4:5) - [i,j];
                ds = sqrt(sum(ds.^2));

                % Distance totale
                D = sqrt(dc^2 + ((ds/S)^2) * (m^2));

                % Mise à jour des distances et des labels
                if D < distances(ind)
                    distances(ind) = D;
                    labels(ind) = k;
                end
            end
        end
    end

    % Mise à jour des centres
    pos_C = C(:,4:5); % Positions des anciens centres
    for k = 1:size(C,1)
        indices = find(labels == k);
        selected = image(indices,:);
        C(k,1:3) = mean(selected(:,1:3));
        [row,col] = ind2sub(taille,indices);
        C(k,4:5) = mean([row,col]);
    end
    C(:,4:5) = round(C(:,4:5));

    % Déplacement total des centres
    deplacement = sum((pos_C - C(:,4:5)).^2, 2);
    deplacement = sum(sqrt(deplacement));
    if deplacement < seuil
        converge = true;
    end
    
    % Affichage des superpixels
    figure
    labels = reshape(labels,taille);
    mask = boundarymask(labels);
    imshow(labeloverlay(image_rgb,mask,'Transparency',0),'InitialMagnification',67)
    title(['Itération ',num2str(nb_iter+1)])
    
    % Affichage des centres
    hold on;
    plot(C(:,5),C(:,4),'*','color','r');

    nb_iter = nb_iter + 1;
end


% Binarisation
b_couleur = C(:,3); % Composante b des couleurs des centres
b_couleur = rescale(b_couleur);
[counts,x] = imhist(b_couleur,32);
T = otsuthresh(counts);

im_mask = zeros(taille);
for i=1:taille(1)
    for j=1:taille(2)
        im_mask(i,j) = b_couleur(labels(i,j)) > T;
    end
end

% Affichage du masque binaire
figure
imshow(im_mask)

