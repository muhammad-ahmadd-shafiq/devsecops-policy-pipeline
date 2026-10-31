
package main

# TEST 1: A container without non-root configuration
# must be rejected.


test_container_must_run_as_non_root if {
    count(deny) == 1 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27",
                        "resources": {
                            "requests": {
                                "cpu": "100m",
                                "memory": "64Mi"
                            },
                            "limits": {
                                "cpu": "500m",
                                "memory": "256Mi"
                            }
                        }
                    }]
                }
            }
        }
    }
}

# TEST 2: A privileged container must be rejected.

test_privileged_container_must_be_rejected if {
    count(deny) == 1 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27",
                        "securityContext": {
                            "privileged": true
                        },
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }]
                }
            }
        }
    }
}

# TEST 3: Missing CPU and memory resources must be rejected.

test_resource_requirements_must_be_enforced if {
    count(deny) == 4 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27"
                    }]
                }
            }
        }
    }
}

# TEST 4: latest image tags must be rejected.

test_latest_image_tag_must_be_rejected if {
    count(deny) == 1 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:latest",
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }]
                }
            }
        }
    }
}

# TEST 5: ServiceAccount token automounting must be disabled.

test_service_account_token_automount_must_be_disabled if {
    count(deny) == 1 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": true,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27",
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }]
                }
            }
        }
    }
}

# TEST 6: A fully secure Deployment must be allowed.

test_secure_deployment_must_pass if {
    count(deny) == 0 with input as {
        "kind": "Deployment",
        "metadata": {"name": "secure-test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27",
                        "securityContext": {
                            "privileged": false
                        },
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }]
                }
            }
        }
    }
}

# TEST 7: Init containers must also be checked.

test_insecure_init_container_must_be_rejected if {
    count(deny) == 1 with input as {
        "kind": "Deployment",
        "metadata": {"name": "test"},
        "spec": {
            "template": {
                "spec": {
                    "automountServiceAccountToken": false,
                    "securityContext": {
                        "runAsNonRoot": true,
                        "runAsUser": 10001
                    },
                    "containers": [{
                        "name": "app",
                        "image": "nginx:1.27",
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }],
                    "initContainers": [{
                        "name": "setup",
                        "image": "busybox:1.36",
                        "securityContext": {
                            "privileged": true
                        },
                        "resources": {
                            "requests": {"cpu": "100m", "memory": "64Mi"},
                            "limits": {"cpu": "500m", "memory": "256Mi"}
                        }
                    }]
                }
            }
        }
    }
}
