# gallica-social-network
gallica-social-network est un outil de reconstitution et de visualisation du réseau social d'un personnage public français des XIXe et XXe siècles conçu par Benjamin Azoulay.

Fondé sur l'exploitation des ressources numériques de la BnF (Gallica), cet outil effectue une recherche des noms propres situés à proximité de la mention du personnage étudié. Les noms les plus fréquemment associés au personnage étudié sont révélés par l'algorithme qui produit ensuite une visualisation graphique du réseau social reconstitué.

Une option de l'algorithme permet de ne sonder que la chronique mondaine et révèle ainsi le cercle de mondanité fréquenté par l'intéressé.

Le programme édite un nuage de noms ainsi qu'un histogramme lors de l'exécution de la fonction d'affichage.

Un paramétrage des bornes chronologiques pour la période étudiée est possible.


## Pour utiliser ce programme : 

1 : Ouvrez la page de recherche avancée de Gallica : https://gallica.bnf.fr/services/engine/search/advancedSearch/

2 : Dans le champ "texte" inscrivez le nom du personnage étudié. Ex : "abel bonnard".

3 : Demandez les résultats "au numéro" en cochant la case correspondante.

4 : Restreignez la recherche au seul corpus de presse en cochant la case correspondante.

5 : Lancez la recherche.

6 : Copiez la "question" située dans l'url de recherche. Elle est située entre parenthèses dans l'URL après la mention query=(question) 

7 : Copiez cette question dans le script R à l'endroit indiqué.

8 : Remplacez les mentions "abel bonnard" dans le code R par le nom que vous avez inscrit dans votre recherche Gallica. Veillez aussi à indiquer les bornes chronologiques de votre choix.

9 : Lancez le script sans les fonctions d'affichage finales.

10 : Veillez à effectuer un dernier nettoyage manuel des matrices sur excel avant l'execution de la fonction d'affichage. Cela permettra d'éliminer les résidus, notamment les noms de ville et de pays, le nom recherché (qui ne doit pas apparaitre dans le graphe) et quelques éléments non filtrés.

![WC_réseau_1914_mondain_nettoye](https://user-images.githubusercontent.com/25954316/92419152-ec82a100-f16b-11ea-9910-f53ce9f73d97.png)
![WC_réseau_periode_mondain_nettoye](https://user-images.githubusercontent.com/25954316/93771751-349acc80-fc1e-11ea-821f-8f6ecc576a32.png)
