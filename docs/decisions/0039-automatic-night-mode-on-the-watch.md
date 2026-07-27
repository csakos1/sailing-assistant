# ADR 0039 — Automatikus éjszakai mód az órán (roadmap S4)

**Státusz:** elfogadva
**Dátum:** 2026-07
**Kontextus-ADR-ek:** ADR 0015 (watch sync — D7 design-tokenek, a „Piros
éjszakai téma" halasztása), ADR 0016 (az óra a primary élő kijelző),
ADR 0019 (a kijelző láthatóan marad), ADR 0012 (`WatchClock`), ADR 0031
(mélység-riasztás overlay), ADR 0023 (konfidencia-színek)

> **Számozás.** A 0038 az offline csempe-csomagnak van fenntartva (több
> dokumentum és a párhuzamos munka is így hivatkozza), ezért az éjszakai
> mód a 0039-et kapja. A hézag szándékos.

## Kontextus

A balatoni tour-race-ek (Kékszalag, Hosszútávú) **éjszakába nyúlnak**. Az
óra az ADR 0016 óta a **primary élő kijelző**, és az ADR 0019 szerint a
verseny alatt **láthatóan kell maradnia** — vagyis pontosan az a felület,
ami éjjel folyamatosan a szem előtt van.

A mai `watchDarkTheme` elsődleges szövegszíne `#E9F1F7`, egy majdnem-fehér,
kékes árnyalat. Ez nappal helyes választás (magas kontraszt, napfény-
olvashatóság), éjjel viszont két bajt okoz: **elrontja a sötét-adaptációt**
(a kékes-fehér a leginkább, mert a szkotópos érzékenység csúcsa a
kék-zöldben van), és a csuklóról visszaverődő fény a kormányos látóterébe
kerül.

A hajón lévő **B&G Vulcan** ugyanezt a problémát éjszakai módban vörös-
narancs előtérrel oldja meg. A felhasználó igénye, hogy az óra **ugyanazt a
vizuális nyelvet** beszélje, mint a műszer, és hogy a váltás **automatikus**
legyen — kézi kapcsolgatást a versenyen nem akar.

Ez a döntés nem új irányt nyit: az **ADR 0015 D7** és a
`docs/design-system.md` a „Napfény / Piros éjszakai témát" explicit
**v2-deferredként** rögzítette, és kifejezetten azért tette a szín-tokeneket
`ThemeExtension`-be, hogy a másik téma később **drop-in** legyen. Ez az ADR
ezt a halasztott tételt váltja be, a `ThemeExtension`-mechanizmus
megváltoztatása nélkül.

## Döntés

### D1 — Hatókör: kizárólag az `apps/watch`

A funkció csak az órán jelenik meg. A telefon-UI, a `WatchPayload`, a
`wearable_bridge` és a natív híd **változatlan**.

Indok kettős. Egyrészt az óra a primary éjszakai felület, a telefon zsebben
van kikapcsolt kijelzővel (ADR 0016). Másrészt a telefonon a drága rész nem
a téma, hanem a biztonsági térkép (ADR 0037) **raszter csempéje**: azt nem
lehet átszínezni, csak `ColorFilter`-rel szűrni, ami a partvonalat és a
mélységi árnyalatokat is átfesti — épp azt az információt, amiért a képernyő
létezik. A telefonos éjszakai mód így nem „ugyanaz kicsiben", hanem külön
probléma, külön szelet (lásd Halasztva).

### D2 — Csak a szöveg-rámpa vált; a jelentés-hordozó színek maradnak

Éjszakai módban **a három szöveg-token** (`text`, `textSecondary`,
`textTertiary`) vált vörös-narancsra. **Változatlan marad**: `background`,
`surface`, `critical`, `port`, `starboard`, `signal`, `amber`.

Indok: ezek a tokenek nem díszítés, hanem **jelentést kódolnak** — a
starboard/port a hajós navigációs-fény konvenciót, a `critical` a
riasztást, a `signal` a friss/megbízható állapotot, az `amber` a medium
konfidenciát. Ha éjszaka mindent egy hue-ra húznánk, a színkód elveszne, és
a felület olvashatóbb helyett szegényebb lenne.

Következik ebből, hogy éjszakai módban a felület **nem egyszínű**: teál,
piros és zöld akcentusok maradnak a narancs szöveg mellett. Ez tudatos.

### D3 — A narancs-rámpa három foka

| Token | Nappali | Éjszakai | Kontraszt a háttéren |
|---|---|---|---|
| `text` | `#E9F1F7` | **`#EE5035`** | 5,6 : 1 |
| `textSecondary` | `#93A8BA` | **`#A63825`** | 3,1 : 1 |
| `textTertiary` | `#5C7285` | **`#8C2F1F`** | 2,4 : 1 |

Az alapszín (`#EE5035`, hue ≈ 9°) a Vulcan éjszakai módjának megfigyelt
színe. Ez **vörös-narancs, nem borostyán** — és pont ez a lényeg: a
sötét-adaptációt a vörös felé tolt szín őrzi meg.

A második és harmadik fok **nem** a nappali rámpa arányaival képződik. A
`#EE5035` érzékelt fényereje eleve nagyjából a mai *tercier* szinten van
(a majdnem-fehér `#E9F1F7` sokszorosan világosabb), ezért az arányos
tompítás olvashatatlanba vinné a rámpa alját. A fokok azonos hue-n és
telítettségen, csökkenő világossággal készültek, és az alsó fok tudatosan
a 3:1 alatt marad — a tercier szerepe eleve a „ne bízz benne" jelzés.

A három érték **literál konstans** a témában; a származtatás itt van
rögzítve, nem kódban. Indok: a hangolás on-device, szemre történik, és egy
számított rámpa azt a látszatot keltené, hogy az értékek levezetettek.

### D4 — A riasztás előtere additív token (`onCritical`)

A `depth_alert_overlay.dart` nem-ambient módban `critical` háttérre
`text`-tel ír. Ha a `text` narancs lesz, a kontraszt **1,10 : 1** — a
riasztás szövege gyakorlatilag eltűnne a saját hátteréből, éjjel, sekélybe
futás közben.

Ezért a `WatchColors` **additív `onCritical` tokent** kap, az `amber`
bevált mintájára: default értéke a mai `#E9F1F7`, tehát a meglévő
`WatchColors`-konstrukciók (téma + tesztek) változatlanul fordulnak, és a
nappali kinézet byte-azonos marad. Az éjszakai téma `onCritical`-ja a
`background` (`#04080D`) → **6,1 : 1** a piros mezőn.

A widget így **nem tud** az éjszakai módról: tokent olvas, ahogy eddig. Ez
a D2 „a critical marad" döntésének a kimondatlan következménye: a warning
színe tényleg marad, de a rajta lévő szöveg nem maradhat.

### D5 — A `ColorScheme` is a rámpára áll

A téma `ColorScheme.fromSeed(seedColor: signal)`-t épít, tehát minden
`Text`, ami nem ad explicit színt, a scheme közel-fehér `onSurface`-ét
kapja. Az éjszakai téma ezért a scheme `onSurface` / `onSurfaceVariant`
mezőjét is a narancs-rámpára állítja.

Indok: enélkül a fehér **implicit úton** átszivárogna, és a grep nem
mutatná meg, honnan. A nappali téma érintetlen.

### D6 — A nap-állás az órán, helyben számolódik

A napkelte/napnyugta tiszta Dart függvény a **`packages/shared`**-ben
(`src/sun_times.dart`), NOAA-algoritmus, külső függőség nélkül. Az óra
maga számol; a `WatchPayload` **nem bővül**.

Indok:

- Nulla ütközés a payload-szerződéssel (és a párhuzamos, payload-felületet
  érintő munkával).
- A mód akkor is helyes, ha a telefon-kapcsolat megszakad — márpedig az
  éjszakai mód épp akkor kell a leginkább, amikor semmi más nem működik.
- A `shared` a helyes réteg: az `apps/watch` a `domain`-t is látja
  (ADR 0015 D6), de a halasztott **telefonos** éjszakai mód ugyanezt fogja
  használni, és a `shared` mindkettőnek közös. Precedens: a
  `live_formatters.dart` szintén megjelenítési logika a `shared`-ben.

**Rétegezési következmény:** a `shared` **nem** függhet a `domain`-től
(`domain → shared`), ezért a függvény **nem** kap `Coordinate`-et. A
referencia-pozíció két `double` konstans a `shared`-ben (a tó közepe,
≈ 46,83° É / 17,70° K).

A tó két vége között a napnyugta ~3,5 perc eltérés (Keszthely ↔ Siófok,
~0,9° hosszúság). Egy több tíz perces jelenségnél ez zaj, ezért a valódi
GPS-pozíció használata nem adna mérhető pontosságot — cserébe adatfüggést
adna egy olyan funkcióhoz, aminek adat nélkül is működnie kell.

### D7 — Küszöb: geometriai napnyugta / napkelte, konstans offsettel

A mód **napnyugtakor** kapcsol be és **napkeltekor** ki, egy
`nightModeOffset` konstanssal eltolva, aminek a v1 értéke `Duration.zero`.

Kimondandó korlát: **a geometriai napnyugtakor még világos van.** A valódi
sötétedés a polgári szürkület vége (a Nap 6°-kal a horizont alatt), ami a
Balatonon nyáron ~35 perccel későbbre esik. A mód tehát a kelleténél
**korábban** kapcsol. Ezt azért vállaljuk, mert (a) a felhasználó
megfogalmazása ez volt, (b) a korai kapcsolás ártalmatlan (a narancs
szürkületben is olvasható), míg a késői kapcsolás pont a bajt okozza, amit
el akarunk kerülni, és (c) az offset egyetlen konstans, tehát az első vízi
tapasztalat után egy sor átírásával hangolható.

### D8 — Idő-forrás: a rendszeróra, nem a `WatchClock`

A predikátum a készülék fali óráját használja (`DateTime.now`,
injektálható seammel a teszthez), **nem** a `WatchClock` GPS-extrapolációját.

Indok: a `WatchClock` anchor nélkül `untrusted`, tehát payload érkezése
előtt nem tudnánk módot választani — az app indulása pedig épp az a pillanat,
amikor a helyes témával kell megjelennie. A napnyugtához perc-pontosság
elég, amit az NTP-szinkronizált rendszeróra bőven ad. Minden számítás
**UTC-ben** folyik, így a nyári időszámítás nem játszik.

### D9 — Percenkénti újraértékelés, hiszterézis nélkül

Egy 60 s periódusú timer értékeli újra a predikátumot. Hiszterézis nem
kell: a napállás monoton, a küszöböt naponta kétszer, egy irányba lépi át
— nincs mit lecsillapítani.

### D10 — Nincs kézi kapcsoló; fejlesztői kényszerítés van

A felhasználó felé **nulla UI**: nincs kapcsoló, nincs beállítás.

A tesztelhetőségért egy `--dart-define=FORETACK_FORCE_NIGHT=1` seam
kényszeríti a módot (az ADR 0007 `FORETACK_` névtér-mintája). Ez nem
felhasználói felület, és nem is jelenik meg sehol — nélküle az on-device
verifikáció napnyugtára várást jelentene.

### D11 — Az ambient-tompítás mechanizmusa változatlan

Az ambient-mód ma **token-választással** tompít (`ambient ? textSecondary :
text` és társai), nem külön festéssel. Ezt nem nyúljuk meg: a narancs-rámpa
bekötésével az ambient **automatikusan** a rámpa második fokát (`#A63825`)
kapja, tehát a kért „ambientben kicsit más narancs" **plusz kód nélkül**
teljesül.

Ez egyben az ADR 0015 D7 tokenes tervének a visszaigazolása: a téma-csere
tényleg drop-in, mert egyetlen widget sem ismer színt.

### D12 — Az átmenet animált marad

A `MaterialApp` téma-cserét az `AnimatedTheme` alapból ~200 ms alatt
vezeti át, és a `WatchColors.lerp` már készen van rá. **Nem kapcsoljuk ki**:
napi egyszer egy rövid szín-átmenet kellemesebb, mint egy villanás, és nulla
kódba kerül.

### D13 — Téma-nevek

A meglévő `watchDarkTheme` **változatlan** marad (tesztek hivatkozzák);
mellé `watchNightTheme` kerül, a színkészletek `watchDayColors` /
`watchNightColors` néven. A „dark" és a „night" egy fájlban zavaró lehet,
ezért a doc-komment rögzíti: a **dark** a sötét-only alaptéma (v1 óta), a
**night** az éjszakai-látás módja.

## Következmények

- **Vállalt romlás 1 — a port-nyíl beleolvad.** A `port` (`#FF5A52`) és a
  `#EE5035` közötti kontraszt 1,17 : 1, tehát éjszaka a bal-nyíl színe
  gyakorlatilag azonos a szöveggel. A jelentést azonban a **geometria**
  hordozza (a nyíl iránya és oldala, ARCHITECTURE §7.3), a szín csak
  redundáns megerősítés — így ez nem funkció-vesztés, csak halványabb
  redundancia. Tudatosan vállalva.
- **Vállalt romlás 2 — a low-konfidencia ív bealkonyul.** A `low` a
  `textTertiary`-ból jön (`#8C2F1F`), amit az ambient-rajzoló még 0,4
  alfával is szoroz. Nagyon halvány lesz. A low jelentése épp az, hogy „ne
  bízz benne" — vállalva.
- **A `signal` teál marad**, tehát a „következő bója" lap hero-száma
  éjszaka is teál. Ez szándékos: a teál a friss/megbízható jelentés
  hordozója, és a narancs komplementere, tehát kiemel, nem zavar.
- **Ambient-késleltetés.** A Wear OS ambient módban a timereket
  visszafogja, ezért a napnyugtakori váltás a következő ébredésig
  csúszhat. Elfogadható: ilyenkor a kijelző eleve tompított.
- **OLED-nyereség.** A `#EE5035` egy csatornán világos, kettőn sötét; a
  majdnem-fehérhez képest ez **kevesebb fogyasztás** az órák OLED
  paneljein. Mellékhaszon, nem indok.
- **Új felület a `shared`-ben** (`sun_times.dart` + a barrel-export). Nincs
  új külső függőség, nincs pubspec-változás, tehát `melos bootstrap` sem
  kell.
- **A `WatchApp` `ConsumerWidget` lesz** (ma `StatelessWidget`), hogy a
  téma-választás a providerből jöjjön. A `ProviderScope` már a helyén van.
- **Doc-sync:** a `docs/design-system.md` „v1-ben csak a sötét téma van
  bekötve … a Piros éjszakai téma v2-deferred" mondata elavul, és az
  `ARCHITECTURE.md` óra-fejezete is bővül. A `docs/deferred.md` „Piros
  éjszakai téma" tétele a feature végén a `## Done` szakaszba mozdul, a
  commit hash-ével.

### Szeletek

1. `docs(adr)` — ez a dokumentum.
2. `docs(architecture)` — `ARCHITECTURE.md` + `docs/design-system.md` sync.
3. `feat(shared)` — `sun_times.dart` + barrel + tesztek. Nulla UI.
4. `feat(watch)` — `onCritical` token, `watchNightColors`,
   `watchNightTheme`, a `depth_alert_overlay` átállítása a tokenre.
   **Viselkedés-változás nélkül:** a téma még nincs bekötve.
5. `feat(watch)` — `nightModeProvider`, a `WatchApp` bekötése, a
   `FORETACK_FORCE_NIGHT` seam, tesztek. **Ez kapcsolja be a funkciót.**
6. On-device verifikáció mindkét órán, kényszerített módban, ambientben is
   — majd szükség esetén a végleges szín (`fix(watch)`, három sor).

## Elvetett alternatívák

- **A telefon számol, a payload visz egy flaget.** Egyetlen igazságforrás
  lenne, valódi GPS-pozícióval. Elvetve: payload-szerződés-változást és
  natív-híd-érintést hozna egy olyan funkcióért, aminek a pontossági
  igénye perc, és kapcsolat-vesztéskor az óra beragadna az utolsó
  állapotba.
- **Kézi kapcsoló (vagy automatika + felülbírálás).** A felhasználó
  explicit kérése az automatika volt; egy kapcsoló a kis kijelzőn helyet és
  nav-mélységet enne, és a versenyen a kapcsolgatás maga a probléma.
- **`ColorFilter` az egész widget-fára.** Egyetlen sor lenne, de a
  `critical`, `starboard`, `port` és `signal` jelentés-hordozó színeket is
  átfestené — épp azt rombolná le, amit a D2 véd.
- **Fényerő-szenzoros váltás.** Az óra fényerő-szenzora nem a napszakot
  méri: kabátujj alatt, kajütben vagy zsebben hamis éjszakát jelezne,
  reflektorfényben pedig hamis nappalt. A napállás determinisztikus és
  tesztelhető.
- **Polgári szürkület (−6°) mint küszöb.** Pontosabban modellezi a valódi
  sötétedést, de a D7 offset-konstans ugyanezt adja egy számmal, mérési
  tapasztalat alapján hangolva — a bonyolultabb küszöb-modell most
  spekulatív lenne.
- **Az `amber` token újrahasználata szövegszínként.** Kézenfekvő lett
  volna, de az `amber` a **medium konfidencia** jelentését hordozza
  (ADR 0023 D7); szövegszínként a jelzés némán elveszne.

## Halasztva

- **Telefonos éjszakai mód** — külön szelet, a csempe-tintázás önálló
  problémájával együtt.
- **Napfény-téma** (a `design-system.md` harmadik témája) — változatlanul
  v2.
- **Kézi felülbírálás / hangolható offset a beállításokban** — csak akkor,
  ha a vízi tapasztalat kéri.
- **Az `onCritical`-hoz hasonló tokenizálás a többi implicit színpárra** —
  ha az on-device kör talál még fehér szivárgást.

---

## Addendum 1 — Az éjszakai mód a jel-színeket is tompítja

**Dátum:** 2026-07
**Kiváltó ok:** az első on-device verifikáció (2026-07-27, valódi napnyugtakor).

### Kontextus

A verifikáció a törzs döntéseit igazolta: a váltás pontosan a számított
napnyugtakor történt meg, a szöveg-rámpa mindhárom foka helyes, az ambient a
második fokot kapta, és **fehér szöveg sehol nem szivárgott át** — a D5
(`ColorScheme.onSurface` rögzítése) tehát elég volt.

Egy dolog viszont a képernyőn derült ki, amit a kontraszt-számítás nem
jelzett előre: a jelentés-hordozó színek a tompított narancs **mellett**
kiugróan világosak. A `signal` (teál, relatív fényerő 0,575) és a
`starboard` (zöld, 0,468) a `text` (0,242) mellett most már a képernyő
legvilágosabb pontjai — vagyis pont az a felület vakít, aminek a
sötét-adaptációt kellene őriznie. A törzs D2-je ezt nem látta előre, mert a
tokeneket **jelentésük szerint** csoportosította, nem fényerő szerint.

Ehhez járul egy fizikai tény: a szem szkotópos érzékenységének csúcsa
~507 nm, azaz **épp a kék-zöld tartományban** — a teál a lehető
legrosszabb szín a sötét-adaptáció szempontjából.

### Döntés

#### A1-D1 — A D2 megnyílik: a jel-színek is váltanak

A törzs D2-je („kizárólag a három szöveg-token vált") **hatályát veszti**.
Éjszakai módban a `signal`, a `starboard` és az `amber` is tompított
változatot kap.

Amit a D2-ből **megtartunk**: az árnyalat nem változik, tehát a színkód
jelentése sértetlen. Zöld marad zöld, teál marad teál — csak halkabb.

#### A1-D2 — A tompítás mértéke: ~79% fényerő-vágás, azonos árnyalaton

| Token | Nappali | Éjszakai | Kontraszt a háttéren |
|---|---|---|---|
| `signal` | `#16E0C4` | **`#0C6E60`** | 3,27 : 1 |
| `starboard` | `#2FD06E` | **`#176B3C`** | 3,06 : 1 |
| `amber` | `#FFB300` | **`#7D5800`** | 3,13 : 1 |

A három érték azonos relatív vágással készült, így a nappali fényerő-sorrend
megmarad. A 3:1 körüli kontraszt tudatos: ezek **glyph-ek és ívek**, nem
folyó szöveg — a mai szöveg-rámpa alsó két foka is ez alatt van.

#### A1-D3 — A `port` változatlan marad

A bal-oldal piros (`#FF5A52`) nem tompul, tehát éjszaka ez lesz a képernyő
legvilágosabb színe.

Indok: a vörös hosszú hullámhosszú, a sötét-adaptációt lényegesen kevésbé
rontja, mint az azonos fényerejű zöld vagy teál — a tompítás itt keveset
nyerne, cserébe a bal-oldal jelzését halkítaná. Ez **szándékos aszimmetria**,
nem kifelejtés.

Következmény: a `port` és a `text` közötti kontraszt továbbra is 1,17:1,
tehát a bal-nyíl gyakorlatilag a szöveg színén van (a törzs Következmények
szakaszában vállalt romlás) — a jelentést a nyíl geometriája hordozza.

#### A1-D4 — A konfidencia-ív fokozatait a hossz különbözteti meg, nem a szín

A tompítás után a három fokozat fényereje összeér: `signal` 0,121,
`amber` 0,113, `textTertiary` 0,077 — a high és a medium közötti kontraszt
**1,04:1**.

Ezt vállaljuk, mert az ív jelentését elsősorban a **kitöltött hányad**
hordozza (1 / 0,66 / 0,33), és ez az ADR 0023 D7 óta tudatosan shape-kódolt
(„shape is, nem csak szín"). A szín innentől megerősítés, nem önálló jel.

Ha az on-device kör mégis azt mutatja, hogy a fokozatok összemosódnak, a
javítás **nem** a szín visszavilágosítása, hanem a hossz- vagy
vastagság-különbség növelése.

#### A1-D5 — A „csak a szöveg-rámpa vált" szerkezeti invariáns szűkül

A `watchNightColors` továbbra is a `watchDayColors`-ból származik
`copyWith`-tel, de már hat mezőt ír felül. A szerkezet így is garantálja,
hogy **ami nem szerepel a `copyWith`-ben, az nem térhet el**; a garantáltan
azonos halmaz ezután: `background`, `surface`, `critical`, `port`.

Az `onCritical` (törzs D4) és a séma-rögzítés (törzs D5) **érintetlen**.

### Következmények

- A `watch_night_theme_test.dart` „leaves every meaning-carrying colour
  untouched" tesztje szűkül a négy ténylegesen változatlan tokenre, és
  kiegészül a három új érték állításával. A teszt neve is pontosításra
  szorul: már nem minden jelentés-hordozó szín marad.
- Az on-device kör megismétlendő, külön figyelemmel a konfidencia-ív
  fokozataira és a `starboard` nyíl olvashatóságára a 42 mm-es Watch4-en.
- A `docs/design-system.md` éjszakai rámpa-táblázata kiegészül a három
  jel-színnel.
- A törzs D2-je történelmi feljegyzés marad; az érvényes szabály ez az
  addendum.

### Elvetett alternatívák

- **Egyetlen zöld család két világossággal** (a `signal` és a `starboard`
  ugyanaz az árnyalat): vizuálisan egységesebb, de visszavonná az ADR 0023
  D7 döntését, ami a konfidenciát szándékosan tette teálra, hogy ne ütközzön
  a starboard zöldjével.
- **Enyhébb, ~50%-os tompítás:** olvashatóbb glyph-eket adna, de a
  verifikáció épp azt mutatta, hogy a probléma a nappali fényerő — a fél
  megoldás a panaszt nem szüntetné meg.
- **A jel-színek narancsba forgatása:** a legjobb lenne a
  sötét-adaptációnak, de megszüntetné a színkódot (starboard/port,
  megbízható/megbízhatatlan), ami a felület fő olvasási segédlete.
