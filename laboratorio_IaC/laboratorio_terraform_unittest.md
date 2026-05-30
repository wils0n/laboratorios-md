# Laboratorio: Unit Testing para Lambda en GitLab CI/CD

**Duración estimada:** 30–45 min  
**Nivel:** Intermedio  
**Contexto:** Continuación de `laboratorio_terraform_gitlab.md`. El proyecto y el Lambda ya existen. En este lab agregas un job de unit tests al pipeline existente — los tests corren sin AWS y sin desplegar nada.

---

## Objetivos de aprendizaje

- Escribir unit tests para un handler Lambda en Python puro
- Agregar un job `test` al pipeline de GitLab CI/CD existente
- Entender por qué los tests corren antes del `plan` y el `apply`
- Verificar que el pipeline bloquea el deploy si los tests fallan

---

## Punto de partida

Al terminar `laboratorio_terraform_gitlab.md`, tu proyecto tiene esta estructura:

```
gitlab_terraform_demo/
├── .gitlab-ci.yml
├── main.tf
├── variables.tf
├── terraform.tfvars
└── app/
    └── handler.py
```

Al terminar este lab tendrá:

```
gitlab_terraform_demo/
├── .gitlab-ci.yml          ← modificado: nuevo job test
├── main.tf                 ← sin cambios
├── variables.tf            ← sin cambios
├── terraform.tfvars        ← sin cambios
└── app/
    ├── handler.py          ← sin cambios
    └── test_handler.py     ← nuevo
```

`main.tf` no cambia — el Lambda es el mismo. Solo se agregan tests y un job al pipeline.

---

## Parte 1: Archivo de tests

### 1.1 `app/test_handler.py`

Los tests llaman directamente a `lambda_handler()` con eventos simulados. No necesitan AWS, credenciales ni red.

**Archivo: `app/test_handler.py`**

```python
import json
import unittest

from handler import lambda_handler


class TestLambdaHandler(unittest.TestCase):

    def test_default_name(self):
        event = {"queryStringParameters": None}
        result = lambda_handler(event, None)
        body = json.loads(result["body"])
        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(body["message"], "Hello, World!")

    def test_custom_name(self):
        event = {"queryStringParameters": {"name": "UTEC"}}
        result = lambda_handler(event, None)
        body = json.loads(result["body"])
        self.assertEqual(body["message"], "Hello, UTEC!")

    def test_response_structure(self):
        event = {"queryStringParameters": None}
        result = lambda_handler(event, None)
        self.assertIn("statusCode", result)
        self.assertIn("headers", result)
        self.assertIn("body", result)

    def test_content_type_header(self):
        event = {"queryStringParameters": None}
        result = lambda_handler(event, None)
        self.assertEqual(result["headers"]["Content-Type"], "application/json")


if __name__ == "__main__":
    unittest.main()
```

**Qué prueba cada test:**

| Test | Qué verifica |
|---|---|
| `test_default_name` | Sin `name` en query → responde `"Hello, World!"` |
| `test_custom_name` | Con `name=UTEC` → responde `"Hello, UTEC!"` |
| `test_response_structure` | El dict tiene las tres claves que Lambda espera |
| `test_content_type_header` | El header `Content-Type` es `application/json` |

### 1.2 Correr los tests localmente

```bash
pip install pytest
python -m pytest app/ -v
```

```
app/test_handler.py::TestLambdaHandler::test_content_type_header PASSED
app/test_handler.py::TestLambdaHandler::test_custom_name         PASSED
app/test_handler.py::TestLambdaHandler::test_default_name        PASSED
app/test_handler.py::TestLambdaHandler::test_response_structure  PASSED

4 passed in 0.03s
```

Verifica que los 4 tests pasan antes de commitear.

---

## Parte 2: Actualizar el pipeline

### 2.1 Cambio en `.gitlab-ci.yml`

Agrega el job `test-python` al stage `tf-validate`. Solo necesitas añadir el bloque — el resto del archivo queda igual.

**Diff — qué agregar al `.gitlab-ci.yml` existente:**

```yaml
# Agregar después del job lint-python, antes del job plan

test:
  stage: validate
  image: python:3.11-slim
  before_script:
    - pip install pytest
  script:
    - python -m pytest app/ -v
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
```

**Agregar `test` a `needs:` del job `plan`:**

```yaml
plan:
  needs:
    - job: tf-check
    - job: tf-validate
    - job: lint-python
    - job: test        # ← agregar esta línea
```

### 2.2 `.gitlab-ci.yml` completo actualizado

```yaml
stages:
  - validate
  - plan
  - apply

default:
  image:
    name: hashicorp/terraform:1.8
    entrypoint: [""]

variables:
  TF_IN_AUTOMATION: "true"
  TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default"
  TF_HTTP_LOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
  TF_HTTP_UNLOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
  TF_HTTP_USERNAME: "gitlab-ci-token"
  TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
  TF_HTTP_LOCK_METHOD: "POST"
  TF_HTTP_UNLOCK_METHOD: "DELETE"

.terraform_cache: &terraform_cache
  cache:
    key: "${CI_COMMIT_REF_SLUG}-terraform"
    paths:
      - .terraform/

.terraform_init: &terraform_init
  before_script:
    - terraform --version
    - terraform init -reconfigure

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: validate
# ══════════════════════════════════════════════════════════════════════════════

tf-check:
  stage: validate
  before_script:
    - terraform --version
  script:
    - terraform fmt -check -recursive
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

tf-validate:
  stage: validate
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform validate
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

lint-python:
  stage: validate
  image: python:3.11-slim
  before_script:
    - pip install flake8
  script:
    - flake8 app/ --max-line-length=100 --statistics
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

test-python:
  stage: validate
  image: python:3.11-slim
  before_script:
    - pip install pytest
  script:
    - python -m pytest app/ -v
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: plan
# ══════════════════════════════════════════════════════════════════════════════

plan:
  stage: plan
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan
      - lambda.zip
    expire_in: 1 week
    when: always
  needs:
    - job: tf-check
    - job: tf-validate
    - job: lint-python
    - job: test
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: apply
# ══════════════════════════════════════════════════════════════════════════════

apply:
  stage: apply
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform apply tfplan
    - terraform output
  environment:
    name: aws-lambda
  needs:
    - job: plan
      artifacts: true
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

destroy:
  stage: apply
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform destroy -auto-approve
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

---

## Parte 3: Flujo del pipeline actualizado

```
validate:
  ┌───────────────┐  ┌────────────┐  ┌──────────────┐  ┌──────┐
  │   fmt-check   │  │  validate  │  │ lint-python  │  │ test │  ← al mismo tiempo
  └───────────────┘  └────────────┘  └──────────────┘  └──────┘
                                          │
                                        plan
                                          │
                                   apply ▶ / destroy ▶
```

El job `plan` espera que los **4 jobs** del stage `validate` terminen correctamente. Si `test` falla, `plan` no corre y el deploy queda bloqueado.

---

## Parte 4: Push y verificar

```bash
git add app/test_handler.py .gitlab-ci.yml
git commit -m "test: add unit tests for lambda handler and test job to pipeline"
git push origin main
```

En GitLab verás el stage `validate` con 4 jobs corriendo en paralelo. Abre los logs del job `test` para ver el output de pytest.

### 4.1 Verificar que un test fallido bloquea el deploy

Rompe un test temporalmente para ver el comportamiento:

```python
# En app/test_handler.py, cambia temporalmente:
self.assertEqual(body["message"], "Hello, UTEC_ROTO!")  # falla a propósito
```

```bash
git add app/test_handler.py
git commit -m "test: break test on purpose"
git push origin main
```

Observa en GitLab:
- El job `test` falla con `AssertionError`
- El job `plan` **no corre** — queda bloqueado
- El Lambda no se actualiza

Revierte el cambio y vuelve a pushear:

```bash
# Restaura el test correcto y pushea
git revert HEAD
git push origin main
```

---

## Parte 5: Troubleshooting

| Problema | Causa probable | Solución |
|---|---|---|
| `ModuleNotFoundError: handler` | pytest no encuentra `handler.py` | Verifica que `test_handler.py` esté en `app/` junto a `handler.py` |
| `test` falla con `ImportError: pytest` | pip install no corrió | Verifica el `before_script: - pip install pytest` en el job |
| `plan` corre aunque `test` falló | Falta `test` en `needs:` del job `plan` | Agrega `- job: test` a la lista de `needs:` |
| Tests pasan localmente pero fallan en CI | Diferencia de versión Python | Verifica que uses `python:3.11-slim` en el job y Python 3.11 localmente |

---

## Checklist de Éxito

- [ ] `python -m pytest app/ -v` pasa los 4 tests localmente
- [ ] El job `test` aparece en el stage `validate` junto a los otros 3 jobs
- [ ] Los 4 jobs del stage `validate` corren en paralelo
- [ ] Un test roto bloquea el job `plan` y el deploy no ocurre
- [ ] Al restaurar el test, el pipeline completo vuelve a pasar

---

## Entregables

1. **Repositorio GitLab** actualizado con:
   - `app/test_handler.py` con los 4 tests
   - `.gitlab-ci.yml` con el job `test` y `needs:` actualizado
2. **Capturas de pantalla:**
   - Stage `validate` con los 4 jobs en paralelo
   - Logs del job `test` mostrando los 4 tests pasando
   - Pipeline con test fallido: job `plan` bloqueado
   - Pipeline restaurado: todos los jobs verdes

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps e Infraestructura como Código – Terraform y GitLab CI/CD*  
Universidad de Ingeniería y Tecnología (UTEC)
