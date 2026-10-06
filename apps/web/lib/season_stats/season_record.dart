/// Egy szezon-rekord: az érték, a verseny neve és napja (ADR 0049
/// Addendum 2 R5). Az érték SI-ben: táv méterben, sebesség és szél
/// m/s-ben. A nap helyi naptári nap, éjfélkor, a napló szerint.
typedef SeasonRecord = ({double value, String raceName, DateTime day});
