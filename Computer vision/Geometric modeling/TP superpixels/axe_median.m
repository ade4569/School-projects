clear
close all
nb_images = 36; % Nombre d'images
rayon_min = 5; % Rayon minimal

% chargement de l'image
nom = 'images/viff.001.ppm';

% chargement des masques (pour l'elimination des fonds bleus)
% de taille nb_lignes x nb_colonnes x nb_images
load mask;
fprintf('Chargement des donnees termine\n');
mask_1 = im_mask(:,:,1);
mask_1 = 1 - mask_1;

% load im_mask;
% fprintf('Chargement des donnees termine\n');
% mask_1 = im_mask(:,:,1);

figure;
imshow(mask_1);
title('Masque image 1');

taille = size(mask_1);

% Initialisation du premier point du contour
x0 = round(taille(1)/2);
y0 = 1;
while mask_1(x0,y0) ~= 1
    y0 = y0 + 1;
end

% Affichage du contour
contour = bwtraceboundary(mask_1,[x0 y0],'W');
hold on;
plot(y0,x0,'*','color','y');
hold on;
plot(contour(:,2),contour(:,1),'g','LineWidth',2);
axis equal;

% Filtrage du contour
contour = contour(1:10:end,:);

% Voronoi
[vx, vy] = voronoi(contour(2:end,1),contour(2:end,2));
vx = round(vx);
vy = round(vy);
Ns = size(vx,2); % Nombre de sommets dans Voronoi
P = [vx(1,:)' vy(1,:)' ; vx(2,:)'  vy(2,:)'];
P = unique(P,'rows');   % liste des sommets distincts

% Recherche des points du squelette
squelette = [];
for i = 1:size(P,1)
    x = P(i,1);
    y = P(i,2);
    if x <= taille(1) && y <= taille(2) && x > 0 && y > 0 && mask_1(x,y)
        distance = contour - repmat([x y],size(contour,1),1);
        distance = distance.^2;
        distance = sqrt(sum(distance,2));
        rayon = min(distance);
        if rayon > rayon_min
            squelette = [squelette ; x y rayon];
        end
    end
end

% Affichage des points du squelette
hold on
plot(squelette(:,2),squelette(:,1),'.','color','m')

% Recherche des aretes de l'axe médian
A = sparse(taille(1)*taille(2));
for j = 1:Ns
    x1 = vx(1,j);
    x2 = vx(2,j);
    y1 = vy(1,j);
    y2 = vy(2,j);
    if x1 > 0 && x2 > 0 && y1 > 0 && y2 > 0 && ...
            x1 <= taille(1) && x2 <= taille(1) && y1 <= taille(2) && y2 <= taille(2) && ...
            mask_1(x1,y1) && mask_1(x2,y2)

        i1 = sub2ind(taille,x1,y1);
        i2 = sub2ind(taille,x2,y2);
        A(i1,i2) = 1;
        A(i2,i1) = 1;
    end
end

% Affichage de l'axe médian
figure;
imshow(mask_1);
hold on
[coordsx, coordsy] = ind2sub(taille,1:taille(1)*taille(2));
gplot(A,[coordsy', coordsx'])
title('Axe médian');




