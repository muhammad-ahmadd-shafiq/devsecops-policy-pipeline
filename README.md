# DevSecOps Policy-as-Code Pipeline

A practical DevSecOps project that demonstrates how to move security
checks earlier in the software delivery lifecycle and enforce security
requirements again at deployment time.

The project combines CI security gates, Infrastructure-as-Code scanning,
Kubernetes policy-as-code, image signing, and software bill of materials
(SBOM) verification. The objective is to make insecure code,
infrastructure, containers, and workloads fail before they reach a
running environment.

## Project goals

-   Detect exposed secrets before code is merged.
-   Identify source-code and dependency vulnerabilities.
-   Enforce Dockerfile security and quality checks.
-   Scan container images for known vulnerabilities.
-   Validate Terraform configurations with both static analysis and
    custom policies.
-   Enforce Kubernetes workload security requirements.
-   Prevent unsigned or untrusted container images from being admitted
    to the Kubernetes cluster.
-   Publish a signed container image and attach a CycloneDX SBOM.
-   Demonstrate both successful and intentionally failing security
    tests.

## Security pipeline

The GitHub Actions workflow is defined in:

`.github/workflows/security-pipeline.yml`

It runs for pushes and pull requests targeting `main`, and can also be
started manually with `workflow_dispatch`.

### Gate 0: Secret detection

**Tool:** Gitleaks

Scans the repository for accidentally committed credentials, API keys,
tokens, and other secret patterns. A detected secret causes the security
job to fail.

### Gate 1: Source-code and dependency security

**Tools:** Bandit, pip-audit, pytest

-   Bandit checks Python source code for common security issues.
-   pip-audit checks installed/project dependencies against known
    vulnerability advisories.
-   pytest runs the application's automated tests.

These checks help identify application-level security problems and
vulnerable dependencies before building the container.

### Gate 2: Dockerfile security and linting

**Tool:** Hadolint

Checks the Dockerfile for common mistakes and insecure practices. The
application image is configured to run as a non-root user, and the
Dockerfile uses explicit dependency installation practices.

### Gate 3: Container image security

**Tool:** Trivy

Scans the built application container image for known vulnerabilities.
The pipeline is configured to report or fail on the configured severity
threshold, including HIGH and CRITICAL findings.

The application container uses Flask with Gunicorn and listens on port
`5000`.

### Gate 4: Terraform security and policy-as-code

**Tools:** Checkov, Conftest, Open Policy Agent (OPA)

The repository includes separate Terraform examples:

-   `terraform/secure`
-   `terraform/insecure`

Checkov performs static security analysis of Terraform resources.
Conftest evaluates custom Rego policies against Terraform
plan/configuration data.

The secure example is used to demonstrate a compliant configuration. The
intentionally insecure example is used to prove that policy violations
are detected, including controls around public network exposure, SSH
access, and EBS encryption.

### Gate 5: Kubernetes policy-as-code

**Tools:** Conftest, OPA, Rego

Custom Kubernetes policies validate workload manifests before
deployment. The policy checks cover workload hardening requirements such
as:

-   Running containers as non-root.
-   Restricting Linux capabilities.
-   Using a restrictive seccomp profile.
-   Avoiding unnecessary service-account token mounting.
-   Requiring secure container and pod configuration.

The repository includes a secure workload manifest and intentionally
insecure test manifests. The negative tests demonstrate that
non-compliant resources are rejected by the policy checks.

### Gate 6: Kubernetes admission control

**Tool:** Kyverno

Kyverno extends policy enforcement from CI checks to the Kubernetes API
admission stage.

The project includes admission policies and test workloads under
`policies/kyverno` and `k8s/kyverno`. The admission controls are
intended to enforce secure workload requirements and verify container
images from the project's GHCR repository.

The image verification policy uses Sigstore/Cosign keyless identity
information to trust signatures produced by the approved GitHub Actions
workflow. It also requires a signed CycloneDX SBOM attestation.

An intentionally unsigned image is used as a negative test. It should
not be admitted when the image verification policy matches the workload.

### Gate 7: Software supply-chain security

**Tools:** Docker Buildx, GitHub Container Registry (GHCR), Trivy,
Anchore SBOM Action, Cosign, CycloneDX

The supply-chain job is responsible for producing and publishing the
application image and its security metadata.

The implemented workflow includes:

-   Building and publishing the container image to GHCR.
-   Scanning the published image for vulnerabilities.
-   Generating a CycloneDX SBOM.
-   Signing the image with Cosign keyless signing through GitHub Actions
    OIDC.
-   Attaching and verifying the SBOM attestation.
-   Verifying the image signature against the expected GitHub Actions
    identity.

The image should be referenced by its immutable digest when verifying or
deploying it. A mutable tag can point to a different image later,
whereas a digest identifies the exact image content.

## Technology stack

  Area                     Tools and technologies
  ------------------------ --------------------------------------
  CI/CD                    GitHub Actions
  Source security          Gitleaks, Bandit
  Dependency security      pip-audit
  Application testing      pytest
  Dockerfile linting       Hadolint
  Container security       Docker, Trivy
  Infrastructure as Code   Terraform, AWS provider
  IaC security             Checkov
  Policy as Code           Open Policy Agent, Conftest, Rego
  Kubernetes               Kubernetes, Kind, kubectl
  Admission control        Kyverno
  Container registry       GitHub Container Registry
  SBOM                     CycloneDX, Anchore SBOM Action
  Image signing            Sigstore Cosign, GitHub Actions OIDC

## Repository layout

The main project areas are organized as follows. Some supporting files
may exist in additional subdirectories.

``` text
devsecops-policy-pipeline/
├── .github/
│   └── workflows/
│       └── security-pipeline.yml
├── docs/
│   ├── kubernetes-policy-enforcement.md
│   └── kyverno-admission-control.md
├── k8s/
│   ├── bad-deployments/
│   └── kyverno/
├── policies/
│   ├── conftest/
│   │   └── kubernetes/
│   └── kyverno/
│       └── admission/
├── terraform/
│   ├── insecure/
│   └── secure/
├── Dockerfile
├── README.md
└── ...
```

## Running checks locally

Run commands from the repository root unless stated otherwise.

### Python tests and source checks

``` powershell
python -m pytest
python -m bandit -r .
python -m pip_audit
```

Run these from the project's configured Python environment and ensure
the project's dependencies are installed.

### Dockerfile lint

``` powershell
docker run --rm -i hadolint/hadolint:v2.15.1 < Dockerfile
```

### Terraform checks

Run Terraform initialization separately for each example:

``` powershell
terraform -chdir=terraform/secure init
terraform -chdir=terraform/secure validate

terraform -chdir=terraform/insecure init
terraform -chdir=terraform/insecure validate
```

Run Checkov against each example:

``` powershell
checkov -d terraform/secure
checkov -d terraform/insecure
```

Run the corresponding Conftest checks using the policy paths and input
format configured in the repository.

### Kubernetes policy checks

Run Conftest against the secure and intentionally insecure Kubernetes
manifests using the repository's Kubernetes policy directory. The
insecure fixtures are expected to produce policy failures; those
failures demonstrate that the controls are working.

### Kubernetes admission tests

Use the project Kind cluster and confirm the active context before
applying resources:

``` powershell
kubectl config current-context
kubectl get nodes
kubectl get imagevalidatingpolicies
```

The expected project context is `kind-devsecops-lab`. Apply or remove
test workloads using the manifests under `k8s/kyverno`. The
intentionally unsigned image test is expected to be denied by the image
verification policy when the policy matches the image reference.

## GitHub Actions and registry configuration

The supply-chain workflow uses GitHub Actions permissions for repository
read access, package publishing, and OIDC identity token issuance. The
workflow should retain the least privileges required by each job.

For GHCR publishing, the workflow uses the GitHub Actions token. For
local pulls of a private package, authenticate with a GitHub Personal
Access Token that has the required package permissions. Never commit
tokens, passwords, private keys, or other credentials to the repository.

The keyless signing identity is tied to the approved workflow:

``` text
https://github.com/muhammad-ahmadd-shafiq/devsecops-policy-pipeline/.github/workflows/security-pipeline.yml@refs/heads/main
```

The expected OIDC issuer is:

``` text
https://token.actions.githubusercontent.com
```

If the workflow filename, repository, owner, or branch changes, update
the identity expected by the verification policy accordingly.

## Security testing approach

This project uses both positive and negative test cases:

-   **Positive tests:** secure Terraform and Kubernetes configurations
    should pass the relevant policy checks.
-   **Negative tests:** intentionally insecure configurations should
    fail the relevant checks.
-   **Admission test:** an unsigned image from the configured GHCR
    repository should be denied by Kyverno.
-   **Supply-chain verification:** the published image signature and
    SBOM attestation should verify against the expected trusted
    identity.

A successful pipeline does not mean that software is completely
vulnerability-free. It means that the configured checks completed
successfully and no violations covered by those checks were found at
that point in time.

## Important repository hygiene

Terraform provider binaries and local working directories must not be
committed. The `.gitignore` should exclude Terraform's `.terraform`
directories while retaining `.terraform.lock.hcl` files.

Before pushing changes, check that no `.terraform` directory, state
file, credential, generated secret, or other large local artifact is
staged.

## Project status

This repository demonstrates a multi-layer DevSecOps workflow across
source code, dependencies, Docker, Terraform, Kubernetes manifests,
admission control, and container supply-chain verification.

The workflow and policies are actively being developed. For a
reproducible result, use the versions pinned in the repository's
configuration and inspect the latest GitHub Actions run for the current
pass/fail status of each gate.

## Author

**Muhammad Ahmad**

-   GitHub: https://github.com/muhammad-ahmadd-shafiq
-   LinkedIn: https://www.linkedin.com/in/muhammad-ahmad-11b220428/
