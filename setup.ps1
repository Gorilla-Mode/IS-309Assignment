param(
    [Switch]$c, # runs a clean install
    [Switch]$f, # overwrites existing env file
    [Switch]$nc, # prevents compose from running
    [Switch]$r, # prevents env from being generated
    [Switch]$d, # Detached, so it doesn't hog the cli
    [Switch]$h # help
)

if($h)
{
    Write-Host "    -c: clean. Cleans up previous install. Removes any containers, images and volumes defined in docker-compose"
    Write-Host "    -f: force. Forces creation of .env file, overwriting if one already exists"
    Write-Host "    -nc: no compose. Stops docker-compose up from running"
    Write-Host "    -r: rebuild. Stops .env file from being generated, allowing rebuild"
    Write-Host "    -d: detach. Composes detached, running service in background leaving cli clear for more shi"
    Write-Host "    -h: helper. Displays what you're reading rn"
    
    return
}

if ($nc -and ($r -or $c -or $d))
{
    Write-Host "    ERROR: Wack flag combo, script TERMINATED"
    return
}

if ($c)
{
    Write-Host "WARNING: Selected flag delete images and volumes defined in docker compose!"
    $conf = Read-Host "     Confirm [Y]"
    
    
    if ($conf -notlike "Y")
    {
        Write-Host "     Aborted"
        exit
    }
}

# retiveves the path of the this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
# --- env ----
if (!$r)
{
    if($f)
    {
        # overwrites file if it exists
        New-Item -Path $scriptDir -Name ".env" -ItemType "File" -Force
    }
    else
    {
        Write-Host $scriptDir
        # checks if file already exists
        if((Test-Path -Path ($scriptDir + "/.env")))
        {
            Write-Output "ERROR: .env file aready exists in directory, use -f to overwrite"
            return
        }
        else
        {
            New-Item -Path $scriptDir -Name ".env" -ItemType "File"
        }
    }
    
    #Passwords stored as secure strings to hide input
    $databaseName = Read-Host "Create database name"
    $secureRootPwd = Read-Host "Create root password" -AsSecureString
    $appUserName = Read-Host "Create app username"
    $secureAppPwd = Read-Host "Create app user password" -AsSecureString

    #returns passwords to plain text
    $rootPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureRootPwd))
    $appPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureAppPwd))

    try
    {
        #populates env file
        Write-Host "    Populating .env @ $scriptDir"

        Add-Content -Path ($scriptDir + "/.env") -Value ("POSTGRES_USER=postgres")
        Write-Host "        - Postgres root username inserted"
        Add-Content -Path ($scriptDir + "/.env") -Value ("POSTGRES_PASSWORD=$rootPwd")
        Write-Host "        - Postgres root password inserted"
        Add-Content -Path ($scriptDir + "/.env") -Value ("POSTGRES_DB=$databaseName")
        Write-Host "        - Postgres database name inserted"
        Add-Content -Path ($scriptDir + "/.env") -Value ("APP_USER=$appUserName")
        Write-Host "        - App username inserted"
        Add-Content -Path ($scriptDir + "/.env") -Value ("APP_PASSWORD=$appPwd")
        Write-Host "        - App user password inserted"
        Add-Content -Path ($scriptDir + "/.env") -Value ("EXTERNALCONNECTION=postgresql://$($appUserName):$($appPwd)@localhost:5432/$databaseName")
        Write-Host "        - External connection string inserted"

        Write-Host "    .env populated successfully"
    }
    catch
    {
        return
    }
}

if ($nc)
{
    return
}

# ---- Docker ----

cd $scriptDir

if ($c)
{
    #removes any previous containers, images and volumes defined in docker-compose.yml
    #this is done so that new password applies to database.
    docker-compose down -v --rmi "all"
}
if($d)
{
    docker-compose up -d
}
else
{
    docker-compose up
}