import 'dart:math';

import 'coord.dart';
import 'eci.dart';
import 'globals.dart';
import 'julian.dart';
import 'vector.dart';

class Site {
  late CoordGeo geo; // lat, lon, alt of Earth site

  // Construction
  Site(CoordGeo geo) : this.geo = geo;
  // c'tor accepting:
//    Latitude  in degress (negative south)
//    Longitude in degress (negative west)
//    Altitude  in km
  Site.fromLatLngAlt(double degLat, double degLon, double kmAlt) {
    this.geo = CoordGeo(lat: deg2rad(degLat), lon: deg2rad(degLon), alt: kmAlt);
  }

  /// getPosition()
  /// Return the ECI coordinate of the site at the given time.
  Eci getPosition(Julian date) {
    return Eci.fromGeo(this.geo, date);
  }

  /// setGeo()
  /// Set a new geographic position
  void setGeo(CoordGeo geo) {
    this.geo = geo;
  }

  double getLat() {
    return this.geo.lat;
  }

  double getLon() {
    return this.geo.lon;
  }

  double getAlt() {
    return this.geo.alt;
  }

  /// getLookAngle()
  /// Return the topocentric (azimuth, elevation, etc.) coordinates for a target
  /// object described by the input ECI coordinates.
  CoordTopo getLookAngle(Eci eci) {
    // Calculate the ECI coordinates for this cSite object at the time
    // of interest.
    Julian date = eci.getDate();
    Eci eciSite = Eci.fromGeo(this.geo, date);

    // The Site ECI units are km-based; ensure target ECI units are same
    assert(eci.unitsAreKm());

    Vector vecRgRate = Vector(
        x: eci.getVel().x - eciSite.getVel().x,
        y: eci.getVel().y - eciSite.getVel().y,
        z: eci.getVel().z - eciSite.getVel().z);

    double x = eci.getPos().x - eciSite.getPos().x;
    double y = eci.getPos().y - eciSite.getPos().y;
    double z = eci.getPos().z - eciSite.getPos().z;
    double w = sqrt(sqr(x) + sqr(y) + sqr(z));

    Vector vecRange = Vector(x: x, y: y, z: z, w: w);

    // The site's Local Mean Sidereal Time at the time of interest.
    double theta = date.toLmst(getLon());

    double sin_lat = sin(getLat());
    double cos_lat = cos(getLat());
    double sin_theta = sin(theta);
    double cos_theta = cos(theta);

    double top_s = sin_lat * cos_theta * vecRange.x +
        sin_lat * sin_theta * vecRange.y -
        cos_lat * vecRange.z;
    double top_e = -sin_theta * vecRange.x + cos_theta * vecRange.y;
    double top_z = cos_lat * cos_theta * vecRange.x +
        cos_lat * sin_theta * vecRange.y +
        sin_lat * vecRange.z;
    double az = atan(-top_e / top_s);

    if (top_s > 0.0) az += PI;

    if (az < 0.0) az += 2.0 * PI;

    double el = asin(top_z / vecRange.w);
    double rate = (vecRange.x * vecRgRate.x +
            vecRange.y * vecRgRate.y +
            vecRange.z * vecRgRate.z) /
        vecRange.w;

    CoordTopo topo = CoordTopo(
        az: az, // azimuth,   radians
        el: el, // elevation, radians
        range: vecRange.w, // range, km
        rangeRate: rate); // rate,  km / sec

    // // Elevation correction for atmospheric refraction.
    // // Reference:  Astronomical Algorithms by Jean Meeus, pp. 101-104
    // // Note:  Correction is meaningless when apparent elevation is below horizon
    // topo.el += deg2rad(
    //     (1.02 / tan(deg2rad(rad2deg(el) + 10.3 / (rad2deg(el) + 5.11)))) /
    //         60.0);
    // if (topo.el < 0.0) {
    //   topo.el = el; // Reset to true elevation
    // }

    // if (topo.el > (PI / 2)) {
    //   topo.el = (PI / 2);
    // }

    return topo;
  }
}
