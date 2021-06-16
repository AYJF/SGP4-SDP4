/// Latitude,  radians (negative south)
/// Longitude, radians (negative west)
/// Altitude,  km      (above mean sea level)
class CoordGeo {
  CoordGeo({
    this.lat: 0.0,
    this.lon: 0.0,
    this.alt: 0.0,
  });

  double lat;
  double lon;
  double alt;
}

/// Azimuth, radians
/// Elevation, radians
/// Range, kilometers
/// Range rate of change, km/sec
/// Negative value means "towards observer"
class CoordTopo {
  CoordTopo({
    this.az: 0.0,
    this.el: 0.0,
    this.range: 0.0,
    this.rangeRate: 0.0,
  });

  double az;
  double el;
  double range;
  double rangeRate;
}
