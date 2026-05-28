import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Race-azonosítók forrása — injektálható seam (tesztben felülírható).
///
/// A `clockProvider` mintáját követi: a side-effectet (itt az UUID-generálást)
/// egyetlen helyen kötjük be, így a hívók determinisztikus id-vel tesztelhetők
/// `overrideWithValue`-val, mockolás nélkül.
final idProvider = Provider<String Function()>((ref) => const Uuid().v4);
