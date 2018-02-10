Add-Type -TypeDefinition @"
	public enum VendorStatus
	{
		active = 100,
		inactive = 200,
		pending = 300
	}
"@

<#
.SYNOPSIS
    creates sql statements from suppliers gz file
.DESCRIPTION
    creates sql statements from suppliers gz file
.PARAMETER FilePath
    Path to suppliers compressed file
	#>

function Get-SqlCommandsFromSuppliers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [psobject] $Suppliers
    )
    process {
        $statements = @()
        $now = Get-Date
        $Suppliers | ForEach-Object {
            $statements += "INSERT INTO dbo.Vendor (ABN, FirstName, LastName, CompanyName, Status, Email, CompanyAddress, CompanySuburb, CompanyState, CompanyPostCode, MobileNumber,BankAccountName, BSB, BankAccountNumber, MsaDownloaded, MsaUploaded, ProfileComplete, CreatedBy, UpdatedBy, CreatedOn, UpdatedOn, VendorLeadId) VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}','{19}','{20}','{21}'); `n" -f @(`
                    '00000000000',
					'',
					'',
					$_.name -replace '''', ''''''
					[int][enum]::parse([type]'VendorStatus', $_.status),
					$_.notification_email,
					$_.remit_to_address.remit_to_address1,
					$_.remit_to_address.remit_to_city,
					$_.remit_to_address.remit_to_state,
					$_.remit_to_address.remit_to_postal,
					$_.remit_to_address.remit_to_phone,
					$_.bank_account.account_name,
					($_.bank_account.bsb -replace '-', '')
					$_.bank_account.account_number,
					0,
					0,
					0,
					-1,
					-1,
					$now,
					$now,
					-1)
		}
		return $statements
    }
}


