export image_name := env("IMAGE_NAME", "serenno")
export default_tag := env("DEFAULT_TAG", "latest")
export image_tag := env("BUILD_IMAGE_TAG", default_tag)
export base_dir := env("BUILD_BASE_DIR", ".")
export filesystem := env("BUILD_FILESYSTEM", "ext4")

container_runtime := env("CONTAINER_RUNTIME", `command -v podman >/dev/null 2>&1 && echo podman || echo docker`)

build-containerfile $image_name=image_name:
    sudo {{container_runtime}} build -f Containerfile -t "${image_name}:${default_tag}" .

bootc *ARGS:
    sudo {{container_runtime}} run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -e RUST_LOG=debug \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bootc {{ARGS}}

generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    sudo {{container_runtime}} run \
        --privileged \
        --rm \
        -it \
        -v ./output:/output \
        ghcr.io/osbuild/image-builder-cli:latest \
        build bootc-installer --bootc-ref ghcr.io/thiagojedi/{{image_name}}:{{default_tag}}

# Runs shfmt on all Bash scripts
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    # Check if shfmt is installed
    if ! command -v shfmt &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    # Run shfmt on all Bash scripts
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'
