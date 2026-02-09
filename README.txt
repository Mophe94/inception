# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    README.txt                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: dbajeux <dbajeux@student.19.be>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/09/03 10:46:26 by dbajeux           #+#    #+#              #
#    Updated: 2025/09/16 10:30:50 by dbajeux          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

                    🐳****INCEPTION****🐳



✅              ----Guide pratique pour crée VM----

1.             ****Instalation de ca VM****

    🔺Etapes
    
        - telecharger ISO d'un OS via internet (debian 12) 
        - lancer la VM avec : 1. les caracteristique de la puissance donner 
                              2. la taille de memoire (harddisk) a donner
                              3. nom et en "clic" sur "eviter l'instalation guider"                      
        - Langue et clavier → au choix.
        - Nom de la machine → important pour Inception, choisis déjà un nom propre (ex: inception-vm).
        - Nom de domaine → tu peux laisser vide ou mettre 42.fr (peu importe pour l’instant).
        - Utilisateur root → soit tu définis un mot de passe root, soit tu laisses vide pour utiliser sudo avec ton utilisateur normal.
        - Création de l’utilisateur → crée un utilisateur principal (ex: dylan).
        - Partitionnement → Guided (entier disque, LVM pas obligatoire).
        - Accepter que l'instalateur installe APT(instalateur de packet),GRUB(Service qui permet de BOOT l'OS debian)
        - Logiciels à installer → désélectionne tout sauf “SSH server” et “standard system utilities”.

2.             ****guide des service a installer sur ca VM****

    🔸 Décomposition des Service (utile)

        - Sudo Permet de donner des droit admin a un user
        - Shh service (pour pouvoir se connecter a distance et securiser)
        - Git (versionning)
        - Vim : Nano (editeur de texte)
        - Build essential : outils de dev a installer (surtout pour Make dans ce projet)



✅              ----installer Docker----

1.             ****ajoutez les Dépendances Docker****

    🔸 Décomposition des dependances(Service obligatoire)

        ca-certificates → Permet de vérifier les certificats SSL et sécuriser les connexions HTTPS (téléchargement de paquets/clés sans erreur).
        curl            → Outil en ligne de commande pour récupérer des fichiers ou parler à Internet (HTTP/HTTPS, API, etc.).
        gnupg           → Gère les clés de chiffrement/signature GPG pour vérifier que les paquets téléchargés viennent bien de Docker (authenticité).
        lsb-release     → Fournit des infos sur la distribution (ex. : Debian 12 bookworm) pour configurer automatiquement le bon dépôt.

2.             ****ajouter la clé GPG de Docker****

    🔑 Pourquoi cette étape ?
    
        Chaque paquet Docker est signé avec une clé privée par Docker. 
        Pour que ton système puisse vérifier cette signature, il a besoin de la clé publique correspondante.
        On télécharge donc cette clé et on l’installe dans /etc/apt/keyrings/.
        
        👉 Résultat : quand tu feras apt install docker-ce, Debian vérifiera automatiquement que le paquet vient bien de Docker et n’a pas été modifié.
    
    ⚙️ Concrètement
    
        La commande ressemble à ça :
        
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        🔹 Décomposition de la commande
        
            mkdir -p /etc/apt/keyrings      → crée le dossier qui stockera les clés GPG si besoin.
            curl -fsSL ...                  → télécharge la clé GPG officielle de Docker.
            gpg --dearmor                   → convertit la clé en format lisible par apt.
            -o /etc/apt/keyrings/docker.gpg → enregistre la clé dans ce fichier.

3.              ****ajouter le dépot officiel de Docker****

    🔑 Pourquoi c'est necessaire ? 

        Par defaut, Debian ne contient pas les paquets Docker les plus récents.
        le depot officiel DOcker contient la LTS
        Ajouter le dépot permet a 'apt' de savoir ou chercher Docker quand tu fais 'apt install docker-ce'
        
        La commande ressemble à ça :

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        🔹 Décomposition de la commande

            echo "deb ... stable"                        → on crée la ligne qui décrit le dépôt Docker pour Debian. 
            arch=$(dpkg --print-architecture)            → prend automatiquement l’architecture de ta machine (amd64, arm64, etc.). 
            signed-by=/etc/apt/keyrings/docker.gpg       → indique à apt d’utiliser la clé GPG que tu as ajoutée à l’étape 2 pour vérifier les paquets. 
            $(lsb_release -cs)                           → récupère automatiquement le nom de code de ta Debian (ex. : bookworm). 
            sudo tee /etc/apt/sources.list.d/docker.list → écrit cette ligne dans un fichier séparé pour le dépôt Docker.
            > /dev/null                                  → supprime la sortie standard pour ne pas polluer le terminal.
        
        👉 Résultat : Ton systeme Debian connait maintenant le dépot officiel Docker

4.              ****Installer Docker Engine + tous ses plug-in****

        La commande ressemble à ça :

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        🔸 Décomposition des plug-in
            
            docker-ce             → DOCKER ENGINE le moteur principal qui gère les conteneurs
            docker-ce-cli         → Interface en ligne de commande ('docker run','docker ps'...)
            containerd.io         → Runtime de conteneurs, moteur qui execute vraiment les conteneurs
            docker-buildx-plugin  → Extension pour builder des images Docker avancées
            docker-compose-plugin → Support natif de Docker Compose v2('docker compose')

5.              ****Verification de l'instalation****
    
    tester que ca a bien ete installer
        La commande ressemble à ça :
    
            docker --version
            docker compose version

            👉 Résultat : donne les versions de chacun des Services

    tester que ca fonctionne 
        La commande ressemble à ça :

            docker run hello-world 

            👉 Résultat : dois lancer un conteneurs ephémère print un msg et se fermer 
              
6.              ****ajouter ton utilisateur au groupe Docker****

    La commande ressemble à ça :
        
        sudo usermod -aG docker dylan

    se deconnecter et se reconnecter pour rendre cela actif



✅              ----Preparer l’arborescence du projet----


    pour satisfaire au mieux l'enoncer preparer cette configuration de fichier a la racine de 
    /home/user
    
            inception/
         ├─ srcs/
         │   ├─ docker-compose.yml
         │   ├─ .env
         │   └─ requirements/
         │       ├─ nginx/
         │       ├─ wordpress/
         │       └─ mariadb/
         └─ secrets/
             ├─ db_password.txt
             ├─ db_root_password.txt
             └─ credentials.txt



✅              ----Nginx----

        Nginx, c’est quoi ?

            Nginx est à la fois :
                - Un serveur web (il sert des fichiers statiques : HTML, CSS, JS, images…),
                - Un reverse proxy (il reçoit les requêtes HTTP/HTTPS et les redirige vers des services en backend : PHP-FPM, Node, API…),
                - Un équilibreur de charge (load balancer) si besoin,
                - Un terminator TLS (il gère le chiffrement HTTPS, certificats, HTTP/2, redirections 80→443).

    

✅              ----Mariadb----

    Qu’est-ce que MariaDB ?

        MariaDB est un système de gestion de base de données relationnelle (SGBDR), c’est-à-dire un logiciel qui permet de stocker, organiser et interroger des données sous forme de tables. C’est en fait un fork de MySQL, créé par les développeurs originaux de MySQL après que ce dernier a été racheté par Oracle.
        Les points essentiels à connaître :
        Relationnel : Les données sont organisées en tables, avec des lignes (enregistrements) et des colonnes (champs).
        SQL : On utilise le langage SQL (Structured Query Language) pour interagir avec les données : créer des tables, insérer des données, faire des requêtes, etc.
        Open source : MariaDB est libre et gratuit, ce qui en fait un choix populaire pour les projets open source et les conteneurs.
        Compatible MySQL : La plupart des applications conçues pour MySQL fonctionnent directement avec MariaDB.
        Exemple concret :
        Si tu crées un site web WordPress, WordPress a besoin d’une base de données pour stocker tous tes articles, utilisateurs, commentaires, réglages. MariaDB peut être cette base.



✅              ----Docker compose----

    Qu’est-ce que le docker compose ?

        🧱 1. Le rôle de docker-compose.yml

        Tu peux voir ce fichier comme une carte d’architecture : il décrit comment tes briques (conteneurs) doivent être assemblées pour construire un système complet.
        Dans ton cas :
        
        mariadb = la base de données (persistence des infos, utilisateurs, posts WP).
        
        wordpress = l’application métier (PHP-FPM qui génère des pages dynamiques).
        
        nginx = le serveur web frontal (reverse proxy qui parle HTTP/S avec les clients).
        
        👉 docker-compose orchestre leur lancement, définit comment ils communiquent (réseau), où ils stockent leurs données (volumes), et avec quelles variables de configuration (env).

        🎯 Ce que tu es en train de construire

        En résumé, ton docker-compose met en place une architecture 3-tier classique qu’on retrouve partout en entreprise :
        
        Database layer (MariaDB) → persistance des données.
        
        Application layer (WordPress + PHP-FPM) → logique métier.
        
        Presentation layer (NGINX) → interface avec l’extérieur, HTTPS, reverse proxy.
        
        👉 C’est une mini-infra cloud sur ton laptop. Tu pourrais la pousser sur un VPS ou l’intra 42 avec très peu de changements.

        explication du mot clé "bridge" : 

        cela signifie : que tu simule un reseau interne local et connecte tous les conteneur a se reseau 
                        et en exposant le port 443 je stipule a nginx que je peux acceder a ce reseau via se port 

        Donc ta conclusion est parfaite :

        Bridge = réseau interne isolé pour tous tes conteneurs.
        
        Port exposé = porte d’entrée que tu choisis d’ouvrir (ici nginx:443).
        
        ⚡ C’est ce mécanisme qui fait que ton mariadb n’est pas visible du monde extérieur → sécurité renforcée. Seul WordPress peut lui parler (via le bridge).

        metaphore explicatif du mot cle bridge : 

            🎯 Métaphore finale

            Imagine que tu as un immeuble privé (ton réseau bridge Docker) :
            
            Les appartements = conteneurs.
            
            Ils peuvent se parler via l’interphone (réseau interne).
            
            Mais personne dehors n’a accès → sauf si tu installes une porte d’entrée avec une sonnette (port exposé via ports:).
            
            Ici, nginx = la porte d’entrée de l’immeuble, tout le reste est caché à l’intérieur.


🔳 Commandes Utiles 

    ip a → permet de voir l'ip de ca VM
    groups → permet de voir tous les groupe auquels ton utilisateur appartient
    docker ps → permet de voir ls conteneurs en cours d'execution uniquement
    docker ps -a → permet de voir les conteneurs existants (meme terminés)
    docker build -t <nom image> . → permet de build l'image sur base du Dockerfile attention a bien le lancer a partir du dossier ou se trouve le Dockerfile (contexte du build) 
    docker images → permet de voir toutes les images présentes sur la machine 
    docker run -d -p 443:443 --<nom du conteneurs> <nom de l'image>
        -d                        → détaché (le conteneur tourne en arrière-plan)
        -p 443:443                → mappe le port 443 du conteneur sur le port 443 de ta VM
        --name my_nginx_container → nom du conteneur pour le gérer facilement
        my_nginx_image            → l’image que tu viens de build