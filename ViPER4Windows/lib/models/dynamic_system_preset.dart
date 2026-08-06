import 'package:viper4windows/l10n/app_localizations.dart';

class BuiltinDsDevice {
  final String Function(S) nameOf;
  final int xLow;
  final int xHigh;
  final int yLow;
  final int yHigh;
  final int sideGainLow;
  final int sideGainHigh;

  const BuiltinDsDevice({
    required this.nameOf,
    required this.xLow,
    required this.xHigh,
    required this.yLow,
    required this.yHigh,
    required this.sideGainLow,
    required this.sideGainHigh,
  });
}

class DsDevices {
  DsDevices._();

  static const List<BuiltinDsDevice> builtins = [
    BuiltinDsDevice(
      nameOf: _extremeHpV2,
      xLow: 140,
      xHigh: 6200,
      yLow: 40,
      yHigh: 60,
      sideGainLow: 10,
      sideGainHigh: 80,
    ),
    BuiltinDsDevice(
      nameOf: _highEndHpV2,
      xLow: 180,
      xHigh: 5800,
      yLow: 55,
      yHigh: 80,
      sideGainLow: 10,
      sideGainHigh: 70,
    ),
    BuiltinDsDevice(
      nameOf: _commonHpV2,
      xLow: 300,
      xHigh: 5600,
      yLow: 60,
      yHigh: 105,
      sideGainLow: 10,
      sideGainHigh: 50,
    ),
    BuiltinDsDevice(
      nameOf: _lowEndHpV2,
      xLow: 600,
      xHigh: 5400,
      yLow: 60,
      yHigh: 105,
      sideGainLow: 10,
      sideGainHigh: 20,
    ),
    BuiltinDsDevice(
      nameOf: _commonEpV2,
      xLow: 100,
      xHigh: 5600,
      yLow: 40,
      yHigh: 80,
      sideGainLow: 50,
      sideGainHigh: 50,
    ),
    BuiltinDsDevice(
      nameOf: _extremeHpV1,
      xLow: 1200,
      xHigh: 6200,
      yLow: 40,
      yHigh: 80,
      sideGainLow: 0,
      sideGainHigh: 20,
    ),
    BuiltinDsDevice(
      nameOf: _highEndHpV1,
      xLow: 1000,
      xHigh: 6200,
      yLow: 40,
      yHigh: 80,
      sideGainLow: 0,
      sideGainHigh: 10,
    ),
    BuiltinDsDevice(
      nameOf: _commonHpV1,
      xLow: 800,
      xHigh: 6200,
      yLow: 40,
      yHigh: 80,
      sideGainLow: 10,
      sideGainHigh: 0,
    ),
    BuiltinDsDevice(
      nameOf: _commonEpV1,
      xLow: 400,
      xHigh: 6200,
      yLow: 40,
      yHigh: 80,
      sideGainLow: 10,
      sideGainHigh: 0,
    ),
  ];
}

String _extremeHpV2(S l) => l.dsDeviceExtremeHeadphoneV2;
String _highEndHpV2(S l) => l.dsDeviceHighEndHeadphoneV2;
String _commonHpV2(S l) => l.dsDeviceCommonHeadphoneV2;
String _lowEndHpV2(S l) => l.dsDeviceLowEndHeadphoneV2;
String _commonEpV2(S l) => l.dsDeviceCommonEarphoneV2;
String _extremeHpV1(S l) => l.dsDeviceExtremeHeadphoneV1;
String _highEndHpV1(S l) => l.dsDeviceHighEndHeadphoneV1;
String _commonHpV1(S l) => l.dsDeviceCommonHeadphoneV1;
String _commonEpV1(S l) => l.dsDeviceCommonEarphoneV1;
