# luci-app-sbproxy v2 starter

This second-step starter remembers the first-step pitfalls:

- fixes init/script permissions with uci-defaults
- fixes rpcd ACL for running subscription importer
- adds DNS page
- makes main node selectable from imported nodes
- shows basic service status/log

## Still intentionally incomplete

- no full route rules UI yet
- no ruleset UI yet
- no full VMess / JSON subscription parser yet
- no server mode yet

## Build

Put under OpenWrt SDK package directory as `luci-app-sbproxy`, then:

```sh
make defconfig
make package/luci-app-sbproxy/compile V=s
```
