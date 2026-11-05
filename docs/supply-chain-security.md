# Phase 4: Software Supply Chain Security

## Overview

This phase implements software supply-chain security for the DevSecOps Policy Pipeline.

The objective is to establish component transparency, image integrity, and verifiable build identity.

## Technologies

- Syft: Generates Software Bill of Materials.
- CycloneDX: SBOM data format.
- Cosign: Container image signing and verification.
- Sigstore: Keyless signing infrastructure.
- GitHub Actions OIDC: Workload identity.
- GitHub Container Registry: Container image storage.

## Implementation

### 1. SBOM Generation

Syft scans the built container image and generates a CycloneDX JSON SBOM.

The SBOM identifies software components and their versions, including operating system packages and application dependencies.

### 2. Container Image Publishing

GitHub Actions builds and pushes the image to GHCR.

Images are tagged using the Git commit SHA to provide traceability.

### 3. Keyless Image Signing

Cosign signs the immutable image digest using GitHub Actions OIDC.

The workflow does not store a permanent Cosign private key in GitHub Secrets.

Sigstore issues a short-lived signing certificate based on the workflow identity.

### 4. Signature Verification

Cosign verifies the image signature against the expected GitHub Actions workflow identity and OIDC issuer.

### 5. SBOM Attestation

The CycloneDX SBOM is attached to the image digest as a signed attestation.

Cosign verifies the attestation's cryptographic signature and identity.

### 6. CI/CD Integration

The supply-chain job runs only after the existing security jobs succeed and only publishes from the main branch.

Pull requests do not publish or sign container images.

## Security Benefits

- Improved software component visibility.
- Image provenance and signer identity verification.
- Cryptographic image integrity.
- Reduced reliance on long-lived signing secrets.
- SBOM retention for audit and vulnerability investigation.
- Traceability between source commits and published images.

## Limitations

A valid image signature does not prove that the image is free of vulnerabilities.

An SBOM identifies components but does not independently establish that those components are safe.

Vulnerability scanning, policy enforcement, and trusted image verification remain necessary.

## Future Integration

The next stage will enforce image trust at Kubernetes admission time so that unsigned or untrusted images cannot be deployed.
