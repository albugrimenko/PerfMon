<# 
    .SYNOPSIS 
    Perfmon to SQL Server Importer - by David Klee
    http://www.heraflux.com
    
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        Obligatory Disclaimer
        THE SCRIPT AND PARSER IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE 
        INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
        SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA 
        OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION 
        WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    Sample usage of this script:
        ./PerfmonToSQL.ps1 -PerfmonDir "E:\PerfmonData" -ServerName="PRDSQL01" 

    --------------------------------------------------------
    Modified by Alex Bugrimenko
    1. Assume that server name is in the file name and it must NOT contain "_". ("_" used as a separator).
    2. Server name removed from the counter name -> counter stored as an hierarchy: Category\Counter
    3. Square brackets are not allowed in the counter name (power shell does NOT support it in a property name) -> replaced by ()

    The sequence:
    1. Collect all .blg files from all servers listed in the $ConfigFileName
       - store them in the $DestDir
       - use $DaysToProcess = 0 for current files only
    2. Relog all .blg files in the $DestDir -> .tsv files
    3. Delete processed .blg files
    4. Process .tsv files - dump to the database
    5. If $DoneDir is not empty, all processed files will be copied there. Otherwise, processed .tsv files will be deleted.
    --------------------------------------------------------

    #>

<#    
param( 
    $PerfmonDir,
    $ServerName,
    $ConnString = "Data Source=XXX;Initial Catalog=PerfmonE;Connection Timeout=1200;Integrated Security=False;User Id=perfmon;Password=perfmon;Application Name=PowerShell_PerfmonToSQL;",
    $BatchSize = 50000
)
#>
# Contains a simple list of servers to get data from in a format:
# Server Name|full path to the performance monitor files folder
$ConfigFileName = "d:\Temp\PerfMon\PerfmonToSQL_AB.servers"

# Sets how many historical files should be processed in each run. If you need to import only current (today) file, set it to 0.
$DaysToProcess = 5

# Destination Directory
$DestDir = "d:\Temp\PerfMon\Data\"

# Done Directory - Processed files will be copied here if not empty. Otherwise processed files will be deleted
$DoneDir = ""  # "d:\Temp\PerfMon\Data\Processed\"

# DB connection string. Script uses bcp utility to import data to the DB.
$DBConnString = "Data Source=XXX;Initial Catalog=PerfmonE;Connection Timeout=1200;Integrated Security=False;User Id=perfmon;Password=perfmon;Application Name=PowerShell_PerfmonToSQL;"

# bcp utility batch size. Default value is 50,000
$DBBatchSize = 50000

Clear-Host

Write-Host "-- Copying all files from all servers to DestDir"
$config = Get-Content $ConfigFileName
foreach($line in $config) {
    $ServerName = $line.Split("|")[0]
    $ServerPathName = $line.Split("|")[1]
    Write-Host "-- Copying data (.blg files) for" $ServerName "from" $ServerPathName
    $Files = get-childitem $ServerPathName -recurse 
    $BLGList = $Files | where {$_.extension -eq ".blg"} | where {$_.LastWriteTime.Date -ge (Get-Date).Date.AddDays(-$DaysToProcess)}
    ForEach ($File in $BLGList) {
        Copy-Item -Path $File.FullName -Destination $DestDir
        Write-Host "-+ Copied " $File.FullName        
    }
}

$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

# Find all BLG files and RELOG to CSV
# Relog with TSV format instead of CSV because of Counters that have commas in them
# Example: \\DBASE\Processor Information(1,4)\% of Maximum Frequency
Write-Host "-- Reloging BLG files"
$n = 0
$Files = get-childitem $DestDir # -recurse 
$BLGList = $Files | where {$_.extension -eq ".blg"}
ForEach ($File in $BLGList) {
    Write-Host "-- file: " $File.Basename
    $CSVName = $DestDir + $File.Basename + ".tsv"
    relog $File.FullName -f tsv -y -o $CSVName
    $n++

    # remove not allowed characters from the header if any
    $content = Get-Content $CSVName
    if ($content.Count -gt 0 -and $content[0] -match [Regex]::Escape("[")) {
        New-Item $CSVName -ItemType "file" -Force
        $nn = 0
        foreach($line in $content) {
            # adjust header
            if ($nn -eq 0) {
                $line = $line -replace "\[", "(" -replace "\]", ")"
            }
            $line | Add-Content -Path $CSVName
            $nn++
        }
    }

    # delete .blg file
    Remove-Item -Path $File.FullName
}
Write-Host "++ Relogged BLG files:" $n " file(s) processed."

$EndTime = $StartTime.Elapsed
Write-Host $([string]::Format("`r++ Time elapsed: {0:d2}:{1:d2}:{2:d2}", $EndTime.hours, $EndTime.minutes, $EndTime.seconds))

if ($n -lt 1) {
    Write-Host "+++ DONE +++"
    Break
}

$StartTime2 = [System.Diagnostics.Stopwatch]::StartNew()

# Find all CSV files and import into database
Write-Host "-- Saving data to DB"

$Files = get-childitem $DestDir -recurse 
$CSVList = $Files | where {$_.extension -eq ".tsv"}
ForEach ($File in $CSVList) {
    # -- DB conection
    $conn = new-object System.Data.SqlClient.SqlConnection($DBConnString)
    $bcp = new-object ("System.Data.SqlClient.SqlBulkCopy") $conn
    $bcp.DestinationTableName = "stage.Perfmon"
    $bcp.BulkCopyTimeout = 0
    $conn.Open()
   
    # Create placeholder datatable
    $dt = new-object System.Data.DataTable
    $col0 = new-object System.Data.DataColumn 'ServerName' 
    $col1 = new-object System.Data.DataColumn 'DateTimeStamp' 
    $col2 = new-object System.Data.DataColumn 'CounterInstance'
    $col3 = new-object System.Data.DataColumn 'CounterValue' 
    $dt.columns.Add($col0) 
    $dt.columns.Add($col1)
    $dt.columns.Add($col2)
    $dt.columns.Add($col3)

    $ServerName = $File.BaseName.Split("_")[0]
    Write-Host "-- Server:" $ServerName " Importing TSV file:" $File.Basename

    $datapointCounter = 0

    #Load this CSV into RAM
    $csv = Import-Csv -Delimiter "`t" -Path $File.FullName

    $err_cnt = 0
    $err_cnt_max = 5

    # Iterate through the CSV
    foreach($line in $csv) {
        if ($err_cnt -gt $err_cnt_max) {
            break
        }

        try {
            $properties = $line | Get-Member -MemberType NoteProperty

            # Iterate through columns
            $timestamp = $line | select -ExpandProperty $properties[0].Name
            for($i=1; $i -lt $properties.Count -and $err_cnt -le $err_cnt_max; $i++) {
                $colname = $properties[$i].Name -replace $ServerName, "" -replace "\\\\", ""
                Try {
                    $colvalue = $line | select -ExpandProperty $properties[$i].Name
                    $colvalue = $colvalue.Trim()
                }
                Catch {
                    Write-Host "-! Invalid counter name:" $colname
                    $error.Clear()
                    Continue
                }

                if (!$colvalue -or $colvalue.trim() -eq "") { 
                    continue 
                }

                # Prep data
                $row = $dt.NewRow()
                $row.ServerName = $ServerName
                $row.DateTimeStamp = [datetime]$timestamp
                $row.CounterInstance = [string]$colname
                $row.CounterValue = [float]$colvalue
                $dt.Rows.Add($row)
                $datapointCounter = $datapointCounter + 1

                # Flush to database after batch size is met
                if ( ($datapointCounter % $DBBatchSize) -eq 0 ) {
                    Write-Host "-+" $datapointCounter "points collected. Flushing to database..."
                    $bcp.WriteToServer($dt)
                    $dt.Clear()
                }
            }
        } 
        catch {
            $err_cnt++
            Write-Host "-! Invalid counter name: " $col.Name
            Write-Host "-!" $_.Exception.Message
        }
    }

    # Final flush to database
    if ($dt.Rows.Count -gt 0) {
        Write-Host "-+" $datapointCounter "points collected. Flushing to database..."
        $bcp.WriteToServer($dt)
        $dt.Clear()
    }

    # DB Clean up
    $conn.Close()
    $conn.Dispose()
    $bcp.Close()
    $bcp.Dispose()
    $dt.Dispose()
    [System.GC]::Collect()

    # moving file to the Processed dir
    if ($DoneDir -eq "") {
        Remove-Item -Path $File.FullName
    }
    else {
        Move-Item -Path $File.FullName -Destination $DoneDir -Force
    }
    Write-Host "-+ File processing completed." 

    if ($err_cnt -ge $err_cnt_max) {
        Write-Host "!! Number of errors exceeded limit of" $err_cnt_max
	Break
    }
}

$EndTime = $StartTime2.Elapsed
Write-Host $([string]::Format("`r++ Time elapsed: {0:d2}:{1:d2}:{2:d2}", $EndTime.hours, $EndTime.minutes, $EndTime.seconds))

Write-Host "-- Moving data to final table and clean up staging table"
$conn = new-object System.Data.SqlClient.SqlConnection($DBConnString)
$conn.Open()
$cmd = new-object System.Data.SqlClient.SqlCommand
$cmd.Connection = $conn
$cmd.CommandTimeout = 600
$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
$cmd.CommandText = "stage.Perfmon_Import"
$f = $cmd.ExecuteNonQuery()
$conn.Close()
$conn.Dispose()
Write-Host "++ Done importing this Perfmon data batch!"

$EndTime = $StartTime.Elapsed
Write-Host $([string]::Format("`r+++ DONE. Total time elapsed: {0:d2}:{1:d2}:{2:d2}", $EndTime.hours, $EndTime.minutes, $EndTime.seconds))
