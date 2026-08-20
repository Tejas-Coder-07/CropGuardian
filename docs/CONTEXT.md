# Crop Guardian - Project Context

> Paste this whole file at the start of any new AI session.
> Last updated: 20 Aug 2026

## 0. HOW TO WORK WITH ME (read this first)

I am Tejas. I am NOT an experienced developer. I need exact instructions, not
theory. Follow these rules:

Command format - every single time:
- Say "NEW TERMINAL (click + in terminal panel)" or "SAME TERMINAL"
- Say "STOP FIRST (press q / Ctrl+C)" if something is running
- After each command say "Check:" and what correct output looks like
- ONE task at a time. Do not give five commands at once.
- If I say "next", give the next single step.

Things that keep going wrong - avoid these:
- PowerShell backticks in .Replace() get inserted LITERALLY not as newlines.
  Use [IO.File]::ReadAllLines + index editing, or [string[]]@(...) for InsertRange.
- URLs with & in PowerShell MUST be quoted or they truncate.
- .Replace() silently does nothing if whitespace does not match exactly.
  Always verify with Select-String after.
- I sometimes paste terminal output back INTO the terminal by accident.
- Correct project path is ALWAYS C:\dev\CropGuardian. If imports show
  croupguardiandurgaprajapati, I am in the wrong folder.

My environment:
- Windows, VS Code, PowerShell
- Internet is my phone hotspot only. Builds: 2-5 min normal, 8-15 after clean,
  20-40 with timeouts. DO NOT tell me to run flutter clean unless necessary.
- Build fails with "Read timed out" - just rerun. Progress is cached.
- Same phone is hotspot AND debug device, so USB and network compete.
- Screen mirror: type "mirror" in a new terminal (alias set up).

Verification loop used constantly:
  flutter analyze lib 2>&1 | Select-String "error"
Nothing printed = compiles. ~90 style warnings are intentionally ignored.

## 1. SITUATION

- Team Maverick, Cambridge Institute of Engineering, Bengaluru
- Decode SIH 2026, track Bharat Shakti, PS2 Smart Agriculture Copilot
- Selected Top 80 on 16 Aug 2026
- GRAND FINALE: 5 Sep 2026, Bengaluru, offline
- ~15 days build time left
- I am working SOLO. Do not plan around parallel teammate work.

Team (for deck only, not task allocation):
| Tejas S | Team Lead and Architecture - doing all work currently |
| Durga Prajapati | Flutter/Mobile (original repo host) |
| Rakesh Kumar Shah | ML and Computer Vision |
| Deepraj Kumar Gupta | Cloud, Data, DevOps |
| Likitha | UI/UX and Field Research |

Prize structure: Rs 1,80,000 across 2 venues x 3 tracks. Bharat Shakti Bengaluru
= 14 teams competing for Rs 30,000. SPONSOR TRACKS ARE SEPARATE AND INDEPENDENT -
judged on how well you used each tool, not on winning the main track. Sponsor
pool is worth more and has far less competition.

## 2. PRODUCT

Crop Guardian - AI farming copilot for small and marginal farmers.

Three claims everything rests on:
1. Works OFFLINE
2. Works by VOICE in the farmer language
3. Goes END-TO-END: diagnosis -> advisory -> sale

Positioning (never say "we beat GPT"): not a smarter model, THE ONLY ONE THAT
WORKS IN A FIELD WITH NO SIGNAL. Compare on: offline / latency / cost per query /
tuned on Indian field images.

## 3. ACCOUNTS (all under tejus.sgowda07@gmail.com)

| Firebase | project crop-guardian-9d47a, number 933418454759 |
| Package ID | com.tejas.cropguardian |
| GitHub | github.com/Tejas-Coder-07/CropGuardian (private) |
| Backend LIVE | https://crop-guardian-api.onrender.com |
| Gemini | Google AI Studio free tier, model gemini-3.5-flash |
| Cloudinary | cloud m0uxcnw7, preset crop_images (unsigned) |
| OpenWeather | free tier, active |
| Tavily | free tier + 8000 finalist credits |
| Startuped.ai | Pro, 1000 credits from founder, workspace CropGuardian |
| Local path | C:\dev\CropGuardian |

EVERYTHING IS FREE TIER. TOTAL SPEND Rs 0. KEEP IT THAT WAY.

WARNING: Gemini model names change. gemini-2.0-flash does NOT exist for this key.
On 404, list models:
  $key = (Get-Content .env | Select-String "^GEMINI_API_KEY=").ToString().Split("=")[1]
  curl.exe -s "https://generativelanguage.googleapis.com/v1beta/models?key=$key" | Select-String "models/gemini"

## 4. WHAT IS BUILT (verified on device)

THE ML MODEL - the centrepiece:
- MobileNetV3-Large, transfer learning from ImageNet
- PlantVillage: 54,305 images, 38 disease classes, 14 crops
- Two-stage: frozen backbone 5 epochs, then unfreeze last 30 layers at 1e-5
- Augmentation: flip, rotation, zoom, contrast, brightness
- 96.19% validation accuracy
- INT8 TFLite, 1.7 MB, at assets/ml/crop_model.tflite
- Trained on Colab free T4. DO NOT use .cache() on the dataset - it OOMs and
  crashes the runtime. This wasted an hour.

HYBRID DIAGNOSIS FLOW:
On-device TFLite first. Confidence >= 0.70 answers offline with zero network.
Below that, show "I am not sure" plus "Ask expert model" which escalates to
cloud Gemini. Below 0.45 = isUnknownCrop (not one of the 38 classes). Farmer
taps Correct/Wrong, corrections stored for retraining.
THIS ESCALATION IS THE BEST DEMO MOMENT IN THE APP.

SCREENS WORKING ON DEVICE:
- Offline AI diagnosis + Smart Scan + pest detection (verified airplane mode)
- Cloud escalation - correctly ID'd rose black spot at 92%
- Voice input STT with per-language locale - transcribes to text field
- Market prices - Kolar mandi, Rs 19.11/kg onion, sell/hold advice
- Weather advisory + disease risk + irrigation - live Chintamani data
- Government schemes via Tavily - all sources pmkisan.gov.in
- Farm expense tracker - offline SQLite, 8 categories
- Crop advisory fertiliser/soil/plan - backend live, screen built
- Community, marketplace, profile, auth, dashboard - pre-existing

BACKEND (FastAPI on Render, RENDER TRACK QUALIFIED with 2 services):
- /health
- /api/v1/market/prices/{crop}?lat=&lon= nearest mandi haversine, per-kg and
  per-quintal, LinearRegression 7-day forecast, sell/hold recommendation
- /api/v1/market/crops, /api/v1/market/nearest-mandi
- /api/v1/weather/advisory OpenWeather to crop disease risk + irrigation
- /api/v1/schemes/search Tavily restricted to official gov domains only
- /api/v1/advisory/fertiliser /soil-health /crop-plan Gemini JSON-shaped
- Postgres provisioned
FREE TIER SLEEPS AFTER 15 MIN, ~50s COLD START. Add keep-alive cron before finale.

KEY FILES:
lib/core/ml/offline_classifier.dart      TFLite, thresholds
lib/core/data/local_database.dart        SQLite: scans, advisory_cache, expenses
lib/core/location/location_service.dart  GPS + district + offline persistence
lib/core/api/api_client.dart             backend client, graceful degradation
lib/Screens/diagnosis_screen/services/hybrid_diagnosis_service.dart
lib/Screens/diagnosis_screen/services/gemini_service.dart
backend/app/api/{health,market,weather,schemes,advisory}.py
backend/app/services/location.py         mandi list + haversine + state to language

## 5. DESIGN DECISIONS - DO NOT REVERSE

DO NOT FINE-TUNE AN LLM. No data, no time, would lose to Gemini Flash. The vision
model is the thing that is genuinely ours. If a judge asks "did you train an LLM?"
answer: "No. Fine-tuning on data we could gather in 50 days would be worse than
Gemini. We put training effort where it wins - a vision model on Indian field
images that runs offline on a Rs 8,000 phone."

"LEARNING" IS RETRIEVAL, NOT TRAINING. Farmer corrections stored and fed back as
context and future retraining data for the vision model.

HONEST NUMBERS ONLY. Dashboard used to average model confidence and call it
"accuracy" - wrong, a judge would catch it. Now shows 96% Model accuracy (real
validation figure) until 5+ farmer ratings exist, then Farmer rated % from
actual feedback.

SAFETY GUARDRAILS ARE DELIBERATE - KEEP THEM:
- Every pesticide/chemical recommendation gets "Confirm with your local
  agriculture officer or Krishi Vigyan Kendra" appended AT THE API LEVEL
- Scheme search restricted to official gov.in domains, no blog advice
- Farmer free-text wrapped as data in Gemini prompt (prompt-injection guard)
- Price forecasts carry "Confirm with your local mandi before selling"

LOCATION IS A FIRST-CLASS INPUT. Prices, weather, schemes and language all key
off the saved GPS/district. Never hardcode a city.

OFFLINE COUNTS MUST INCLUDE LOCAL SQLITE, not just Firestore. An offline-first
app showing zero because nothing synced is backwards.

## 6. KNOWN GAPS - BE HONEST ABOUT THESE

1. price_index values in backend/app/services/location.py are ESTIMATES, not live
   Agmarknet data. The location logic, haversine and mandi mapping are real; the
   underlying prices are seeded. EITHER WIRE THE LIVE FEED OR DISCLOSE BEFORE THE
   FINALE. Do not let a judge discover it.
2. Model guesses on crops outside its 38 classes (gave "corn 54%" on a rose).
   isUnknownCrop threshold added but NOT YET SURFACED IN THE UI.
3. Mic needs louder speech than Google assistant. Tuning via SpeechListenOptions.
4. ~90 lint warnings, zero errors. Cleanup needed before Play Store.
5. Both GetX and Provider used for state.
6. No flutter test coverage at all.
7. Cloudinary free tier 25GB will not survive real users - compress before upload.
8. Firebase Spark has no Cloud Functions - needed for retraining pipeline.

## 7. FEATURES: 15 of 19 DONE

DONE: offline AI, pest detection, smart scan, voice assistant, market price,
weather disease, fertiliser, soil health, irrigation, schemes, expenses, crop
planner, community, marketplace, dashboard

REMAINING:
- Emergency alerts (#16) - FCM push, ALSO UNLOCKS THE n8n SPONSOR TRACK
- Satellite monitoring (#12) - Sentinel NDVI, half a day
- Carbon footprint (#18) - simple calculator
- Yield prediction (#9) - needs training data we do not have. KEEP AS ROADMAP,
  DO NOT FAKE IT.

Tejas wants all 19 present. Not all deep - 3-4 demo-grade, rest functional but
simple. Nothing removed, nothing embarrassing on stage.

## 8. SPONSOR TRACKS

| Render | QUALIFIED (web service + Postgres) | $600 credits |
| Tavily | live in scheme search | 10,000 credits |
| n8n | do with emergency alerts | 1-yr Cloud Pro x5 (~$3,000) |
| Lyzr AI | build one assistant as Lyzr agent | Rs 10,000 cash |
| Startuped | ZERO ENG HOURS, BIGGEST CASH PRIZE | up to Rs 25,000 |
| Swytchcode | needs their CLI as build tool | $1,000 credits |

Startuped guidance: run ONLY idea validation, market research, positioning, GTM
plan, launch strategy. SKIP their marketing onboarding (social channels, leads,
brand) - that is for SaaS companies and burns credits. Complete every module and
feed their critique back in so there is visible iteration.

Swytchcode + Codemate winners also get Pre-Placement Interviews - worth more than
cash for final-year students.

## 9. REMAINING WORK IN PRIORITY ORDER

1. Emergency alerts + n8n - one build, one feature, one sponsor track
2. Build APK + WEB VERSION - Tejas explicitly wants a shareable link for judges
   AND an APK. Web build to Firebase Hosting. WARNING: TFLITE CANNOT RUN IN A
   BROWSER. Web version must use cloud Gemini; the offline claim stays a
   phone-only demo. Say this plainly, do not let it surprise anyone.
3. Satellite (#12) + carbon (#18)
4. Update the deck - Crop_Guardian_Maverick_Decode_SIH_2026.pptx, 12 slides on
   the official OSCode template. Several claims have changed since it was made.
5. Lyzr + Swytchcode if time allows
6. Demo rehearsal - especially the airplane-mode moment
7. Lint cleanup, firestore.rules review, keep-alive cron

## 10. WORKING LOG

18 Aug Day 1. Ownership migration. Own Firebase project, package renamed to
com.tejas.cropguardian, all Durga traces removed, secrets to .env (gitignored),
Firestore security rules deployed, pushed to own GitHub. Deleted
openrouter_health_check.dart (had a leaked live key, revoked). Fixed main.dart
colorScheme compile error.

19 Aug Day 2. Trained model on Colab: 96.19%, 38 classes, 1.7MB TFLite. Built
OfflineClassifier, LocalDatabase, GeminiService (replacing dead OpenRouter),
HybridDiagnosisService.

19 Aug Day 3. Wired hybrid service into viewmodel + offline result UI (ON-DEVICE
badge, confidence %, escalation button, feedback buttons). Built entire FastAPI
backend.

19 Aug Day 4. Deployed backend to Render. RENDER TRACK QUALIFIED. Verified all
endpoints live. Added location service + API client.

19-20 Aug Day 5. Live market prices on device (Kolar mandi, per-kg, sell/hold).
Weather advisory screen. Expense tracker. Live Tavily scheme search. Crop
advisory. Honest dashboard stats. Voice input wired and confirmed transcribing on
device. Fixed Gemini model to gemini-3.5-flash. Updated contact to +91 9513065382.

NEXT: emergency alerts + n8n integration.