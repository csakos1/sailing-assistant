import 'package:flutter/foundation.dart';
import 'package:foretack_web/app/leave_warning_registry.dart';

/// A VM-en nincs böngészőfül: a kötés üres, a visszaadott leválasztó
/// sem csinál semmit. A [registry] a tesztekben így is olvasható.
VoidCallback bindLeaveWarning(LeaveWarningRegistry registry) => _unbind;

void _unbind() {}
