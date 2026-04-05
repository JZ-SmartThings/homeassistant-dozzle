# Dozzle 
https://dozzle.dev/guide/what-is-dozzle
# Home assistant
https://developers.home-assistant.io/docs/add-ons
# security
https://www.home-assistant.io/blog/2022/03/14/cas-content-trust/


https://github.com/hassio-addons/addon-glances
https://github.com/hassio-addons/addon-adguard-home
https://github.com/hassio-addons/addon-overseerr


Add-on Home Assistant Dozzle pour visualiser les logs Docker en temps réel https://github.com/Erreur32/homeassistant-dozzle
 donc on se concentre sur la doc de home assistant pour realise l'addon
dozzle marche tres bien , rien a faire avec ( en theorie )
 il faut apparement bien deux port interne pour dozzle 8080 pour ingress et 8081 pour acces externe et le 7007 pour l'agent
j'ai retiré le port 8080 de la section ports car c'est un port réservé pour l'ingress
J'ai gardé uniquement :
Le port 8081 mappé vers 8099 pour l'accès externe
Le port 7007 pour l'agent Dozzle
Le port 8080 est réservé pour l'ingress et n'est pas modifiable
L'utilisateur peut uniquement configurer le port externe (8099) et le port de l'agent (7007)

attention bien mapper ces ports  pour HA !!!
Problèmes : accès Ingress ne fonctionne pas actuellement,  

Documentation : https://dozzle.dev/guide/ et https://developers.home-assistant.io/docs/add-ons
Configuration : port 8099 par défaut pour l'access externe seulement, accès externe fonctionnel, support SSL optionnel
Note : à évaluer si Nginx est la bonne solution pour résoudre le problème d'ingress
