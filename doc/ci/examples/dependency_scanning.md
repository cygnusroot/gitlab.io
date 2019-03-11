# Dependency Scanning with GitLab CI/CD **[ULTIMATE]**

## Job definition template

CAUTION: **Caution:**
The CI/CD template for job definition is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual job definition).

This example shows how to run Dependency Scanning on your
project's dependencies by using GitLab CI/CD.

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` using [the CI/CD template](https://docs.gitlab.com/ee/ci/yaml/#includetemplate) for Dependency Scanning:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml
```

The above example will create a `dependency_scanning` job in your CI/CD pipeline
and scan your dependencies for possible vulnerabilities. The report will be saved as a
[Dependency Scanning report artifact](../../ci/yaml/README.md#artifactsreportsdependency_scanning-ultimate)
that you can later download and analyze.
Due to implementation limitations we always take the latest Dependency Scanning artifact available.

The results are sorted by the priority of the vulnerability:

1. High
1. Medium
1. Low
1. Unknown
1. Everything else

Behind the scenes, the [GitLab Dependency Scanning Docker image](https://gitlab.com/gitlab-org/security-products/dependency-scanning)
is used to detect the languages/package managers and in turn runs the matching scan tools.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the [GitLab Dependency Scanning documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on Dependency Scanning in merge requests](../../user/project/merge_requests/dependency_scanning.md).

## Job execution customization

You can customize dependency scanning job execution in various ways of different granularity.

### Scanning tool settings

Dependency scanning tool settings can be changed through environment variables. These variables are documented in the:                                                                             
- Job definition [template](#job-definition-template).
- Dependency Scanning [README](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings).

The customization itself is performed by using the [`variables`](https://docs.gitlab.com/ee/ci/yaml/#variables)
parameter in the project's pipeline configuration file (`.gitlab-ci.yml`):

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DEP_SCAN_DISABLE_REMOTE_CHECKS: true
```

Because template is evaluated [before](https://docs.gitlab.com/ee/ci/yaml/#include) the CI config,
the last mention of the variable will take precedence.

### Overriding job definition

If you want to override the job definition (change its properties like `variables` or `dependencies`), you need to open
its definition after the template inclusion and specify any additional keys under it: 

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

dependency_scanning:
  variables:
    CI_DEBUG_TRACE: "true"
``` 

## Supported languages and package managers

See [the full list of supported languages and package managers](../../user/project/merge_requests/dependency_scanning.md#supported-languages-and-dependency-managers).

## Manual job definition

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions _(although it's preferred to use 
[the job definition template](#job-definition-template) since 11.9)_.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

If you are on GitLab prior to 11.9, you can define it manually using the following snippet:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$SP_VERSION" /code
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

You can supply many other [settings variables](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings)
via `docker run --env` to customize your job execution.

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Dependency Scanning job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$SP_VERSION" /code
  artifacts:
    paths: [gl-dependency-scanning-report.json]
```

[ee]: https://about.gitlab.com/pricing/
