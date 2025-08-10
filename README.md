# Grtoco 🚀

O descriere scurtă a proiectului. Acesta este un social media bazat pe grupuri, unde utilizatorii pot crea și se pot alătura comunităților, pot posta conținut (text, imagini, video), pot viziona live-uri și pot iniția apeluri de grup.

## Caracteristici Principale ✨

* **Autentificare securizată**: Creare cont, login, resetare parolă, cu opțiuni de autentificare socială (Google, Facebook).
* **Grupuri**: Utilizatorii pot crea grupuri publice sau secrete. Administratorii au funcții de moderare.
* **Feed personalizat**: Un feed unic ce afișează conținut doar din grupurile din care utilizatorul face parte.
* **Conținut multimedia**: Suport pentru postări cu text, imagini, videoclipuri scurte (Reels) și live-uri.
* **Mesagerie avansată**: Chat de grup și mesagerie privată (DM) cu suport pentru conținut media.
* **Apeluri de grup**: Apeluri video și audio de înaltă calitate cu mai mulți participanți.
* **Sistem de moderare**: Funcționalitate de raportare a conținutului și un sistem de administrare pentru a menține un mediu sigur.

## Tehnologii Utilizate 🛠️

* **Frontend**: Flutter (pentru o experiență cross-platform fluidă).
* **Backend**: Firebase
    * **Autentificare**: `firebase_auth`
    * **Bază de date**: `cloud_firestore`
    * **Stocare media**: `firebase_storage`
    * **Notificări**: `firebase_messaging`
* **Live-uri și Apeluri**: Agora SDK (pentru streaming-uri și apeluri video/audio în timp real).
* **Gestionare Stare**: Provider / Bloc / Riverpod (alegeți ce ați folosit)
* **Alte pachete**: `image_picker`, `video_player`, etc.

## Structura Proiectului 📂

/lib
├── /models          # Modelele de date (User, Group, Post, etc.)
├── /screens         # Interfețele de utilizator
├── /services        # Servicii de bază (FirebaseService, AgoraService)
├── /widgets         # Componente UI reutilizabile
├── /utils           # Funcții utilitare și constante
└── main.dart