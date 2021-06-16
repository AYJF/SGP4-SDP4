import 'package:sgp4_sdp4/sgp4_sdp4.dart';

main() {
  /// TLE Example. Getting from https://www.celestrak.com/NORAD/elements/
  const String name = "NOAA 1 [-]";
  const String line1 =
      "1 04793U 70106A   21166.60470920 -.00000034  00000-0  63442-4 0  9992";
  const String line2 =
      "2 04793 101.6070 233.8539 0031162 315.9496 221.8620 12.53999299311603";

  /// Get the current date and time
  final dateTime = DateTime.now();

  /// Parse the TLE
  final TLE tleSGP4 = new TLE(name, line1, line2);

  ///Create a orbit object and print if is
  ///SGP4, for "near-Earth" objects, or SDP4 for "deep space" objects.
  final Orbit orbit = new Orbit(tleSGP4);
  print("is SGP4: ${orbit.period() < 255 * 60}\n");

  /// get the Keplerian elements
  print("Keplerian elements and values:");
  print("Argument of Perigee: ${rad2deg(orbit.argPerigee())}");
  print("Eccentricity: ${orbit.eccentricity()}");
  print("Inclination:  ${rad2deg(orbit.inclination())}");
  print("RAAN:         ${rad2deg(orbit.raan())}");
  print("Mean Motion:  ${orbit.meanMotion()}");

  /// get the utc time in Julian Day
  ///  + 4/24 need it, diferent time zone (Cuba -4 hrs )
  final double utcTime = Julian.fromFullDate(dateTime.year, dateTime.month,
              dateTime.day, dateTime.hour, dateTime.minute)
          .getDate() +
      4 / 24.0;

  final Eci eciPos =
      orbit.getPosition((utcTime - orbit.epoch().getDate()) * MIN_PER_DAY);

  ///Get the current lat, lng of the satellite
  final CoordGeo coord = eciPos.toGeo();
  if (coord.lon > PI) coord.lon -= TWOPI;

  print("\n\n");

  print("lat: ${rad2deg(coord.lat)}");
  print("lng: ${rad2deg(coord.lon)}");
  print("Period: ${(orbit.period() / 60.0).round()} min");
}
