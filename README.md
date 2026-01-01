# Docker Build cache

This repository has a small golang application that is built into a container,
which is then reused in different stages.

## Experiment 1 - gha Docker Backend and make commands

Using the make commands did not work to store anything into the cache, no matter
which invocation or configuration used.

This is because the GHA backend [makes use of some environment variables](https://docs.docker.com/build/cache/backends/gha/) for authentication, but these [are not exposed](https://github.com/actions/runner/issues/3046) to actions other than `nodejs` and `docker`. It is possible to work around this by using [this action](https://github.com/crazy-max/ghaction-github-runtime) to expose these variables to the build. After this is done, the gha backend works as expected.

## Experiment 2 - gha Docker Backend and official actions

Using the actions and adding scopes worked to some extent, with layers added to
the GHA cache. However, the restored cache across workflow steps was not enough
to prevent a re-download and re-compilation of transient golang dependencies.

## Experiment 3 - Export an image as artifact and reload it

This is the one that worked best: building the image in the first step, exporting it, and then reloading into the runner before running the test is what
allowed reusing the image across steps without needing to use any cache in an
actual registry. Setting the retention time for the artifact to one day allow for quick expiration of these temporary artifacts.

## Docker cache optimisation for golang

The intention is that the GHA caches are used across the same workflow in the same branch, but not shared by different branches or different workflows. For this reason, an action is used to compute an individual docker cache scope that is reused across each workflow, where needed.

Caches were not being properly reused while the local directory was mounted inside the container, so the build is split in a step that downloads the dependencies, and another step that compiles the binary.

Both these changes resulted in reuse of cache layers across different workflow steps.
