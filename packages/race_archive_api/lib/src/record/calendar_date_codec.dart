import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/record/calendar_date.dart';

/// A [key] mező naptári napja (`"YYYY-MM-DD"`) a [reader] objektumában.
///
/// A rossz alak vagy a nem létező nap dekódolási hiba, nem szabálysértés
/// (ADR 0048 Addendum 2 H5).
CalendarDate readCalendarDate(JsonReader reader, String key) =>
    CalendarDate.tryParse(reader.string(key)) ??
    JsonReader.failAt(reader.childPath(key), 'existing date YYYY-MM-DD');
