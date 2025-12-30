# Docker Build cache

This repository has a small golang application that is built into a container,
which is then reused in different stages.

It uses buildkit to build the images with the gha backend to cache the go
build stages.
