# yampl-temp-deploy-action

This repository houses an action and several reusable workflows for creating, updating, and destroying temporary environments.

## Create Action
### Action Inputs

| Input        | Required?  | Details                     | Example                                   |
|-----------------|-----|------------------------------------|-------------------------------------------|
| dest-path       | Yes | Path where templated files should get copied | app/myapp                 |    
| repository      | Yes | Infrastructure-as-code repo where templating should take place | clevyr/myapp-deployment|
| repo-token      | yes | GitHub token for the `repository` | `${{ secret.repo-token}}` |
| template-path   | Yes | Path where templated files should get copied  | templates/myapp |
| yaml_values     | Yes | Image tag, typically a full or partial git SHA  | See example workflow |
| branch          | No  | Branch the commit step will operate on, recommended  when calling from a PR |  |
| commit_message  | No  | Commit message for the commit step  | |

### Action Example

Here is an example that will call this action.
```yaml
name: Temp Environment Create
on:
  pull_request:
    types: labeled

env:
  nsprefix: app
  repository: "clevyr/myapp-deployment"
  url_suffix: myapp.com 

jobs:
  create-temp:
    name: Create Temp Enviornment
    runs-on: ubuntu-latest
    if: github.event.label.name == 'deploytemp'
    environment: 
      name: "temp${{ github.event.pull_request.number }}"
      url: "https://${{ steps.color-animal.outputs.result }}.${{ env.url_suffix }}"
    steps:
      - name: Generate Values
        id: color-animal
        uses: clevyr/color-animal-action@v1
      - name: Create Temp Environment
        uses: clevyr/yampl-temp-deploy-action/@v1
        with: 
          repository: ${{ env.repository }}
          repo-token: ${{ secrets.repo-token }}
          dest-path: "apps/myapp"
          template-path: "templates/myapp"
          yampl_values: |
            url=${{ steps.color-animal.outputs.result }}.${{ env.url_suffix }}
            namespace=${{ env.nsprefix }}-temp${{ github.event.pull_request.number }}
            tag=${{ github.sha }}
```

## Get-PR Workflow
This workflow retreives the PR for a current commit. 
It has no inputs, and simply outputs the PR number if it exists.

## Update Workflow
The update workflow updates a temp environment. 

### Inputs

| Input        | Required?  | Details                     | Example                                   |
|--------------|-----|------------------------------------|-------------------------------------------| 
| file-path    | Yes | Path to file where the tag will be updated | `"apps/myapp/temp${{needs.get-pr.outputs.pr}}/app/helmrelease.yaml"`
| pr           | Yes | PR number                           | `${{needs.get-pr.outputs.pr}}` |
| repository   | Yes | Infrastructure-as-code repo to update | `clevyr/myapp-deployment` |
| repo-token (secret)  | Yes | Secret reference for the repository token |  `${{ secrets.repo-token }}` |
| tag          | Yes  | Image tag to bump to       |   `${{ github.sha }}`
| commit_message  | No  | Commit message for the commit step  | |

### Update Workflow Example
Here is an example of a job that calls this workflow:
```yaml
name: Temp Environment Update
on: push

jobs:
  get-pr:
    name: Get PR
    uses: clevyr/yampl-temp-deploy-action/.github/workflows/get-pr.yaml@v1
  update:
    name: Update Temp
    needs: get-pr
    if: needs.get-pr.outputs.pr
    uses: clevyr/yampl-temp-deploy-action/.github/workflows/update.yaml@v1
    secrets:
      repo-token: ${{ secrets.repo-token }}
    with: 
      repository: "clevyr/myapp-deployment"
      file-path: "apps/myapp/temp${{ needs.get-pr.outputs.pr }}/app/helmrelease.yaml"
      pr: "${{ needs.get-pr.outputs.pr }}"
      tag: "${{ github.sha }}
```

## Destroy Workflow
The destroy workflow destroys a temp environment 

### Inputs
| Input        | Required?  | Details                     | Example                                   |
|--------------|-----|------------------------------------|-------------------------------------------|
| pr           | Yes | PR number                           | `${{needs.get-pr.outputs.pr}}` |
| repository   | Yes | Infrastructure-as-code repo to update | `clevyr/myapp-deployment` |
| repo-token (secret)  | Yes | Secret reference for the repository token |  `${{ secrets.repo-token }}` |
| temp-path    | Yes | Path to temp environment directory | See example job
| commit_message  | No  | Commit message for the commit step  | |

### Destroy Workflow Example 
```yaml
name: Temp Environment Destroy
on:
  pull_request:
    types: [closed, unlabeled]

jobs:
  get-pr:
    name: Get PR
    if: github.event.label.name == 'deploytemp'
    uses: clevyr/yampl-temp-deploy-action/.github/workflows/get-pr.yaml@v1
  destroy:
    name: Destroy
    needs: get-pr
    if: needs.get-pr.outputs.pr
    uses: clevyr/yampl-temp-deploy-action/.github/workflows/destroy.yaml@v1
    secrets:
      repo-token: ${{ secrets.PAT }}
    with: 
      repository: "clevyr/myapp-deployment"
      temp-path: "apps/myapp/temp${{needs.get-pr.outputs.pr}}"
      pr: "${{needs.get-pr.outputs.pr}}"
  remove-github-deployment:
    name: Remove GitHub Environment
    needs: destroy
    runs-on: ubuntu-latest
    steps:
      - uses: strumwolf/delete-deployment-environment@v2
        with:
          token: ${{ secrets.repo-token }}
          environment: "temp${{ github.event.pull_request.number }}"
```