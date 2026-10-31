# Phase 3: Kubernetes Policy-as-Code Enforcement

## Overview

This phase extends the DevSecOps Policy Pipeline with custom Kubernetes security policies.

The objective is to detect insecure workload configurations before they reach a Kubernetes cluster.

## Technologies

- Open Policy Agent (OPA)
- Rego
- Conftest
- Kubernetes YAML
- GitHub Actions

## Security Policies

### 1. Non-root execution

Containers must run as non-root users.

The policy checks Pod-level and container-level security contexts and rejects an effective user ID of zero.

### 2. Privileged container prevention

Containers must not use privileged execution.

This reduces the potential impact of a compromised application container.

### 3. Resource requirements

Every container must define:

- CPU requests
- Memory requests
- CPU limits
- Memory limits

This provides predictable resource allocation and helps reduce resource exhaustion risks.

### 4. Image tag security

Containers must use an explicit image version or digest.

Mutable `latest` tags and untagged images are rejected.

### 5. ServiceAccount token protection

Deployments must explicitly disable automatic ServiceAccount token mounting.

Applications should receive Kubernetes API credentials only when required.

### 6. Init container coverage

The same container-level requirements apply to init containers.

This prevents insecure configurations from bypassing normal container policies.

## Testing

Automated Rego unit tests validate the policy behavior.

Secure Deployment manifests are expected to pass.

Deliberately insecure manifests are expected to trigger policy violations.

## CI/CD Integration

GitHub Actions runs the Kubernetes policy checks on pushes and pull requests.

The pipeline:

1. Installs Conftest.
2. Verifies Rego unit tests.
3. Validates secure Kubernetes manifests.
4. Confirms detection of all expected insecure configurations.

## Security Architecture

Conftest acts as a pre-deployment policy enforcement mechanism.

The policy engine evaluates manifests before deployment, allowing violations to be caught during CI/CD.

## Limitations

CI-based manifest validation does not independently enforce security inside a running Kubernetes cluster.

A deployment could bypass this pipeline through another deployment path.

Runtime admission control will be introduced in the next enforcement stage using Kyverno.
