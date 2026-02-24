%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSEIL : A METTRE DANS UN AUTRE SCRIPT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load donnees;
% Calcul des faces du maillage
FACES = zeros(4*size(tri,1),3);
for i = 1:size(tri,1)
    faces = [tri(i,1:3) ; tri(i,2:4) ; tri(i,[1,2,4]) ; tri(i,[1,3,4])];
    FACES((4*i-3):(4*i),:) = faces;
end

% Tri des faces
FACES = sortrows(FACES, 1:3);

% Suppression des faces
for j = size(FACES,1):-1:2
    if FACES(j,:) == FACES(j-1,:)
        FACES(j,:) = [];
        FACES(j-1,:) = [];
    end
end

fprintf('Calcul du maillage final termine : %d faces. \n',size(FACES,1));

% Affichage du maillage final
% figure;
% hold on
% for i = 1:size(FACES,1)
%    plot3([X(1,FACES(i,1)) X(1,FACES(i,2))],[X(2,FACES(i,1)) X(2,FACES(i,2))],[X(3,FACES(i,1)) X(3,FACES(i,2))],'r');
%    plot3([X(1,FACES(i,1)) X(1,FACES(i,3))],[X(2,FACES(i,1)) X(2,FACES(i,3))],[X(3,FACES(i,1)) X(3,FACES(i,3))],'r');
%    plot3([X(1,FACES(i,3)) X(1,FACES(i,2))],[X(2,FACES(i,3)) X(2,FACES(i,2))],[X(3,FACES(i,3)) X(3,FACES(i,2))],'r');
% end