# Application Deployment

This is to document how we deploy client and server to staging and production using GitHub Actions
We currently have client and server at

https://github.com/pangeachat/client-v0

https://github.com/pangeachat/server

**Client and server use the same deploy workflow to staging and production**

## Deploy Staging

Deploy staging workflow is triggered automatically on *pushs* to *main* branch. 

Once the workflow trigger, you can check the status or progress of deploy jobs in GitHub Actions

https://github.com/pangeachat/client-v0/actions/workflows/web-deploy-staging.yml

https://github.com/pangeachat/server/actions/workflows/deploy-staging.yml

## Deploy Prod

Deploy prod workflow is triggered automatically on *releases*.

Here is how to create a release: https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository

Once the workflow trigger, you can check the status or progress of deploy jobs in GitHub Actions

https://github.com/pangeachat/client-v0/actions/workflows/web-deploy-prod.yml

https://github.com/pangeachat/server/actions/workflows/deploy-prod.yml

## Verify

Staging client: https://app.staging.pangea.chat/

Staging server: https://api.staging.pangea.chat/

Prod client: https://app.pangea.chat/

Prod server: [https://api.pangea.chat/](https://api.pangea.chat/api/v1/language/list)
