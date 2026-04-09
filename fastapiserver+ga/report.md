# Codebase Audit Report

**Student** — Aditya Shrivastava  
**SAP ID** — 500124727  
**Repository** — [`adishri2005/containerization-devops`](https://github.com/adishri2005/containerization-devops)  
**Docker Image** — [`adishri2005/fastapi-app:v0.1`](https://hub.docker.com/r/adishri2005/fastapi-app)  
**Audit Date** — 2026-04-09

---

## Summary

All **18 checks** across **5 deliverable categories** have been verified.  
No corrections required.

| Category | Checks | Result |
|---|:---:|:---:|
| Project Structure & Environment | 2 / 2 | ✅ Pass |
| Base Application Code | 5 / 5 | ✅ Pass |
| Dependencies | 1 / 1 | ✅ Pass |
| Dockerization | 6 / 6 | ✅ Pass |
| CI/CD Pipeline | 4 / 4 | ✅ Pass |

---

## 1 — Project Structure & Environment

| # | Check | File | Status |
|---|---|---|:---:|
| 1.1 | `.env` contains `DOCKERTOKEN=tokengeneratedfromdockerhub` | [`fastapiserver+ga/.env`](https://github.com/adishri2005/containerization-devops/blob/main/fastapiserver+ga/.env) | ✅ |
| 1.2 | `.gitignore` explicitly ignores `.env` | [`fastapiserver+ga/.gitignore`](https://github.com/adishri2005/containerization-devops/blob/main/fastapiserver+ga/.gitignore) | ✅ |

---

## 2 — Base Application Code

**File** — [`fastapiserver+ga/main.py`](https://github.com/adishri2005/containerization-devops/blob/main/fastapiserver+ga/main.py)

| # | Check | Status |
|---|---|:---:|
| 2.1 | Imports `FastAPI` from `fastapi` | ✅ |
| 2.2 | Imports `uvicorn` | ✅ |
| 2.3 | Root endpoint `@app.get("/")` returns `{"name": "Aditya Shrivastava", "sapid": "500124727", "Location": "Dehradun"}` | ✅ |
| 2.4 | Dynamic endpoint `@app.get("/{data}")` present | ✅ |
| 2.5 | Server runs on `host="0.0.0.0"`, `port=80`, `reload=True` | ✅ |

---

## 3 — Dependencies

**File** — [`fastapiserver+ga/requirements.txt`](https://github.com/adishri2005/containerization-devops/blob/main/fastapiserver+ga/requirements.txt)

| # | Check | Status |
|---|---|:---:|
| 3.1 | Lists `fastapi` and `uvicorn` (no extras) | ✅ |

---

## 4 — Dockerization

**File** — [`fastapiserver+ga/Dockerfile`](https://github.com/adishri2005/containerization-devops/blob/main/fastapiserver+ga/Dockerfile)

| # | Check | Status |
|---|---|:---:|
| 4.1 | Base image is `FROM ubuntu` | ✅ |
| 4.2 | Runs `apt update -y` | ✅ |
| 4.3 | Installs `python3`, `python3-pip`, `pipenv` | ✅ |
| 4.4 | `WORKDIR /app` and `COPY . /app/` | ✅ |
| 4.5 | Dependencies via `pipenv install -r requirements.txt` | ✅ |
| 4.6 | `EXPOSE 80` and `CMD pipenv run python3 ./main.py` | ✅ |

---

## 5 — CI/CD Pipeline

**File** — [`.github/workflows/DockerBuild.yml`](https://github.com/adishri2005/containerization-devops/blob/main/.github/workflows/DockerBuild.yml)

| # | Check | Status |
|---|---|:---:|
| 5.1 | Triggered on `push`, runs on `ubuntu-latest` | ✅ |
| 5.2 | Uses `actions/checkout@v1` | ✅ |
| 5.3 | DockerHub login via `secrets.DOCKERTOKEN` piped to `docker login` | ✅ |
| 5.4 | Builds and pushes `adishri2005/fastapi-app:v0.1` | ✅ |

---

## Deployment Verification

| Metric | Value |
|---|---|
| GitHub Actions Run | [`#1` — ✅ Success](https://github.com/adishri2005/containerization-devops/actions) |
| Duration | 1m 15s |
| Docker Hub Image | [`adishri2005/fastapi-app:v0.1`](https://hub.docker.com/r/adishri2005/fastapi-app) — **Active** |
| Image Size | ~251 MB |
| Image Digest | `sha256:696590b96a84...` |

---

## Verdict

> **18 / 18 — Full compliance. No corrections required.**

All deliverables are present, correctly configured, and the CI/CD pipeline has been verified end-to-end with a successful build and push to Docker Hub.
