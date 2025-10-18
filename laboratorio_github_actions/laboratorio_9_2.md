
# Laboratorio 9.2: CI/CD → Publicación en **AWS ECR** con GitHub Actions (Actualizado)

**Duración estimada:** 60–90 min  
**Nivel:** Intermedio  
**Contexto:** Continuación del Lab 9.1 (CI + Docker). Reemplazamos Docker Hub por **Amazon ECR** y autenticamos GitHub Actions en AWS con **OIDC** (sin llaves largas). Incluye alternativa con Access Keys (no recomendada en prod).

---

## Objetivos de aprendizaje
- Construir imágenes Docker en CI y publicarlas en **ECR**.
- Autenticarse en AWS vía **OIDC** con GitHub Actions.
- Crear (si no existe), etiquetar y **push** a ECR.
- Versionar imágenes (latest + rama + timestamp + SHA).
- Aplicar buenas prácticas: cache de build, escaneo y troubleshooting.

---

## Requisitos previos
- Cuenta AWS con permisos en **IAM** y **ECR**.  
- Repo GitHub con tests funcionando.  
- **Dockerfile** válido en el proyecto.  
- (Opcional) AWS CLI + Docker local.

---

## Parte 1: Estructura mínima

```
ci_to_ecr_demo/
├── .github/workflows/devops.yml
├── hello.py
├── tests/test_hello.py
├── requirements.txt
├── Dockerfile
└── README.md
```

### Dockerfile simple (Python)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY hello.py .
ENV PYTHONUNBUFFERED=1
CMD ["python", "hello.py"]
```

---

## Parte 2: Configurar **OIDC** en AWS IAM (recomendado)

1) **Identity provider (OIDC)**
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

2) **Crear Role** (GitHubActionsECRRol) confiando en ese proveedor  
**Trust policy** (reemplaza `<AWS_ACCOUNT_ID>` y tu repo/branch):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

3) **Permisos del Role** (GitHubActionsECRPolicy)
> Incluye `BatchGetImage`, `GetDownloadUrlForLayer` y `DescribeImages` para evitar el **403** cuando Buildx hace HEAD/GET del manifiesto/capas.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRPullPushAndManageRepo",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:CreateRepository"
      ],
      "Resource": "*"
    }
  ]
}
```

4) Copia el **ARN** del Role:  
`arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>`

---

## Parte 3: **Cómo obtener tu AWS Account ID**

El ID de cuenta es un número de 12 dígitos.

**Opción A — AWS CLI (recomendada):**
```bash
aws sts get-caller-identity --query Account --output text
```
> Devuelve solo el número de cuenta. Asegúrate de que el perfil/credencial activo sea el correcto.

**Opción B — Consola AWS:**
- En la esquina superior derecha (menú de tu cuenta) → **Account ID**.  
- O ir a **Support Center** / **My Account** y copiar el número.

**Opción C — CloudShell:**
- Abre AWS CloudShell y ejecuta el mismo comando de la Opción A.

---

## Parte 4: **Secrets & Variables** en GitHub

En **Settings → Secrets and variables → Actions**:

**Repository secrets**
- `AWS_ROLE_ARN` → ARN del Role (OIDC).  
- *(Solo si usas Access Keys como fallback)* `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

**Repository variables**
- `AWS_REGION` → ej. `us-east-1`
- `AWS_ACCOUNT_ID` → ej. `664418991493`
- `ECR_REPO_NAME` → ej. `ci-to-ecr-demo`

---

## Parte 5: Workflow de GitHub Actions (final, solo OIDC)

**Archivo:** `.github/workflows/devops.yml`

```yaml
name: CI/CD → ECR
run-name: "${{ github.actor }} publicó a ECR en ${{ github.ref_name }}"

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  PYTHON_VERSION: "3.11"
  AWS_REGION: ${{ vars.AWS_REGION }}
  AWS_ACCOUNT_ID: ${{ vars.AWS_ACCOUNT_ID }}
  ECR_REPO_NAME: ${{ vars.ECR_REPO_NAME }}

jobs:
  lint:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-python@v5
          with:
            python-version: ${{ env.PYTHON_VERSION }}
        - run: |
            pip install flake8 black isort
            flake8 . --count --select=E9,F63,F7,F82 --show-source
            black --check .
            isort --check-only .
  test:
    needs: lint
    runs-on: ubuntu-latest
    outputs:
      build_tag: ${{ steps.meta.outputs.tag }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache pip
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: pip-${{ runner.os }}-${{ hashFiles('requirements.txt') }}
          restore-keys: pip-${{ runner.os }}-

      - name: Install deps
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        run: |
          export PYTHONPATH="${PYTHONPATH}:$(pwd)"
          pytest -q

      - name: Compute build tag
        id: meta
        run: |
          TS=$(date +%Y%m%d-%H%M%S)
          echo "tag=${TS}-${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

  docker-ecr:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: gha-${{ github.run_id }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Ensure ECR repository exists
        run: |
          aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" >/dev/null 2>&1 ||           aws ecr create-repository --repository-name "$ECR_REPO_NAME"             --image-scanning-configuration scanOnPush=true             --encryption-configuration encryptionType=AES256

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Extract Docker metadata (tags/labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPO_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
            type=raw,value=${{ needs.test.outputs.build_tag }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build & Push image to ECR
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPO_NAME }}:buildcache
          cache-to: type=registry,ref=${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPO_NAME }}:buildcache,mode=max

      - name: Summary
        run: |
          echo "## 🐳 Publicación exitosa en AWS ECR" >> $GITHUB_STEP_SUMMARY
          echo "**Registro:** ${{ steps.login-ecr.outputs.registry }}" >> $GITHUB_STEP_SUMMARY
          echo "**Repositorio:** $ECR_REPO_NAME" >> $GITHUB_STEP_SUMMARY
          echo "**Tags:**" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          echo "${{ steps.meta.outputs.tags }}" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
```

**Tags que se publican**
- `latest` (rama por defecto)  
- `main`  
- `main-<shortSHA>`  
- `<timestamp>-<shortSHA>`

---

## Parte 6: Explicación de cada *action/step* del job `docker-ecr`

1. **Checkout** — `actions/checkout@v4`  
   Baja el código del repositorio al runner. Necesario para leer `Dockerfile`, etc.

2. **Configure AWS credentials (OIDC)** — `aws-actions/configure-aws-credentials@v4`  
   - Asume el **Role** via OIDC usando `secrets.AWS_ROLE_ARN`.  
   - Exporta credenciales temporales de AWS al entorno.  
   - Requiere `permissions: id-token: write` en el job y **trust policy** correcta.  
   - *Errores típicos:* `Could not load credentials` (ARN vacío/incorrecto), `AccessDenied` (trust policy mal configurada).

3. **Ensure ECR repository exists** — (AWS CLI)  
   - Verifica si existe el repo en ECR; si no, lo crea con **escaneo on-push** y **cifrado AES256**.  
   - Evita fallas por `RepositoryNotFoundException` durante el push.

4. **Login to Amazon ECR** — `aws-actions/amazon-ecr-login@v2`  
   - Ejecuta `docker login` contra el registro de ECR usando **GetAuthorizationToken**.  
   - Expone `steps.login-ecr.outputs.registry` con el valor `<ACCOUNT>.dkr.ecr.<region>.amazonaws.com`.  
   - *Errores típicos:* `no basic auth credentials` (no se configuraron credenciales antes).

5. **Extract Docker metadata (tags/labels)** — `docker/metadata-action@v5`  
   - Genera **tags** y **labels** para la imagen a partir del contexto (`branch`, `SHA`, timestamp).  
   - Expone `steps.meta.outputs.tags` / `labels` para usarlos en build-push.  
   - Útil para versionado reproducible y trazabilidad.

6. **Set up Docker Buildx** — `docker/setup-buildx-action@v3`  
   - Prepara el builder **Buildx** para funciones avanzadas: cache, plataformas, etc.  
   - Recomendado para builds consistentes y más rápidos.

7. **Build & Push image to ECR** — `docker/build-push-action@v5`  
   - Construye la imagen desde `Dockerfile` y la **publica** a ECR (`push: true`).  
   - Usa los **tags/labels** generados.  
   - Configura **cache-from / cache-to** en el propio repositorio ECR (`:buildcache`).  
   - *Permisos necesarios:* además de `PutImage` y carga de capas, se requieren permisos de **lectura** (`BatchGetImage`, `GetDownloadUrlForLayer`, `DescribeImages`) para que Buildx haga `HEAD/GET` del manifiesto; sin eso aparecerá **403 Forbidden**.

8. **Summary** — (Markdown al job summary)  
   - Publica un resumen en la UI de GitHub Actions con el registro, repo y tags publicados.  
   - Útil para informes rápidos al equipo.

---

## Parte 7: Verificación

1. Push a `main` y revisa **Actions** (`test` y `docker-ecr`).  
2. En **ECR**, confirma los tags en `ECR_REPO_NAME`.  
3. (Opcional) Pull local:

```bash
aws ecr get-login-password --region $AWS_REGION  | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
```

---

## Troubleshooting (resumen)

- **403 al hacer HEAD/GET de manifiesto** → agrega `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, `ecr:DescribeImages` (incluido en la policy actualizada).  
- **`Could not load credentials`** → `role-to-assume` vacío o mal configurado; usa `secrets.AWS_ROLE_ARN` o muévelo a `vars`.  
- **`no basic auth credentials`** → falta `amazon-ecr-login@v2`.  
- **OIDC** → requiere `permissions: id-token: write` y trust policy con `sub` correcto (repo + rama).

---

## Changelog (qué se actualizó)
- ✅ Corrección de **dominio OIDC** (`token.actions.githubusercontent.com`).  
- ✅ Uso de **`secrets.AWS_ROLE_ARN`** en el workflow (evita error de carga de credenciales).  
- ✅ **Policy ECR** ampliada para soportar cache/verificación (resuelve 403).  
- ✅ Se agregaron pasos para **obtener AWS Account ID**.  
- ✅ Se añadió **explicación de cada action/step** del job `docker-ecr`.  
- ✅ Troubleshooting ampliado.  
- ✅ Workflow final simplificado **solo OIDC**.
