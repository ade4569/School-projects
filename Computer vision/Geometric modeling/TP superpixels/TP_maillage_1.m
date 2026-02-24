clear;
close all;
% Nombre d'images utilisees
nb_images = 36; 

% chargement des images
for i = 1:nb_images
    if i<=10
        nom = sprintf('images/viff.00%d.ppm',i-1);
    else
        nom = sprintf('images/viff.0%d.ppm',i-1);
    end
    % im est une matrice de dimension 4 qui contient 
    % l'ensemble des images couleur de taille : nb_lignes x nb_colonnes x nb_canaux 
    % im est donc de dimension nb_lignes x nb_colonnes x nb_canaux x nb_images
    im(:,:,:,i) = imread(nom); 
end

% Affichage des images
figure; 
subplot(2,2,1); imshow(im(:,:,:,1)); title('Image 1');
subplot(2,2,2); imshow(im(:,:,:,9)); title('Image 9');
subplot(2,2,3); imshow(im(:,:,:,17)); title('Image 17');
subplot(2,2,4); imshow(im(:,:,:,25)); title('Image 25');

% Conversion de l'image en LAB
for num_im = 1:nb_images
    image(:,:,:,num_im) = rgb2lab(im(:,:,:,num_im));
end

% Masques binaires
im_mask = zeros(size(image,1),size(image,2),nb_images);

for num_im = 1:nb_images

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A COMPLETER                                             %
    % Calculs des superpixels                                 % 
    % Conseil : afficher les germes + les régions             %
    % à chaque étape / à chaque itération                     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % ........................................................%
    K = 400; % Nombre de superpixels
    taille = size(image(:,:,1)); % Taille de l'image
    N = taille(1)*taille(2); % Nombre de pixels dans l'image
    S = round(sqrt(N/K)); % Taille d'un superpixel
    C = []; % Liste des centres
    m = 20; % Terme de compacité
    % Critères d'arret de la segmentation
    nb_iter_max = 10;
    seuil = 10;
    
    % Segmentation Matlab
    % figure
    % [L,num_lab] = superpixels(image,K);
    % BW = boundarymask(L);
    % imshow(imoverlay(image,BW,'cyan'),'InitialMagnification',67)
    
    % Initialisation des centres
    c_x = round(S/2);
    c_y = round(S/2);
    while taille(2) - c_y > 0
        while taille(1) - c_x > 0
            color = [image(c_x,c_y,1,num_im) image(c_x,c_y,2,num_im) image(c_x,c_y,3,num_im)];
            C = [C ; color c_x c_y];
            c_x = c_x + S;
        end
        c_y = c_y + S;
        c_x = round(S/2);
    end
    
    N_C = size(C,1);    % Nombre de centres
    
    % Affichage des centres
    % hold on;
    % plot(C(:,5),C(:,4),'*','color','r');
    
    % Initialisation des labels et des distances
    image_vec = reshape(image(:,:,:,num_im),N,3);
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
                    color = [image_vec(ind,1) image_vec(ind,2) image_vec(ind,3)];
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
            selected = image_vec(indices,:);
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
    
        nb_iter = nb_iter + 1;
    end
    
    % Affichage des superpixels
    regions = lab2rgb(image_vec);
    regions = reshape(regions,taille(1),taille(2),3);
    
    % figure
    labels = reshape(labels,taille);
    mask = boundarymask(labels);
    %mask = boundarymask(L);
    % imshow(labeloverlay(regions,mask,'Transparency',0),'InitialMagnification',67)
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A COMPLETER                                             %
    % Binarisation de l'image à partir des superpixels        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % ........................................................%
    b_couleur = C(:,3); % Composante b des couleurs des centres
    b_couleur = rescale(b_couleur);
    [counts,x] = imhist(b_couleur,32);
    T = otsuthresh(counts);
    
    for i=1:taille(1)
        for j=1:taille(2)
            im_mask(i,j,num_im) = b_couleur(labels(i,j)) > T;
        end
    end
end
save im_mask


