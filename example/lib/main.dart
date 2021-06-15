import 'package:sgp4_sdp4/sgp4_sdp4.dart';

main() {
  /// TLE Example. Getting from https://www.celestrak.com/NORAD/elements/
  const String name = "FENGYUN 2H";
  const String line1 =
      "1 43491U 18050A   21166.49349236 -.00000118  00000-0  00000-0 0  9992";
  const String line2 =
      "2 43491   0.2424 116.6184 0003771  15.2255  28.7068  1.00276093 11113";

  /// Get the current date and time
  final dateTime = DateTime.now();

  /// Parse the TLE
  final TLE tleSGP4 = new TLE(name, line1, line2);

  ///Create a orbit object and print if is
  ///SGP4, for "near-Earth" objects, or SDP4 for "deep space" objects.
  final Orbit orbit = new Orbit(tleSGP4);
  print("is SGP4: ${orbit.period() < 255 * 60}");

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

  print("lat: ${rad2deg(coord.lat)}  lng: ${rad2deg(coord.lon)}");
}
