<#
.SYNOPSIS
    Déploie un fichier vers plusieurs machines distantes via SMB.

.DESCRIPTION
    Ce script vérifie l'accessibilité du port TCP 445 de chaque machine,
    ouvre une connexion SMB authentifiée, vérifie le dossier de destination,
    copie le fichier avec Robocopy puis génère un rapport CSV.

    La liste des machines est chargée depuis un fichier CSV.

.NOTES
    Auteur           : Clément BRILLAC
    Version          : 1.0 - version publique anonymisée
    Usage            : Démonstration / portfolio GitHub
    Propriété        : Clément BRILLAC
    Copyright        : © Clément BRILLAC. Tous droits réservés.

    Cette version publique a été anonymisée. Elle ne contient aucun nom de
    serveur, adresse IP, identifiant, mot de passe ou chemin provenant d'un
    environnement réel.

    Les identifiants sont demandés à l'exécution et ne sont pas stockés
    dans le code.
#>

[CmdletBinding()]
param(
    [string]$FichierSource = "C:\FileDeployment\source\example-file.xls",
    [string]$FichierCSV    = "C:\FileDeployment\config\machines.csv",
    [string]$CheminRelatif = "Users\Public\Documents",
    [string]$FichierLog    = "C:\FileDeployment\logs\deployment-report.csv"
)

# ============================
# Identifiants
# ============================

$credential = Get-Credential -Message "Compte autorisé à accéder aux machines distantes"

# ============================
# Vérifications de départ
# ============================

if (!(Test-Path $FichierSource)) {
    Write-Host "ERREUR : fichier source inaccessible : $FichierSource" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $FichierCSV)) {
    Write-Host "ERREUR : fichier CSV inaccessible : $FichierCSV" -ForegroundColor Red
    exit 1
}

$sourceFolder = Split-Path $FichierSource
$sourceFile   = Split-Path $FichierSource -Leaf

$machines = Import-Csv -Path $FichierCSV -Delimiter ';'
$resultats = @()

$logFolder = Split-Path $FichierLog
if ($logFolder -and !(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# ============================
# Traitement des machines
# ============================

foreach ($machine in $machines) {

    $nomSite = "$($machine.Site)".Trim()
    $ip      = "$($machine.IP)".Trim()

    if ([string]::IsNullOrWhiteSpace($ip)) {
        Write-Host "Ligne ignorée : IP vide dans le CSV pour $nomSite." -ForegroundColor Yellow
        continue
    }

    if ([string]::IsNullOrWhiteSpace($nomSite)) {
        $nomSite = "Site sans nom"
    }

    $partageAdmin = "\\$ip\C$"
    $cheminReseau = "\\$ip\C$\$CheminRelatif"

    Write-Host "`n--- Connexion à $nomSite ($ip) ---" -ForegroundColor Cyan

    $statut = "INCONNU"
    $detail = ""
    $roboCode = $null

    # ============================
    # Test TCP 445
    # ============================

    $port445OK = $false

    for ($i = 1; $i -le 3; $i++) {
        Write-Host "Test SMB 445 tentative $i/3 pour $nomSite ($ip)..." -ForegroundColor Yellow

        $test445 = Test-NetConnection $ip -Port 445 -WarningAction SilentlyContinue

        if ($test445.TcpTestSucceeded -eq $true) {
            $port445OK = $true
            break
        }

        Start-Sleep -Seconds 5
    }

    if (-not $port445OK) {
        $statut = "ECHEC_PORT_445"
        $detail = "Port 445 inaccessible après 3 tentatives"

        Write-Host "ERREUR - $nomSite : port 445 inaccessible." -ForegroundColor Red

        $resultats += [PSCustomObject]@{
            Site     = $nomSite
            IP       = $ip
            Statut   = $statut
            Detail   = $detail
            Robocopy = ""
        }

        continue
    }

    Write-Host "OK - $nomSite : port 445 accessible." -ForegroundColor Green

    # ============================
    # Nettoyage ancienne connexion
    # ============================

    cmd.exe /c "net use $partageAdmin /delete /y >nul 2>&1"

    # ============================
    # Connexion au partage C$
    # ============================

    $userName = $credential.UserName
    $password = $credential.GetNetworkCredential().Password

    $connexion = cmd.exe /c "net use $partageAdmin /user:`"$userName`" `"$password`" 2>&1"

    if ($LASTEXITCODE -ne 0) {
        $statut = "ECHEC_CONNEXION_C$"
        $detail = ($connexion -join " ")

        Write-Host "ERREUR - $nomSite : connexion impossible à $partageAdmin" -ForegroundColor Red

        $resultats += [PSCustomObject]@{
            Site     = $nomSite
            IP       = $ip
            Statut   = $statut
            Detail   = $detail
            Robocopy = ""
        }

        continue
    }

    Write-Host "OK - $nomSite : connexion au partage réussie." -ForegroundColor Green

    # ============================
    # Vérification destination
    # ============================

    if (!(Test-Path $cheminReseau)) {
        $statut = "ECHEC_DOSSIER"
        $detail = "Dossier destination introuvable : $cheminReseau"

        Write-Host "ERREUR - $nomSite : dossier introuvable." -ForegroundColor Red

        cmd.exe /c "net use $partageAdmin /delete /y >nul 2>&1"

        $resultats += [PSCustomObject]@{
            Site     = $nomSite
            IP       = $ip
            Statut   = $statut
            Detail   = $detail
            Robocopy = ""
        }

        continue
    }

    # ============================
    # Copie via Robocopy
    # ============================

    Write-Host "Copie du fichier via Robocopy..." -ForegroundColor Yellow

    robocopy $sourceFolder $cheminReseau $sourceFile /R:3 /W:5 /Z /NP /NFL /NDL

    $roboCode = $LASTEXITCODE

    if ($roboCode -le 7) {
        $statut = "OK"
        $detail = "Fichier copié avec succès via Robocopy"
        Write-Host "OK - $nomSite : fichier copié. Code Robocopy : $roboCode" -ForegroundColor Green
    }
    else {
        $statut = "ECHEC_ROBOCOPY"
        $detail = "Échec Robocopy. Code retour : $roboCode"
        Write-Host "ERREUR - $nomSite : échec Robocopy. Code : $roboCode" -ForegroundColor Red
    }

    # ============================
    # Déconnexion
    # ============================

    cmd.exe /c "net use $partageAdmin /delete /y >nul 2>&1"

    # ============================
    # Ajout résultat
    # ============================

    $resultats += [PSCustomObject]@{
        Site     = $nomSite
        IP       = $ip
        Statut   = $statut
        Detail   = $detail
        Robocopy = $roboCode
    }
}

# ============================
# Export du rapport
# ============================

$resultats | Export-Csv -Path $FichierLog -Delimiter ';' -NoTypeInformation -Encoding UTF8

Write-Host "`nRapport généré : $FichierLog" -ForegroundColor Cyan
