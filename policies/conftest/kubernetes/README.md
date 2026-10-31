# Kubernetes Policy-as-Code

## Overview

This directory contains custom Open Policy Agent Rego policies used by Conftest to validate Kubernetes Deployment manifests.

The policies enforce workload security requirements before deployment.

## Security Controls

1. Require non-root container execution.
2. Prohibit privileged containers.
3. Require CPU and memory requests and limits.
4. Reject mutable latest image tags and untagged images.
5. Disable automatic ServiceAccount token mounting.
6. Validate regular containers and init containers.
7. Require container images to be specified.

## Policy Files

- `main.rego`: Kubernetes security policies.
- `main_test.rego`: Automated Rego unit tests.

## Local Validation

Run the policy unit tests:

```bash
conftest verify --policy policies/conftest/kubernetes
```

Validate the secure Deployment:

```bash
conftest test --policy policies/conftest/kubernetes k8s/deployment.yaml
```

Validate deliberately insecure examples:

```bash
conftest test --policy policies/conftest/kubernetes k8s/bad-deployments
```

The insecure examples are negative test fixtures. They are expected to produce policy violations and must never be deployed.

## Enforcement Model

Conftest evaluates Kubernetes manifests during CI/CD.

A successful security gate demonstrates that the tested manifests satisfy the defined policies.

These checks are pre-deployment controls. Runtime admission enforcement will be implemented separately using Kyverno.
