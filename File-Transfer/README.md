# PowerShell SMB Multi-Site File Sync

Script PowerShell de démonstration permettant d'automatiser des échanges de fichiers entre un serveur central et plusieurs sites distants via SMB.

## Fonctionnalités

- test de disponibilité du port TCP 445 avec plusieurs tentatives ;
- connexion aux partages SMB distants ;
- transfert **OUT** : serveur central vers site distant ;
- synchronisation **COMMUN** : copie des fichiers absents ou plus récents ;
- transfert **IN** : site distant vers serveur central ;
- utilisation de `Robocopy` et prise en compte de ses codes retour ;
- suppression du fichier source uniquement après une copie réussie ;
- gestion des erreurs par site ;
- génération d'un rapport CSV en fin d'exécution.

## Sécurité et anonymisation

Cette version publique contient uniquement des données fictives. Les noms de serveurs, adresses IP, chemins internes, identifiants, mots de passe, informations d'entreprise et signatures/certificats de la version d'origine ont été retirés.

Les adresses `192.0.2.0/24` utilisées dans l'exemple sont réservées à la documentation et ne correspondent pas à l'infrastructure d'origine.

Les identifiants sont demandés à l'exécution avec `Get-Credential` et ne sont pas enregistrés dans le script.

## Prérequis

- Windows PowerShell 5.1 ou PowerShell compatible avec les commandes Windows utilisées ;
- accès réseau SMB/TCP 445 aux machines distantes ;
- `Robocopy` disponible ;
- compte disposant des droits nécessaires sur les partages ciblés.

## Configuration

Adaptez les valeurs placées au début du script :

```powershell
$racineLivraison = "C:\FileTransferDemo"
$cheminRelatifMagasin = "transfert"

$magasins = @{
    "192.0.2.10" = "site001"
    "192.0.2.20" = "site002"
    "192.0.2.30" = "site003"
}
```

Le script demande ensuite les identifiants nécessaires :

```powershell
$credential = Get-Credential
```

## Organisation attendue

```text
C:\FileTransferDemo
├── commun
├── site001
│   ├── in
│   └── out
├── site002
│   ├── in
│   └── out
└── rapport_livraison.csv
```

## Fonctionnement

**OUT** copie les fichiers `exp*.txt` du dossier `out` du site vers la machine distante. Le fichier source est supprimé uniquement lorsque Robocopy indique une copie réussie.

**COMMUN** distribue les fichiers communs à chaque site. Un fichier est copié lorsqu'il n'existe pas sur la destination ou lorsque la version centrale est plus récente.

**IN** récupère les fichiers `rec*.txt` présents sur le site distant vers son dossier `in` central. Le fichier distant est supprimé uniquement après une copie réussie.

## Rapport

À la fin du traitement, un rapport CSV contient pour chaque site son statut, le détail du traitement et le nombre de fichiers traités dans chaque flux.

## Avertissement

Ce projet est fourni comme exemple technique. Testez-le dans un environnement de laboratoire avant toute utilisation en production et adaptez l'authentification, les droits et les chemins à votre propre infrastructure.
