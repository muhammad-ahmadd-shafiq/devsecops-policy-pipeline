
package main

# Only evaluate Kubernetes Deployments.
# Other resource types, such as Services, are ignored by these policies.

pod_spec := input.spec.template.spec if {
    input.kind == "Deployment"
}

# Collect normal containers and init containers.
# All container-level policies will evaluate both.

all_containers contains container if {
    some container in object.get(pod_spec, "containers", [])
}

all_containers contains container if {
    some container in object.get(pod_spec, "initContainers", [])
}

# --------------------------------------------------
# POLICY 1: Containers must run as non-root.
# --------------------------------------------------

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    pod_security := object.get(pod_spec, "securityContext", {})
    container_security := object.get(container, "securityContext", {})

    pod_non_root := object.get(pod_security, "runAsNonRoot", false)
    container_non_root := object.get(container_security, "runAsNonRoot", false)

    not pod_non_root
    not container_non_root

    msg := sprintf(
        "Container '%s' must explicitly run as non-root.",
        [container.name],
    )
}

# Explicit container-level false overrides pod-level true.

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    container_security := object.get(container, "securityContext", {})

    object.get(container_security, "runAsNonRoot", true) == false

    msg := sprintf(
        "Container '%s' must not override non-root execution with false.",
        [container.name],
    )
}

# An effective user ID of zero is prohibited.

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    pod_security := object.get(pod_spec, "securityContext", {})
    container_security := object.get(container, "securityContext", {})

    effective_user := object.get(
        container_security,
        "runAsUser",
        object.get(pod_security, "runAsUser", -1),
    )

    effective_user == 0

    msg := sprintf(
        "Container '%s' must not run with user ID 0.",
        [container.name],
    )
}

# --------------------------------------------------
# POLICY 2: Privileged containers are prohibited.
# --------------------------------------------------

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    container_security := object.get(container, "securityContext", {})

    object.get(container_security, "privileged", false) == true

    msg := sprintf(
        "Container '%s' must not run as privileged.",
        [container.name],
    )
}

# --------------------------------------------------
# POLICY 3: CPU and memory requests and limits
# are mandatory for every container.
# --------------------------------------------------

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    limits := object.get(resources, "limits", {})

    missing_resources := [
        resource |
        resource := "CPU requests"
        object.get(requests, "cpu", null) == null
    ]

    count(missing_resources) > 0

    msg := sprintf(
        "Container '%s' must define CPU requests.",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    limits := object.get(resources, "limits", {})

    object.get(requests, "memory", null) == null

    msg := sprintf(
        "Container '%s' must define memory requests.",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    limits := object.get(resources, "limits", {})

    object.get(limits, "cpu", null) == null

    msg := sprintf(
        "Container '%s' must define CPU limits.",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    limits := object.get(resources, "limits", {})

    object.get(limits, "memory", null) == null

    msg := sprintf(
        "Container '%s' must define memory limits.",
        [container.name],
    )
}

# --------------------------------------------------
# POLICY 4: Image tags must be explicit and cannot
# be latest.
# --------------------------------------------------

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    image := object.get(container, "image", "")

    image_parts := split(image, "@")
    image_name := image_parts[0]

    path_parts := split(image_name, "/")
    image_last_part := path_parts[count(path_parts) - 1]

    tag_parts := split(image_last_part, ":")

    count(tag_parts) == 2
    tag_parts[1] == "latest"

    msg := sprintf(
        "Container '%s' must not use the latest image tag.",
        [container.name],
    )
}

# An untagged image without a digest can implicitly use latest.

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    image := object.get(container, "image", "")

    image_parts := split(image, "@")
    image_name := image_parts[0]

    path_parts := split(image_name, "/")
    image_last_part := path_parts[count(path_parts) - 1]

    tag_parts := split(image_last_part, ":")

    count(tag_parts) == 1
    count(image_parts) == 1

    msg := sprintf(
        "Container '%s' must use an explicit image tag or digest.",
        [container.name],
    )
}

# --------------------------------------------------
# POLICY 5: ServiceAccount token automounting
# must be explicitly disabled.
# --------------------------------------------------

deny contains msg if {
    input.kind == "Deployment"

    object.get(pod_spec, "automountServiceAccountToken", true) != false

    msg := sprintf(
        "Deployment '%s' must disable automatic ServiceAccount token mounting.",
        [input.metadata.name],
    )
}
# Containers must specify an image.

deny contains msg if {
    input.kind == "Deployment"

    some container in all_containers

    object.get(container, "image", "") == ""

    msg := sprintf(
        "Container '%s' must specify a container image.",
        [container.name],
    )
}