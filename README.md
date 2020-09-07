# gallica-social-network
gallica-social-network est un outil de visualisation du réseau social d'un personnage public français des XIXe et XXe siècles.

Fondé sur l'exploitation des ressources numériques de la BnF (Gallica), cet outil effectue une recherche des noms propres situés à proximité de la mention du personnage étudié. Les noms les plus fréquemment associés au personnage étudié sont révélés par l'algorithme qui produit ensuite une visualisation graphique du réseau social reconstitué.

Une option de l'algorithme permet de ne sonder que la chronique mondaine et révèle ainsi le cercle de mondanité fréquenté par l'intéressé.

Un paramétrage des bornes chronologiques pour la période étudiée est possible.


Pour utiliser ce programme : 

1 : Ouvrez la page de recherche avancée de Gallica : https://gallica.bnf.fr/services/engine/search/advancedSearch/

2 : Dans le champ "texte" inscrivez le nom du personnage étudié. Ex : "abel bonnard".

3 : Demandez les résultats "au numéro" en cochant la case correspondante.

4 : Restreignez la recherche au seul corpus de presse en cochant la case correspondante.

5 : Lancez la recherche.

6 : Dans le bandeau de gauche cliquez sur l'onglet "exporter" puis cliquez sur "ok" sous la mention "générer votre rapport de recherche"

7 : Dans la page qui s'ouvre cliquez sur "exporter" puis cochez la mention "DONNÉES BIBLIOGRAPHIQUES DE LA RECHERCHE - CSV" et sous "limite d'export du fichier", choisissez "60 000"

8 : Inscrivez votre adresse e-mail dans le champ et cliquez sur "envoyer"

9 : Téléchargez le rapport de recherche en pièce jointe du mail que la BnF vous envoie automatiquement.

10 : Déplacez ce fichier dans le dossier de votre projet r et renommez la "rapport.csv". Le fichier "rapport.csv" contenu dans ce repository est un exemple (rapport de la recherche "abel bonnard" dans le corpus de presse de Gallica). Remplacez le par votre propre rapport de recherche.

11 : Vous pouvez utiliser l'algorithme : n'oubliez pas de rechercher et remplacer les mentions "abel bonnard" dans le code R par le nom que vous avez inscrit dans votre recherche Gallica. Veillez aussi à indiquer les bornes chronologiques de votre choix.

12 : Veillez à effectuer un dernier nettoyage manuel des matrices avant l'execution de la fonction d'affichage. Cela permettra d'éliminer les résidus.

![WC_réseau_1914_mondain_nettoye](https://user-images.githubusercontent.com/25954316/92419152-ec82a100-f16b-11ea-9910-f53ce9f73d97.png)
