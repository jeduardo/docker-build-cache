# Docker Build cache

This repository has a small golang application that is built into a container,
which is then reused in different stages.

## Experiment 1 - gha Docker Backend and make commands

Using the make commands did not work to store anything into the cache, no matter
which invocation or configuration used.

## Experiment 2 - gha Docker Backend and official actions

Using the actions and adding scopes worked to some extent, with layers added to
the GHA cache. However, the restored cache across workflow steps was not enough
to prevent a re-download and re-compilation of transient golang dependencies.

## Experiment 3 - Export an image as artifact and reload it

This is the one that worked best: building the image in the first step, exporting it, and then reloading into the runner before running the test is what
allowed reusing the image across steps without needing to use any cache in an
actual registry. Setting the retention time for the artifact to one day allow for quick expiration of these temporary artifacts.