IMAGE_NAME := reverse-cow
DOCKER     := docker
PLATFORM   ?= linux/amd64
CACHE_SCOPE ?= local
CACHE_DIR ?= .buildx-cache
ENABLE_LOCAL_CACHE ?= false
ENABLE_GHA_CACHE_SAVE ?= false

# Selecting the build command depending on whether it's on CI or not
ifeq ($(GITHUB_ACTIONS),true)
  ifeq ($(ENABLE_GHA_BACKEND),true)
    BUILD_CMD = $(DOCKER) buildx build --load \
      --platform $(PLATFORM) \
      --build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
      --cache-from type=gha
    ifeq ($(ENABLE_GHA_CACHE_SAVE),true)
      BUILD_CMD += --cache-to type=gha,mode=max
    endif
    ifeq ($(ENABLE_LOCAL_CACHE),true)
      BUILD_CMD += --cache-from type=local,src=$(CACHE_DIR)
      BUILD_CMD += --cache-to type=local,dest=$(CACHE_DIR),mode=max
    endif
    BUILD_CMD += -t $(IMAGE_NAME) .
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

.PHONY: build run test test-docker

build:
	@if [ "$(ENABLE_LOCAL_CACHE)" = "true" ]; then mkdir -p $(CACHE_DIR); fi
	$(BUILD_CMD)

run:
	$(DOCKER) run --rm \
		-v "$(PWD):/work" \
		-w /work \
		$(IMAGE_NAME) \
		$(ARGS)

test:
	go run github.com/onsi/ginkgo/v2/ginkgo run ./...

test-docker:
	@if [ "$(GITHUB_ACTIONS)" = "true" ]; then \
		mkdir -p $(CACHE_DIR); \
		$(DOCKER) buildx build \
			--platform $(PLATFORM) \
			--build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
			--cache-from type=local,src=$(CACHE_DIR) \
			--cache-to type=local,dest=$(CACHE_DIR),mode=max \
			--target test \
			.; \
	else \
		$(DOCKER) buildx build \
			--platform $(PLATFORM) \
			--build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
			--target test \
			.; \
	fi
