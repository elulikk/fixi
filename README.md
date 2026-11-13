# Fixi

Marketplace de servicio técnico a domicilio: los clientes publican lo que necesitan, los técnicos ofertan con precio,
tiempo y reputación, y el cliente elige la opción que más le conviene y paga dentro de la app. Fixi cobra 5% de comisión al técnico.

| Carpeta   | Contenido |
|-----------|-----------|
| `server/` | Servidor (API + tiempo real) que corre en una PC |
| `app/`    | App Android (Flutter) para clientes y técnicos |
| `admin/`  | Panel web de administración |
| `docs/`   | Arquitectura, diseño, plan comercial y legal |

Empezá por [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).

## Arranque rápido

1. Servidor (en la PC): `cd server && npm install && npm run dev` → queda en `http://localhost:4000` y muestra la dirección de red para el celular.
2. Panel de administración: abrí `http://localhost:4000/admin/`.
3. App: instalá el APK (`cd app && flutter build apk --release`, sale en `app/build/app/outputs/flutter-apk/app-release.apk`), tocá "Configurar servidor" y cargá la dirección de red de la PC.

Las cuentas de demo están en [server/README.md](server/README.md). El plan comercial y los borradores legales están en [docs/comercial/](docs/comercial/README.md).
