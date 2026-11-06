
# Software Supply-Chain Security

## Overview

This phase implements software supply-chain security controls for the
DevSecOps Policy Pipeline.

The objective is to ensure that container images are built, scanned,
documented, signed, and verified before they are allowed to run in
Kubernetes.

The implementation uses:

- Docker Buildx
- GitHub Container Registry
- Trivy
- Anchore Syft
- CycloneDX
- Cosign
- GitHub Actions OIDC
- GitHub Artifact Attestations
- SLSA Build Provenance
- Kyverno ImageValidatingPolicy

## 1. Secure Image Build

The supply-chain-security job runs only after the preceding security
gates have passed.

It builds the application image using Docker Buildx and publishes it
to GitHub Container Registry.

Images are tagged using the Git commit SHA.

The build also generates maximum-detail BuildKit provenance.

Published images are referenced by their immutable SHA-256 digest
for subsequent security operations.

## 2. Container Vulnerability Scanning

Trivy scans the published image by digest.

The configured pipeline fails when HIGH or CRITICAL vulnerabilities
are detected, subject to the ignore-unfixed setting.

This prevents images that violate the configured vulnerability
threshold from progressing through the publishing workflow.

## 3. Software Bill of Materials

Anchore Syft generates a CycloneDX JSON Software Bill of Materials.

The SBOM describes the components discovered in the published
container image.

A custom Python validation script checks:

- Valid JSON structure
- CycloneDX format
- Specification version
- Non-empty component list
- SBOM serial number

The resulting SBOM is uploaded as a GitHub Actions artifact.

## 4. Image Signing with Cosign

Cosign uses keyless signing through GitHub Actions OIDC.

The workflow obtains a short-lived signing identity instead of
depending on a long-lived private signing key.

The image is signed using its immutable digest.

The workflow verifies the signature using:

- Expected certificate identity
- GitHub Actions OIDC issuer
- Published image digest

## 5. SBOM Attestation

The pipeline creates a Cosign CycloneDX attestation.

The attestation binds the SBOM to the published image digest.

The pipeline subsequently verifies the attestation using the
expected GitHub Actions signing identity.

## 6. SLSA Build Provenance

GitHub Actions generates a signed SLSA build provenance attestation
for the published container image.

The attestation is associated with the image digest and published
to the container registry.

The GitHub CLI verifies the provenance and checks the expected
repository, workflow, and source branch.

BuildKit provenance is also enabled with mode=max.

## 7. Kubernetes Admission Enforcement

Kyverno ImageValidatingPolicy enforces image trust requirements.

The policy checks:

1. Image signature validity.
2. Trusted GitHub Actions signing identity.
3. CycloneDX SBOM attestation.
4. SBOM document format.
5. SLSA provenance attestation.

Image validation is configured to require digest-based references.

Images that fail the configured trust requirements are denied.

## 8. Negative Testing

The project includes tests for:

- Unsigned container images.
- Images signed using an untrusted local key.
- Rejection of untrusted images during Kubernetes admission.
- Acceptance of a correctly signed image.

These tests demonstrate that image admission depends on trusted
cryptographic evidence rather than simply the presence of an image.

## 9. Supply-Chain Security Architecture

```text
Source Repository
       |
       v
GitHub Actions Security Gates
       |
       v
Docker Buildx
       |
       +---- BuildKit Provenance
       |
       v
Container Image
       |
       v
GitHub Container Registry
       |
       +---- Trivy Vulnerability Scan
       |
       +---- CycloneDX SBOM
       |
       +---- Cosign Image Signature
       |
       +---- Cosign SBOM Attestation
       |
       +---- GitHub SLSA Provenance
       |
       v
Cryptographic Verification
       |
       v
Kubernetes Admission Controller
       |
       v
Kyverno ImageValidatingPolicy
       |
       +---- Verify Image Signature
       |
       +---- Verify SBOM Attestation
       |
       +---- Verify Build Provenance
       |
       v
Trusted Deployment
```

## 10. Security Outcome

The completed implementation establishes a verifiable chain of
trust between the source repository, container build, published
image, software inventory, signing identity, and Kubernetes
admission process.

The pipeline does not rely solely on successful image building
or vulnerability scanning.

It also verifies cryptographic evidence before trusting an
artifact for deployment.

## Verification Status

Phase 6 is complete only after:

- The GitHub Actions supply-chain job passes.
- The image signature is successfully verified.
- The SBOM is generated and validated.
- The SBOM attestation is successfully verified.
- The SLSA provenance is successfully verified.
- Kyverno admits the trusted image.
- Kyverno rejects an unsigned image.
- Kyverno rejects an image signed by an untrusted identity.
