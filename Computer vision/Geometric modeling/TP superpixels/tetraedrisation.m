clear
close all

nb_images = 36; % Nombre d'images
rayon_min = 5; % Rayon minimal

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

% chargement des masques (pour l'elimination des fonds bleus)
% de taille nb_lignes x nb_colonnes x nb_images
load mask;
fprintf('Chargement des donnees termine\n');

mask_1 = im_mask(:,:,1);
mask_1 = 1 - mask_1;
% figure;
% title('Masque image 1');
% imshow(mask_1);

taille = size(mask_1);

% Initialisation du premier point du contour
x0 = round(taille(1)/2);
y0 = 1;
while mask_1(x0,y0) ~= 1
    y0 = y0 + 1;
end

% Affichage du contour
contour = bwtraceboundary(mask_1,[x0 y0],'W');
% hold on;
% plot(y0,x0,'*','color','y');
% hold on;
% plot(contour(:,2),contour(:,1),'g','LineWidth',2);
% axis equal;

% Voronoi
%[vx, vy] = voronoi(contour(:,1),contour(:,2));
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
% hold on
% plot(squelette(:,2),squelette(:,1),'.','color','m')

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
% figure;
% title('Axe médian');
% imshow(mask_1);
% hold on
% [coordsx, coordsy] = ind2sub(taille,1:taille(1)*taille(2));
% gplot(A,[coordsy', coordsx'])

% chargement des points 2D suivis 
% pts de taille nb_points x (2 x nb_images)
% sur chaque ligne de pts 
% tous les appariements possibles pour un point 3D donne
% on affiche les coordonnees (xi,yi) de Pi dans les colonnes 2i-1 et 2i
% tout le reste vaut -1
pts = load('viff.xy');
% Chargement des matrices de projection
% Chaque P{i} contient la matrice de projection associee a l'image i 
% RAPPEL : P{i} est de taille 3 x 4
load dino_Ps;

% Reconstruction des points 3D
X = []; % Contient les coordonnees des points en 3D
color = []; % Contient la couleur associee
% Pour chaque couple de points apparies
for i = 1:size(pts,1)
    % Recuperation des ensembles de points apparies
    l = find(pts(i,1:2:end)~=-1);
    % Verification qu'il existe bien des points apparies dans cette image
    if size(l,2) > 1 & max(l)-min(l) > 1 & max(l)-min(l) < 36
        A = [];
        R = 0;
        G = 0;
        B = 0;
        % Pour chaque point recupere, calcul des coordonnees en 3D
        for j = l
            A = [A;P{j}(1,:)-pts(i,(j-1)*2+1)*P{j}(3,:);
            P{j}(2,:)-pts(i,(j-1)*2+2)*P{j}(3,:)];
            R = R + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),1,j));
            G = G + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),2,j));
            B = B + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),3,j));
        end;
        [U,S,V] = svd(A);
        X = [X V(:,end)/V(end,end)];
        color = [color [R/size(l,2);G/size(l,2);B/size(l,2)]];
    end;
end;
fprintf('Calcul des points 3D termine : %d points trouves. \n',size(X,2));

%affichage du nuage de points 3D
figure;
hold on;
for i = 1:size(X,2)
    plot3(X(1,i),X(2,i),X(3,i),'.','col',color(:,i)/255);
end;
axis equal;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A COMPLETER                  %
% Tetraedrisation de Delaunay  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = delaunayTriangulation(X(1:3,:)');                    

% A DECOMMENTER POUR AFFICHER LE MAILLAGE
fprintf('Tetraedrisation terminee : %d tetraedres trouves. \n',size(T,1));
% Affichage de la tetraedrisation de Delaunay
% figure;
% tetramesh(T);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A DECOMMENTER ET A COMPLETER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calcul des barycentres de chacun des tetraedres
poids = ones(4,5);
for i = 1:4
    poids(i,i+1) = 4;
end
poids = poids ./ repmat(sum(poids),4,1);
nb_barycentres = 5; 
C_g = zeros(4,size(T,1),nb_barycentres);
for i = 1:size(T,1)
    % Calcul des barycentres differents en fonction des poids differents
    % En commencant par le barycentre avec poids uniformes
    barycentre = [T.Points(T.ConnectivityList(i,:),:) ones(4,1)];
    for k = 1:nb_barycentres
        C_g(:,i,k) = poids(:,k)' * barycentre;
    end
end

% A DECOMMENTER POUR VERIFICATION 
% A RE-COMMENTER UNE FOIS LA VERIFICATION FAITE
% Visualisation pour vérifier le bon calcul des barycentres
% for i = 1:nb_images
%    for k = 1:nb_barycentres
%        o = P{i}*C_g(:,:,k);
%        o = o./repmat(o(3,:),3,1);
%        imshow(im_mask(:,:,i));
%        hold on;
%        plot(o(2,:),o(1,:),'rx');
%        pause;
%        close;
%    end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A DECOMMENTER ET A COMPLETER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copie de la triangulation pour pouvoir supprimer des tetraedres
tri=T.ConnectivityList;
% Retrait des tetraedres dont au moins un des barycentres 
% ne se trouvent pas dans au moins un des masques des images de travail
% Pour chaque barycentre
for j=size(T,1):-1:1
    supprime = false;
    for k=1:nb_barycentres
        masked = 0; % nombre de masques dans lesquels im_mask(barycentre) vaut 1
        for i=1:nb_images
            proj_bary = P{i}*C_g(:,j,k);
            proj_bary = proj_bary./repmat(proj_bary(3),3,1);
            x = round(proj_bary(1));
            y = round(proj_bary(2));
            if x > 0 && y > 0 && x <= taille(1) && y <= taille(2) && im_mask(x,y,i)
                supprime = true;
            end
        end
    end
    % suppression du tetraèdre
    if supprime
        tri(j,:) = [];
    end
end

% A DECOMMENTER POUR AFFICHER LE MAILLAGE RESULTAT
% Affichage des tetraedres restants
fprintf('Retrait des tetraedres exterieurs a la forme 3D termine : %d tetraedres restants. \n',size(tri,1));
figure;
trisurf(tri,X(1,:),X(2,:),X(3,:));

% Sauvegarde des donnees
save donnees;

