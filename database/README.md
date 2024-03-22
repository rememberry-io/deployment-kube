https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql

https://www.hashicorp.com/blog/dynamic-database-credentials-with-vault-and-kubernetes

https://github.com/nicholasjackson/demo-vault/blob/master/dynamic-secrets-k8s/config/postgres.yml

## This only needs to be done once per vault
```zsh
vault secrets enable database
```

```zsh
kubectl exec $(kubectl get pods -n vault --selector "app.kubernetes.io/instance=vault,component=server" -o jsonpath="{.items[0].metadata.name}") -n vault -c vault -- \
  sh -c ' \
    vault write auth/kubernetes/config \
       token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
       kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
       kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
```

```zsh
vault secrets enable database
```

```zsh
vault write database/config/remstaging \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@staging-rem-postgresql.rememberry.svc.cluster.local:5432/remstaging?sslmode=disable" \
    username="postgres" \
    password="password" \
    password_authentication="scram-sha-256"
```

```zsh
vault write database/roles/rem-staging-role \
    db_name="remstaging" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

```zsh
vault write -force database/rotate-root/remstaging
```

```zsh
vault read database/creds/rem-staging-role
```


```zsh
vault auth enable kubernetes
```

go to vault folder



```zsh
vault write auth/kubernetes/role/rem-staging-backend \
    bound_service_account_names=staging-rem-backend-service-acc \
    bound_service_account_namespaces=rememberry \
    policies=rem-staging-backend \
    ttl=1h
```


for the migration
```zsh
vault write database/roles/staging-migration \
    db_name=remstaging \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        ALTER ROLE \"{{name}}\" SUPERUSER;" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;" \
    default_ttl="1h" \
    max_ttl="1h"
```

user for backend-usage
```zsh
vault write database/roles/rem-staging-role \
    db_name="remstaging" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        ALTER ROLE \"{{name}}\" SUPERUSER;" \
    default_ttl="1h" \
    max_ttl="24h"
```
