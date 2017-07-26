Configuration Main
{
  param (
  $machineName,
  $webDeployPackagePath,
  $dbServerName,
  $dbName,
  [PSCredential] $serverCredential,
  [PSCredential] $dbCredential
  )

  $userName = $serverCredential.UserName
  $password = $serverCredential.GetNetworkCredential().Password
  $dbUserName = $dbCredential.UserName
  $dbPassword = $dbCredential.GetNetworkCredential().Password

  Node ($machineName)
  {
	   
     WindowsFeature WebServerRole

        {

           

            Name = "Web-Server"

            Ensure = "Present"


            }

	 
        WindowsFeature WebAppDev

        {

            Name = "Web-App-Dev"

            Ensure = "Present"


            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WebAspNet45

        {

            Name = "Web-Asp-Net45"

            Ensure = "Present"

            Source = $Source

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WebNetExt45

        {

            Name = "Web-Net-Ext45"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WebMgmtCompat
	  {
		Name = "Web-Mgmt-Compat"

		Ensure = "Present"

        DependsOn = "[WindowsFeature]WebServerRole"
	  
	  }

        WindowsFeature WebISAPIExt

        {

            Name = "Web-ISAPI-Ext"

            Ensure = "Present"


            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebISAPIFilter

        {

            Name = "Web-ISAPI-Filter"

            Ensure = "Present"

 
            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebLogLibraries

        {

            Name = "Web-Log-Libraries"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebRequestMonitor

        {

            Name = "Web-Request-Monitor"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebMgmtTools

        {

            Name = "Web-Mgmt-Tools"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebMgmtConsole

        {

            Name = "Web-Mgmt-Console"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WAS

        {

            Name = "WAS"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WASProcessModel

        {

            Name = "WAS-Process-Model"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WASNetEnvironment

        {

            Name = "WAS-NET-Environment"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WASConfigAPIs

        {

            Name = "WAS-Config-APIs"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

   #script block to download WebPI MSI from the Azure storage blob
    Script DownloadWebPIImage
    {
        GetScript = {
            @{
                Result = "WebPIInstall"
            }
        }
        TestScript = {
            Test-Path "C:\WindowsAzure\wpilauncher.exe"
        }
        SetScript ={
            $source = "http://go.microsoft.com/fwlink/?LinkId=255386"
            $destination = "C:\WindowsAzure\wpilauncher.exe"
            Invoke-WebRequest $source -OutFile $destination
       
        }
    }

    Package WebPi_Installation
        {
            Ensure = "Present"
            Name = "Microsoft Web Platform Installer 5.0"
            Path = "C:\WindowsAzure\wpilauncher.exe"
            ProductId = '4D84C195-86F0-4B34-8FDE-4A17EB41306A'
            Arguments = ''
        }

    Package WebDeploy_Installation
        {
            Ensure = "Present"
            Name = "Microsoft Web Deploy 3.5"
            Path = "$env:ProgramFiles\Microsoft\Web Platform Installer\WebPiCmd-x64.exe"
            ProductId = ''
			Arguments = "/install /products:WDeploy  /AcceptEula"
			DependsOn = @("[Package]WebPi_Installation")
        }
	

	Script DeployWebPackage
	{
		GetScript = {
            @{
                Result = ""
            }
        }
        TestScript = {
            $false
        }
        SetScript ={

		$webClient = New-Object -TypeName System.Net.WebClient
		$destination= "C:\WindowsAzure\DotNetAppSqlDb.zip" 
        $webClient.DownloadFile($using:webDeployPackagePath,$destination)
        $connectionStringName = "MyDbConnection-Web.config Connection String"
        $connectionString = "Server=tcp:"+ "$using:dbServerName" + ".database.windows.net,1433;Database=" + "$using:dbName" + ";User ID=" + "$using:dbUserName" + "@$using:dbServerName" + ";Password=" + "$using:dbPassword"+ ";Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        $connectionString | Out-File -filepath C:\WindowsAzure\outfile.txt -append -width 200

        [string[]]$Arguments = @(
            "-verb:sync",
            "-source:package=`"C:\WindowsAzure\DotNetAppSqlDb.zip`"",
            "-dest:auto,computerName=`"localhost`",userName=$using:userName,password=$using:password",
            "-setParam:name=`"$using:connectionStringName`",value=`"$using:connectionString`""
        )

		$MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")
        Start-Process "$MSDeployPath\msdeploy.exe" -ArgumentList $Arguments -Verb runas
        }

	}
    
  }

}
