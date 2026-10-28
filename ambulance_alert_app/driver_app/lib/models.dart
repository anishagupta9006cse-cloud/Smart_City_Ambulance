import 'package:latlong2/latlong.dart';

double _d(dynamic v, [double def = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

String _s(dynamic v, [String def = '']) => v == null ? def : v.toString();

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _l(dynamic v) => v is List ? v : <dynamic>[];

class Junction {
  final String id;
  final String name;
  final LatLng point;
  final double chain;
  Junction(this.id, this.name, this.point, this.chain);

  factory Junction.fromJson(Map<String, dynamic> j) => Junction(
        _s(j['id']),
        _s(j['name'], 'Junction'),
        LatLng(_d(j['lat']), _d(j['lng'])),
        _d(j['chain']),
      );
}

class RouteInfo {
  final List<LatLng> points;
  final List<Junction> junctions;
  final double distance;
  final double duration;
  final bool fallback;
  RouteInfo(this.points, this.junctions, this.distance, this.duration, this.fallback);

  factory RouteInfo.fromJson(Map<String, dynamic> j) {
    final pts = <LatLng>[];
    for (final e in _l(j['points'])) {
      final l = _l(e);
      if (l.length >= 2) pts.add(LatLng(_d(l[0]), _d(l[1])));
    }
    return RouteInfo(
      pts,
      _l(j['junctions']).map((e) => Junction.fromJson(_m(e))).toList(),
      _d(j['distance']),
      _d(j['duration']),
      j['fallback'] == true,
    );
  }
}

class PlaceResult {
  final String name;
  final LatLng point;
  final String category; // hospital | police | transport | market | ... | other
  final bool local; // true = saved in our own places database
  final int? distance; // metres from the user (if known)
  PlaceResult(this.name, this.point,
      {this.category = 'other', this.local = false, this.distance});
}

class NextJunction {
  final String id;
  final String name;
  final LatLng point;
  final double distance;
  NextJunction(this.id, this.name, this.point, this.distance);
}

class PostInfo {
  final String id;
  final String name;
  final LatLng point;
  final double radius;
  final double distAhead;
  final String status;
  final bool acked;
  PostInfo(this.id, this.name, this.point, this.radius, this.distAhead, this.status, this.acked);
}

class PoliceAction {
  final String postName;
  final String action;
  final int at;
  PoliceAction(this.postName, this.action, this.at);

  String get label {
    switch (action) {
      case 'ack':
        return 'Police saw your alert';
      case 'clear_lane':
        return 'Police are clearing the lane';
      case 'escalate':
        return 'Police asked for help';
      default:
        return action;
    }
  }
}

/// A police post whose phone is online (shown on the driver map, even when it is not on the route).
class PolicePost {
  final String id;
  final String name;
  final String area;
  final LatLng point;
  final double radius;
  PolicePost(this.id, this.name, this.area, this.point, this.radius);

  factory PolicePost.fromJson(Map<String, dynamic> j) => PolicePost(
        _s(j['id']),
        _s(j['name'], 'Police Post'),
        _s(j['area']),
        LatLng(_d(j['lat']), _d(j['lng'])),
        _d(j['radius'], 500),
      );
}

/// State of one IoT device (display + buzzer).
class IotTelemetry {
  final double? lat;
  final double? lng;
  final double speed;
  final double altitude;
  final int sats;
  final bool fix;
  final double hdop;
  final int? battery;
  final int updatedAt;

  IotTelemetry({
    this.lat,
    this.lng,
    this.speed = 0,
    this.altitude = 0,
    this.sats = 0,
    this.fix = false,
    this.hdop = 0,
    this.battery,
    this.updatedAt = 0,
  });

  factory IotTelemetry.fromJson(Map<String, dynamic> j) => IotTelemetry(
        lat: j['lat'] != null ? _d(j['lat']) : null,
        lng: j['lng'] != null ? _d(j['lng']) : null,
        speed: _d(j['speed']),
        altitude: _d(j['altitude']),
        sats: (j['sats'] is num) ? (j['sats'] as num).toInt() : 0,
        fix: j['fix'] == true,
        hdop: _d(j['hdop']),
        battery: (j['battery'] is num) ? (j['battery'] as num).toInt() : null,
        updatedAt: (j['updatedAt'] is num) ? (j['updatedAt'] as num).toInt() : 0,
      );
}

class IotDevice {
  final String id;
  final bool online;
  final int? lastSeenSec;
  final bool auto;
  final bool displayOn;
  final String displayText;
  final bool buzzerOn;
  final String buzzerPattern;
  final int buzzerRemaining;
  final bool ledOn;
  final String ledPattern;
  final int ledRemaining;
  final IotTelemetry? telemetry;

  IotDevice({
    required this.id,
    required this.online,
    required this.lastSeenSec,
    required this.auto,
    required this.displayOn,
    required this.displayText,
    required this.buzzerOn,
    required this.buzzerPattern,
    required this.buzzerRemaining,
    this.ledOn = false,
    this.ledPattern = 'off',
    this.ledRemaining = 0,
    this.telemetry,
  });

  factory IotDevice.fromJson(Map<String, dynamic> j) {
    final d = _m(j['display']);
    final b = _m(j['buzzer']);
    final l = _m(j['led']);
    final tel = j['telemetry'] is Map ? IotTelemetry.fromJson(_m(j['telemetry'])) : null;
    return IotDevice(
      id: _s(j['id']),
      online: j['online'] == true,
      lastSeenSec: j['lastSeenSec'] is num ? (j['lastSeenSec'] as num).round() : null,
      auto: j['auto'] != false,
      displayOn: d['on'] == true,
      displayText: _s(d['text']),
      buzzerOn: b['on'] == true,
      buzzerPattern: _s(b['pattern'], 'off'),
      buzzerRemaining: _d(b['remainingSec']).round(),
      ledOn: l['on'] == true,
      ledPattern: _s(l['pattern'], 'off'),
      ledRemaining: _d(l['remainingSec']).round(),
      telemetry: tel,
    );
  }
}

class BedBooking {
  final String hospitalName;
  final String bedType;
  final String patientBrief;
  final String contactPhone;
  final String status;
  final int bookedAt;

  BedBooking({
    required this.hospitalName,
    required this.bedType,
    this.patientBrief = '',
    this.contactPhone = '',
    this.status = 'CONFIRMED',
    int? bookedAt,
  }) : bookedAt = bookedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'hospitalName': hospitalName,
        'bedType': bedType,
        'patientBrief': patientBrief,
        'contactPhone': contactPhone,
        'status': status,
        'bookedAt': bookedAt,
      };

  factory BedBooking.fromJson(Map<String, dynamic> j) => BedBooking(
        hospitalName: _s(j['hospitalName']),
        bedType: _s(j['bedType'], 'Emergency ICU Bed'),
        patientBrief: _s(j['patientBrief']),
        contactPhone: _s(j['contactPhone']),
        status: _s(j['status'], 'CONFIRMED'),
        bookedAt: (j['bookedAt'] is num) ? (j['bookedAt'] as num).toInt() : null,
      );
}

class TripState {
  final String status; // ok | off_route | completed | stopped
  final double chain;
  final double total;
  final double remaining;
  final double etaSec;
  final NextJunction? nextJunction;
  final List<PostInfo> posts;
  final List<PoliceAction> actions;
  final bool critical;

  TripState({
    required this.status,
    required this.chain,
    required this.total,
    required this.remaining,
    required this.etaSec,
    required this.nextJunction,
    required this.posts,
    required this.actions,
    this.critical = false,
  });

  factory TripState.fromJson(Map<String, dynamic> j) {
    NextJunction? nj;
    if (j['nextJunction'] is Map) {
      final n = _m(j['nextJunction']);
      nj = NextJunction(_s(n['id']), _s(n['name'], 'Junction'),
          LatLng(_d(n['lat']), _d(n['lng'])), _d(n['distance']));
    }
    return TripState(
      status: _s(j['status'], 'ok'),
      critical: _s(j['priority']) == 'critical',
      chain: _d(j['chain']),
      total: _d(j['total']),
      remaining: _d(j['remaining']),
      etaSec: _d(j['etaSec']),
      nextJunction: nj,
      posts: _l(j['posts']).map((e) {
        final p = _m(e);
        return PostInfo(_s(p['id']), _s(p['name'], 'Police Post'),
            LatLng(_d(p['lat']), _d(p['lng'])), _d(p['radius'], 500),
            _d(p['distAhead']), _s(p['status'], 'standby'), p['acked'] == true);
      }).toList(),
      actions: _l(j['actions']).map((e) {
        final a = _m(e);
        return PoliceAction(_s(a['postName']), _s(a['action']), _d(a['at']).round());
      }).toList(),
    );
  }
}
