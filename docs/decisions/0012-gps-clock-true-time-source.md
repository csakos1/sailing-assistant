# ADR 0012 — GPS-idő mint true-time forrás (telefon-GNSS anchor + monoton extrapoláció)

## Státusz
Elfogadva — 2026-05

## Kontextus
A LiveRaceScreen státuszsorának GPS-idő mezője ma a streamből kiolvasott
értéket mutatja: boatStateProvider → instrumentTimeUtc → toLocal()
(ARCHITECTURE.md §8.7 / §10.4). Az instrumentTimeUtc az RMC dátum+idő
mezőiből összefűzött GPS-instant. Az eredeti szándék: chartplotter-egyezés.

Vízi teszt (2026-05) feltárta: a Vulcan NMEA-over-WiFi (TCP 10110) kimenete
köteges, 4–6 mp-es transzport-késéssel flush-öl. Egy Foretacktól független
capture (Serial WiFi Terminal) megerősíti: az RMC GPS-instantja (09:06:47 UTC)
a telefonhoz a prefix szerint ~4 mp-cel később (11:06:51 helyi) érkezik. Vagyis
az instrumentTimeUtc helyes érték, de mindig 4–6 mp-et késik — épp az eredeti
szándék bukik el rajta.

Követelmény: a rajthoz az app órájának másodperc-pontosan egyeznie kell a
műszer és a rendezőség GPS-órájával (UTC). Futás közben nincs internet → NTP
nem opció. A telefon wall-clock-ja nem GPS-pontos.

Kulcs: az adatnak nincs a streamtől független forrása, de az IDŐNEK van — a
telefon saját GNSS-vevője ugyanabból a forrásból (műhold) adja az UTC-t, mint a
műszer, transzport-késés és internet nélkül.

## Döntés
- D1 — Idő-seam. A presentation a GPS-idő cellához egy dedikált "true-time"
  forrást fogyaszt (a clockProvider-seam mintájára / mögé), NEM az
  instrumentTimeUtc-t. A domain platform-független marad (DIP); a GNSS-olvasás
  data/platform-réteg.
- D2 — Elsődleges (és gyakorlatilag kötelező) anchor: a telefon saját GNSS-
  vevője. Egy fix → műholdas UTC (a fix toLocal()/UTC ideje, NEM a nyers GPS-
  week-idő). Közös forrás a műszerrel → <1 mp egyezés.
- D3 — Ketyegtetés monoton órával. kijelzett = anchorUtc + monotonElapsed, ahol
  az eltelt időt Stopwatch (monoton) adja, NEM DateTime.now() különbség.
  Néhány percenként re-anchor friss GNSS-fixszel.
- D4 — Battery. Nem folyamatos GPS: rövid, alkalmi fix; a pozíció a műszerből.
- D5 — Stream cross-check + staleness. Az instrumentTimeUtc megmarad, de nem a
  kijelző forrása: (a) cross-check — kijelzett >= stream-instant, a különbség ~
  a transzport-késés (a normál 4–6 mp NEM riaszt); (b) staleness-jelzés, ha a
  különbség egy küszöb (default 10 mp) fölé nő.
- D6 — Fallback-lánc, ha GNSS nincs: (1) korábbi session-anchor → tovább monoton
  órán; (2) ha sosem volt → telefon wall-clock EXPLICIT "nem szinkronizált"
  jelzéssel (megbízhatatlan, mert a telefon-óra ≠ GPS és nincs NTP); (3) stream-
  instant + késés-becslés csak diagnosztika. A megjelenítés mindig jelzi a
  forrást/megbízhatóságot.
- D7 — UTC explicit. Mindig UTC-t tartunk és toLocal()-lal jelenítünk meg; nyers
  GPS-week-idő sosem a kijelzőre.

## Következmények
- Az óra a műszerrel <1 mp-en egyezik internet nélkül is, simán ketyeg, immunis
  a wall-clock-ugrásokra.
- Új platform-függőség az apps/phone-ban: location/GNSS (Android
  ACCESS_FINE_LOCATION). DIP megmarad.
- §8.7 / §10.4 módosul: a GPS-idő forrása a true-time seam; az instrumentTimeUtc
  cross-check/staleness szerepre vált.
- A stream-adat (TWA, pozíció) továbbra is 4–6 mp-et késik — NEM ennek az ADR-
  nek a hatóköre (boat-side).
- A true-time seam fake-elhető; a replay-tesztek determinisztikusak maradnak.

## Elvetett alternatívák
- A — Stream-instant + lokális elapsed: simán ketyeg, de 4–6 mp-et késik → a
  rajt-igényt nem teljesíti.
- B — Telefon wall-clock NTP-re: nincs internet, és a telefon-óra ≠ GPS → csak
  megbízhatatlan fallback.
- C — Egyszeri manuális szinkron: manuális, hibázható; a GNSS automatikus és
  pontosabb. Megtartható kényelmi/fallback gombnak.
- D — Folyamatos telefon-GPS: battery-zabáló és felesleges.

## Felülvizsgálat
Vízi teszt (Fázis 9) után; ha a GNSS-anchor lassú fix-időt vagy battery-gondot
ad; ha a leap-second/UTC-kezelésben anomália van.
