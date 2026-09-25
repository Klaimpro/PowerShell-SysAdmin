# File Deployment — PowerShell

Script PowerShell de déploiement d'un fichier vers plusieurs machines distantes via **SMB**.

Ce projet est une version publique et anonymisée destinée à présenter un exemple d'automatisation d'administration système.

## Fonctionnalités

- import de la liste des machines depuis un fichier CSV ;
- test de disponibilité de **TCP/445** avec 3 tentatives ;
- authentification SMB ;
- contrôle de l'existence du dossier de destination ;
- copie avec **Robocopy** ;
- interprétation des codes retour Robocopy ;
- déconnexion propre du partage ;
- rapport CSV avec le résultat de chaque machine.

## Arborescence

```text
File-Deployment/
├── Deploy-FileToRemoteHosts.ps1
├── machines.example.csv
└── README.md
```

## Sécurité

Aucun mot de passe n'est enregistré dans le script.

Les identifiants sont demandés au lancement :

```powershell
$credential = Get-Credential
```

La version publique ne contient aucun nom de serveur, adresse IP, compte, mot de passe ou chemin provenant de l'environnement d'origine.

Les adresses IP du fichier d'exemple appartiennent au bloc `192.0.2.0/24`, réservé à la documentation.

## Format du fichier CSV

Le séparateur utilisé est `;`.

```csv
Site;IP
Site-001;192.0.2.10
Site-002;192.0.2.20
Site-003;192.0.2.30
```

## Exemple d'utilisation

```powershell
.\Deploy-FileToRemoteHosts.ps1 `
    -FichierSource "C:\FileDeployment\source\example-file.xls" `
    -FichierCSV "C:\FileDeployment\config\machines.csv" `
    -CheminRelatif "Users\Public\Documents" `
    -FichierLog "C:\FileDeployment\logs\deployment-report.csv"
```

Le script demande ensuite le compte disposant des droits nécessaires sur les machines distantes.

## Codes Robocopy

Les codes de retour **0 à 7** sont considérés comme des résultats sans erreur bloquante. Un code supérieur à 7 est enregistré comme un échec de copie.

## Rapport

Le rapport contient :

| Champ | Description |
| --- | --- |
| `Site` | Nom logique de la machine/site |
| `IP` | Adresse de la machine |
| `Statut` | Résultat du traitement |
| `Detail` | Information ou erreur rencontrée |
| `Robocopy` | Code retour de Robocopy |

## Prérequis

- Windows PowerShell 5.1 ou environnement Windows compatible ;
- `Test-NetConnection` ;
- `Robocopy` ;
- accès TCP/445 aux machines cibles ;
- compte disposant des droits nécessaires sur le partage administratif.

## Avertissement

Ce script est fourni comme exemple technique. Il doit être testé et adapté avant toute utilisation dans un environnement de production.

## Auteur

**Clément BRILLAC**

Administrateur Systèmes, Réseaux & Télécoms

© Clément BRILLAC — Tous droits réservés.
