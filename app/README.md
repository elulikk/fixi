# Fixi — App Android (Flutter)

App móvil de Fixi, el marketplace de servicio técnico a domicilio. Una sola app con dos modos (cliente y técnico). Habla con el servidor de `server/` según el contrato de `docs/ARQUITECTURA.md`.

- Flutter 3.19 / Dart 3.3, Material 3, tema claro y oscuro.
- Estado con Riverpod, navegación con go_router, red con Dio, tiempo real con `web_socket_channel`, mapas con `flutter_map` (tiles de OpenStreetMap, sin claves).
- No usa Firebase ni ningún servicio que requiera API keys.

## Requisitos

- Flutter 3.19.0 (no hace falta actualizar).
- Android SDK en `%LOCALAPPDATA%\Android\Sdk` (platform 34/35, build-tools 34).
- JDK 17 o superior. El `java` del PATH puede ser Java 8, que no sirve: usá el JBR de Android Studio.

```powershell
flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
# o, solo para una sesión:
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

El proyecto ya está ajustado para ese JDK: Gradle 8.5, AGP 8.2.2 y Kotlin 1.9.22 (`android/gradle/wrapper/gradle-wrapper.properties` y `android/settings.gradle`).

## Correr en desarrollo

```powershell
cd app
flutter pub get
flutter run            # emulador o dispositivo conectado
```

Con el servidor levantado (`npm run dev` en `server/`) y el emulador de Android, la app funciona sin configurar nada: la URL por defecto es `http://10.0.2.2:4000` (el `localhost` de la PC visto desde el emulador).

## Configurar la URL del servidor

Desde la app: pantalla de login (ícono de servidor, arriba a la derecha) o Perfil > Ajustes > Servidor. Ahí se edita la URL base, se prueba con **Probar conexión** (llama a `/health`) y se guarda (queda persistida).

| Dónde corre la app | URL |
|---|---|
| Emulador de Android | `http://10.0.2.2:4000` (default) |
| Celular real en la misma red WiFi | `http://<IP-de-la-PC>:4000` (ej. `http://192.168.0.15:4000`) |

En un celular real, el firewall de Windows tiene que permitir el puerto 4000. La app permite tráfico http (`usesCleartextTraffic`) porque el server de demo corre en LAN sin HTTPS; en producción conviene usar HTTPS y quitar esa opción de `android/app/src/main/AndroidManifest.xml`.

El valor por defecto y las credenciales de demo están en `lib/core/config/constants.dart`.

## Cuentas de demo

Contraseña común: `fixi1234` (documentado en `server/README.md`).

- Cliente: `cliente@fixi.app`
- Técnico: `tecnico@fixi.app`

La pantalla de login tiene los botones **Demo cliente** y **Demo técnico**.

## Compilar el APK

```powershell
cd app
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter build apk --release
```

Resultado: `app/build/app/outputs/flutter-apk/app-release.apk`. La primera vez tarda varios minutos (descarga Gradle y dependencias).

Para instalarlo en un emulador o celular conectado:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
```

## Firmar para publicar

Por defecto el release se firma con la clave de debug (sirve para probar y repartir a mano, no para Play Store). Para firmar con tu clave:

1. Crear el keystore (una sola vez, guardalo y hacé backup):

   ```powershell
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore $env:USERPROFILE\fixi-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fixi
   ```

2. Crear `app/android/key.properties` (no se sube a git):

   ```properties
   storePassword=<tu contraseña>
   keyPassword=<tu contraseña>
   keyAlias=fixi
   storeFile=C:/Users/<vos>/fixi-release.jks
   ```

3. Compilar de nuevo. Si existe `key.properties`, `android/app/build.gradle` firma con esa clave automáticamente. Para Play Store usá `flutter build appbundle --release`.

Cambiá también el `applicationId` (`ar.fixi.fixi`) si publicás bajo otro nombre.

## Tests y análisis

```powershell
flutter analyze
flutter test
```

Los tests cubren el formato de dinero, el cálculo de comisión (5%), el parseo de modelos del contrato (ofertas, trabajos, necesidades), niveles y algunos widgets.

## Estructura

```
lib/
  main.dart, app.dart            arranque, router, listener global de eventos en tiempo real
  core/
    api/        ApiClient (token + errores {error:{code,message}}), RealtimeService (WebSocket con reconexión)
    config/     constantes (URL, credenciales demo, comisión)
    models/     modelos tipados con fromJson
    state/      providers Riverpod (ajustes, auth, ubicación, datos)
    theme/      tema Material 3 claro/oscuro
    util/       formato de dinero, distancias y tiempos
    widgets/    componentes comunes (avatar, insignias, esqueletos, estados vacíos/error)
  features/
    onboarding/ splash y onboarding
    auth/       login, registro, configuración de servidor
    client/     inicio, explorar, pedidos, publicar necesidad, comparador de ofertas, perfil público
    jobs/       pago, seguimiento con mapa, chat, calificación
    tech/       panel, oportunidades, ofertas, servicios, alta de perfil técnico, Mercado Pago
    profile/    perfil, edición, ajustes, ayuda, notificaciones
    shared/     shell con navegación, tarjetas y mapa
```

## Notas

- Fuentes: Plus Jakarta Sans e Inter se descargan en el primer uso con `google_fonts` (necesita internet la primera vez; sin conexión usa la fuente del sistema).
- Ubicación: si no hay permiso o GPS, se usa la dirección guardada del usuario o el Obelisco (-34.6037, -58.3816). Si el GPS queda a más de 200 km de la zona de servicio (p. ej. un emulador en California), también se ignora.
- Pago: el botón abre el `checkoutUrl` en el navegador; al volver, la app consulta el estado cada 3 s y por WebSocket (`job.updated`). Si el server devuelve un checkout con `localhost`, se reemplaza por el host configurado en la app.
- Mapa de servicios: el contrato no trae las coordenadas del técnico en los servicios, así que en la vista de mapa se ubican de forma aproximada según su distancia al usuario (si el server agrega `lat`/`lng` al servicio se usan directamente).
