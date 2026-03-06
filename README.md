# RobJob Mobile

Flutter mobilni aplikace pro platformu RobJob, umoznujici kandidatum vytvaret a spravovat sve Video CV.

## Technologie

- **Flutter** (Dart SDK >=3.0.0)
- **Material Design 3**
- **Laravel** backend (PHP)

### Hlavni zavislosti

| Balicek | Ucel |
|---------|------|
| dio | HTTP klient pro komunikaci s API |
| go_router | Deklarativni routovani a navigace |
| flutter_secure_storage | Bezpecne ukladani tokenu |
| image_picker | Vyber videa ze zarizeni |
| video_player + chewie | Prehravani videi |
| permission_handler | Sprava opravneni zarizeni |

## Funkce

- **Prihlaseni** – email/heslo autentizace s Bearer tokeny a bezpecnym ulozistem
- **Nahrani Video CV** – nahrani videa z kamery nebo galerie (max 10 minut)
- **Sledovani zpracovani** – real-time progress uploadu a stav encodovani videa
- **Prehravani videa** – HLS prehravani hotoveho Video CV

## Struktura projektu

```
lib/
├── main.dart                  # Vstupni bod aplikace
├── app/
│   └── app.dart               # Root widget, nastaveni routeru
├── core/
│   ├── api_client.dart        # Dio HTTP klient s auth interceptorem
│   └── storage_service.dart   # Bezpecne ukladani tokenu
└── features/
    ├── auth/
    │   ├── login_screen.dart
    │   └── auth_service.dart
    └── candidate/
        ├── video_cv_screen.dart
        ├── video_upload_widget.dart
        ├── video_cv_player.dart
        └── candidate_service.dart
```

## Spusteni

```bash
# Instalace zavislosti
flutter pub get

# Spusteni v debug modu
flutter run

# Build pro Android
flutter build apk

# Build pro iOS
flutter build ios
```

## API

Aplikace komunikuje s backendem na `https://test-api.robjob.cz/api/`.

Hlavni endpointy:

- `POST /v1/auth/mobile/login` – prihlaseni
- `GET /v1/me/show` – aktualni uzivatel
- `GET /v1/candidate_profiles/show` – profil kandidata
- `POST /v1/candidate_profiles/update` – upload Video CV
- `POST /v1/auth/logout` – odhlaseni
