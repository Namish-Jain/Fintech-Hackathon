# FinBytes 📱

> Transform complex financial news into 90-word, jargon-free micro-learning cards.

## 🚀 Quick Start

```bash
flutter pub get
flutter run
```

## 🗂️ Project Structure

```
lib/
├── main.dart                  # App entry — ProviderScope, theme, orientations
├── theme/
│   └── app_theme.dart         # Deep Navy (#0A0E21) + Neon Green (#00E676) palette
│                              # Space Grotesk headlines · Inter body
├── models/
│   └── byte_model.dart        # Byte data class — Supabase-ready fromMap/toMap
├── data/
│   └── mock_data.dart         # 3 high-quality mock cards (Markets, Crypto, Personal Finance)
├── screens/
│   └── feed_screen.dart       # TikTok-style vertical snap feed + AppBar + progress dots
└── widgets/
    └── byte_card.dart         # Full-screen card — bullets, ELI5 toggle, category badge
```

## 🎨 Design System

| Token              | Value       | Usage                    |
|--------------------|-------------|--------------------------|
| Deep Navy/Black    | `#0A0E21`   | Scaffold & card bg       |
| Card Surface       | `#0F1535`   | Card background          |
| Neon Green         | `#00E676`   | Primary accent, CTA      |
| Text Primary       | `#F0F4FF`   | Headlines & body         |
| Text Secondary     | `#8892B0`   | Metadata & captions      |

**Typography:** Space Grotesk (headlines) · Inter (body) via `google_fonts`

## 📦 Key Packages

| Package                | Purpose                          |
|------------------------|----------------------------------|
| `tiktoklikescroller`   | Vertical snap-scroll feed        |
| `flutter_riverpod`     | ELI5 toggle state per card       |
| `google_fonts`         | Space Grotesk + Inter typography |
| `supabase_flutter`     | Auth + DB (Phase 3 ready)        |

## ✅ Phase 1 Checklist

- [x] Flutter project initialised with premium dark theme
- [x] `Byte` model with `id`, `title`, `source`, `summaryBullets`, `eli5Content`, `category`
- [x] TikTok-style vertical snap feed via `tiktoklikescroller`
- [x] 3 mock cards — Markets, Crypto, Personal Finance (all < 90 words)
- [x] ELI5 toggle with smooth animated crossfade (Riverpod state)
- [x] Category colour badges + source badges
- [x] Animated progress dots at bottom

## 📋 Mock Cards

| # | Category         | Headline                                           |
|---|------------------|----------------------------------------------------|
| 1 | Markets          | S&P 500 Hits Record High as Jobs Data Beats Expectations |
| 2 | Crypto           | Bitcoin Tops $95K as Institutional ETF Inflows Surge     |
| 3 | Personal Finance | High-Yield Savings Accounts Still Beating Inflation      |

## 🗺️ Roadmap

- **Phase 2 (Hours 10–20):** Onboarding survey · MCQ quiz overlay · Lottie animations
- **Phase 3 (Hours 20–36):** Supabase Auth · FastAPI AI backend · Real data stream
