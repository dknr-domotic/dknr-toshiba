# README

[![Release](https://img.shields.io/docker/v/jcpd/dknr-toshiba?sort=semver)](https://img.shields.io/docker/v/jcpd/dknr-toshiba?sort=semver)
[![Pull](https://img.shields.io/docker/pulls/jcpd/dknr-toshiba)](https://img.shields.io/docker/pulls/jcpd/dknr-toshiba)
[![Issue](https://img.shields.io/github/issues/dknr-domotic/dknr-toshiba)](https://img.shields.io/github/issues/dknr-domotic/dknr-toshiba)
[![License](https://img.shields.io/github/license/dknr-domotic/dknr-toshiba)](https://github.com/dknr-domotic/dknr-toshiba/blob/master/LICENSE)


## A propos

**dknr-toshiba** est un projet consacré au pilotage, à la récupération et à l'exploitation des données des climatiseurs Toshiba équipés d'un module wifi. Il n'existe pas d'accès local à ces modules : ce projet passe par le cloud Toshiba, avec la même API que l'application Toshiba Home AC Control.

Toutes les informations sont regroupées sur votre serveur MQTT, dans la même arborescence que les autres projets DKNR.

Ce projet n'est ni édité ni soutenu par Toshiba. L'API utilisée n'est pas publique, elle peut changer sans préavis.

Version 0.1 : le projet débute, il est en cours de validation sur du matériel réel.


## Fonctionnalités

- **Connexion avec le compte Toshiba Home AC Control**.
- **Support de plusieurs climatiseurs** d'un même compte.
- **Etat reçu en direct** : un changement fait depuis la télécommande ou l'application est connu dès que Toshiba le transmet, sans interroger son cloud en boucle.
- **Pilotage** : marche / arrêt, mode, consigne, ventilation, direction, limitation de puissance, fonctions (Eco, puissance maximale, hors gel 8 °C...) et purificateur.
- **Seules les options disponibles** sur chaque climatiseur sont proposées.
- **Températures** intérieure et extérieure.
- **Consommation** des climatiseurs qui la mesurent, avec graphiques par heure et par jour.
- **Support Home-Assistant Discovery** en lecture et pilotage.


## Matériel requis

* un ou plusieurs climatiseurs Toshiba avec module wifi, intégré ou ajouté, déjà enregistrés dans l'application Toshiba Home AC Control.
* une machine exécutant le logiciel docker et ayant accès à internet.

Ce projet vise les modules wifi de type B (**RB-N105S-G**, **RB-N106S-G**). Les autres modules reconnus par l'application Toshiba Home AC Control passent par le même cloud et devraient fonctionner.

Si vous utilisez votre compte sur un autre système domotique en même temps, il n'y a pas de conflit : chaque installation de ce projet se présente à Toshiba avec son propre identifiant.


## Installation

Des images Docker prêtes à l'emploi sont disponibles. 
Utilisez le fichier docker-compose.yaml à la racine du dépôt en fournissant les variables d'environnement suivantes :

* **DKNR_USERNAME** : login de l'interface node-red.
* **DKNR_PASSWORD** : mot de passe de l'interface node-red.
* **DKNR_SECRET**   : un mot secret pour encrypter les credits.

Le tableau de bord est disponible sur `http://<ip du serveur docker>:1880/` et l'éditeur Node-RED sur `http://<ip du serveur docker>:1880/admin`.

Le conteneur doit pouvoir joindre `mobileapi.toshibahomeaccontrols.com` (port 443) et `toshibasmaciothubprod.azure-devices.net` (port 8883).


## Configuration

### Connecter le compte

Dans la page **Compte**, saisissez le **nom d'utilisateur** et le **mot de passe** du compte Toshiba Home AC Control. Le nom d'utilisateur est celui choisi à la création du compte dans l'application, ce n'est pas l'adresse e-mail. Les climatiseurs du compte apparaissent ensuite dans la page **Piloter**, avec le nom donné dans l'application.

Toshiba ne fournit pas de jeton de session renouvelable : **le mot de passe est enregistré** dans le volume du conteneur, pour se reconnecter seul après un redémarrage ou quand Toshiba ferme la session. Si Toshiba refuse le mot de passe, il est effacé et le projet ne retente rien : il faut se reconnecter depuis la page **Compte**.

En cas d'échec, la ligne **Dernière erreur** de la page **Compte** donne la réponse exacte de Toshiba.

Le bouton **Déconnecter** efface le compte, son mot de passe, ses climatiseurs et leurs topics MQTT.

### Lecture des états

Les changements d'état et les températures sont envoyés par Toshiba dès qu'ils se produisent. En complément, les climatiseurs sont relus toutes les 15 minutes, ainsi que leur consommation.

Toshiba bloque les accès trop fréquents : dans ce cas le projet suspend ses accès pendant le délai demandé par Toshiba, 15 minutes au plus. Le bouton **Actualiser** de la page **Piloter** demande une lecture immédiate (une par 20 secondes au plus).

### Pilotage

Dans la page **Piloter**, chaque climatiseur a ses boutons. Avec plusieurs climatiseurs, une liste permet de choisir celui à afficher ; ce choix est gardé par navigateur. Le bouton coloré est la valeur actuelle : il change quand le climatiseur a confirmé la commande.

* La **consigne** va de 17 à 30 °C, et de 5 à 13 °C avec la fonction hors gel 8 °C.
* Certaines **fonctions** n'existent que dans certains modes : le hors gel, le mode sommeil et le chauffage au sol en mode chaud, par exemple. Seules celles du mode en cours sont proposées.
* La **puissance** limite la puissance du climatiseur à 50, 75 ou 100 %.

Le tableau de bord de ce projet n'est pas protégé par mot de passe : ne l'exposez pas en dehors de votre réseau local.

### Consommation

La page **Surveiller** montre la consommation par heure (24 dernières heures) et par jour (14 derniers jours) des climatiseurs qui la mesurent. Toshiba donne un cumul depuis le début de l'année, relevé toutes les 15 minutes : les graphiques se remplissent à partir de la connexion du compte, et une heure affichée peut contenir quelques minutes de l'heure précédente.


## MQTT

Avec le topic `dknr` par défaut, l'identifiant d'un appareil est celui donné par Toshiba au climatiseur, affiché dans la page **Compte** :

* `dknr/get/toshiba/<id>/<entité>` : valeurs publiées (retenues) à chaque changement.
* `dknr/set/toshiba/<id>/<entité>` : commande. Une commande retenue (retain) est ignorée.
* `dknr/set/toshiba/<id>/refresh` : demande une lecture immédiate (une lecture par 20 secondes au plus).
* `dknr/discovery/toshiba/<id>/<entité>` : description des entités.
* `homeassistant/<type>/toshiba/<id>_<entité>/config` : Home Assistant Discovery.

Entités :

* `fault` : `1` en défaut, `0` quand tout va bien. Le défaut est levé quand le compte n'est pas connecté, quand la liaison avec Toshiba est perdue depuis 5 minutes ou quand aucune nouvelle du climatiseur n'est arrivée depuis 40 minutes. Elle est déclarée en discovery DKNR (type binaire) et Home Assistant (binary_sensor de type « problem »), pour servir d'alerte dans votre domotique.
* `state` : `1` en fonction, `0` à l'arrêt, en lecture et en commande (`ON` / `OFF` acceptés en commande).
* `mode` : `auto`, `cool` froid, `heat` chaud, `dry` déshumidificateur, `fan` ventilation.
* `temperatureSetpoint` : consigne en °C, nombre entier.
* `fanRate` : `auto`, `quiet` silence, `1` à `5`.
* `fanDirection` : `off` fixe, `vertical`, `horizontal`, `both` toutes directions, `fixed1` à `fixed5` positions fixes.
* `powerLimit` : `50`, `75` ou `100` (%).
* `preset` : fonction en cours : `off` aucune, `high_power` puissance maximale, `eco`, `silent1` et `silent2` unité extérieure silencieuse, `heating8` hors gel 8 °C, `sleep` sommeil, `floor` chauffage au sol, `comfort` confort.
* `purifier` : `1` en fonction, `0` à l'arrêt.
* `temperatureIndoor` : température intérieure en °C.
* `temperatureOutdoor` : température extérieure en °C.
* `energy` : consommation depuis le début de l'année, en Wh. Elle repart de zéro au 1er janvier.

Les commandes `mode`, `fanRate`, `fanDirection`, `powerLimit` et `preset` acceptent la clé ou le nom de l'option. Seules les entités et les options disponibles sur le climatiseur sont déclarées, et une valeur que le climatiseur ne donne pas n'est pas publiée.

Si le module wifi d'un climatiseur perd sa connexion, Toshiba continue de donner son dernier état connu : le défaut n'est levé qu'au bout de 40 minutes sans nouvelle.


## A faire

* Programmation horaire de l'application Toshiba.
* Fonction cheminée et auto-nettoyage.


## Contribuer

Ce projet est **open-source**, vous pouvez participer en créant des [tickets](https://github.com/dknr-domotic/dknr-toshiba/issues) ou en proposant de [requêtes](https://github.com/dknr-domotic/dknr-toshiba/pulls) sur le dépôt github du projet.


## Voir aussi

- [DKNR Teleinfo](https://github.com/dknr-domotic/dknr-teleinfo)
- [DKNR APSystems](https://github.com/dknr-domotic/dknr-apsystems)
- [DKNR Daikin](https://github.com/dknr-domotic/dknr-daikin)
- [DKNR Zendure](https://github.com/dknr-domotic/dknr-zendure)
- [DKNR RFXCom](https://github.com/dknr-domotic/dknr-rfxcom)
- [DKNR Nuki](https://github.com/dknr-domotic/dknr-nuki)
- [DKNR Verisure](https://github.com/dknr-domotic/dknr-verisure)
- [Toshiba-AC-control](https://github.com/KaSroka/Toshiba-AC-control), bibliothèque Python dont le protocole est repris ici.
