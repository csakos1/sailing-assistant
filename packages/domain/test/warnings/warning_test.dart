import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Warning', () {
    group('codeId', () {
      test('minden v1 leaf a saját stabil snake_case id-jét adja', () {
        // A codeId logba/telemetriába kerül, ezért szerződés-szintű:
        // egy string-csere is breaking change.
        expect(const GatewayDisconnected().codeId, 'gateway_disconnected');
        expect(const GpsSignalLost().codeId, 'gps_signal_lost');
        expect(const GpsTimeUnsynced().codeId, 'gps_time_unsynced');
        expect(
          const WindShiftTrendInsufficient().codeId,
          'wind_shift_trend_insufficient',
        );
      });

      test('a négy v1 codeId egyedi', () {
        final ids = <String>{
          const GatewayDisconnected().codeId,
          const GpsSignalLost().codeId,
          const GpsTimeUnsynced().codeId,
          const WindShiftTrendInsufficient().codeId,
        };
        expect(ids, hasLength(4));
      });
    });

    group('severity', () {
      test('a kapcsolat- és GPS-kiesés critical', () {
        expect(const GatewayDisconnected().severity, WarningSeverity.critical);
        expect(const GpsSignalLost().severity, WarningSeverity.critical);
      });

      test('a GPS-idő-szinkronhiány warning', () {
        expect(const GpsTimeUnsynced().severity, WarningSeverity.warning);
      });

      test('az elégtelen szél-trend info', () {
        expect(
          const WindShiftTrendInsufficient().severity,
          WarningSeverity.info,
        );
      });
    });

    group('equality', () {
      test('azonos típusú leafek egyenlők, azonos hashCode-dal', () {
        expect(const GatewayDisconnected(), const GatewayDisconnected());
        expect(
          const GatewayDisconnected().hashCode,
          const GatewayDisconnected().hashCode,
        );
      });

      test('eltérő leaf-típusok nem egyenlők azonos severity mellett sem', () {
        // Mindkettő critical, de a runtimeType megkülönbözteti —
        // a severity-egyezés nem jelent egyenlőséget.
        expect(const GatewayDisconnected(), isNot(const GpsSignalLost()));
      });
    });
  });
}
