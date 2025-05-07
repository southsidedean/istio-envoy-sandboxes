# orders-app
## The Orders app, in single and multi-cluster formats. Based on the Colorwheel app.
### Tom Dean | Buoyant

Last updated 4/11/24

Repository contents:

```bash
.
├── README.md
├── multi-cluster
│   ├── orders-hpa
│   │   ├── orders
│   │   │   ├── kustomization.yaml
│   │   │   ├── ns.yaml
│   │   │   ├── orders-central.yaml
│   │   │   ├── orders-east.yaml
│   │   │   └── orders-west.yaml
│   │   └── warehouse
│   │       ├── kustomization.yaml
│   │       ├── ns.yaml
│   │       ├── server.yaml
│   │       ├── warehouse-boston.yaml
│   │       ├── warehouse-chicago.yaml
│   │       └── warehouse-oakland.yaml
│   └── orders-nohpa
│       ├── orders
│       │   ├── kustomization.yaml
│       │   ├── ns.yaml
│       │   ├── orders-central.yaml
│       │   ├── orders-east.yaml
│       │   └── orders-west.yaml
│       └── warehouse
│           ├── kustomization.yaml
│           ├── ns.yaml
│           ├── server.yaml
│           ├── warehouse-boston.yaml
│           ├── warehouse-chicago.yaml
│           └── warehouse-oakland.yaml
└── single-cluster
    ├── orders-hpa
    │   ├── kustomization.yaml
    │   ├── ns.yaml
    │   ├── orders-central.yaml
    │   ├── orders-east.yaml
    │   ├── orders-west.yaml
    │   ├── server.yaml
    │   ├── warehouse-boston.yaml
    │   ├── warehouse-chicago.yaml
    │   └── warehouse-oakland.yaml
    └── orders-nohpa
        ├── kustomization.yaml
        ├── ns.yaml
        ├── orders-central.yaml
        ├── orders-east.yaml
        ├── orders-west.yaml
        ├── server.yaml
        ├── warehouse-boston.yaml
        ├── warehouse-chicago.yaml
        └── warehouse-oakland.yaml
```
