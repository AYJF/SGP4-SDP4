class CoordGeo {
  CoordGeo({
    this.lat: 0.0,
    this.lon: 0.0,
    this.alt: 0.0,
  });

  double lat; // Latitude,  radians (negative south)
  double lon; // Longitude, radians (negative west)
  double alt; // Altitude,  km      (above mean sea level)
}

class CoordTopo {
  CoordTopo({
    this.az: 0.0,
    this.el: 0.0,
    this.range: 0.0,
    this.rangeRate: 0.0,
  });

  double az; // Azimuth, radians
  double el; // Elevation, radians
  double range; // Range, kilometers
  double rangeRate; // Range rate of change, km/sec
  // Negative value means "towards observer"
}
