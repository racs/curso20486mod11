# install.ps1
param($rootPath, $toolsPath, $package, $project)

function CountSolutionFilesByExtension($extension) {
	$path = [System.IO.Path]::GetDirectoryName($project.FullName)
	$totalfiles = [System.IO.Directory]::EnumerateFiles("$path", "*." + $extension, [System.IO.SearchOption]::AllDirectories)
	[int]$totalcount = ($totalfiles | Measure-Object).Count
	
	[int]$count = $totalcount
	# Don't count the DisplayTemplates directory - need to subtract them.
	if (($extension -eq "cshtml") -or ($extension -eq "vbhtml")) {
		$razorfiles = [System.IO.Directory]::EnumerateFiles("$path\Views\Shared\DisplayTemplates", "*." + $extension)
		[int]$razorcount = ($razorfiles | Measure-Object).Count
		[int]$count = $totalcount - $razorcount
	}
	
	Write-Host "Project has $count $extension extensions"
	return $count
}

### Copied from MvcScaffolding
function InferPreferredViewEngine() {
	# Assume you want Razor except if you already have some ASPX views and no Razor ones
	Write-Host "Checking for .aspx extensions"
	if ((CountSolutionFilesByExtension "aspx") -eq 0) { return "razor" }
	Write-Host "Checking for razor extensions"
	if (((CountSolutionFilesByExtension "cshtml") -gt 0) -or ((CountSolutionFilesByExtension vbhtml) -gt 0)) { return "razor" }
	Write-Host "No razor found, using aspx"
	return "aspx"
}

function Add-Or-Update-AppSettings() {
	$xml = New-Object xml

	$web_config_path = Get-Web-Config-Path
	$xml.Load($web_config_path)

	$conf = $xml.SelectSingleNode("configuration")
	if ($conf -eq $null)
	{
		$conf = $xml.CreateElement("configuration")
		$xml.AppendChild($conf)
	}
	
	$appSettings = $xml.SelectSingleNode("configuration/appSettings")
	if ($appSettings -eq $null) {
		$appSettings = $xml.CreateElement("appSettings")
		$conf.AppendChild($appSettings)
	}
	
	# add or update MvcSiteMapProvider_UseExternalDIContainer
	$ext_di = $xml.SelectSingleNode("configuration/appSettings/add[@key='MvcSiteMapProvider_UseExternalDIContainer']")
	if ($ext_di -ne $null) {
		$ext_di.SetAttribute("value", "false")
	} else {
		$ext_di = $xml.CreateElement("add")
		
		$key = $xml.CreateAttribute("key")
		$key.Value = "MvcSiteMapProvider_UseExternalDIContainer"
		$ext_di.Attributes.Append($key)
		
		$value = $xml.CreateAttribute("value")
		$value.Value = "false"
		$ext_di.Attributes.Append($value)
		
		$appSettings.AppendChild($ext_di)
	}
	
	# add or update MvcSiteMapProvider_ScanAssembliesForSiteMapNodes
	$scan = $xml.SelectSingleNode("configuration/appSettings/add[@key='MvcSiteMapProvider_ScanAssembliesForSiteMapNodes']")
	if ($scan -ne $null) {
		$scan.SetAttribute("value", "true")
	} else {
		$scan = $xml.CreateElement("add")
		
		$key = $xml.CreateAttribute("key")
		$key.Value = "MvcSiteMapProvider_ScanAssembliesForSiteMapNodes"
		$scan.Attributes.Append($key)
		
		$value = $xml.CreateAttribute("value")
		$value.Value = "true"
		$scan.Attributes.Append($value)
		
		$appSettings.AppendChild($scan)
	}
	
	Save-Document-With-Formatting $xml $web_config_path
}

function Add-Pages-Namespaces() {
	$xml = New-Object xml
	
	$web_config_path = Get-Web-Config-Path
	$xml.Load($web_config_path)

	$conf = $xml.SelectSingleNode("configuration")
	if ($conf -eq $null)
	{
		$conf = $xml.CreateElement("configuration")
		$xml.AppendChild($conf)
	}
	
	$system_web = $xml.SelectSingleNode("configuration/system.web")
	if ($system_web -eq $null) {
		$system_web = $xml.CreateElement("system.web")
		$conf.AppendChild($system_web)
	}
	
	$pages = $xml.SelectSingleNode("configuration/system.web/pages")
	if ($pages -eq $null) {
		$pages = $xml.CreateElement("pages")
		$system_web.AppendChild($pages)
	}
	
	$namespaces = $xml.SelectSingleNode("configuration/system.web/pages/namespaces")
	if ($namespaces -eq $null) {
		$namespaces = $xml.CreateElement("namespaces")
		$pages.AppendChild($namespaces)
	}
	
	# add MvcSiteMapProvider.Web.Html if it doesn't already exist
	$html = $xml.SelectSingleNode("configuration/system.web/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html']")
	if ($html -eq $null) {
		$html = $xml.CreateElement("add")
		
		$namespace_html = $xml.CreateAttribute("namespace")
		$namespace_html.Value = "MvcSiteMapProvider.Web.Html"
		$html.Attributes.Append($namespace_html)
		
		$namespaces.AppendChild($html)
	}
	
	# add MvcSiteMapProvider.Web.Html.Models if it doesn't already exist
	$html_models = $xml.SelectSingleNode("configuration/system.web/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html.Models']")
	if ($html_models -eq $null) {
		$html_models = $xml.CreateElement("add")
		
		$namespace_models = $xml.CreateAttribute("namespace")
		$namespace_models.Value = "MvcSiteMapProvider.Web.Html.Models"
		$html_models.Attributes.Append($namespace_models)
		
		$namespaces.AppendChild($html_models)
	}
	
	Save-Document-With-Formatting $xml $web_config_path
}

function Add-Razor-Pages-Namespaces() {
	$xml = New-Object xml

	$path = [System.IO.Path]::GetDirectoryName($project.FullName)
	$web_config_path = "$path\Views\Web.config"

	# load Web.config as XML
	$xml.Load($web_config_path)

	$conf = $xml.SelectSingleNode("configuration")
	if ($conf -eq $null)
	{
		$conf = $xml.CreateElement("configuration")
		$xml.AppendChild($conf)
	}
	
	$system_web_webpages_razor = $xml.SelectSingleNode("configuration/system.web.webPages.razor")
	if ($system_web_webpages_razor -eq $null) {
		$system_web_webpages_razor = $xml.CreateElement("system.web.webPages.razor")
		$conf.AppendChild($system_web_webpages_razor)
	}
	
	$pages = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages")
	if ($pages -eq $null) {
		$pages = $xml.CreateElement("pages")
		
		$page_base_type = $xml.CreateAttribute("pageBaseType")
		$page_base_type.Value = "System.Web.Mvc.WebViewPage"
		$pages.Attributes.Append($page_base_type)
		
		$system_web_webpages_razor.AppendChild($pages)
	}
	
	$namespaces = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces")
	if ($namespaces -eq $null) {
		$namespaces = $xml.CreateElement("namespaces")
		$pages.AppendChild($namespaces)
	}
	
	# add MvcSiteMapProvider.Web.Html if it doesn't already exist
	$html = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html']")
	if ($html -eq $null) {
		$html = $xml.CreateElement("add")
		
		$namespace_html = $xml.CreateAttribute("namespace")
		$namespace_html.Value = "MvcSiteMapProvider.Web.Html"
		$html.Attributes.Append($namespace_html)
		
		$namespaces.AppendChild($html)
	}
	
	# add MvcSiteMapProvider.Web.Html.Models if it doesn't already exist
	$html_models = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html.Models']")
	if ($html_models -eq $null) {
		$html_models = $xml.CreateElement("add")
		
		$namespace_models = $xml.CreateAttribute("namespace")
		$namespace_models.Value = "MvcSiteMapProvider.Web.Html.Models"
		$html_models.Attributes.Append($namespace_models)
		
		$namespaces.AppendChild($html_models)
	}
	
	Save-Document-With-Formatting $xml $web_config_path
}

function Update-SiteMap-Element() {
	$xml = New-Object xml

	$web_config_path = Get-Web-Config-Path
	$xml.Load($web_config_path)

	$siteMap = $xml.SelectSingleNode("configuration/system.web/siteMap")
	if ($siteMap -ne $null) {
		if ($xml.SelectSingleNode("configuration/system.web/siteMap[@enabled]") -ne $null) {
			$siteMap.SetAttribute("enabled", "false")
		} else {
			$enabled = $xml.CreateAttribute("enabled")
			$enabled.Value = "false"
			$siteMap.Attributes.Append($enabled)
		}
	}
	
	Save-Document-With-Formatting $xml $web_config_path
}

function Add-MVC4-Config-Sections() {
	$xml = New-Object xml
	
	$web_config_path = Get-Web-Config-Path
	$xml.Load($web_config_path)
	
	$conf = $xml.SelectSingleNode("configuration")
	if ($conf -eq $null)
	{
		$conf = $xml.CreateElement("configuration")
		$xml.AppendChild($conf)
	}
	
	$ws = $xml.SelectSingleNode("configuration/system.webServer")
	if ($ws -eq $null) {
		$ws = $xml.CreateElement("system.webServer")
		$conf.AppendChild($ws)
	}
	
	$modules = $xml.SelectSingleNode("configuration/system.webServer/modules")
	if ($modules -eq $null) {
		$modules = $xml.CreateElement("modules")
		$ws.AppendChild($modules)
	}
	
	$remove = $xml.SelectSingleNode("configuration/system.webServer/modules/remove[@name='UrlRoutingModule-4.0']")
	if ($remove -eq $null) {
		$remove = $xml.CreateElement("remove")
		
		$name = $xml.CreateAttribute("name")
		$name.Value = "UrlRoutingModule-4.0"
		$remove.Attributes.Append($name)
		
		$modules.AppendChild($remove)
	}
	
	$add = $xml.SelectSingleNode("configuration/system.webServer/modules/add[@name='UrlRoutingModule-4.0']")
	if ($add -eq $null) {
		$add = $xml.CreateElement("add")
		
		$name = $xml.CreateAttribute("name")
		$name.Value = "UrlRoutingModule-4.0"
		$add.Attributes.Append($name)
		
		$type = $xml.CreateAttribute("type")
		$type.Value = "System.Web.Routing.UrlRoutingModule"
		$add.Attributes.Append($type)
		
		$modules.AppendChild($add)
	}
	
	Save-Document-With-Formatting $xml $web_config_path
}

#Gets the encoding from an open xml document as a System.Text.Encoding type
function Get-Document-Encoding([xml] $xml) {
	[string] $encodingStr = ""
	if ($xml.FirstChild.NodeType -eq [System.Xml.XmlNodeType]::XmlDeclaration) {
		[System.Xml.XmlDeclaration] $declaration = $xml.FirstChild
		$encodingStr = $declaration.Encoding
	}
	if ([string]::IsNullOrEmpty($encodingStr) -eq $false) {
		$encoding = $null
		Try {
			$encoding = [System.Text.Encoding]::GetEncoding($encodingStr)
		}
		Catch [System.Exception] {
			$encoding = $null
		}
		return $encoding
	} else {
		return $null
	}
}

function Save-Document-With-Formatting([xml] $xml, [string] $path) {
	# save the xml file with formatting and original encoding
	$encoding = Get-Document-Encoding $xml
	$writer = New-Object System.Xml.XmlTextWriter -ArgumentList @($path, $encoding)
	$writer.Formatting = [System.Xml.Formatting]::Indented
	$xml.Save($writer)
	$writer.Close()
}

function Get-Web-Config-Path() {
	$path = [System.IO.Path]::GetDirectoryName($project.FullName)
	$web_config_path = "$path\Web.config"
	return $web_config_path
}

# Infer which view engine you're using based on the files in your project
if ([string](InferPreferredViewEngine) -eq 'aspx') { 
	(Get-Project).ProjectItems | ?{ $_.Name -eq "Views" } | %{ $_.ProjectItems | ?{ $_.Name -eq "Shared" } } | %{ $_.ProjectItems | ?{ $_.Name -eq "DisplayTemplates" } } | %{ $_.ProjectItems | ?{ $_.Name -eq "MenuHelperModel.cshtml" -or  $_.Name -eq "SiteMapHelperModel.cshtml" -or  $_.Name -eq "SiteMapNodeModel.cshtml" -or  $_.Name -eq "SiteMapNodeModelList.cshtml" -or  $_.Name -eq "SiteMapPathHelperModel.cshtml" -or  $_.Name -eq "SiteMapTitleHelperModel.cshtml" -or  $_.Name -eq "CanonicalHelperModel.cshtml" -or  $_.Name -eq "MetaRobotsHelperModel.cshtml" } } | %{ $_.Delete() }
} else {
	(Get-Project).ProjectItems | ?{ $_.Name -eq "Views" } | %{ $_.ProjectItems | ?{ $_.Name -eq "Shared" } } | %{ $_.ProjectItems | ?{ $_.Name -eq "DisplayTemplates" } } | %{ $_.ProjectItems | ?{ $_.Name -eq "MenuHelperModel.ascx" -or  $_.Name -eq "SiteMapHelperModel.ascx" -or  $_.Name -eq "SiteMapNodeModel.ascx" -or  $_.Name -eq "SiteMapNodeModelList.ascx" -or  $_.Name -eq "SiteMapPathHelperModel.ascx" -or  $_.Name -eq "SiteMapTitleHelperModel.ascx" -or  $_.Name -eq "CanonicalHelperModel.ascx" -or  $_.Name -eq "MetaRobotsHelperModel.ascx" } } | %{ $_.Delete() }
}

# If MVC 4 or higher, install web.config section to fix 404 not found on sitemap.xml (#124)
$mvc_version = $project.Object.References.Find("System.Web.Mvc").Version
Write-Host "MVC Version: $mvc_version"
if ($mvc_version -notmatch '^[123]\.' -or [string]::IsNullOrEmpty($mvc_version))
{
	Write-Host "Installing config sections for MVC >= 4"
	Add-MVC4-Config-Sections
}

# Fixup the web.config files
Add-Or-Update-AppSettings
Add-Pages-Namespaces
Add-Razor-Pages-Namespaces
Update-SiteMap-Element

# SIG # Begin signature block
# MIIdiQYJKoZIhvcNAQcCoIIdejCCHXYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTBFWV+hXPcCWQ7jEO2Z/W2Lw
# 7cygghhTMIIEwjCCA6qgAwIBAgITMwAAAMDeLD0HlORJeQAAAAAAwDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODUw
# WhcNMTgwOTA3MTc1ODUwWjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046
# N0FCNS0yREYyLURBM0YxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDoiKVSfklVAB4E
# Oc9+r95kl32muXNITYcTbaRtuJl+MQzEnD0eU2JUXx2mI06ONnTfFW39ZQPF1pvU
# WkHBrS6m8oKy7Em4Ol91RJ5Knwy1VvY2Tawqh+VxwdARRgOeFtFm0S+Pa+BrXtVU
# hTtGl0BGMsKGEQKdDNGJD259Iq47qPLw3CmllE3/YFw1GGoJ9C3ry+I7ntxIjJYB
# LXA122vw93OOD/zWFh1SVq2AejPxcjKtHH2hjoeTKwkFeMNtIekrUSvhbuCGxW5r
# 54KW0Yus4o8392l9Vz8lSEn2j/TgPTqD6EZlzkpw54VSwede/vyqgZIrRbat0bAh
# b8doY8vDAgMBAAGjggEJMIIBBTAdBgNVHQ4EFgQUFf5K2jOJ0xmF1WRZxNxTQRBP
# tzUwHwYDVR0jBBgwFoAUIzT42VJGcArtQPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJ
# oEegRYZDaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljcm9zb2Z0VGltZVN0YW1wUENBLmNybDBYBggrBgEFBQcBAQRMMEowSAYIKwYB
# BQUHMAKGPGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0VGltZVN0YW1wUENBLmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQUFAAOCAQEAGeJAuzJMR+kovMi8RK/LtfrKazWlR5Lx02hM9GFmMk1zWCSc
# pfVY6xqfzWFllCFHBtOaJZqLiV97jfNCLpG0PULz24CWSkG7jJ+mZaCSicZ7ZC3b
# WDh1zpc54llYVyyTkRVYx/mtc9GujqbS8CBZgjaT/JsECnvGAPUcLYuSGt53CU1b
# UuiNwuzAhai4glcYyq3/7qMmmAtbnbCZhR5ySoMy7BwdzN70drLtafCJQncfAHXV
# O5r6SX4U/2J2zvWhA8lqhZu9SRulFGRvf81VTf+k5rJ2TjL6dYtSchooJ5YVvUk6
# i7bfV0VBN8xpaUhk8jbBnxhDPKIvDvnZlhPuJjCCBgAwggPooAMCAQICEzMAAADD
# Dpun2LLc9ywAAAAAAMMwDQYJKoZIhvcNAQELBQAwfjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2ln
# bmluZyBQQ0EgMjAxMTAeFw0xNzA4MTEyMDIwMjRaFw0xODA4MTEyMDIwMjRaMHQx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xHjAcBgNVBAMTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBALtX1zjRsQZ/SS2pbbNjn3q6tjohW7SYro3UpIGgxXXFLO+CQCq3gVN382MB
# CrzON4QDQENXgkvO7R+2/YBtycKRXQXH3FZZAOEM61fe/fG4kCe/dUr8dbJyWLbF
# SJszYgXRlZSlvzkirY0STUZi2jIZzqoiXFZIsW9FyWd2Yl0wiKMvKMUfUCrZhtsa
# ESWBwvT1Zy7neR314hx19E7Mx/znvwuARyn/z81psQwLYOtn5oQbm039bUc6x9nB
# YWHylRKhDQeuYyHY9Jkc/3hVge6leegggl8K2rVTGVQBVw2HkY3CfPFUhoDhYtuC
# cz4mXvBAEtI51SYDDYWIMV8KC4sCAwEAAaOCAX8wggF7MB8GA1UdJQQYMBYGCisG
# AQQBgjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBSnE10fIYlV6APunhc26vJUiDUZ
# rzBRBgNVHREESjBIpEYwRDEMMAoGA1UECxMDQU9DMTQwMgYDVQQFEysyMzAwMTIr
# YzgwNGI1ZWEtNDliNC00MjM4LTgzNjItZDg1MWZhMjI1NGZjMB8GA1UdIwQYMBaA
# FEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFf
# MjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
# TZdPNH7xcJOc49UaS5wRfmsmxKUk9N9E1CS6s2oIiZmayzHncJv/FB2wBzl/5DA7
# EyLeDsiVZ7tufvh8laSQgjeTpoPTSQLBrK1Z75G3p2YADqJMJdTc510HAsooNGU7
# OYOtlSqOyqDoCDoc/j57QEmUTY5UJQrlsccK7nE3xpteNvWnQkT7vIewDcA12SaH
# X/9n7yh094owBBGKZ8xLNWBqIefDjQeDXpurnXEfKSYJEdT1gtPSNgcpruiSbZB/
# AMmoW+7QBGX7oQ5XU8zymInznxWTyAbEY1JhAk9XSBz1+3USyrX59MJpX7uhnQ1p
# gyfrgz4dazHD7g7xxIRDh+4xnAYAMny3IIq5CCPqVrAY1LK9Few37WTTaxUCI8aK
# M4c60Zu2wJZZLKABU4QBX/J7wXqw7NTYUvZfdYFEWRY4J1O7UPNecd/311HcMdUa
# YzUql36fZjdfz1Uz77LKvCwjqkQe7vtnSLToQsMPilFYokYCYSZaGb9clOmoQHDn
# WzBMfIDUUGeipe4O6z218eV5HuH1WBlvu4lteOIgWCX/5Eiz5q/xskAEF0ZQ1Axs
# kRR97sri9ibeGzsEZ1EuD6QX90L/P5GJMfinvLPlOlLcKjN/SmSRZdhlEbbbare0
# bFL8v4txFsQsznOaoOldCMFFRaUphuwBMW1edMZWMQswggYHMIID76ADAgECAgph
# Fmg0AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20x
# GTAXBgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBS
# b290IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0
# MDMxMzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# ITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP
# 7tGn0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySH
# nfL0Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUo
# Ri4nrIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABK
# R2YRJylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSf
# rx54QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGn
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMP
# MAsGA1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQO
# rIJgQFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZ
# MBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1Ud
# HwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYI
# KwYBBQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWlj
# cm9zb2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKi
# jG1iuFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV
# 3U+rkuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5
# nGctxVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tO
# i3/FNSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbM
# UVbonXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXj
# pKh0NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh
# 0EPpK+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLax
# aj2JoXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWw
# ymO0eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma
# 7kng9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3ow
# ggVioAMCAQICCmEOkNIAAAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBS
# b290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoX
# DTI2MDcwODIxMDkwOVowfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLry
# tlghn0IbKmvpWlCquAY4GgRJun/DDB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlk
# h36UYCRsr55JnOloXtLfm1OyCizDr9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sI
# UM+zRLdd2MQuA3WraPPLbfM6XKEW9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5
# pUkp5w2+oBN3vpQ97/vjK1oQH01WKKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd
# 6IlPhBryoS9Z5JA7La4zWMW3Pv4y07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9T
# upwPrRkjhMv0ugOGjfdf8NBSv4yUh7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOn
# qWbsYR9q4ShJnV+I4iVd0yFLPlLEtVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKC
# X9vAFbO9G9RVS+c5oQ/pI0m8GLhEfEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkw
# p6uO3+xbn6/83bBm4sGXgXvt1u1L50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo
# 8e1twyiPLI9AN0/B4YVEicQJTMXUpUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96e
# TvSWsLxGoGyY0uDWiIwLAgMBAAGjggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAd
# BgNVHQ4EFgQUSG5k5VAF04KqFzc3IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBT
# AHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgw
# FoAUci06AjGQQ7kUBU7h6qfHMdEjiTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0
# MjAxMV8yMDExXzAzXzIyLmNybDBeBggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKG
# Qmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0
# MjAxMV8yMDExXzAzXzIyLmNydDCBnwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMw
# gYMwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# ZG9jcy9wcmltYXJ5Y3BzLmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwA
# XwBwAG8AbABpAGMAeQBfAHMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0B
# AQsFAAOCAgEAZ/KGpZjgVHkaLtPYdGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy
# 0W2D/r4/6ArKO79HqaPzadtjvyI1pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9
# a+M+By4pm+Y9G6XUtR13lDni6WTJRD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUM
# m+1o+mgulaAqPyprWEljHwlpblqYluSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMO
# r5kol5hNDj0L8giJ1h/DMhji8MUtzluetEk5CsYKwsatruWy2dsViFFFWDgycSca
# f7H0J/jeLDogaZiyWYlobm+nt3TDQAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWn
# duVAKmWjw11SYobDHWM2l4bf2vP48hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1
# HxS+YWG18NzGGwS+30HHDiju3mUv7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnF
# sZulP0V3HjXG0qKin3p6IvpIlR+r+0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9az
# I2h15q/6/IvrC4DqaTuv/DDtBEyO3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/
# +6jMpF3BoYibV3FWTkhFwELJm3ZbCoBIa/15n8G9bW1qyVJzEw16UM0xggSgMIIE
# nAIBATCBlTB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgw
# JgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExAhMzAAAAww6b
# p9iy3PcsAAAAAADDMAkGBSsOAwIaBQCggbQwGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkE
# MRYEFL86HR7yiujlb227AvDUh6apP9kGMFQGCisGAQQBgjcCAQwxRjBEoCaAJABN
# AGkAYwByAG8AcwBvAGYAdAAgAEwAZQBhAHIAbgBpAG4AZ6EagBhodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAnNkJtSYRy36rnNkWJzGv
# KiAG/47A+G5V9sToDpCTGllZ8wMeV2TjcnINLDtwqTPMoihg4t/V+SEjqY0j/bFW
# 6I/Q+yWiLPZ16BXfyq8HUevXy3R6CFuOETq4heM/bEp9UHgyP+Oa1950q8ZVoCG1
# yn77pApSFXfbF/B/mpTlmmGEUaU4pzaPZ3XUNPmQDZp/lBvoXjxywd3ctLzxzlr7
# V2F8nw7ChcWDBZO45OBI/s3nIPW1MjN1lLOUT9RNCMXLd/0UEwOHDkvoZwS7zNQV
# LPvo/df4+6AETe59O/IEf9JzArDxdPQCZKvtv7goUjCk/dKK60T35NM5LM4F4f6K
# WqGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0ECEzMAAADA3iw9B5TkSXkAAAAAAMAwCQYFKw4DAhoFAKBdMBgG
# CSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE3MTIyMDA5
# MjE1OFowIwYJKoZIhvcNAQkEMRYEFFU7iVMVYfCvdkVo7p/YsFYQgKeMMA0GCSqG
# SIb3DQEBBQUABIIBAE2wpv5RC4SSLV2sCM3JySBPdRNL+lfqOxw+q3M6dt5bBlvA
# W493RqTrmcUfF/cXxXnp+1+aAmG6XsWkSznpQhLrUNQWkePFEtENs3FBmcgChNBX
# UOzpCyyAJkJjbif5FmJvjllwhkFf6AiIDzW8XPAm+V0cllGxtC9vcAPJf0BPtdWx
# q9k8MQDWVdvCTRhoJXTdKjURnjQV7VAdn6jR80nUwxnicqocycFX4k3gZnuR4yIw
# WlZr0Ug6PI3YPMJ1UPV52zdZGjhaG7DIJyh9/odR4hGOfL/ZRLI9fdwRP56dmSb0
# o2brk7P6DbuR19OCncKK6c3Ajbet1We5i33e3+0=
# SIG # End signature block
