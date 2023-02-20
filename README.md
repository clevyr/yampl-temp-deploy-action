# yampl-temp-deploy-action

## Special Values
There are a couple special values this action supports.

| Value   | Function
|---------|-----------
| COLORANIMAL | Replaced with a random color + random animal, like "red-shrimp"
| RAND32      | Replaced with a random alphanumeric value of the specified length, in this case, 32. 



## Environment Variables

| Variable            | Details                                                                                 | Example                                       |
|---------------------|-----------------------------------------------------------------------------------------|-----------------------------------------------|
| YAMPL_hostname | Hostname for the deployment. | "COLORANIMAL"
| YAMPL_namespace   | Kubernetes namespace    | `mynamespace-temp{{github.event.pull_request.number}}`
| YAMPL_tag | Image tag, typically a full or partial git SHA | `${{ github.event.pull_request.head.sha \|\| github.sha }}`
| YAMPL_*   | Any additional values that need to get passed into YAMPL. | `YAMPL_smtphost=smtp.example.com`