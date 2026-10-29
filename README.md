# DevSecOps Policy-as-Code Pipeline

A portfolio project demonstrating how security policies can be
enforced throughout application delivery, from source code to
Kubernetes admission control.

## Project goals

- Build a repeatable CI pipeline.
- Test the application before packaging it.
- Build a container that runs as a non-root user.
- Deploy locally to Kubernetes using kind.
- Add automated security gates and policy enforcement in later phases.

## Architecture

Flask application -> GitHub Actions -> Docker image -> kind cluster

## Current status

Phase 1: Foundation

- [x] Flask application and health endpoint
- [x] Unit tests
- [x] Multi-stage Dockerfile
- [x] Non-root container user
- [x] GitHub Actions test and build workflow
- [x] Local Kubernetes deployment

## Security scope

This is a learning project, not a production security certification.
Security scanning, image signing, and Kubernetes admission policies
will be introduced and tested in subsequent phases.