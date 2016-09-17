# Prerequisites
 - [Download](http://go.microsoft.com/fwlink/?LinkID=286152) and install the Microsoft Online Services Sign-In Assistant for IT Professionals RTW on your PC.
 - You’ll also need to [download](http://go.microsoft.com/fwlink/p/?linkid=236297) and install the Azure Active Directory Module for Windows PowerShell

## Scripts
 - [Connect-AAD](Connect-AAD.ps1) - Connect to AAD Service with Administrator Credentials for AAD. You may need to run this only once before other scripts.
 - [Create-AADUsers](Create-AADUsers.ps1) - Create Azure Active Directory users from a csv file (default csv [here](data/Create-AADUsers.csv))and send them emails with their usernames and temporary password. File is moved to processed folder after task is done
 - [Send-HtmlEmail](Send-HtmlEmail.ps1) - Send Html email using a [specific](templates/Create-AADUsers.htm) html email template.
 - [Get-Configuration](Get-Configuration.ps1) - Get PSObject containing configuration from a [Configuration.json](../Configuration.json) file.

 ## How to use

Clone the repo somewhere on your PC.

 If running manually use it as in following example.

 ```
 cd folderwherecloned
 . .\Connect-AAD.ps1
 Connect-AAD
 ```
