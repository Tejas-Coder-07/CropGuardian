# Crop Guardian - Project Context

> Paste this file at the start of any new AI session to restore full context.
> Last updated: 18 Aug 2026

## 1. Situation
- Team Maverick, Cambridge Institute of Engineering, Bengaluru
- Decode SIH 2026, track Bharat Shakti, PS2 - Smart Agriculture Copilot
- Selected in Top 80 on 16 Aug 2026. Grand Finale 5 Sep 2026, Bengaluru (offline)
- Build time remaining: ~19 days

### Team
| Member | Role |
|---|---|
| Tejas S | Team Lead & Architecture - system design, APIs, Firebase + ML layer |
| Durga Prajapati | Flutter / Mobile |
| Rakesh Kumar Shah | ML & Computer Vision |
| Deepraj Kumar Gupta | Cloud, Data & DevOps |
| Likitha | UI/UX & Field Research |

## 2. Product
Three claims the pitch rests on:
1. Works offline
2. Works by voice, in the farmer's language
3. End-to-end: diagnosis -> advisory -> sale

Framing: not a smarter model - the only one that works in a field with no signal.

## 3. Accounts (all under tejus.sgowda07@gmail.com)
- Firebase project: crop-guardian-9d47a (project number 933418454759)
- Package ID: com.tejas.cropguardian
- GitHub: github.com/Tejas-Coder-07/CropGuardian (private)
- Gemini API via Google AI Studio (free tier)
- Cloudinary: cloud name m0uxcnw7, preset crop_images (unsigned)
- Local path: C:\dev\CropGuardian
- Everything free tier. No paid services.

## 4. Repo state
Flutter, ~7500 lines, 65 Dart files.

WORKING: auth, cloud diagnosis (image -> Cloudinary -> Gemini -> parsed JSON ->
translate -> TTS -> Firestore), community feed, marketplace, farmer profile,
dashboard stats, organic remedy database (654 lines).

PARTIAL: voice (speech_to_text initialised but not wired to UI), 3 languages
(English/Hindi/Kannada).

STATIC DATA: market prices (~80 hardcoded), govt schemes (3 links), learning hub.

MISSING ENTIRELY: offline AI, weather disease prediction, fertiliser, soil health,
irrigation, yield prediction, expense tracker, satellite monitoring, emergency
alerts, crop planner, carbon footprint.

## 5. Known problems
1. assets/ml/plant_model.tflite is NEVER loaded. labels.txt has only Plant/NonPlant -
   it is not a disease model. The offline claim is unimplemented. THIS IS THE
   BIGGEST GAP.
2. Both GetX and Provider used for state.
3. 91 lint warnings (deprecated withOpacity, avoid_print) - no errors.

## 6. Architecture decisions
DO NOT fine-tune an LLM. No data, no time.
- Vision model learns: MobileNetV3 + PlantVillage. Farmer confirms/corrects
  diagnosis -> image + label to Firestore -> periodic retrain -> push new .tflite
  via Firebase ML. Real demoable learning loop.
- LLM "learns" via retrieval not training: embed confirmed diagnoses, retrieve
  nearest past cases as Gemini context.
- Confidence escalation: on-device model first; below threshold say "I am not sure -
  asking the expert model" and escalate to cloud Gemini. BEST DEMO MOMENT.
- Data tiers: SQLite on device (offline), Firestore (sync), Cloudinary (images).
- Keep benchmarks out of farmer UI.

## 7. Scope
All 19 features stay. 3-4 demo-grade (offline scan + feedback loop, voice, scheme
assistant, dashboard), rest functional but simple.
Fertiliser + soil + irrigation = ONE service with three prompts.
Phone OTP login wanted for farmers - deferred to Day 6-7 (Spark plan caps SMS at
10/day).

## 8. Sponsor tracks
| Track | Qualifies via | Prize |
|---|---|---|
| n8n | Emergency alerts + weather workflows | 1yr Cloud Pro x5 |
| Tavily | Live search in scheme assistant | 10,000 credits |
| Render | Python ML API + Postgres = 2 services | $600 |
| Lyzr AI | One assistant as Lyzr agent | Rs 10,000 cash |
| Startuped | GTM/validation - Likitha, zero eng hours | Rs 25,000 cash |
| Swytchcode | SKIP - requires their CLI |  |

## 9. Deck
Crop_Guardian_Maverick_Decode_SIH_2026.pptx - 12 slides on official OSCode template.
Deck claims offline AI, satellite, yield prediction, carbon - all absent in code.
Reconcile before finale.

## 10. Working log
- 18 Aug 2026 - DAY 1 COMPLETE. Ownership migration done: own Firebase project,
  package renamed to com.tejas.cropguardian, all Durga traces removed, secrets in
  .env (gitignored), Firestore security rules deployed, pushed to own GitHub.
  Deleted openrouter_health_check.dart (had leaked key). Fixed main.dart
  colorScheme compile error.
  NEXT: Day 2 - offline core. Rakesh trains real disease model (PlantVillage,
  MobileNetV3, INT8). Tejas builds TFLite service + SQLite layer.
- 19 Aug 2026 - DAY 2. Trained MobileNetV3 on PlantVillage: 96.19% val accuracy, 38 classes, INT8 TFLite 1.7MB in assets/ml/. Built OfflineClassifier (0.70 confidence threshold), LocalDatabase (scans/advisory_cache/expenses), GeminiService replacing dead OpenRouter, HybridDiagnosisService (on-device first -> cloud escalation). Secrets in .env via flutter_dotenv. All committed.
  NEXT: Day 3 - wire HybridDiagnosisService into DiagnosisViewModel + UI. Add confidence badge, 'asking expert model' escalation state, and tick/cross feedback buttons that write correctedLabel for retraining.

- 19 Aug 2026 - DAY 3. Wired HybridDiagnosisService into DiagnosisViewModel. Added _buildOfflineResult UI: ON-DEVICE badge, confidence %, low-confidence warning, 'Ask expert model' escalation button, Correct/Wrong feedback with correction dialog. Built FastAPI backend (backend/): health, market (location-aware via nearest_mandi haversine, per-kg + per-quintal, LinearRegression 7d forecast), weather (OpenWeather -> crop disease risk rules + irrigation advice), schemes (Tavily search restricted to gov domains). Backend runs on uvicorn localhost:8000.
  KNOWN GAP: market price_index values are estimates, not live Agmarknet data - disclose or replace before finale.
  NEEDED IN .env: OPENWEATHER_API_KEY, TAVILY_API_KEY
  NOT YET TESTED ON DEVICE - USB cable pending. Test offline scan flow when cable arrives.
  NEXT: Day 4 - deploy backend to Render (2 services = qualifies Render track), connect Flutter to backend, add farmer location to profile.

- 19 Aug 2026 - DAY 4 (part). Backend DEPLOYED to Render: https://crop-guardian-api.onrender.com - web service + Postgres (render.yaml blueprint, singapore region). RENDER TRACK QUALIFIED (2 services). Verified live: /health, /api/v1/market/prices/{crop}?lat=&lon= (returns nearest mandi + per-kg), /api/v1/weather/advisory (real OpenWeather data -> disease risk), /api/v1/schemes/search (Tavily, gov domains only). Note: free tier sleeps after 15min idle, ~50s cold start - add keep-alive cron before finale. Note: PowerShell needs quotes around URLs with & or it truncates.
  NEXT: connect Flutter app to https://crop-guardian-api.onrender.com, add farmer location to profile.
