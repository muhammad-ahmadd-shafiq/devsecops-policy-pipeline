
# Phase 5: Kubernetes Admission Control with Kyverno

## Overview

Phase 5 introduces Kubernetes-native admission control using Kyverno.

Earlier project phases implemented security checks in GitHub Actions and
pre-deployment Kubernetes policy testing with Conftest and OPA.

This phase adds runtime admission enforcement.

Kyverno evaluates Kubernetes admission requests and rejects workloads
that violate the configured security policies.

## Architecture

1. A developer submits a Kubernetes workload.
2. The Kubernetes API server receives the admission request.
3. Kyverno evaluates the resource against the configured policies.
4. The workload is either admitted or rejected.
5. Image verification checks the Cosign signature and SBOM attestation.

## Technology Stack

- Kubernetes
- Kind
- Docker Desktop
- Helm
- Kyverno 1.19.2
- Kyverno Helm chart 3.9.2
- Kyverno CLI 1.19.2
- Cosign
- GitHub Container Registry
- GitHub Actions

## Security Policies

### 1. Non-root execution

Workloads must explicitly configure non-root execution and a non-zero UID.

### 2. Privileged container prevention

Privileged containers are prohibited.

### 3. Privilege escalation prevention

Every container must explicitly disable privilege escalation.

### 4. Resource requirements

Every container must define CPU and memory requests and limits.

### 5. Image version enforcement

Images must use an explicit version tag or SHA256 digest.
The latest tag is prohibited.

### 6. ServiceAccount token restriction

Automatic ServiceAccount token mounting must be disabled.

### 7. Image signature verification

Images from the project's GHCR repository must have a valid Cosign keyless
signature from the approved GitHub Actions workflow.

### 8. SBOM attestation verification

The image must have a valid CycloneDX SBOM attestation signed by the
approved GitHub Actions workflow.

## Admission Enforcement

Kyverno runs as an admission controller inside the Kubernetes cluster.

The API server sends admission requests to Kyverno.

If a resource violates an enforced policy, the admission request is rejected.

This prevents insecure resources from being admitted through direct
kubectl operations or deployment systems that bypass GitHub Actions.

## Local Environment

The project uses Kind to create a local Kubernetes cluster.

Kyverno is installed using Helm in the dedicated kyverno namespace.

Application resources are deployed into the policy-pipeline namespace.

## Testing

Secure workloads should be admitted.

Insecure workloads should be rejected.

Unsigned or incorrectly signed project images should be rejected.

Policy reports, Kubernetes Events, and Kyverno logs are used to inspect
policy evaluation results.

## CI Integration

The Kyverno CLI tests the workload security policy in GitHub Actions.

The CI job verifies that the secure manifest passes and that the
intentionally insecure fixture is rejected.

Live image signature and SBOM verification are enforced by Kyverno
inside the Kubernetes cluster.

## Security Benefits

- Prevents insecure workloads from being admitted.
- Reduces reliance on CI/CD as the only security boundary.
- Enforces container security at deployment time.
- Verifies image authenticity using Cosign.
- Connects software supply-chain security with Kubernetes admission control.
- Provides policy evaluation results and operational visibility.

## Phase 5 Deliverables

- Kyverno installed in a local Kubernetes cluster.
- CEL-based ValidatingPolicy.
- ImageValidatingPolicy.
- Cosign keyless signature verification.
- CycloneDX SBOM attestation verification.
- Secure and insecure Kubernetes test manifests.
- GitHub Actions Kyverno CLI integration.
- Phase 5 documentation.
