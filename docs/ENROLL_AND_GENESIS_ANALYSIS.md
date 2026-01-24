# Analysis: enroll-crypto and generate-genesis-block vs test-network

## Reference: fabric-test/fabric-samples/test-network

- **network.sh** – `createOrgs()` with `CRYPTO="Certificate Authorities"`: brings up CAs, then `. organizations/fabric-ca/registerEnroll.sh` → `createOrg1`, `createOrg2`, `createOrderer`
- **organizations/fabric-ca/registerEnroll.sh** – `createOrderer()`:
  1. Enroll "CA admin" (admin:adminpw) to `.../ordererOrganizations/example.com` with `FABRIC_CA_CLIENT_HOME` set; **no -M** → writes to `.../example.com/msp`
  2. **Uses `ca-cert.pem`** for `--tls.certfiles` (from `organizations/fabric-ca/ordererOrg/ca-cert.pem`)
  3. For each orderer: **register with no `-u`** (uses enrolled CA admin from `FABRIC_CA_CLIENT_HOME`), then enroll MSP, enroll TLS, copy `tlscacerts/*`→`ca.crt`, `signcerts/*`→`server.crt`, `keystore/*`→`server.key`
  4. After all orderers: register `ordererAdmin`, enroll `Admin@example.com`

- **test-network runs `fabric-ca-client` on the host** with `localhost:7054` / `localhost:8054` / `localhost:9054` (each CA has its own host port in compose-ca). **We run `fabric-ca-client` in Docker** and use `ca-orderer:7054` etc. on the container network.

- **configtx/configtx.yaml**: `ClientTLSCert` and `ServerTLSCert` point to  
  `../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt`  
  Paths are relative to the config file. `generate-genesis-block.ps1` mounts `configtx`→`/etc/hyperledger/configtx` and `organizations`→`/etc/hyperledger/organizations`, so `../organizations` resolves correctly.

---

## Root cause of `server.crt: no such file or directory`

1. **configtxgen** reads `../organizations/.../tls/server.crt` from the mounted `organizations` dir.
2. **server.crt** is produced only when the **orderer TLS enroll** succeeds and we copy `signcerts/*` → `server.crt`.
3. Orderer TLS enroll was failing with **Error Code: 20 - Authentication failure**:
   - Either `orderer` was not registered, or
   - It was registered earlier with a different secret (e.g. from a previous run or different script).
4. **tls/** had `ca.crt`, `server.key`, `keystore/` but **no signcerts** → no `server.crt`. `ca.crt` came from our fallback; `server.key` from a partial TLS enroll (key/CSR generated, CA rejected so no signcerts).

---

## Differences we had vs test-network (now addressed in enroll-crypto.ps1)

| Area | test-network | Our script (before) | Change |
|------|--------------|---------------------|--------|
| **--tls.certfiles for orderer** | `ca-cert.pem` | `tls-cert.pem` | Use `ca-cert.pem` when present; fallback to `tls-cert.pem`. |
| **CA admin for register** | Enroll admin to `.../example.com/msp`, then **register with no `-u`** (uses identity from `FABRIC_CA_CLIENT_HOME`) | Register with `-u "https://admin:adminpw@ca-orderer:7054"` | Enroll CA admin to `.../example.com/msp` first; then `register` with **no `-u`** and `FABRIC_CA_CLIENT_HOME=.../example.com`. |
| **Order of ops** | CA admin → register orderer → enroll orderer MSP → enroll orderer TLS → copy → register ordererAdmin → enroll Admin@example.com | CA admin (to users/Admin) → register (with -u) → enroll MSP → enroll TLS → copy; no ordererAdmin | Align order: CA admin to org msp → register orderer (no -u) → enroll MSP/TLS → copy → register ordererAdmin → enroll Admin@example.com. |
| **Where fabric-ca-client runs** | Host (`localhost:9xxx`) | Docker (`ca-orderer:7054` on `network_landregistry`) | Unchanged; we keep Docker. |

---

## generate-genesis-block.ps1

- Mounts: `configtx` → `/etc/hyperledger/configtx`, `organizations` → `/etc/hyperledger/organizations`.
- `FABRIC_CFG_PATH=/etc/hyperledger/configtx`, `-configPath /etc/hyperledger/configtx`.
- `../organizations` in configtx is relative to the config file → `/etc/hyperledger/organizations`. No change needed.

---

## Clean re-run (recommended after script changes)

To avoid a stale `orderer` identity in the orderer CA DB (wrong or old secret):

```powershell
# 1) Remove generated crypto and orderer CA persistence
Remove-Item -Recurse -Force network\organizations\peerOrganizations -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force network\organizations\ordererOrganizations -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force network\organizations\fabric-ca\ordererOrg -ErrorAction SilentlyContinue

# 2) Restart orderer CA so it re-initializes (compose project name may vary)
cd network
docker-compose stop ca-orderer
docker-compose up -d ca-orderer
cd ..

# 3) Wait for CA to be ready, then enroll
.\scripts\enroll-crypto.ps1

# 4) Generate genesis
.\scripts\generate-genesis-block.ps1
```

Do **not** delete `network\organizations\fabric-ca\{landreg,subregistrar,court}` if you want to keep those CA DBs; only `ordererOrg` must be removed to reset the orderer identity.
