set shell := ["bash", "-euo", "pipefail", "-c"]

image_name := "mbp14-3-bluefin"
default_tag := "local"
base_image := "ghcr.io/ublue-os/bluefin-dx:latest"

build target_image=image_name tag=default_tag:
    sudo podman build \
      --build-arg BASE_IMAGE={{base_image}} \
      --tag localhost/{{target_image}}:{{tag}} \
      .

list-images:
    sudo podman images | grep "mbp14-3-bluefin\|REPOSITORY"

rebase-local target_image=image_name tag=default_tag:
    sudo rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/{{target_image}}:{{tag}}

rollback:
    sudo rpm-ostree rollback

status:
    rpm-ostree status
