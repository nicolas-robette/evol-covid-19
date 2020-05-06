library(tidyverse)
library(rvest)
library(gridExtra)
library(zoo)

# temp <- tempfile()
# download.file("https://www.insee.fr/fr/statistiques/fichier/4470857/2020-04-24_deces_sexe_age_lieu_csv.zip",temp)
# unzip(temp, list=TRUE)
# unz(temp, "2020-04-24_deces_parsexe_age_jour_France.csv") %>% read_csv %>% str
# unlink(temp)




## Importation des données ----

# Source : https://www.data.gouv.fr/fr/datasets/donnees-hospitalieres-relatives-a-lepidemie-de-covid-19/

doc <- read_html("https://www.data.gouv.fr/fr/datasets/donnees-hospitalieres-relatives-a-lepidemie-de-covid-19/")
liens <- doc %>% html_nodes(xpath="//div[@class='resources-list']/article/footer/div/a[@download='']") %>% html_attr('href')


## covid-19
# dep	= Département
# sexe = Sexe
# jour = Date de notification
# hosp = Nombre de personnes actuellement hospitalisées
# rea = Nombre de personnes actuellement en réanimation ou soins intensifs
# rad = Nombre cumulé de personnes retournées à domicile
# dc = Nombre cumulé de personnes décédées à l'hôpital
import1 <- read_csv2(liens[1])


## covid-19 - nouveaux
# dep	= Département
# sexe = Sexe
# incid_hosp = Nombre quotidien de personnes nouvellement hospitalisées
# incid_rea	= Nombre quotidien de nouvelles admissions en réanimation
# incid_dc = Nombre quotidien de personnes nouvellement décédées
# incid_rad	= Nombre quotidien de nouveaux retours à domicile
import2 <- read_csv2(liens[2])


## covid-19 - classe age
# reg	= Region
# cl_age90	= Classe age
# jour = Date de notification
# hosp = Nombre de personnes actuellement hospitalisées
# rea	= Nombre de personnes actuellement en réanimation ou soins intensifs	Number of people currently in resuscitation or critical care	0								
# rad	= Nombre cumulé de personnes retournées à domicile
# dc = Nombre cumulé de personnes décédées
import3 <- read_csv2(liens[3])

import3 %>% 




## (DATA stock) ----

stock <- import1 %>% group_by(jour) %>%
                     summarise(hosp = sum(hosp),
                               rea = sum(rea),
                               dc = sum(dc),
                               rad = sum(rad)) %>%
                     pivot_longer(c('hosp','rea','dc','rad')) %>%
                     mutate(name = factor(name, levels=c('dc','rea','hosp','rad')))




## Décès cumulés ----

stock %>% filter(name=='dc') %>%
          ggplot(aes(x = jour, y = value)) + 
            geom_line() +
            theme_minimal() +
            scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
            theme(axis.text.x = element_text(angle=60, hjust = 1)) +
            xlab(NULL) + ylab(NULL) +
            ggtitle("Nombre de décès cumulés - Covid-19")




## Stocks réa et hospi ----

p1 <- stock %>% filter(name=='rea') %>%
                ggplot(aes(x = jour, y = value)) + 
                  geom_line() +
                  theme_minimal() +
                  scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
                  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                  xlab(NULL) + ylab(NULL) +
                  ggtitle("Stock réanimation - Covid-19")

p2 <- stock %>% filter(name=='hosp') %>%
                ggplot(aes(x = jour, y = value)) + 
                  geom_line() +
                  theme_minimal() +
                  scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
                  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                  xlab(NULL) + ylab(NULL) +
                  ggtitle("Stock hospitalisation - Covid-19")

grid.arrange(p1, p2, ncol=2)




## (DATA stockdep) ----

stockdep <- import1 %>% group_by(dep,jour) %>%
                        summarise(hosp = sum(hosp),
                                  rea = sum(rea),
                                  dc = sum(dc),
                                  rad = sum(rad)) %>%
                        pivot_longer(c('hosp','rea','dc','rad')) %>%
                        mutate(name = factor(name, levels=c('dc','rea','hosp','rad')))




## Stocks réa par département ----

stockdep %>% filter(name=='rea' & dep %in% c('14','67','75','93')) %>%
             ggplot(aes(x = jour, y = value, color=dep)) + 
               geom_line() +
               theme_minimal() +
               scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
               theme(axis.text.x = element_text(angle=60, hjust = 1)) +
               xlab(NULL) + ylab(NULL) +
               ggtitle("Stock réanimation par département - Covid-19")




## (DATA nouveaux) ----

nouveaux <- import2 %>% group_by(jour) %>%
                        summarise(incid_hosp = sum(incid_hosp),
                                  incid_rea = sum(incid_rea),
                                  incid_dc = sum(incid_dc),
                                  incid_rad = sum(incid_rad)) %>%
                        pivot_longer(c('incid_hosp','incid_rea','incid_dc','incid_rad')) %>%
                        mutate(name = factor(name, levels=c('incid_dc','incid_rea','incid_hosp','incid_rad'), labels=c('décès','réanimation','hospitalisation','sorties')))

nouveaux_rel <- import2 %>% group_by(jour) %>%
                            summarise(incid_hosp = sum(incid_hosp),
                                      incid_rea = sum(incid_rea),
                                      incid_dc = sum(incid_dc),
                                      incid_rad = sum(incid_rad)) %>%
                            mutate(incid_hosp = incid_hosp/incid_hosp[1],
                                   incid_rea = incid_rea/incid_rea[1],
                                   incid_dc = incid_dc/incid_dc[1],
                                   incid_rad = incid_rad/incid_rad[1]) %>%
                            pivot_longer(c('incid_hosp','incid_rea','incid_dc','incid_rad')) %>%
                            mutate(name = factor(name, levels=c('incid_dc','incid_rea','incid_hosp','incid_rad')))




## Nouveaux cas (réa/hospi/dc/rad) ----

ggplot(nouveaux, aes(jour, value, colour=name)) + geom_line()

ggplot(nouveaux, aes(jour, value, colour=name)) + 
  geom_smooth(span=0.4, se=FALSE, size=0.5) +
  theme_minimal() +
  scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
  xlab(NULL) + ylab(NULL) +
  scale_color_manual(values = c('black','brown2','purple','mediumseagreen'), name = "", labels = c("décès", "réanimation", "hospitalisations", "sorties")) +
  ggtitle("Nouveaux cas - Covid-19")
  
ggplot(nouveaux, aes(jour, value)) + 
  geom_line(color = 'black', size = 1) +
  geom_smooth(span=0.4, se=FALSE, color = 'red', size = 0.5) +
  theme_minimal() +
  scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
  xlab(NULL) + ylab(NULL) +
  facet_wrap(~name, scales = "free_y")
  
ggplot(nouveaux_rel, aes(jour, value, colour=name)) + geom_line()

ggplot(nouveaux_rel, aes(jour, value, colour=name)) + 
  geom_smooth(span=0.4, se=FALSE, size = 0.5) +
  theme_minimal() +
  scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
  xlab(NULL) + ylab(NULL) +
  scale_color_manual(values = c('black','brown2','purple','mediumseagreen'), name = "", labels = c("décès", "réanimation", "hospitalisations", "sorties")) +
  ggtitle("Nouveaux cas (base 1) - Covid-19")




## (DATA nouveauxdep) ----

nouveauxdep <- import2 %>% group_by(dep,jour) %>%
                           summarise(incid_hosp = sum(incid_hosp),
                                     incid_rea = sum(incid_rea),
                                     incid_dc = sum(incid_dc),
                                     incid_rad = sum(incid_rad)) %>%
                           pivot_longer(c('incid_hosp','incid_rea','incid_dc','incid_rad')) %>%
                           mutate(name = factor(name, levels=c('incid_dc','incid_rea','incid_hosp','incid_rad'), labels=c('décès','réanimation','hospitalisation','sorties')))




## Nouveaux cas réa par département ----

nouveauxdep %>% filter(name=='réanimation' & dep %in% c('14','67','75','93')) %>%
                ggplot(aes(x = jour, y = value, color=dep)) + 
                  geom_line(aes(y = rollmean(value, 7, fill=rep("extend",3))), size = 0.5) +
                  theme_minimal() +
                  scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
                  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                  xlab(NULL) + ylab(NULL) +
                  ggtitle("Nouveaux cas en réanimation par département - Covid-19")




## Nouveaux décès par département ----

nouveauxdep %>% filter(name=='décès' & dep %in% c('14','67','75','93')) %>%
                ggplot(aes(x = jour, y = value, color=dep)) + 
                  geom_line(aes(y = rollmean(value, 7, fill=rep("extend",3)))) +
                  theme_minimal() +
                  scale_x_date(date_labels = "%d %b", date_breaks = "2 days") +
                  theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                  xlab(NULL) + ylab(NULL) +
                  ggtitle("Décès par département - Covid-19")



## (DATA parage) ----

parage <- import3 %>% group_by(jour, cl_age90) %>%
                      summarise(hosp = sum(hosp),
                                rea = sum(rea),
                                dc = sum(dc),
                                rad = sum(rad)) %>%
                                filter(cl_age90!="0") %>%
                      arrange(cl_age90, jour) %>%
                      group_by(cl_age90) %>%
                      mutate(newdc = dc-lag(dc),
                             newrad = rad-lag(rad)) %>%
                      ungroup() %>%
                      mutate(Age = factor(cl_age90, labels=c("0-9","10-19","20-29","30-39","40-49","50-59","60-69","70-79","80-89","90 et +")) %>% fct_rev) %>%
                      mutate(newdc = ifelse(newdc<0, NA, newdc)) %>%
                      pivot_longer(c('hosp','rea','dc','rad','newdc','newrad'))




## Stocks réa par âge ----

parage %>% filter(name=='rea') %>%
           ggplot(aes(x = jour, y = value, color = Age)) + 
             geom_line(size = 0.5) +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock réanimation par âge - Covid-19")

parage %>% filter(name=='rea') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col() +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock réanimation par âge - Covid-19")

parage %>% filter(name=='rea') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col(position = 'fill') +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock réanimation par âge - Covid-19")




## Stocks hospitalisation par âge ----

parage %>% filter(name=='hosp') %>%
           ggplot(aes(x = jour, y = value, color = Age)) + 
             geom_line() + 
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock hospitalisation par âge - Covid-19")

parage %>% filter(name=='hosp') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col() +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock hospitalisation par âge - Covid-19")

parage %>% filter(name=='hosp') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col(position = 'fill') +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Stock hospitalisation par âge - Covid-19")




## Nouveaux décès par âge ----

parage %>% filter(name=='newdc') %>%
           ggplot(aes(x = jour, y = value, color = Age)) + 
             geom_line(aes(y = rollmean(value, 7, fill=rep("extend",3)))) +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Nouveaux décès par âge - Covid-19")

parage %>% filter(name=='newdc') %>%
            ggplot(aes(x = jour, y = value, fill = Age)) + 
              geom_col() +
              theme_minimal() +
              scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
              theme(axis.text.x = element_text(angle=60, hjust = 1)) +
              xlab(NULL) + ylab(NULL) +
              ggtitle("Nouveaux décès par âge - Covid-19")

parage %>% filter(name=='newdc') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col(position = "fill") +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Nouveaux décès par âge - Covid-19")




## Décès cumulés par âge ----

parage %>% filter(name=='dc') %>% 
           ggplot(aes(x = jour, y = value, color = Age)) + 
             geom_line(size = 0.5) +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Décès cumulés par âge - Covid-19")

parage %>% filter(name=='dc') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col() +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Décès cumulés par âge - Covid-19")

parage %>% filter(name=='dc') %>%
           ggplot(aes(x = jour, y = value, fill = Age)) + 
             geom_col(position = "fill") +
             theme_minimal() +
             scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
             theme(axis.text.x = element_text(angle=60, hjust = 1)) +
             xlab(NULL) + ylab(NULL) +
             ggtitle("Décès cumulés par âge - Covid-19")




## (DATA parregion) ----

parregion <- import3 %>% group_by(jour, reg) %>%
                         summarise(hosp = sum(hosp),
                                   rea = sum(rea),
                                   dc = sum(dc),
                                   rad = sum(rad)) %>%
                         arrange(reg, jour) %>%
                         group_by(reg) %>%
                         mutate(newdc = dc-lag(dc),
                                newrad = rad-lag(rad)) %>%
                         ungroup() %>%
                         pivot_longer(c('hosp','rea','dc','rad','newdc','newrad'))




## Nouveaux décès par région ----

parregion %>% filter(name=='newdc' & reg %in% c('11','28','44','53')) %>%
              ggplot(aes(x = jour, y = value, color = reg)) + 
                geom_line(aes(y = rollmean(value, 7, fill=rep("extend",3)))) +
                theme_minimal() +
                scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
                theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                xlab(NULL) + ylab(NULL) +
                ggtitle("Nouveaux décès par région - Covid-19")




## Stocks réa par région ----

parregion %>% filter(name=='rea' & reg %in% c('11','28','44','53')) %>%
              ggplot(aes(x = jour, y = value, color = reg)) + 
                geom_line() +
                theme_minimal() +
                scale_x_date(date_labels = "%d %b", date_breaks = "1 day") +
                theme(axis.text.x = element_text(angle=60, hjust = 1)) +
                xlab(NULL) + ylab(NULL) +
                ggtitle("Stock réanimation par région - Covid-19")




library (maps)
map ('france')
title (main="Taux d'evolution de la population entre 1990 et 1999")
DATA <- read.table ("population.csv", header=TRUE)
df <- aggregate (data.frame (PSDC99=DATA$PSDC99, PSDC90=DATA$PSDC90), by=list(DATA$DEP), FUN = sum)
> df$TAUX <- (df$PSDC99-df$PSDC90)/df$PSDC90*100
> DEP <- read.table ("departement.csv", header=TRUE)
> df <- merge (df, DEP, by.x="Group.1", by.y="DEP")
> df$CLASS <- cut (df$TAUX, c(-Inf, -6, -4, -2, 0, 2, 4, 6, Inf), right=TRUE)
> col <- c(rgb (1:4/4, 0, 0), rgb (0, 4:1/4, 0))
> map ('france', regions=df$NOM, col=col[df$CLASS], fill=TRUE, add=TRUE, exact=TRUE)
> legend ('bottomleft', legend=attr (df$CLASS, 'levels'), col=col, lty=1, lwd=10)
> box()





#Importation du package
library(raster)

#Importation d'une base de données avec les résultats des élections présidentielles de 2012, premier tour

base <- nouveauxdep %>% filter(jour=="2020-04-01" & name=="réanimation") 
  
base2012=read.csv2("http://dimension.usherbrooke.ca/voute/FPP.csv", header=TRUE, encoding="latin1")
dim(base2012)
head(base2012)

#Importation des formes
formes <- getData(name="GADM", country="FRA", level=2)
head(formes)

#Établissement de l'index
idx <- match(formes$NAME_1, base2012$regions)
idx <- match(formes$CC_2, base$code_dept)

#Tranfert des données pour les six principaux candidats en fonction de la règle de concordance
condordance <- as.data.frame(base)[idx, "value"]
formes$Hollande_p <- as.data.frame(base)[idx, "value"] #concordance

concordance <- base2012[idx, "Sarkozy_p"]
formes$Sarkozy_p <- concordance

#Tracage de la première carte: Hollande
#établissemment de la charte des coupeurs puis tracage de la carte en utilisant
couleurs <- colorRampPalette(c('white', 'red'))
spplot(formes, "Hollande_p", col.regions=couleurs(30),  main=list(label="Nouveaux cas en réa",cex=.8))





library(cartography)
library(rgdal)

Fond <-readOGR(dsn ="/data/user/r/nrobette/Covid", layer = "geoflar-departements-2015")
# slotNames(Fond)
Fond2 <- Fond[!(Fond@data$code_dept %in% c('971','972','973','974','976')),]

library(readxl)
popdep <- read_excel("Data_pop.xls", sheet=1)
popage <- read_excel("Data_pop.xls", sheet=2)

basetot <- nouveauxdep %>% rename(code_dept = dep) %>%
                           left_join(popdep) %>%
                           mutate(ratio = 100000*value/pop2020) %>%
                           group_by(code_dept,name) %>%
                           mutate(roll = rollmean(ratio,7,fill=rep("extend",3))) %>%
                           ungroup

days <- basetot$jour %>% unique
basetot$name %>% unique
  
baserea <- basetot %>% filter(name=="réanimation")
basedc <- basetot %>% filter(name=="décès")
  
coupures_rea <- seq(from=0, to=max(baserea$roll), length.out=11)
# coupures_rea <- Hmisc::cut2(baserea$ratio, g=10, onlycuts=TRUE)
coupures_dc <- seq(from=0, to=max(basedc$roll), length.out=11)
# coupures_dc <- Hmisc::cut2(basedc$ratio, g=10, onlycuts=TRUE)

mypal <- gray.colors(n=8, start=0, end=1, rev=TRUE) 

day <- "2020-04-01"
basejour <- baserea %>% filter(jour==day)
basejour <- basedc %>% filter(jour==day)

# Fond3 <- Fond2
# Fond3@data <- left_join(Fond3@data,basejour,
         
png("temp.png")
par(mar=c(0.1,0.1,0.1,0.1))
#plot(Fond2, col = "grey60",border = "grey20")
choroLayer(spdf = Fond2, df = basejour, spdfid = 'code_dept', dfid = 'code_dept', var = "ratio", 
           breaks = coupures, col = mypal, legend.pos = "topleft")
dev.off()


library(animation)

saveGIF({
  ani.options(interval = 0.25, nmax = length(days))
  for (i in seq_along(days)) {
    basejour <- basedc %>% filter(jour==days[i])
    par(mar=c(0.1,0.1,2.1,0.1))
    choroLayer(spdf = Fond2, df = basejour, spdfid = 'code_dept', dfid = 'code_dept', var = "roll", 
               breaks = coupures_dc, col = mypal, legend.pos = "topleft")
    title(main=days[i])
  }
}, movie.name = "essai_dc.gif")


saveGIF({
  ani.options(interval = 0.25, nmax = length(days))
  for (i in seq_along(days)) {
    basejour <- baserea %>% filter(jour==days[i])
    par(mar=c(0.1,0.1,2.1,0.1))
    choroLayer(spdf = Fond2, df = basejour, spdfid = 'code_dept', dfid = 'code_dept', var = "roll", 
               breaks = coupures_rea, col = mypal, legend.pos = "topleft")
    title(main=days[i])
  }
}, movie.name = "essai_rea.gif")


# png("temp.png")
# plot(Fond2, col = "grey60",border = "grey20")
# # propSymbolsLayer(spdf = Fond, df = base, spdfid = 'code_dept', dfid = 'code_dept', var = "value", symbols = "square")
# choroLayer(spdf = Fond2, df = base, spdfid = 'code_dept', dfid = 'code_dept', var = "value", 
#            method = "quantile", nclass = 20, col = mypal, legend.pos = "topleft")
# dev.off()



library(rmarkdown)
rmarkdown::render("Evolutions_Covid-19_France.Rmd", md_document(preserve_yaml=TRUE, variant = "markdown_github", toc=TRUE))
