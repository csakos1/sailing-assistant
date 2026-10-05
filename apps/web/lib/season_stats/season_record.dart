/// Egy szezon-rekord: az érték m/s-ben, a verseny neve és napja (ADR 0049
/// D3, Addendum 1 P4). A nap helyi naptári nap, éjfélkor, a napló szerint.
typedef SeasonRecord = ({double valueMps, String raceName, DateTime day});
