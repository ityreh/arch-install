#!/usr/bin/env bash
# tests/run-pod.sh — create (or recreate) the arch-install test pod.
#
#   bash tests/run-pod.sh            # build + create pod (idempotent)
#   podman exec -it arch-install-test /bin/bash        # manual exploration
#   podman exec -it arch-install-test bash /opt/arch-install/tests/manual-test.sh --full

set -euo pipefail

POD_NAME=arch-install-test
IMAGE=arch-install-test:latest
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MOUNT_DIR=/opt/arch-install

command -v podman >/dev/null || die "podman is required"

if podman pod exists "$POD_NAME"; then
    podman pod rm -f "$POD_NAME" >/dev/null
fi

echo "Building image $IMAGE"
podman build -t "$IMAGE" -f "$REPO_DIR/tests/Containerfile" "$REPO_DIR"

echo "Creating pod $POD_NAME"
podman pod create --name "$POD_NAME" >/dev/null

podman run -d \
    --name "${POD_NAME}-target" \
    --pod "$POD_NAME" \
    -v "$REPO_DIR:$MOUNT_DIR:ro" \
    --workdir "$MOUNT_DIR" \
    "$IMAGE" \
    sleep infinity >/dev/null

echo "Pod ready:"
echo "  container  : ${POD_NAME}-target"
echo "  repo mount : $REPO_DIR  ->  $MOUNT_DIR (read-only)"
echo "  attach     : podman exec -it ${POD_NAME}-target /bin/bash"
echo "  smoke test : podman exec -it ${POD_NAME}-target bash $MOUNT_DIR/tests/manual-test.sh --full"