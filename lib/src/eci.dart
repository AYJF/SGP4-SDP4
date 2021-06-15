import 'dart:math';

import 'coord.dart';
import 'globals.dart';
import 'julian.dart';
import 'vector.dart';

enum VecUnits {
  UNITS_NONE, // not initialized
  UNITS_AE,
  UNITS_KM,
}

class Eci {
  late Vector pos;
  late Vector vel;
  late Julian date;
  late VecUnits vecUnits;

  Eci(Vector pos, Vector vel, Julian date, {bool isAeUnits: true})
      : this.pos = pos,
        this.vel = vel,
        this.date = date,
        vecUnits = isAeUnits ? VecUnits.UNITS_AE : VecUnits.UNITS_NONE;

  /// Eci(CoordGeo, Julian)
  /// Calculate the ECI coordinates of the location "geo" at time "date".
  /// Assumes geo coordinates are km-based.
  /// Assumes the earth is an oblate spheroid as defined in WGS '72.
  /// Reference: The 1992 Astronomical Almanac, page K11
  /// Reference: www.celestrak.com (Dr. TS Kelso)
  Eci.fromGeo(CoordGeo geo, Julian date) {
    vecUnits = VecUnits.UNITS_KM;

    double mfactor = TWOPI * (OMEGA_E / SEC_PER_DAY);
    double lat = geo.lat;
    double lon = geo.lon;
    double alt = geo.alt;

    /// Calculate Local Mean Sidereal Time (theta)
    double theta = date.toLmst(lon);
    double c = 1.0 / sqrt(1.0 + F * (F - 2.0) * sqr(sin(lat)));
    double s = sqr(1.0 - F) * c;
    double achcp = (XKMPER_WGS72 * c + alt) * cos(lat);

    this.date = date;

    this.pos.x = achcp * cos(theta); // km
    this.pos.y = achcp * sin(theta); // km
    this.pos.z = (XKMPER_WGS72 * s + alt) * sin(lat); // km
    this.pos.w =
        sqrt(sqr(this.pos.x) + sqr(this.pos.y) + sqr(this.pos.z)); // range, km

    this.vel.x = -mfactor * this.pos.y; // km / sec
    this.vel.y = mfactor * this.pos.x;
    this.vel.z = 0.0;
    this.vel.w = sqrt(sqr(vel.x) + // range rate km/sec^2
        sqr(vel.y));
  }

  Vector getPos() {
    return this.pos;
  }

  Vector getVel() {
    return this.vel;
  }

  Julian getDate() {
    return this.date;
  }

  void setUnitsAe() {
    vecUnits = VecUnits.UNITS_AE;
  }

  void setUnitsKm() {
    vecUnits = VecUnits.UNITS_KM;
  }

  bool unitsAreAe() {
    return vecUnits == VecUnits.UNITS_AE;
  }

  bool unitsAreKm() {
    return vecUnits == VecUnits.UNITS_KM;
  }

  /// toGeo()
// Return the corresponding geodetic position (based on the current ECI
// coordinates/Julian date).
// Assumes the earth is an oblate spheroid as defined in WGS '72.
// Side effects: Converts the position and velocity vectors to km-based units.
// Reference: The 1992 Astronomical Almanac, page K12.
// Reference: www.celestrak.com (Dr. TS Kelso)
  CoordGeo toGeo() {
    ae2Km(); // Vectors must be in kilometer-based units

    double theta = acTan(this.pos.y, this.pos.x);
    double lon = (theta - this.date.toGmst()).remainder(TWOPI);

    if (lon < 0.0) lon += TWOPI; // "wrap" negative modulo

    double r = sqrt(sqr(this.pos.x) + sqr(this.pos.y));
    double e2 = F * (2.0 - F);
    double lat = acTan(this.pos.z, r);

    const double delta = 1.0e-07;
    double phi;
    double c;

    do {
      phi = lat;
      c = 1.0 / sqrt(1.0 - e2 * sqr(sin(phi)));
      lat = acTan(pos.z + XKMPER_WGS72 * c * e2 * sin(phi), r);
    } while ((lat - phi).abs() > delta);

    double alt = r / cos(lat) - XKMPER_WGS72 * c;

    return CoordGeo(
        lat: lat, lon: lon, alt: alt); // radians, radians, kilometers
  }

  /// Convert position, velocity vector units from AE to km
  /// ae2Km()
  /// Convert the position and velocity vector units from AE-based units
  /// to kilometer based units.
  void ae2Km() {
    if (unitsAreAe()) {
      mulPos(XKMPER_WGS72 / AE); // km
      mulPos((XKMPER_WGS72 / AE) * (MIN_PER_DAY / 86400)); // km/sec
      vecUnits = VecUnits.UNITS_KM;
    }
  }

  void mulPos(double factor) {
    this.pos.mul(factor);
  }

  void mulVel(double factor) {
    this.vel.mul(factor);
  }
}
