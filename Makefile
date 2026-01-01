IMAGE_NAME := reverse-cow
DOCKER     := docker
PLATFORM   ?= linux/amd64
CACHE_SCOPE ?= local

# Selecting the build command depending on whether it's on CI or not
ifeq ($(GITHUB_ACTIONS),true)
  ifeq ($(ENABLE_GHA_BACKEND),true)
    BUILD_CMD = $(DOCKER) buildx build --load \
      --platform $(PLATFORM) \
      --build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
      --cache-from type=gha \
      --cache-to type=gha,mode=max \
      -t $(IMAGE_NAME) .
  else
    BUILD_CMD = $(DOCKER) buildx build --load \
      --platform $(PLATFORM) \
      --build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
      -t $(IMAGE_NAME) .
  endif
else
  BUILD_CMD = DOCKER_BUILDKIT=1 $(DOCKER) build \
    --build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
    -t $(IMAGE_NAME) .
endif

.PHONY: build run

build:
	$(BUILD_CMD)

run:
	$(DOCKER) run --rm \
		-v "$(PWD):/work" \
		-w /work \
		$(IMAGE_NAME) \
		$(ARGS)
