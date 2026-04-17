# SpotiRide

> **English version below** — scroll down or [click here](#spotiride-english)

Aplikacja na licznik rowerowy **Garmin Edge 530**, która pokazuje na ekranie co aktualnie gra na Spotify i pozwala sterować muzyką. Jednocześnie wyświetla dane treningowe (prędkość, dystans, czas, tętno, temperaturę itd.) i nagrywa aktywność do Garmin Connect.

---

## Co potrafi ta aplikacja?

**Spotify:**
- Pokazuje tytuł utworu i artystę
- Pasek postępu utworu
- Polubienie utworu przyciskiem LAP
- Play/pauza, następny/poprzedni utwór
- Losowe odtwarzanie i powtarzanie

**Dane jazdy (2 ekrany):**
- Prędkość, średnia prędkość
- Dystans, czas jazdy, stoper
- Tętno, temperatura, godzina
- Zachód słońca, bateria

**Nagrywanie aktywności:**
- Start/pauza przyciskiem START
- Auto-pauza przy niskiej prędkości
- Zapis do Garmin Connect

**Inne:**
- Tryb jasny/ciemny (auto lub ręczny)
- Język polski i angielski
- Przewijanie długich tytułów utworów

---

## Co jest potrzebne?

1. **Garmin Edge 530** (licznik rowerowy)
2. **Telefon** z aplikacją **Garmin Connect** (Android lub iPhone)
3. **Spotify Premium** (darmowe konto nie wystarczy)
4. **Komputer** z kablem USB do podłączenia Garmina
5. Telefon musi być połączony z Garminem przez Bluetooth i mieć dostęp do internetu

---

## Jak pobrać projekt z GitHuba?

GitHub to strona internetowa, na której programiści udostępniają swój kod. Nie musisz znać się na programowaniu — wystarczy pobrać pliki na komputer.

**Sposób 1: Pobierz jako ZIP (najłatwiejszy)**

1. Wejdź na stronę projektu: **https://github.com/bobok7/SpotiRide**
2. Kliknij zielony przycisk **"Code"**
3. Kliknij **"Download ZIP"**
4. Rozpakuj pobrany plik ZIP w dowolnym miejscu na komputerze (np. na Pulpicie)
5. Gotowe — masz cały projekt na swoim komputerze

**Sposób 2: Za pomocą Git (dla zaawansowanych)**

Git to program do zarządzania wersjami kodu. Jeśli chcesz go użyć:

1. Zainstaluj Git ze strony: **https://git-scm.com/downloads**
2. Otwórz terminal (wiersz poleceń) i wpisz:

```
git clone https://github.com/bobok7/SpotiRide.git
```

To polecenie pobierze cały projekt do folderu `SpotiRide` na Twoim komputerze.

**Słowniczek Git (jeśli spotkasz te pojęcia):**
- **Repository (repo)** — folder z projektem przechowywany na GitHubie
- **Clone** — pobranie kopii projektu z GitHuba na swój komputer
- **Commit** — zapisanie zmian w historii projektu (jak „zapisz" w grze)
- **Push** — wysłanie swoich zmian z komputera na GitHuba
- **Pull** — pobranie najnowszych zmian z GitHuba na swój komputer
- **Branch** — oddzielna wersja projektu (np. do testowania nowych funkcji)
- **Fork** — skopiowanie czyjegoś projektu na swoje konto GitHub

Jeśli nie planujesz modyfikować kodu ani udostępniać zmian — **Sposób 1 (ZIP) całkowicie wystarczy**.

---

## Jak zainstalować? (krok po kroku)

### KROK 1: Utwórz aplikację na stronie Spotify Developer

Każdy użytkownik musi utworzyć własną „aplikację" na stronie Spotify. To jest darmowe i trwa 2 minuty. Nie jest to prawdziwa aplikacja — to tylko sposób w jaki Spotify daje dostęp do Twojego konta.

1. Otwórz przeglądarkę i wejdź na stronę: **https://developer.spotify.com/dashboard**
2. Zaloguj się swoim kontem Spotify (tym samym co słuchasz muzyki)
3. Kliknij zielony przycisk **"Create App"**
4. Wypełnij formularz:
   - **App name**: wpisz `SpotiRide` (lub dowolną nazwę)
   - **App description**: wpisz `Garmin` (lub dowolny opis)
   - **Website**: zostaw puste
   - **Redirect URI**: wpisz dokładnie ten adres (skopiuj i wklej):
     ```
     https://garmin-spotify-callback.invalid/callback
     ```
     i kliknij **"Add"** obok
   - **APIs used**: zaznacz ptaszkiem **Web API**
   - Zaznacz zgodę na warunki użytkowania
5. Kliknij **"Save"**

Teraz musisz dodać swoje konto jako użytkownika testowego (nowe aplikacje Spotify są w trybie testowym):

6. Na stronie swojej aplikacji kliknij zakładkę **"Settings"**
7. Następnie przejdź do zakładki **"User Management"**
8. Wpisz swój **adres email** (ten sam co w Spotify) i kliknij **"Add user"**

Na koniec skopiuj swoje dane:

9. Wróć do zakładki **"Settings"**
10. Zobaczysz **Client ID** — skopiuj go (będziesz go potrzebował)
11. Kliknij **"View client secret"** — skopiuj też **Client Secret**

Zapisz oba gdzieś tymczasowo (np. w Notatniku).

---

### KROK 2: Uzyskaj Refresh Token

Refresh Token to specjalny klucz, który pozwala aplikacji na Garminie łączyć się z Twoim kontem Spotify. Uzyskasz go za pomocą strony dołączonej do projektu.

1. W folderze projektu znajdź folder **oauth-helper**
2. Otwórz plik **index.html** (dwuklik na plik — otworzy się w przeglądarce)
3. Wklej **Client ID** i **Client Secret** z Kroku 1
4. Kliknij zielony przycisk **"Zaloguj się do Spotify"**
5. Otworzy się nowa karta — zaloguj się do Spotify i kliknij **"Zgadzam się"**
6. Po zalogowaniu przeglądarka pokaże błąd (np. „nie można otworzyć strony") — **to jest normalne!**
7. Kliknij na **pasek adresu** w przeglądarce (tam gdzie jest długi adres zaczynający się od `https://garmin-spotify-callback...`)
8. Zaznacz **cały adres** (Ctrl+A) i **skopiuj** go (Ctrl+C)
9. Wróć do karty ze stroną SpotiRide
10. **Wklej** skopiowany adres w pole tekstowe (Ctrl+V)
11. Kliknij **"Pobierz Refresh Token"**
12. Pojawi się Twój **Refresh Token** — kliknij **"Kopiuj"**

Zapisz Refresh Token — będziesz go potrzebował w następnym kroku.

---

### KROK 3: Wpisz swoje dane do kodu aplikacji

Aby aplikacja mogła łączyć się z Twoim kontem Spotify, musisz wpisać swoje dane do pliku z kodem. Nie martw się — wystarczy zmienić 3 linijki tekstu.

1. W folderze projektu otwórz folder **SpotiRide**, potem **source**
2. Otwórz plik **TokenManager.mc** w dowolnym edytorze tekstu (np. Notatnik)
3. Na początku pliku znajdziesz 3 linijki:

```
var gClientId = "TWOJ_CLIENT_ID";
var gClientSecret = "TWOJ_CLIENT_SECRET";
```

oraz dalej w klasie:

```
var hardcodedRefreshToken = "TWOJ_REFRESH_TOKEN";
```

4. Zamień tekst w cudzysłowach na swoje dane:
   - Zamiast `TWOJ_CLIENT_ID` wklej swój **Client ID** z Kroku 1
   - Zamiast `TWOJ_CLIENT_SECRET` wklej swój **Client Secret** z Kroku 1
   - Zamiast `TWOJ_REFRESH_TOKEN` wklej swój **Refresh Token** z Kroku 2
5. Zapisz plik

---

### KROK 4: Zainstaluj potrzebne narzędzia do budowania

Aby zamienić kod na plik, który można wgrać na Garmina, potrzebujesz dwóch rzeczy:

**A) Visual Studio Code** (darmowy edytor kodu):
1. Wejdź na **https://code.visualstudio.com**
2. Pobierz i zainstaluj

**B) Connect IQ SDK** (narzędzia Garmina do budowania aplikacji):
1. Wejdź na **https://developer.garmin.com/connect-iq/sdk/**
2. Pobierz **SDK Manager** i zainstaluj
3. W SDK Manager pobierz najnowszą wersję SDK
4. W SDK Manager pobierz też urządzenie **Edge 530**

**C) Rozszerzenie Monkey C do VS Code:**
1. Otwórz Visual Studio Code
2. Kliknij ikonę kwadracików po lewej stronie (Extensions / Rozszerzenia)
3. Wyszukaj **"Monkey C"** i zainstaluj rozszerzenie od Garmin

**D) Klucz developerski:**
1. W VS Code naciśnij **Ctrl+Shift+P**
2. Wpisz **"Monkey C: Generate Developer Key"**
3. Wybierz lokalizację do zapisania klucza

---

### KROK 5: Zbuduj aplikację

1. Otwórz **Visual Studio Code**
2. Kliknij **File > Open Folder** i wybierz folder **SpotiRide** (ten z plikiem monkey.jungle)
3. Naciśnij **Ctrl+Shift+P** (otworzy się pasek poleceń)
4. Wpisz **"Monkey C: Build for Device"** i wybierz to polecenie
5. Wybierz urządzenie **edge530**
6. Poczekaj aż budowanie się zakończy — pojawi się komunikat "BUILD SUCCESSFUL"
7. W folderze **bin** pojawi się plik **SpotiRide.prg** — to jest Twoja gotowa aplikacja

---

### KROK 6: Wgraj aplikację na Garmin Edge 530

1. Połącz **Garmin Edge 530** z komputerem **kablem USB**
2. Garmin pojawi się jako dysk (np. dysk F: lub E:)
3. Otwórz ten dysk i wejdź do folderu **GARMIN**, potem **APPS**
4. Skopiuj plik **SpotiRide.prg** do tego folderu (**GARMIN/APPS/**)
5. Bezpiecznie odłącz Garmina (kliknij „Bezpieczne usuwanie sprzętowe" w systemie)
6. Garmin się zrestartuje

---

### KROK 7: Uruchom aplikację

1. Na Garmin Edge 530 naciśnij przycisk **START** (domyślnie włącza jazdę)
2. Zamiast tego przejdź do **Menu > Aplikacje Connect IQ > SpotiRide**
3. Włącz odtwarzanie muzyki w **Spotify na telefonie**
4. Po kilku sekundach na ekranie Garmina pojawi się tytuł utworu

---

## Jak używać? (przyciski na Garminie)

| Przycisk na Garminie | Co robi w SpotiRide |
| -------------------- | ------------------- |
| **START** (prawy górny) | Rozpoczyna lub pauzuje nagrywanie jazdy |
| **LAP** (prawy dolny) | Lubi aktualny utwór na Spotify (dodaje do polubionych) |
| **Środkowy przycisk** | Otwiera menu z ustawieniami i sterowaniem muzyką |
| **UP** (lewy górny) | Przełącza na poprzedni ekran |
| **DOWN** (lewy dolny) | Przełącza na następny ekran |
| **BACK** (lewy środkowy) | Zapisuje aktywność i zamyka aplikację |

---

## Co jest w menu? (środkowy przycisk)

**Sterowanie Spotify:**
- Play / Pause — wznawia lub pauzuje muzykę
- Następny utwór / Poprzedni utwór
- Losowe odtwarzanie (shuffle) — włącz/wyłącz
- Powtarzanie — wyłączone / playlista / jeden utwór

**Ustawienia:**
- Tryb ekranu — automatyczny (ciemny wieczorem) / jasny / ciemny
- Odświeżanie Spotify — jak często sprawdza co gra (5/10/15/30 sekund)
- Przewijanie — włącza przewijanie długich tytułów utworów
- Temperatura — Celsjusz lub Fahrenheit
- Auto pauza — automatycznie pauzuje nagrywanie gdy się zatrzymasz (próg prędkości 2-6 km/h)
- Opóźnienie pauzy — ile sekund poniżej progu zanim włączy się auto pauza (brak / 3s / 5s / 10s)
- Język — polski lub angielski

**Inne:**
- Zaloguj Spotify — logowanie przez telefon (uwaga: na Edge 530 ta opcja może nie działać — w takim przypadku użyj oauth-helper, patrz Krok 2)
- Odśwież token — ręczne odświeżenie połączenia
- Status Spotify — sprawdza czy połączenie działa
- O aplikacji — ekran z informacjami o autorze i kodem QR do GitHuba
- Zapisz aktywność — zapisuje jazdę do Garmin Connect
- Odrzuć aktywność — kasuje jazdę bez zapisywania

---

## Najczęściej zadawane pytania

**Dlaczego potrzebuję Spotify Premium?**
Darmowe konto Spotify nie pozwala innym aplikacjom sprawdzać co aktualnie gra. To ograniczenie Spotify, nie tej aplikacji.

**Czy to jest bezpieczne?**
Tak. Aplikacja łączy się bezpośrednio z Twoim kontem Spotify. Twoje dane (Client ID, Secret, Token) są tylko na Twoim Garminie i w Twoim kodzie — nigdzie nie są wysyłane.

**Utwór się nie wyświetla / pisze „Brak muzyki"**
- Sprawdź czy Spotify gra na telefonie
- Sprawdź czy telefon jest połączony z Garminem przez Bluetooth
- Poczekaj kilka sekund — informacja odświeża się co 5-30 sekund
- Wejdź w menu > „Status Spotify" — powinno pisać „Połączono"

**Token wygasł / nie działa**

- Wejdź w menu > „Odśwież token"
- Jeśli nie pomaga — powtórz Krok 2 (uzyskaj nowy Refresh Token) i Krok 3
- Opcja „Zaloguj Spotify" w menu może nie działać na Edge 530 — wtedy jedyną metodą jest oauth-helper + przebudowanie aplikacji

---

## Struktura projektu (dla zaawansowanych)

```
SpotiRide/
├── manifest.xml              # Konfiguracja aplikacji Garmin
├── monkey.jungle             # Plik budowania
├── source/
│   ├── SpotifyApp.mc         # Punkt wejścia aplikacji
│   ├── SpotifyView.mc        # Ekrany — Spotify + dane jazdy
│   ├── SpotifyDelegate.mc    # Obsługa przycisków i menu
│   ├── SpotifyApi.mc         # Komunikacja z API Spotify
│   ├── TokenManager.mc       # Logowanie i tokeny Spotify
│   └── AboutView.mc          # Ekran „O aplikacji" z kodem QR
├── resources/
│   ├── drawables/            # Ikona aplikacji + kod QR
│   ├── strings/strings.xml   # Nazwa aplikacji
│   ├── properties.xml        # Definicje ustawień aplikacji
│   └── settings/settings.xml # Ustawienia w Garmin Connect Mobile
oauth-helper/
    └── index.html            # Strona do uzyskania tokenu Spotify
CLAUDE.md                     # Instrukcje dla Claude Code (AI)
```

## Licencja

MIT — możesz używać, zmieniać i udostępniać ten kod za darmo.

---
---

# SpotiRide (English)

A watch-app for the **Garmin Edge 530** bike computer that shows the currently playing Spotify track on screen and lets you control playback. It also displays cycling data (speed, distance, time, heart rate, temperature, etc.) and records activities to Garmin Connect.

---

## Features

**Spotify:**
- Track title and artist display
- Track progress bar
- Like a track with LAP button
- Play/pause, next/previous track
- Shuffle and repeat control

**Cycling data (2 screens):**
- Speed, average speed
- Distance, ride time, timer
- Heart rate, temperature, time of day
- Sunset time, battery level

**Activity recording:**
- Start/pause with START button
- Auto-pause at low speed
- Save to Garmin Connect

**Other:**
- Light/dark mode (auto or manual)
- Polish and English language
- Scrolling long track titles

---

## Requirements

1. **Garmin Edge 530** (bike computer)
2. **Phone** with the **Garmin Connect** app (Android or iPhone)
3. **Spotify Premium** (free accounts won't work)
4. **Computer** with a USB cable to connect the Garmin
5. Phone must be connected to Garmin via Bluetooth and have internet access

---

## How to download the project from GitHub?

GitHub is a website where programmers share their code. You don't need to know programming — just download the files to your computer.

**Option 1: Download as ZIP (easiest)**

1. Go to the project page: **https://github.com/bobok7/SpotiRide**
2. Click the green **"Code"** button
3. Click **"Download ZIP"**
4. Unzip the downloaded file anywhere on your computer (e.g. on your Desktop)
5. Done — you have the entire project on your computer

**Option 2: Using Git (for advanced users)**

Git is a version control program. If you want to use it:

1. Install Git from: **https://git-scm.com/downloads**
2. Open a terminal (command prompt) and type:

```
git clone https://github.com/bobok7/SpotiRide.git
```

This command will download the entire project into a `SpotiRide` folder on your computer.

**Git glossary (if you come across these terms):**
- **Repository (repo)** — a project folder stored on GitHub
- **Clone** — downloading a copy of a project from GitHub to your computer
- **Commit** — saving changes to the project history (like "save game")
- **Push** — sending your changes from your computer to GitHub
- **Pull** — downloading the latest changes from GitHub to your computer
- **Branch** — a separate version of the project (e.g. for testing new features)
- **Fork** — copying someone's project to your own GitHub account

If you don't plan to modify the code or share changes — **Option 1 (ZIP) is all you need**.

---

## Installation (step by step)

### STEP 1: Create an app on the Spotify Developer website

Every user needs to create their own "app" on the Spotify website. It's free and takes 2 minutes. It's not a real app — it's just how Spotify gives access to your account.

1. Open your browser and go to: **https://developer.spotify.com/dashboard**
2. Log in with your Spotify account (the same one you listen to music with)
3. Click the green **"Create App"** button
4. Fill in the form:
   - **App name**: type `SpotiRide` (or any name)
   - **App description**: type `Garmin` (or any description)
   - **Website**: leave empty
   - **Redirect URI**: type exactly this address (copy and paste):
     ```
     https://garmin-spotify-callback.invalid/callback
     ```
     and click **"Add"** next to it
   - **APIs used**: check **Web API**
   - Accept the terms of service
5. Click **"Save"**

Now you need to add your account as a test user (new Spotify apps are in test mode):

6. On your app's page, click the **"Settings"** tab
7. Then go to the **"User Management"** tab
8. Enter your **email address** (same as Spotify) and click **"Add user"**

Finally, copy your credentials:

9. Go back to the **"Settings"** tab
10. You'll see **Client ID** — copy it (you'll need it later)
11. Click **"View client secret"** — copy the **Client Secret** too

Save both somewhere temporarily (e.g. in Notepad).

---

### STEP 2: Get a Refresh Token

A Refresh Token is a special key that lets the app on your Garmin connect to your Spotify account. You'll get it using a page included in the project.

1. In the project folder, find the **oauth-helper** folder
2. Open the **index.html** file (double-click it — it will open in your browser)
3. Paste the **Client ID** and **Client Secret** from Step 1
4. Click the green **"Zaloguj sie do Spotify"** button (it means "Log in to Spotify")
5. A new tab will open — log in to Spotify and click **"Agree"**
6. After logging in, the browser will show an error (e.g. "can't open page") — **this is normal!**
7. Click on the **address bar** in your browser (where the long address starts with `https://garmin-spotify-callback...`)
8. Select the **entire address** (Ctrl+A) and **copy** it (Ctrl+C)
9. Go back to the SpotiRide tab
10. **Paste** the copied address into the text field (Ctrl+V)
11. Click **"Pobierz Refresh Token"** (it means "Get Refresh Token")
12. Your **Refresh Token** will appear — click **"Kopiuj"** (Copy)

Save the Refresh Token — you'll need it in the next step.

---

### STEP 3: Enter your credentials into the app code

For the app to connect to your Spotify account, you need to enter your credentials into a code file. Don't worry — you just need to change 3 lines of text.

1. In the project folder, open the **SpotiRide** folder, then **source**
2. Open the file **TokenManager.mc** in any text editor (e.g. Notepad)
3. At the top of the file you'll find these lines:

```
var gClientId = "TWOJ_CLIENT_ID";
var gClientSecret = "TWOJ_CLIENT_SECRET";
```

and further down in the class:

```
var hardcodedRefreshToken = "TWOJ_REFRESH_TOKEN";
```

4. Replace the text inside the quotes with your own data:
   - Replace `TWOJ_CLIENT_ID` with your **Client ID** from Step 1
   - Replace `TWOJ_CLIENT_SECRET` with your **Client Secret** from Step 1
   - Replace `TWOJ_REFRESH_TOKEN` with your **Refresh Token** from Step 2
5. Save the file

---

### STEP 4: Install the build tools

To turn the code into a file you can load onto your Garmin, you need a few things:

**A) Visual Studio Code** (free code editor):
1. Go to **https://code.visualstudio.com**
2. Download and install it

**B) Connect IQ SDK** (Garmin's tools for building apps):
1. Go to **https://developer.garmin.com/connect-iq/sdk/**
2. Download the **SDK Manager** and install it
3. In SDK Manager, download the latest SDK version
4. In SDK Manager, also download the **Edge 530** device

**C) Monkey C extension for VS Code:**
1. Open Visual Studio Code
2. Click the square icon on the left side (Extensions)
3. Search for **"Monkey C"** and install the extension by Garmin

**D) Developer key:**
1. In VS Code, press **Ctrl+Shift+P**
2. Type **"Monkey C: Generate Developer Key"**
3. Choose a location to save the key

---

### STEP 5: Build the app

1. Open **Visual Studio Code**
2. Click **File > Open Folder** and select the **SpotiRide** folder (the one with the monkey.jungle file)
3. Press **Ctrl+Shift+P** (the command palette will open)
4. Type **"Monkey C: Build for Device"** and select that command
5. Choose **edge530** as the device
6. Wait for the build to finish — you'll see "BUILD SUCCESSFUL"
7. In the **bin** folder you'll find **SpotiRide.prg** — that's your ready app

---

### STEP 6: Upload the app to Garmin Edge 530

1. Connect your **Garmin Edge 530** to your computer with a **USB cable**
2. The Garmin will appear as a drive (e.g. drive F: or E:)
3. Open that drive and go to the **GARMIN** folder, then **APPS**
4. Copy the **SpotiRide.prg** file into that folder (**GARMIN/APPS/**)
5. Safely eject the Garmin (click "Safely Remove Hardware" in your system tray)
6. The Garmin will restart

---

### STEP 7: Launch the app

1. On your Garmin Edge 530, press the **START** button
2. Instead of starting a ride, go to **Menu > Connect IQ Apps > SpotiRide**
3. Start playing music in **Spotify on your phone**
4. After a few seconds, the track title will appear on the Garmin screen

---

## How to use (buttons on the Garmin)

| Button on Garmin | What it does in SpotiRide |
| ---------------- | ------------------------- |
| **START** (top right) | Starts or pauses activity recording |
| **LAP** (bottom right) | Likes the current track on Spotify |
| **Middle button** | Opens the menu with settings and music controls |
| **UP** (top left) | Switches to the previous screen |
| **DOWN** (bottom left) | Switches to the next screen |
| **BACK** (middle left) | Saves activity and exits the app |

---

## What's in the menu? (middle button)

**Spotify controls:**
- Play / Pause — resume or pause music
- Next track / Previous track
- Shuffle — on/off
- Repeat — off / playlist / single track

**Settings:**
- Screen mode — auto (dark in the evening) / light / dark
- Refresh rate — how often it checks what's playing (5/10/15/30 seconds)
- Scrolling — enables scrolling of long track titles
- Temperature — Celsius or Fahrenheit
- Auto pause — automatically pauses recording when you stop (speed threshold 2-6 km/h)
- Pause delay — how many seconds below threshold before auto pause kicks in (none / 3s / 5s / 10s)
- Language — Polish or English

**Other:**
- Login Spotify — login via phone (note: on Edge 530 this option may not work — in that case use oauth-helper, see Step 2)
- Refresh token — manually refresh the connection
- Spotify status — check if the connection works
- About — screen with author info and a QR code to GitHub
- Save activity — saves the ride to Garmin Connect
- Discard activity — deletes the ride without saving

---

## FAQ

**Why do I need Spotify Premium?**
Free Spotify accounts don't allow other apps to check what's currently playing. This is a Spotify limitation, not this app's.

**Is this safe?**
Yes. The app connects directly to your Spotify account. Your credentials (Client ID, Secret, Token) are only on your Garmin and in your code — they are not sent anywhere else.

**Track doesn't show / says "No music"**
- Make sure Spotify is playing on your phone
- Make sure your phone is connected to the Garmin via Bluetooth
- Wait a few seconds — info refreshes every 5-30 seconds
- Go to menu > "Spotify status" — it should say "Connected"

**Token expired / not working**

- Go to menu > "Refresh token"
- If that doesn't help — repeat Step 2 (get a new Refresh Token) and Step 3
- The "Login Spotify" menu option may not work on Edge 530 — in that case the only method is oauth-helper + rebuilding the app

---

## License

MIT — you can use, modify, and share this code for free.
