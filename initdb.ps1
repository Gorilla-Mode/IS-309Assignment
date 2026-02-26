param(
    [Switch]$h, # helper
    [Switch]$ni, # no inject
    [Switch]$ne, # no execute
    [Switch]$r, #Rebuilds database
    [Switch]$rc, #restarts containers
    [Switch]$l #attaches logger
)

if($h)
{
    Write-Host "WARNING: script will not catch any errors inside docker container. Check tables manually for now"
    Write-Host "    -h: helper. Displays what you're reading rn"
    Write-Host "    -ni: no inject. Prevents sql from being injected to container"
    Write-Host "    -ne: no execute. Prevents sql script in container from being executed"
    Write-Host "    -r: rebuild. Drops database, and reacreates it"
    Write-Host "    -rc: restart containers. Restarts containers"
    Write-Host "        -l: logger. Attaches logging to cli, allows confirmation of integration tests. requires -rc"
    return
}

if($l -and !$rc)
{
    Write-Host "    ERROR: Illegal flag. Must run -rc to run -l"
    return
}

if ($r)
{
    Write-Host "WARNING: Selected flag will terminate connections and drop database!"
    $conf = Read-Host "     Confirm [Y]"

    if ($conf -notlike "Y")
    {
        Write-Host "     Aborted"
        exit
    }
}

$scriptAbsolutePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sqlAbsolutePath = $scriptAbsolutePath+"/db.sql"
$SqlUserPath = $scriptAbsolutePath+"/user.sql"
$envAbsolutePath = $scriptAbsolutePath+"/.env"

#tests
$sqlFileExists = Test-Path -Path $sqlAbsolutePath
$envFileExists = Test-Path -Path $envAbsolutePath

if(!$sqlFileExists)
{
    Write-Host "Error: db.sql not found"
    return
}
if(!$envFileExists)
{
    Write-Host "Error: .env file not found, make sure to make env file first"
    return
}

#stores env file as hashtable, for ease of access
$envHash = @{}

if(!$ni)
{
    try
    {
        #injects sql script to container
        Write-Host "Injecting sql from @ $sqlAbsolutePath to container..."
        # Use the container name from docker-compose (container_name: is309_db)
        docker cp $sqlAbsolutePath is309_db:/db.sql
    }
    catch
    {
        Write-Host "Sql injection failed"
        return
    }
}

#populates hashtable with variables and values from env
Get-Content $envAbsolutePath | foreach {
    $variable, $value = $_.split('=')
    if ([string]::IsNullOrWhiteSpace($variable) -or $variable.Contains('#'))
    {
        #skips empty lines or comments
        return
    }
    $envHash["$variable"] = "$value"
}

if($r) #goofy script maybe redo
{
    try
    {
        Write-Host "Rebuilding Database"
        Write-Host "    Generating drop database sql script..."
        $dropsqlAbsolutePath = $scriptAbsolutePath + "/dropdb.sql"
        $dropSqlContent = @"
REVOKE CONNECT ON DATABASE $($envHash['POSTGRES_DB']) FROM public;
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$($envHash['POSTGRES_DB'])' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS $($envHash['POSTGRES_DB']);
CREATE DATABASE $($envHash['POSTGRES_DB']);
"@
        $dropSqlContent | Out-File -FilePath $dropsqlAbsolutePath -Encoding UTF8 -Force

        Write-Host "    Injecting sql from @ $dropsqlAbsolutePath to container..."
        docker cp -q $dropsqlAbsolutePath is309_db:/

        Write-Host "    Executing database sql script on $($envHash['POSTGRES_DB'])..."
        docker exec -i is309_db env PGPASSWORD=$($envHash['POSTGRES_PASSWORD']) psql -U $($envHash['POSTGRES_USER']) -d postgres -f /dropdb.sql

        Write-Host "    Removing used script from @ $dropsqlAbsolutePath..."
        Remove-Item -Path $dropsqlAbsolutePath -ErrorAction SilentlyContinue
        docker exec -i is309_db rm -f /dropdb.sql
        Write-Host "    Database dropped and recreated!"

    }
    catch
    {
        return
    }
}

if(!$ne)
{
    try
    {
        #runs sql script on container
        Write-Host "Executing database sql script on $($envHash['POSTGRES_DB'])..."
        # Run psql inside the Postgres container. Prefix with PGPASSWORD so psql can authenticate non-interactively.
        docker exec -i is309_db sh -c "PGPASSWORD='$($envHash['POSTGRES_PASSWORD'])' psql -U $($envHash['POSTGRES_USER']) -d $($envHash['POSTGRES_DB']) -f /db.sql"
        Write-Host "    Sql script executed, tables built"
    }
    catch
    {
        return
    }
}
if($rc) #Restart container with logger to confirm integration tests
{
    Write-Host "Restaring containers detatched.."
    docker-compose stop
    docker-compose start
    Write-Host "Containers restared, logger attached"
    if($l)
    {
        Write-Host "logger attached"
        docker-compose logs -f --since 0m
    }
}