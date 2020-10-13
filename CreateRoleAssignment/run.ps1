using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$principalId = $Request.Query.principalId
$role = $Request.Query.role
$scope = $Request.Query.scope

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($principalId -And $role -And $scope) {
    
    Connect-AzAccount -Identity

    $spId = (Get-AzKeyVaultSecret -VaultName 'kv-sharedservices-d-we1' -Name 'SP-PCS-PrivilegedRolesAss-Id').SecretValueText
    $spSecret = (Get-AzKeyVaultSecret -VaultName 'kv-sharedservices-d-we1' -Name 'SP-PCS-PrivilegedRolesAss-Secret').SecretValueText
    $tenantId = (Get-AzKeyVaultSecret -VaultName 'kv-sharedservices-d-we1' -Name 'tenant-sharedservices-we1-d-id').SecretValueText

    $spSecret = ConvertTo-SecureString $spSecret -AsPlainText -Force
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential($spId, $spSecret);
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

    New-AzRoleAssignment -ApplicationId $principalId -Scope $scope -RoleDefinitionName $role
    $body = "Role Assignment was completed successfully:"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
