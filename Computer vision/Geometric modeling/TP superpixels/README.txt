Dans le fichier TP_maillage_1.m, il y a la segmentation en superpixels de chaque image,
puis la segmentation binaire pour obtenir le masque de chaque image. Cela permet
d'obtenir les masques binaires qui sont enregistrés dans la matrice im_mask.

Dans le fichier TP_maillage_2.m, il y a la triangulation des points reconstruits et 
l'élimination des tétraèdres superflus, qui permet d'obtenir les données pour 
générer le maillage.

Dans le fichier TP_maillage_3.m, il y a le calcul des faces du maillage, mais cela
ne fonctionne pas. Trop peu de faces sont éliminées pour obtenir un résultat 
convenable.

Dans le fichier axe_median.m, il y a le calcul de l'axe médian pour une image, à
partir d'un des masques fournis.

Dans le fichier segmentation.m, il y a la segmentation en superpixels et la création
d'un masque binaire pour une seule image. La segmentation est comparée avec celle
de Matlab.

Dans le fichier tetraedrisation.m, il y a la tetraedrisation du modèle à partir
des masques fournis.
