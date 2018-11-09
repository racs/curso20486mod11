# uninstall.ps1
param($installPath, $toolsPath, $package, $project)

function Remove-AppSettings() {
	$xml = New-Object xml

	# find the Web.config file
	$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

	# find its path on the file system
	$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

	# load Web.config as XML
	$xml.Load($localPath.Value)

	# remove MvcSiteMapProvider_UseExternalDIContainer
	$ext_di = $xml.SelectSingleNode("configuration/appSettings/add[@key='MvcSiteMapProvider_UseExternalDIContainer']")
	if ($ext_di -ne $null) {
		$ext_di.ParentNode.RemoveChild($ext_di)
	}
	
	# remove MvcSiteMapProvider_ScanAssembliesForSiteMapNodes
	$scan = $xml.SelectSingleNode("configuration/appSettings/add[@key='MvcSiteMapProvider_ScanAssembliesForSiteMapNodes']")
	if ($scan -ne $null) {
		$scan.ParentNode.RemoveChild($scan)
	}
	
	$appSettings = $xml.SelectSingleNode("configuration/appSettings")
	if ($appSettings -ne $null) {
		if (($appSettings.HasChildNodes -eq $false) -and ($appSettings.Attributes.Count -eq 0)) {
			$appSettings.ParentNode.RemoveChild($appSettings)
		}
	}
	
	# save the Web.config file
	$xml.Save($localPath.Value)
}

function Remove-Pages-Namespaces() {
	$xml = New-Object xml

	# find the Web.config file
	$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

	# find its path on the file system
	$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

	# load Web.config as XML
	$xml.Load($localPath.Value)

	# remove MvcSiteMapProvider.Web.Html if it exists
	$html = $xml.SelectSingleNode("configuration/system.web/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html']")
	if ($html -ne $null) {
		$html.ParentNode.RemoveChild($html)
	}
	
	# remove MvcSiteMapProvider.Web.Html.Models if it exists
	$html_models = $xml.SelectSingleNode("configuration/system.web/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html.Models']")
	if ($html_models -ne $null) {
		$html_models.ParentNode.RemoveChild($html_models)
	}
	
	$namespaces = $xml.SelectSingleNode("configuration/system.web/pages/namespaces")
	if ($namespaces -ne $null) {
		if (($namespaces.HasChildNodes -eq $false) -and ($namespaces.Attributes.Count -eq 0)) {
			$namespaces.ParentNode.RemoveChild($namespaces)
		}
	}
	
	$pages = $xml.SelectSingleNode("configuration/system.web/pages")
	if ($pages -ne $null) {
		if (($pages.HasChildNodes -eq $false) -and ($pages.Attributes.Count -eq 0)) {
			$pages.ParentNode.RemoveChild($pages)
		}
	}
	
	$system_web = $xml.SelectSingleNode("configuration/system.web")
	if ($system_web -ne $null) {
		if (($system_web.HasChildNodes -eq $false) -and ($system_web.Attributes.Count -eq 0)) {
			$system_web.ParentNode.RemoveChild($system_web)
		}
	}
	
	# save the Web.config file
	$xml.Save($localPath.Value)
}

function Remove-Razor-Pages-Namespaces() {
	$xml = New-Object xml

	$path = [System.IO.Path]::GetDirectoryName($project.FullName)
	$web_config_file = "$path\Views\Web.config"

	# load Web.config as XML
	$xml.Load($web_config_file)
	
	# remove MvcSiteMapProvider.Web.Html if it exists
	$html = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html']")
	if ($html -ne $null) {
		$html.ParentNode.RemoveChild($html)
	}
	
	# remove MvcSiteMapProvider.Web.Html.Models if it exists
	$html_models = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces/add[@namespace='MvcSiteMapProvider.Web.Html.Models']")
	if ($html_models -ne $null) {
		$html_models.ParentNode.RemoveChild($html_models)
	}
	
	$namespaces = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages/namespaces")
	if ($namespaces -ne $null) {
		if (($namespaces.HasChildNodes -eq $false) -and ($namespaces.Attributes.Count -eq 0)) {
			$namespaces.ParentNode.RemoveChild($namespaces)
		}
	}
	
	$pages = $xml.SelectSingleNode("configuration/system.web.webPages.razor/pages")
	if ($pages -ne $null) {
		if (($pages.HasChildNodes -eq $false) -and ($pages.Attributes.Count -eq 0)) {
			$pages.ParentNode.RemoveChild($pages)
		}
	}

	$system_web_webpages_razor = $xml.SelectSingleNode("configuration/system.web.webPages.razor")
	if ($system_web_webpages_razor -ne $null) {
		if (($system_web_webpages_razor.HasChildNodes -eq $false) -and ($system_web_webpages_razor.Attributes.Count -eq 0)) {
			$system_web_webpages_razor.ParentNode.RemoveChild($system_web_webpages_razor)
		}
	}
	
	# save the Web.config file
	$xml.Save($web_config_file)
}

function Update-SiteMap-Element() {
	$xml = New-Object xml

	# find the Web.config file
	$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

	# find its path on the file system
	$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

	# load Web.config as XML
	$xml.Load($localPath.Value)

	$siteMap = $xml.SelectSingleNode("configuration/system.web/siteMap")
	if ($siteMap -ne $null) {
		if ($xml.SelectSingleNode("configuration/system.web/siteMap[@enabled]") -ne $null) {
			$siteMap.SetAttribute("enabled", "true")
		} else {
			$enabled = $xml.CreateAttribute("enabled")
			$enabled.Value = "true"
			$siteMap.Attributes.Append($enabled)
		}
	}
	
	# save the Web.config file
	$xml.Save($localPath.Value)
}

function Remove-MVC4-Config-Sections() {
	$xml = New-Object xml

	# find the Web.config file
	$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

	# find its path on the file system
	$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

	# load Web.config as XML
	$xml.Load($localPath.Value)
	
	$add = $xml.SelectSingleNode("configuration/system.webServer/modules/add[@name='UrlRoutingModule-4.0']")
	if ($add -ne $null) {
		$add.ParentNode.RemoveChild($add)
	}
	
	$remove = $xml.SelectSingleNode("configuration/system.webServer/modules/remove[@name='UrlRoutingModule-4.0']")
	if ($remove -ne $null) {
		$remove.ParentNode.RemoveChild($remove)
	}
	
	$modules = $xml.SelectSingleNode("configuration/system.webServer/modules")
	if ($modules -ne $null) {
		if (($modules.HasChildNodes -eq $false) -and ($modules.Attributes.Count -eq 0)) {
			$modules.ParentNode.RemoveChild($modules)
		}
	}
	
	$ws = $xml.SelectSingleNode("configuration/system.webServer")
	if ($ws -ne $null) {
		if (($ws.HasChildNodes -eq $false) -and ($ws.Attributes.Count -eq 0)) {
			$ws.ParentNode.RemoveChild($ws)
		}
	}
	
	# save the Web.config file
	$xml.Save($localPath.Value)
}

# If MVC 4 or higher, remove web.config section to fix 404 not found on sitemap.xml (#124)
$mvc_version = $project.Object.References.Find("System.Web.Mvc").Version
Write-Host "MVC Version: $mvc_version"
if ($mvc_version -notmatch '^[123]\.' -or [string]::IsNullOrEmpty($mvc_version))
{
	Write-Host "Removing config sections for MVC >= 4"
	Remove-MVC4-Config-Sections
}

# Undo the changes made to the config file
Remove-AppSettings
Remove-Pages-Namespaces
Remove-Razor-Pages-Namespaces
Update-SiteMap-Element





# SIG # Begin signature block
# MIIdiAYJKoZIhvcNAQcCoIIdeTCCHXUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwHrotWb0SsyyjN7aARirvypK
# z/igghhSMIIEwTCCA6mgAwIBAgITMwAAAMKgCcU3dun2zQAAAAAAwjANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODUx
# WhcNMTgwOTA3MTc1ODUxWjCBsTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpD
# M0IwLTBGNkEtNDExMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJzfPT5gT5YLgF72
# 8Ipv/kMSm0FRtZmMMXMdDBrWM+LOObrNAITBA0w185w4qccTOzXIgsFlOyvvyGfI
# jH+4zLekfpL8U7DuccyDVdS3Lg70hYBCEJll0SwAhfpHR1D4NQaeIRnhnlRuSUwy
# 7LqOxCE6If90dH0+OaVlxiKHw7R5RgeO50m15BHI+6v9US70IZ8JFqRkfLpk52bh
# LNfnossW+CHvAFPVQ0uThMOaoESnJsmban0QaExZvftxreTrz2QQcVw74Y29CYbZ
# RUTIy4zIpuM/i5oBLj9mwf9CogC0rQibwWfEvPyiFuOZ/ncDX5I8KVHa4Y1LoFQq
# YWk/EEkCAwEAAaOCAQkwggEFMB0GA1UdDgQWBBTjHnnY/MhgLBEZmBJtobBujc6d
# rDAfBgNVHSMEGDAWgBQjNPjZUkZwCu1A+3b7syuwwzWzDzBUBgNVHR8ETTBLMEmg
# R6BFhkNodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
# aWNyb3NvZnRUaW1lU3RhbXBQQ0EuY3JsMFgGCCsGAQUFBwEBBEwwSjBIBggrBgEF
# BQcwAoY8aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3Nv
# ZnRUaW1lU3RhbXBQQ0EuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4IBAQAoNFRrsA/+bdu8IJvKoxcry0vIPw0qzrUya7ud9MrJ/pp9EO01
# OFrXqbFfuPW0niqZt7hYrs7bzwSlmbBItCkImv0GCLS/3cf0Vl/c0NxUpn8TUjoo
# +qwnPF3qRGUzcwrI/3Xl9EfoDlc8jWd2f5FqrjeQdmkdOUmtxSnVt1kbW+Fnjlyl
# 1q8aWpkXXgNrBD29iXQV7BklsvtzSVLB32UTZqADm/yzqPC+osWN2eHED2nag1w0
# 51bq++5Pc2mA/UbJeqv+J9VhQwyTGoFdCjE9ygfd7aASPsxiAsRBsNRlylFMjePA
# nFZyI0P0rM+CW09Q641SEKIKbT6T1ww+8ByJMIIGADCCA+igAwIBAgITMwAAAMMO
# m6fYstz3LAAAAAAAwzANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWdu
# aW5nIFBDQSAyMDExMB4XDTE3MDgxMTIwMjAyNFoXDTE4MDgxMTIwMjAyNFowdDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwGA1UEAxMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAu1fXONGxBn9JLalts2Oferq2OiFbtJiujdSkgaDFdcUs74JAKreBU3fzYwEK
# vM43hANAQ1eCS87tH7b9gG3JwpFdBcfcVlkA4QzrV9798biQJ791Svx1snJYtsVI
# mzNiBdGVlKW/OSKtjRJNRmLaMhnOqiJcVkixb0XJZ3ZiXTCIoy8oxR9QKtmG2xoR
# JYHC9PVnLud5HfXiHHX0TszH/Oe/C4BHKf/PzWmxDAtg62fmhBubTf1tRzrH2cFh
# YfKVEqENB65jIdj0mRz/eFWB7qV56CCCXwratVMZVAFXDYeRjcJ88VSGgOFi24Jz
# PiZe8EAS0jnVJgMNhYgxXwoLiwIDAQABo4IBfzCCAXswHwYDVR0lBBgwFgYKKwYB
# BAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKcTXR8hiVXoA+6eFzbq8lSINRmv
# MFEGA1UdEQRKMEikRjBEMQwwCgYDVQQLEwNBT0MxNDAyBgNVBAUTKzIzMDAxMitj
# ODA0YjVlYS00OWI0LTQyMzgtODM2Mi1kODUxZmEyMjU0ZmMwHwYDVR0jBBgwFoAU
# SG5k5VAF04KqFzc3IrVtqMp1ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljQ29kU2lnUENBMjAxMV8yMDEx
# LTA3LTA4LmNybDBhBggrBgEFBQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljQ29kU2lnUENBMjAxMV8y
# MDExLTA3LTA4LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQBN
# l080fvFwk5zj1RpLnBF+aybEpST030TUJLqzagiJmZrLMedwm/8UHbAHOX/kMDsT
# It4OyJVnu25++HyVpJCCN5Omg9NJAsGsrVnvkbenZgAOokwl1NznXQcCyig0ZTs5
# g62VKo7KoOgIOhz+PntASZRNjlQlCuWxxwrucTfGm1429adCRPu8h7ANwDXZJodf
# /2fvKHT3ijAEEYpnzEs1YGoh58ONB4Nem6udcR8pJgkR1PWC09I2Bymu6JJtkH8A
# yahb7tAEZfuhDldTzPKYifOfFZPIBsRjUmECT1dIHPX7dRLKtfn0wmlfu6GdDWmD
# J+uDPh1rMcPuDvHEhEOH7jGcBgAyfLcgirkII+pWsBjUsr0V7DftZNNrFQIjxooz
# hzrRm7bAllksoAFThAFf8nvBerDs1NhS9l91gURZFjgnU7tQ815x3/fXUdwx1Rpj
# NSqXfp9mN1/PVTPvssq8LCOqRB7u+2dItOhCww+KUViiRgJhJloZv1yU6ahAcOdb
# MEx8gNRQZ6Kl7g7rPbXx5Xke4fVYGW+7iW144iBYJf/kSLPmr/GyQAQXRlDUDGyR
# FH3uyuL2Jt4bOwRnUS4PpBf3Qv8/kYkx+Ke8s+U6UtwqM39KZJFl2GURtttqt7Rs
# Uvy/i3EWxCzOc5qg6V0IwUVFpSmG7AExbV50xlYxCzCCBgcwggPvoAMCAQICCmEW
# aDQAAAAAABwwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZ
# MBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTA3MDQwMzEyNTMwOVoXDTIxMDQw
# MzEzMDMwOVowdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEh
# MB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/bSJIqfGsuGeG94uPFmVEjUK3O3RhOJA/u
# 0afRTK10MCAR6wfVVJUVSZQbQpKumFwwJtoAa+h7veyJBw/3DgSY8InMH8szJIed
# 8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J0F6v0LBCBKL5pmyTZ9co3EZTsIbQ5ShG
# Lieshk9VUgzkAyz7apCQMG6H81kwnfp+1pez6CGXfvjSE/MIt1NtUrRFkJ9IAEpH
# ZhEnKWaol+TTBoFKovmEpxFHFAmCn4TtVXj+AZodUAiFABAwRu233iNGu8QtVJ+v
# HnhBMXfMm987g5OhYQK1HQ2x/PebsgHOIktU//kFw8IgCwIDAQABo4IBqzCCAacw
# DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUIzT42VJGcArtQPt2+7MrsMM1sw8w
# CwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMIGYBgNVHSMEgZAwgY2AFA6s
# gmBAVieX5SUT/CrhClOVWeSkoWOkYTBfMRMwEQYKCZImiZPyLGQBGRYDY29tMRkw
# FwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCEHmtFqFKoKWtTHNY9AcTLmUwUAYDVR0f
# BEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEBBEgwRjBEBggr
# BgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNy
# b3NvZnRSb290Q2VydC5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcN
# AQEFBQADggIBABCXisNcA0Q23em0rXfbznlRTQGxLnRxW20ME6vOvnuPuC7UEqKM
# bWK4VwLLTiATUJndekDiV7uvWJoc4R0Bhqy7ePKL0Ow7Ae7ivo8KBciNSOLwUxXd
# T6uS5OeNatWAweaU8gYvhQPpkSokInD79vzkeJkuDfcH4nC8GE6djmsKcpW4oTmc
# Zy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYxPStyC8jqcD3/hQoT38IKYY7w17gX606L
# f8U1K16jv+u8fQtCe9RTciHuMMq7eGVcWwEXChQO0toUmPU8uWZYsy0v5/mFhsxR
# VuidcJRsrDlM1PZ5v6oYemIp76KbKTQGdxpiyT0ebR+C8AvHLLvPQ7Pl+ex9teOk
# qHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7OwTWfIn0L/gHkhgJ4VMGboQhJeGsieIiHQ
# Q+kr6bv0SMws1NgygEwmKkgkX1rqVu+m3pmdyjpvvYEndAYR7nYhv5uCwSdUtrFq
# PYmhdmG0bqETpr+qR/ASb/2KMmyy/t9RyIwjyWa9nR2HEmQCPS2vWY+45CHltbDK
# Y7R4VAXUQS5QrJSwpXirs6CWdRrZkocTdSIvMqgIbqBbjCW/oO+EyiHW6x5PyZru
# SeD3AWVviQt9yGnI5m7qp5fOMSn/DsVbXNhNG6HY+i+ePy5VFmvJE6P9MIIHejCC
# BWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcN
# MjYwNzA4MjEwOTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2
# WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSH
# fpRgJGyvnkmc6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQ
# z7NEt13YxC4Ddato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHml
# SSnnDb6gE3e+lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3o
# iU+EGvKhL1nkkDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6
# nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6ep
# ZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf
# 28AVs70b1FVL5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCn
# q47f7Fufr/zdsGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx
# 7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O
# 9JawvEagbJjS4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0G
# A1UdDgQWBBRIbmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
# gBRyLToCMZBDuRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQy
# MDExXzIwMTFfMDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZC
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQy
# MDExXzIwMTFfMDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCB
# gzA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9k
# b2NzL3ByaW1hcnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABf
# AHAAbwBsAGkAYwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEB
# CwUAA4ICAQBn8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LR
# bYP+vj/oCso7v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r
# 4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb
# 7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6v
# mSiXmE0OPQvyCInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/
# sfQn+N4sOiBpmLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad2
# 5UAqZaPDXVJihsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUf
# FL5hYbXw3MYbBL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWx
# m6U/RXceNcbSoqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMj
# aHXmr/r8i+sLgOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7
# qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCBKAwggSc
# AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAm
# BgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAADDDpun
# 2LLc9ywAAAAAAMMwCQYFKw4DAhoFAKCBtDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQUSTVx8Od2hRc3DI1HUbHw2ABtf2UwVAYKKwYBBAGCNwIBDDFGMESgJoAkAE0A
# aQBjAHIAbwBzAG8AZgB0ACAATABlAGEAcgBuAGkAbgBnoRqAGGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQApiZZ/kj15VboNuZUwcK9K
# r8X0gijlTCzYteq436Itkeyqf3hciuUztzUJ9Ll3k0t1od7a7mCH3cZCb0yGAw53
# bfIhG5lNaDg3zjqduiJ0Awc3F5PSpw6RrueJbaxMupWR0bO4HfVTOj8LnAzlfC+D
# ilr+XimavBCR8l1/mFdmv8SdgmHaSOoLr06xy3+UOtm9ovpuU2ayq2yC3MrZF5kV
# NkkyxKzcKT1xqQPRoAd76K+MDm7VtT41b2edNIq+qV7I4eluhwNwO2DAzOwY/WTo
# tjoZel5w6Ipo5tTte+61FaPGMZAstdb8NbLHy94inJ5AxgWRVeqGThvRDWzUMORw
# oYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQQITMwAAAMKgCcU3dun2zQAAAAAAwjAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTcxMjIwMDkz
# NDM5WjAjBgkqhkiG9w0BCQQxFgQUnnx8gcCePXTg2gokVyNxb5rmd9MwDQYJKoZI
# hvcNAQEFBQAEggEAFUP2XeaossBuLDATfhzMJexQe9J/FX9UBtsCiZYV2BriiJ5x
# dfKYqq1snaVACqc/ie5t3n52vXYxR/bFXjDqTU1XssuLCchsklGit7kjqxVxYryU
# LORQOxWUl4KJxiSK4WHsPMArFBL6gIohtFHOoUJ5RDc31sSfZn1STswpspHtrW65
# 7hZI2+ndOqKqllWAOwbE4KCwdg5oUHaz6uCWEGeeF3oUogp3wWofmPkKpJaAf9ss
# mWFtHNsxO3vrUFhVFqMiNCqURmJoI7kDmzZGzre71BB2/GaeEpjr4Nzge5DI4Ir9
# kO305Y/S0+rmAEqJ1WaEnzq/kIjNIfOwpuxK4w==
# SIG # End signature block
