set shell := ["bash", "-euo", "pipefail", "-c"]

image_name := "mbp14-3-bluefin"
default_tag := "local"
build_tag_file := ".just-build-tag"
base_image := "ghcr.io/ublue-os/bluefin-dx:latest"

build target_image=image_name:
    build_tag="$(date +%Y%m%d%H%M%S%N)"; sudo podman build \
      --build-arg BASE_IMAGE={{base_image}} \
      --build-arg VERSION="$(date +%Y%m%d)" \
      --build-arg ENABLE_MBP_TOUCHBAR_DKMS_LAYER="${ENABLE_MBP_TOUCHBAR_DKMS_LAYER:-1}" \
      --build-arg MBP_TOUCHBAR_DKMS_REPO="${MBP_TOUCHBAR_DKMS_REPO:-https://github.com/nanachi2002/macbook12-spi-driver.git}" \
      --build-arg MBP_TOUCHBAR_DKMS_BRANCH="${MBP_TOUCHBAR_DKMS_BRANCH:-fix/kernel-6.17-compat}" \
      --tag localhost/{{target_image}}:${build_tag} \
      --tag localhost/{{target_image}}:{{default_tag}} .; \
    printf '%s\n' "${build_tag}" > "{{build_tag_file}}"

rebase-remote:
    sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/elephantum/ublue-t1:latest

list-images:
    sudo podman images | grep "mbp14-3-bluefin\|REPOSITORY"

rebase-local target_image=image_name:
    if [[ ! -f "{{build_tag_file}}" ]]; then echo "No recorded build tag found. Run 'just build' first."; exit 1; fi; sudo rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/{{target_image}}:$(<"{{build_tag_file}}")

rollback:
    sudo rpm-ostree rollback

status:
    rpm-ostree status
