class ValueMappings {
  ValueMappings._();

  static const outputVolumeValues = [
    1,
    5,
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    110,
    120,
    130,
    140,
    150,
    160,
    170,
    180,
    190,
    200,
  ];

  static const limiterValues = [30, 50, 70, 80, 90, 100];

  static const agcRatioValues = [50, 100, 300];

  static const agcMaxGainValues = [
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
    3000,
  ];

  static const vseBarkValues = [
    2200,
    2800,
    3400,
    4000,
    4600,
    5200,
    5800,
    6400,
    7000,
    7600,
    8200,
  ];

  static const diffSurroundDelayValues = [
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
  ];

  static const fieldSurroundWideningValues = [
    0,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
  ];

  static const bassGainDbLabels = [
    '3.5',
    '6.0',
    '8.0',
    '9.5',
    '10.9',
    '12.0',
    '13.1',
    '14.0',
    '14.8',
    '15.6',
    '16.1',
    '17.0',
    '17.5',
    '18.1',
    '18.6',
    '19.1',
    '19.5',
    '20.0',
    '20.4',
    '20.8',
  ];

  static const subwooferGainDbLabels = [
    '1.9',
    '8.0',
    '11.5',
    '14.0',
    '15.9',
    '17.5',
    '18.8',
    '20.0',
    '21.0',
    '21.9',
    '22.8',
    '23.5',
    '24.2',
    '24.9',
    '25.5',
    '26.0',
    '26.5',
    '27.0',
    '27.5',
    '28.0',
  ];

  static const clarityGainDbLabels = [
    '0.0',
    '3.5',
    '6.0',
    '8.0',
    '10.0',
    '11.0',
    '12.0',
    '13.0',
    '14.0',
    '14.8',
  ];

  static const dynamicSystemDevices = [
    ('Extreme Headphone (v2)', '140;6200;40;60;10;80'),
    ('High-End Headphone (v2)', '180;5800;55;80;10;70'),
    ('Common Headphone (v2)', '300;5600;60;105;10;50'),
    ('Low-End Headphone (v2)', '600;5400;60;105;10;20'),
    ('Common Earphone (v2)', '100;5600;40;80;50;50'),
    ('Extreme Headphone (v1)', '1200;6200;40;80;0;20'),
    ('High-End Headphone (v1)', '1000;6200;40;80;0;10'),
    ('Common Headphone (v1)', '800;6200;40;80;10;0'),
    ('Common Earphone (v1)', '400;6200;40;80;10;0'),
    ('Apple Earphone', '1200;6200;50;90;15;10'),
    ('Monster Earphone', '1000;6200;50;90;30;10'),
    ('Motorola Earphone', '1100;6200;60;100;20;0'),
    ('Philips Earphone', '1200;6200;50;100;10;50'),
    ('SHP2000', '1200;6200;60;100;0;30'),
    ('SHP9000', '1200;6200;40;80;0;30'),
    ('Unknown Type I', '1000;6200;60;100;0;0'),
    ('Unknown Type II', '1000;6200;60;120;0;0'),
    ('Unknown Type III', '1000;6200;80;140;0;0'),
    ('Unknown Type IV', '800;6200;80;140;0;0'),
    ('Unknown Type V', '0;0;0;0;0;0'),
    ('pittvandewitt flavor #1', '180;5400;40;60;50;0'),
    ('pittvandewitt flavor #2', '1200;6000;40;60;0;80'),
    ('pittvandewitt flavor #3', '140;5400;40;60;0;0'),
  ];

  static const bassModeLabels = ['Natural', 'Pure Bass', 'Subwoofer'];
  static const clarityModeLabels = ['Natural', 'OZone', 'XHiFi'];
  static const analogXModeLabels = ['Mild', 'Medium', 'Strong'];
  static const cureCrossfeedLabels = ['Mild', 'Medium', 'Strong'];

  static int safeIndex(List<int> arr, int idx) {
    if (idx >= 0 && idx < arr.length) return arr[idx];
    return arr.isNotEmpty ? arr[0] : 0;
  }
}
