library(stringr)
library(rvest)
library(ggplot2)
library(ggrepel)
library(dplyr)
library(tm)
library(stm)
library(wordcloud)
library(ggwordcloud)
library(tidytext)

setwd("C:/Users/Benjamin/Downloads/sociabilité")

stopwprds <- read.csv("french_stopwords.txt")
stopwprds <- unique(stopwprds)

#####NETTOYAGE DU RAPPORT DE RECHERCHE ET PREPARATION DE LA MATRICE D'EXTRACTION
rapport<-read.csv("rapport.csv", sep = ";", encoding = "UTF-8") #Lecture du rapport de recherche
rapport<-cbind(rapport[,1],rapport[,3],rapport[,6],rapport[,7]) #Extraction des colonnes contenant les critères d'intérêt
colnames(rapport)<-c("lien","titre","lieu","date")
rapport<-as.data.frame(rapport)
rapport$lien_texte<-str_c(rapport$lien,".texteBrut") #Ajout du lien permettant l'extraction du texte des numéros de presse de la base
rapport$texte_brut<-NA #Ajout d'une colonne destinée à recevoir le texte des numéros de presse de la base
rapport<-rapport[str_count(rapport$date,"-")==2,] #On ne conserve que les numéros présentant une date au format (AAAA/MM/JJ)
rapport$date<-as.numeric(str_remove_all(rapport$date,"-")) #On transforme la date au format numérique
rapport$lieu<-str_extract(rapport$lieu,"([:alnum:]+[:alnum:])") #Nettoyage du nom de la première ville de publication

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

#####CHOIX DES PERIODES D'ETUDE

periode<-function(date_min,date_max)
{
  rapport_periode<-subset(rapport2,rapport2$title>date_min & rapport2$title<date_max)
  return(rapport_periode)
}

rapport_periode<-periode("19181111","19390901") #Choix des bornes chronologiques basses et hautes

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
    mutate(line = row_number()) %>%
    unnest_tokens(word, text) %>%
    anti_join(stopwprds)
  
  
  r_dfm <- tidy_r %>%
    count(title, word, sort = TRUE) %>%
    cast_dfm(title, word, n)
  r_dfm<-as.data.frame(r_dfm)
  r_dfm<-r_dfm[,-1]
  rapport_freq<-as.data.frame(sort(colSums(r_dfm),TRUE))
  nom<-str_c(deparse(substitute(rapport)),".csv")
  write.csv(rapport_freq,nom)
  
}


#####DEFINITION DE LA FONCTION DE NETTOYAGE

nettoyage<-function(nom){
  
  a<-read.csv(nom)
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
# Une fois le csv nettoyé sur excel, il faut supprimer la première colonne indiquant le numéro de ligne originel et enregistrer le fichier sur excel



#####EXECUTION DES FONCTIONS D'AFFICHAGE
affichage("rapport_periode_nettoye.csv","Le réseau d'Abel Bonnard dans l'entre-deux guerres (Gallica-Presse)") #Choix du titre du graphe en deuxième attribut
affichage("rapport_periode_mondain_nettoye.csv","Le réseau mondain d'Abel Bonnard dans l'entre-deux guerres (Gallica-Presse)")
