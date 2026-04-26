# GoGuard — AI-Powered Scam Prevention

GoGuard is a Flutter e-wallet app with real-time AI scam detection built for the FINHACK hackathon.

## Demo Login
```
Email:    demo@goguard.com
Password: demo123
```

## Features

- **GNN (Graph Neural Network)** — checks recipient phone against a scam report graph
- **XGBoost Behavioural Model** — analyses transfer amount, time, and velocity patterns
- **AI Explanation** — LLM-generated bullet points explaining why a transfer was flagged
- **Breathing Room** — HIGH risk transfers require a 60-second cooldown before proceeding
- **Scammer Warning List** — community-powered database with live phone number lookup
- **Trusted Contacts (Whitelist)** — skip scam check for verified contacts
- **Balance tracking** — balance updates in real time after each transfer

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (web) |
| State management | Flutter BLoC |
| Auth | AWS Amplify + Cognito |
| AI Backend | Alibaba Cloud (GNN + XGBoost + LLM) |
| Hosting | AWS Amplify Console |

## Project Structure

```
lib/
├── blocs/
│   ├── auth_bloc/          # Login, logout, balance
│   ├── transfer_bloc/      # Full transfer flow state machine
│   └── whitelist_cubit/    # Trusted contacts
├── models/                 # RiskLabel, Session, TransferFlowData
├── screens/
│   ├── auth/               # Login, Register
│   ├── home/               # Dashboard
│   ├── transfer/           # Recipient → Check → Amount → Analyse → Warning → Success
│   ├── scam_db/            # Scammer warning list + phone lookup
│   ├── whitelist/          # Trusted contacts management
│   └── error/              # Blocked, insufficient funds, timeout
├── services/
│   ├── alibaba_api_service.dart  # GNN + XGBoost + LLM backend
│   ├── risk_engine.dart          # Score fusion (0.5×GNN + 0.5×XGB)
│   └── simple_amplify_config.dart
└── main.dart
```

## Risk Scoring

```
Final Score = 0.5 × GNN Score + 0.5 × XGBoost Score

LOW    → score < 0.4   (green)
MEDIUM → score < 0.7   (amber)
HIGH   → score ≥ 0.7   (red, 60s cooldown)
```

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

## Build for Web

```bash
flutter build web --release
```
