import 'package:domain/domain.dart';

/// A foreground service értesítésének címe szabad és rajt előtti módban
/// (ADR 0054 D5).
const String engineNotificationTitleInstruments = 'Foretack — műszerek';

/// A foreground service értesítésének címe versenyen (ADR 0054 D5).
const String engineNotificationTitleRace = 'Foretack — verseny';

/// Az értesítés címe az engine módjából: `active` alatt a verseny, minden
/// más módban (szabad, rajt előtti, cél után) a műszerek címe.
///
/// A widget-fán kívül, a service-izolátumban is fut, ezért nem az ARB-ből
/// jön (a korábbi rögzített cím mintájára).
String engineNotificationTitle(RaceStatus? status) =>
    status == RaceStatus.active
    ? engineNotificationTitleRace
    : engineNotificationTitleInstruments;
