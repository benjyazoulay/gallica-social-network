library(ggwordcloud)
library(stringr)
library(dplyr)
library(ggplot2)
library(rvest)
library(stats)
library(tidytext)
library(utils)
library(xml2)
library(purrr)

#####EXTRACTION D'UN RAPPORT DE RECHERCHE
#La fonction d'extraction de rapport de recherche depuis gallica fonctionnant mal, nous reprenons ici une partie de l'outil gargallica qui exécute parfaitement cette tâche

setwd("C:/Users/Benjamin/Downloads/gallica-social-network") #inscrivez ici votre répertoire de travail
#####GARGALLICA###############
i = 1

# Indiquez la question (la requête CQL visible dans l'URL query = () )
# Il faut recopier la question posée sur gallica.bnf.fr

question <- '(%20text%20all%20"bonnard"%20%20prox/unit=word/distance=1%20"abel"))%20and%20(dc.type%20all%20"fascicule")%20sortby%20dc.date/sort.ascending&suggest=10&keywords='

page <- function(i)xml2::read_xml(paste0('http://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&query=(', question,')&collapsing=false&maximumRecords=50&startRecord=', i))


# Première 50 réponses (initialiser la structure xml avec un premier coup)
tot <- page(1)
# récupérer le nombre total de réponses
te <- xml2::as_list(tot)
nmax <- as.integer(unlist(te$searchRetrieveResponse$numberOfRecords))
# nmax <- 7853

# Boucle sur la suite, 50 par 50
# Ajouter au document xml tot les réponses des autres pages
for (j in seq(51, nmax, by = 50)){
  temp <- page(j)
  for (l in xml2::xml_children(temp)){
    xml2::xml_add_child(tot, l)
  }
}

xml2::write_xml(tot, 'results.xml')



xml_to_df <- function(doc, ns = xml_ns(doc)) {
  library(xml2)
  library(purrr)
  split_by <- function(.x, .f, ...) {
    vals <- map(.x, .f, ...)
    split(.x, simplify_all(transpose(vals)))
  }
  node_to_df <- function(node) {
    # Filter the attributes for ones that aren't namespaces
    # x <- list(.index = 0, .name = xml_name(node, ns))
    x <- list(.name = xml_name(node, ns))
    # Attributes as column headers, and their values in the first row
    attrs <- xml_attrs(node)
    if (length(attrs) > 0) {attrs <- attrs[!grepl("xmlns", names(attrs))]}
    if (length(attrs) > 0) {x <- c(x, attrs)}
    # Build data frame manually, to avoid as.data.frame's good intentions
    children <- xml_children(node)
    if (length(children) >= 1) {
      x <- 
        children %>%
        # Recurse here
        map(node_to_df) %>%
        split_by(".name") %>%
        map(bind_rows) %>%
        map(list) %>%
        {c(x, .)}
      attr(x, "row.names") <- 1L
      class(x) <- c("tbl_df", "data.frame")
    } else {
      x$.value <- xml_text(node)
    }
    x
  }
  node_to_df(doc)
}

# u <- xml_to_df(xml2::xml_find_all(tot, ".//srw:records"))
x = 1:3
parse_gallica <- function(x){
  xml2::xml_find_all(tot, ".//srw:recordData")[x] %>% 
    xml_to_df() %>% 
    select(-.name) %>% 
    .$`oai_dc:dc` %>% 
    .[[1]] %>% 
    mutate(recordId = 1:nrow(.)) %>% 
    #    tidyr::unnest() %>% 
    tidyr::gather(var, val, - recordId) %>% 
    group_by(recordId, var) %>% 
    mutate(value = purrr::map(val, '.value') %>% purrr::flatten_chr() %>% paste0( collapse = " -- ")) %>% 
    select(recordId, var, value) %>% 
    ungroup() %>% 
    mutate(var = stringr::str_remove(var, 'dc:')) %>% 
    tidyr::spread(var, value) %>% 
    select(-.name)
}

tot <- xml2::read_xml('results.xml')

tot_df <- 1:nmax %>% 
  parse_gallica %>% 
  bind_rows()

write.csv(tot_df,"rapport.csv")
##############################
#rapport<-read.csv("rapport.csv") #Lecture du rapport de recherche
rapport<-tot_df
rapport<-cbind(rapport$identifier,rapport$title,rapport$publisher,rapport$date) #Extraction des colonnes contenant les critères d'intérêt
colnames(rapport)<-c("lien","titre","lieu","date")
rapport<-as.data.frame(rapport)
rapport<-rapport[str_count(rapport$date,"-")==2,] #On ne conserve que les numéros présentant une date au format (AAAA/MM/JJ)
rapport$date<-as.numeric(str_remove_all(rapport$date,"-")) #On transforme la date au format numérique
rapport$lieu<-str_extract(rapport$lieu,"([:alnum:]+[:alnum:])") #Nettoyage du nom de la première ville de publication

#Nettoyage des titres de presse et restriction du titre à 30 caractères
rapport$titre<-str_remove_all(rapport$titre,"  ")
rapport$titre<-str_remove_all(rapport$titre,"\n")
rapport$titre<-str_remove_all(rapport$titre,"\\[")
rapport$titre[nchar(rapport$titre)>30]<-str_extract(rapport$titre[nchar(rapport$titre)>30],"..............................") 
rapport<-rapport[order(rapport$date),]


#####NETTOYAGE DU RAPPORT DE RECHERCHE ET PREPARATION DE LA MATRICE D'EXTRACTION

rapport$lien_texte<-str_c(rapport$lien,".texteBrut") #Ajout du lien permettant l'extraction du texte des numéros de presse de la base
rapport$texte_brut<-NA #Ajout d'une colonne destinée à recevoir le texte des numéros de presse de la base

#####EXTRACTION DU TEXTE DES NUMEROS DE LA BASE SITUE A PROXIMITE DE LA MENTION DU PERSONNAGE RECHERCHE

for (i in 1:length(rapport$texte_brut))
{tryCatch({
  url<-rapport$lien_texte[i]
  texte<-as.character(url%>%read_html()%>%html_text())
  texte<-tolower(texte) #Homogénéisation du texte : suppression de la casse
  texte<-iconv(texte,from="UTF-8",to="ASCII//TRANSLIT") #Lissage du texte : suppression des caractères spéciaux
  texte<-str_extract(texte,".{400}+abel bonnard+.{400}") #On extrait les 800 caractères entourant la mention du personnage étudié, ici abel bonnard
  rapport$texte_brut[i]<-texte
  print(i)
}, error=function(e){})}


#####CREATION D'UN TABLEAU SIMPLIFIE ET EXPLOITABLE POUR LE WORDCLOUD

rapport2<-cbind(rapport$date,rapport$texte_brut)
colnames(rapport2)<-c("title","text")
rapport2<-as.data.frame(rapport2)
rapport2<-subset(rapport2,is.na(rapport2$text)==FALSE)
rapport2$title<-as.character(rapport2$title)
rapport2$text<-str_replace_all(rapport2$text,"[:punct:]"," ")

#####CHOIX DES PERIODES D'ETUDE

periode<-function(date_min,date_max)
{
  rapport_periode<-subset(rapport2,rapport2$title>date_min & rapport2$title<date_max)
  return(rapport_periode)
}

rapport_periode<-periode("19000101","19090301") #Choix des bornes chronologiques basses et hautes

#####RESTRICTION AUX PERSONNALITES MONDAINES
rapport_periode_mondain<-subset(rapport_periode,str_detect(rapport_periode$text,"comtesse|duchesse|princesse|marquise|baronne"))

##### PREPARATIONS DES FICHIERS DE BASE POUR LE NETTOYAGE
mots<-read.csv("mots.txt",encoding = "UTF-8",sep="\n",header = FALSE) #Ce fichier est un dictionnaire très complet de mots incluant les formes verbales de la langue française
mots<-as.data.frame(mots)
colnames(mots)<-c("title")
mots$title<-iconv(mots$title,from="UTF-8",to="ASCII//TRANSLIT")
mots<-unique(mots$title)
mots<-as.data.frame(mots)
colnames(mots)<-c("title")

prenoms<-read.csv("prenoms.csv",sep=";") #Ce fichier est un dictionnaire très complet de prénoms
prenoms<-prenoms[,1]
prenoms<-iconv(prenoms,to="ASCII//TRANSLIT")
prenoms<-as.data.frame(prenoms)
colnames(prenoms)<-c("title")


#####DEFINITION DE LA FONCTION DE COMPTAGE
matrice<-function(rapport)
{
  tidy_r <- rapport %>%
    unnest_tokens(word, text)
  tidy_r$word<-str_replace(tidy_r$word,"[:punct:]","")
  r_dfm<-as.data.frame(unique(tidy_r$word))
  colnames(r_dfm)<-c("word")
  r_dfm$n<-0
  for (i in 1:length(r_dfm$word)) 
  {
    r_dfm$n[i]<-sum(as.numeric(tidy_r$word==r_dfm$word[i]))
  }
  r_dfm<-r_dfm[order(r_dfm$n,decreasing = TRUE),]
  
  nom<-str_c(deparse(substitute(rapport)),".csv")
  write.csv(r_dfm,nom)
  
}


#####DEFINITION DE LA FONCTION DE NETTOYAGE

nettoyage<-function(nom){
  
  a<-read.csv(nom)
  a<-a[,-1]
  colnames(a)<-c("title","count")
  
  a<-anti_join(a,mots,by="title")
  a$title<-str_remove_all(a$title,"d'")
  a$title<-str_remove_all(a$title,"l'")
  a$title<-str_remove_all(a$title,"qu'")
  a$title<-str_remove_all(a$title,"c'")
  a$title<-str_remove_all(a$title,"t'")
  a$title<-str_remove_all(a$title,"n'")
  a$title<-str_remove_all(a$title,"m'")
  a$title<-str_remove_all(a$title,"s'")
  a$title<-str_remove_all(a$title,"j'")
  a<-anti_join(a,mots,by="title")
  a<-anti_join(a,prenoms,by="title")
  a<-subset(a,str_detect(a$title,"[:digit:]")==FALSE)
  a<-subset(a,!str_length(a$title)==2)
  a<-subset(a,!str_length(a$title)==1)
  a<-subset(a,!str_length(a$title)==0)
  a<-subset(a,a$count>3)
  nom1<-str_replace(nom,".csv","_nettoye.csv")
  write.csv(a,nom1)
}


#####DEFINITION DE LA MATRICE D'AFFICHAGE DES NUAGES DE MOT ET DES HISTOGRAMMES
affichage<-function(nom,titre)
{
  nom1<-str_replace(nom,"rapport","réseau")
  nom1<-str_replace(nom1,".csv",".png")
  nom2<-str_replace(nom1,"réseau","WC_réseau")
  rapport_freq_filtre<-read.csv(nom,sep=";")
  colnames(rapport_freq_filtre)<-c("name","count")
  rapport_freq_filtre%>%ggplot(aes(count,reorder(name,count)))+geom_bar(stat="identity")+
    ggtitle(titre)+xlab("nombre de mentions")+ylab("personne mentionnée")+
    ggsave(nom1,scale=3)
  
  set.seed(100)
  ggplot(rapport_freq_filtre,aes(label=name,size=count))+geom_text_wordcloud()+
    scale_radius(range = c(0, 20), limits = c(0, NA)) +
    ggtitle(titre)+
    theme_minimal()+ggsave(nom2,scale=1.5)
  
}


#####EXECUTION DES FONCTIONS
matrice(rapport_periode)
matrice(rapport_periode_mondain)

nettoyage("rapport_periode.csv")
nettoyage("rapport_periode_mondain.csv")
# A ce stade, il faut achever de nettoyer les csv manuellement. Les résidus sont très peu nombreux.
# Il faut veiller à retirer le nom du personnage étudié
# Il faut supprimer tous les résultats dont le nombre d'occurence est inférieur à un plancher défini par l'utilisateur afin de ne pas voir ces noms apparaitre dans les graphiques finaux.
# Une fois le csv nettoyé sur excel, il faut supprimer la première colonne indiquant le numéro de ligne originel et enregistrer le fichier sur excel



#####EXECUTION DES FONCTIONS D'AFFICHAGE
affichage("rapport_periode_nettoye.csv","Le réseau d'Abel Bonnard dans l'entre-deux guerres (Gallica-Presse)") #Choix du titre du graphe en deuxième attribut
affichage("rapport_periode_mondain_nettoye.csv","Le réseau mondain d'Abel Bonnard dans l'entre-deux guerres (Gallica-Presse)")
