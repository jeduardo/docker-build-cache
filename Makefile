IMAGE_NAME := reverse-cow
DOCKER     := docker
PLATFORM   ?= linux/amd64
BUILDX_BUILDER_ID ?=

# Selecting the build command depending on whether it's on CI or not
ifeq ($(GITHUB_ACTIONS),true)
  ifeq ($(ENABLE_GHA_BACKEND),true)
    BUILD_CMD = $(DOCKER) buildx build --load \
      --progress=plain \
      --builder "$(BUILDX_BUILDER_ID)" \
      --platform $(PLATFORM) \
      --cache-from type=gha \
      --cache-to type=gha,mode=max \
      -t $(IMAGE_NAME) .
  else
    BUILD_CMD = $(DOCKER) buildx build --load \
      --progress=plain \
      --builder "$(BUILDX_BUILDER_ID)" \
      --platform $(PLATFORM) \
      -t $(IMAGE_NAME) .
  endif
else
  BUILD_CMD = DOCKER_BUILDKIT=1 $(DOCKER) build -t $(IMAGE_NAME) .
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
