# Created by Daniel Jean Schmidt

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Script = Invoke-RestMethod https://api.github.com/repos/Xayze0/Revive-ToolBox/contents/Revive-ToolBox.ps1?access_token=a963ad6608bffd41b5cbc860e11ac7a6f72ed7cd -Headers @{"Accept"= "application/vnd.github.v3.raw"}

Invoke-Expression $Script