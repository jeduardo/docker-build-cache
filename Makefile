IMAGE_NAME := reverse-cow
DOCKER     := docker
PLATFORM   ?= linux/amd64
CACHE_SCOPE ?= local
CACHE_DIR ?= .buildx-cache
ENABLE_LOCAL_CACHE ?= false
ENABLE_GHA_CACHE_SAVE ?= false

# Selecting the build command depending on whether it's on CI or not
ifeq ($(GITHUB_ACTIONS),true)
  LOCAL_CACHE_FROM :=
  LOCAL_CACHE_TO :=
  ifeq ($(ENABLE_LOCAL_CACHE),true)
    ifneq ($(wildcard $(CACHE_DIR)/index.json),)
      LOCAL_CACHE_FROM = --cache-from type=local,src=$(CACHE_DIR)
    endif
    LOCAL_CACHE_TO = --cache-to type=local,dest=$(CACHE_DIR),mode=max
  endif
  ifeq ($(ENABLE_GHA_BACKEND),true)
    BUILD_CMD = $(DOCKER) buildx build --load \
      --platform $(PLATFORM) \
      --build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
      --cache-from type=gha
    ifeq ($(ENABLE_GHA_CACHE_SAVE),true)
      BUILD_CMD += --cache-to type=gha,mode=max
    endif
    BUILD_CMD += $(LOCAL_CACHE_FROM)
    BUILD_CMD += $(LOCAL_CACHE_TO)
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
			$(LOCAL_CACHE_FROM) \
			$(LOCAL_CACHE_TO) \
			--target test \
			.; \
	else \
		$(DOCKER) buildx build \
			--platform $(PLATFORM) \
			--build-arg CACHE_SCOPE=$(CACHE_SCOPE) \
			--target test \
			.; \
	fi
