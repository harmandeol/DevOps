#Requires -Version 4

#Load Types
{
if (-not ([System.Management.Automation.PSTypeName]'CompressHelper').Type) {
Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.IO;
using System.Threading.Tasks;
public static class CompressHelper {
    public static void CopyStream (Stream src, Stream dest) {
        CopyStreamAsync(src, dest).Wait();  // Faster than just using CopyTo()
    }
    public static Task CopyStreamAsync (Stream src, Stream dest) {
        return src.CopyToAsync(dest);
    }
}
"@
    }
}.Invoke()

<#
.SYNOPSIS
    Stream.CopyTo(stream) method causing problems in PowerShell is nonsense.
.DESCRIPTION
    Utter nonsense. This does that with a blocking call to CopyToAsync, in
    the case of large files while using compression the async variant can execute
    twice as fast although the function explicitly blocks.
.PARAMETER SrcStream
    Stream your data is coming from.
.PARAMETER DestStream
    Stream your data is going to.
#>
function Copy-Stream {
    param (
        [IO.Stream]$SrcStream,
        [IO.Stream]$DestStream
    )

    Write-Debug "Copying streams"
    [CompressHelper]::CopyStream($SrcStream, $DestStream)
}

<#
.SYNOPSIS
    Writes incoming data to a gzip compressed file. Note: CompressionMode=Optimal
    slowest compresion but optimal space savings. GZip analog to Out-File, sans encoding.
.DESCRIPTION
    Writes incoming data to a gzip compressed file. Note: CompressionMode=Optimal
    slowest compresion but optimal space savings. Incoming data may be a object/object[]
    (.ToString() values are written to GZip stream) or Stream.
.PARAMETER InputData
    Incoming data may be a object/object[] (.ToString() values are written to GZip stream) or Stream.
    Note: Stream input is processed much faster as object/string types are written syncronously while
    Stream types are an asyncrouns buffered copy by invoking Copy-Stream.
.PARAMETER FilePath
    Path to written GZip compressed file.
.PARAMETER Force
    Force overwriting destination file.
.EXAMPLE
    Copy data from stream object passed through pipeline, recommended for binary data.
    [System.IO.File]::OpenRead("Example.txt") | Out-GzipFile -FilePath "Example.txt.gz" -Force
.EXAMPLE
    Compress and write same source data from Get-Content, this may not preserve source character encoding.
    Get-Content "Example.txt" | Out-GzipFile -FilePath "Example.txt.gz" -Force
.EXAMPLE
    Download file from FTP server and GZip reponse.
    $request = [FtpWebRequest]WebRequest.Create($serverUri)
    $request.Method = [Net.WebRequestMethods.FtpWebRequestMethods+Ftp]::DownloadFile
    [Net.FtpWebResponse]$response = request.GetResponse();
    $response.GetResponseStream() | Out-GzipFile -FilePath "ftp_data.txt.gz"
#>
function Out-GzipFile {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    param (
           [Parameter(Mandatory=$true,
                      ValueFromPipeline=$true,
                      ValueFromPipelineByPropertyName=$true,
                      Position=0)]
           $InputData,
           [Parameter(Mandatory=$true,
                      ValueFromPipeline=$false,
                      ValueFromPipelineByPropertyName=$true,
                      Position=1)]
           [string]$FilePath,
           [Parameter(Mandatory=$false,
                      ValueFromPipeline=$false,
                      ValueFromPipelineByPropertyName=$true,
                      Position=2)]
           [switch]$Force)

    begin {
        $exists = Test-Path $FilePath
        $mode = $null
        if ($exists -and $Force) {
            $mode = "Truncate"
        }
        elseif ($exists) {
            throw [System.IO.IOException] "File exists and `$Force flag not passed. Quiting.."
        }
        else {
            $mode = "CreateNew"
        }

        $task = $null

        $local:fs = New-Object System.IO.FileStream $FilePath, $mode, 'Write', 'None'
        $local:gz = New-Object System.IO.Compression.GZipStream $fs, ([System.IO.Compression.CompressionLevel]::Optimal)
        $local:sw = New-Object System.IO.StreamWriter $gz
    }
    process {
        $bs = $InputData.GetType().BaseType
        if ($bs -like [Array]) {
            $local:sw.WriteLineAsync($InputData)
        }
        elseif ($bs -like [IO.Stream]) {
            Copy-Stream $InputData $gz
        }
        else {
            if ($task -eq $null) {
                $task = $local:sw.WriteLineAsync($InputData.ToString())
            }
            else {
                $task.Wait()
                $task = $local:sw.WriteLineAsync($InputData.ToString())
            }
        }
    }
    end {
        $local:sw.Flush()
        $local:sw.Close()
        $local:gz.Dispose()
        $local:fs.Dispose()
    }
}

<#
.Synopsis
    Read in data from GZip compressed file.
.DESCRIPTION
    Read in data from GZip compressed file. Returns content line by line or
    optionally returns a Stream object initialized with GZip decompress stream adapter.
.EXAMPLE
    Get-GzipContent -FilePath ".\NYSE-2000-2001.tsv.gz" | ConvertFrom-Csv -Delimiter "`t"
.EXAMPLE
    Get-GzipContent -FilePath ".\NYSE-2000-2001.tsv.gz" -ReturnStream
#>
function Get-GzipContent
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        $FilePath,
        $ReturnStream
    )
    Begin
    {
        $local:fs = [IO.File]::OpenRead($FilePath)
        $local:gz = New-Object IO.Compression.GZipStream $local:fs, ([System.IO.Compression.CompressionMode]::Decompress)
        $local:sr = New-Object IO.StreamReader $local:gz
    }
    Process
    {
        if ($ReturnStream) {
            Write-Warning "Returned stream does not close or dispose automatically."
            return $local:sr
        }

        while (-not $local:sr.EndOfStream) {
            $local:sr.ReadLine()
        }
    }
    End
    {
        if (-not $ReturnStream) {
            $local:sr.Close()
            $local:gz.Dispose()
            $local:fs.Dispose()
        }
    }
}
