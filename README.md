# sgp4_sdp4

NORAD SGP4/SDP4 Implementations

## Getting Started

After looking for some time for some suitable package for the right job with satellite tracking in dart language, I wasn't to be able to find any. That's how sgp4_sdp4 was born!

The SGP4/SDP4 package are implementations of NORAD algorithms for determining satellite location and velocity in Earth orbit.  The algorithms come from the December, 1980 NORAD document ["Space Track Report No. 3"](https://www.celestrak.com/publications/AIAA/2006-6753/).  The orbital algorithms implemented in SGP4/SDP4 package are: SGP4, for "near-Earth" objects, and SDP4 for "deep space" objects.  These algorithms are widely used in the satellite tracking community and produce very accurate results when provided with current NORAD two-line element data.

The package contains complete source code for the SGP4/SDP4 algorithms, miscellaneous supporting classes, and an example program that demonstrates how to calculate the ECI position of a satellite, as well as its geo coordinates(lat,lng)

## Example

A simple usege example 


```dart
import 'package:sgp4_sdp4/sgp4_sdp4.dart';

main() {
  /// TLE Example. Getting from https://www.celestrak.com/NORAD/elements/
  const String name = "NOAA 1";
  const String line1 =
      "1 04793U 70106A   21165.13556590 -.00000028  00000-0  10004-3 0  9995";
  const String line2 =
      "2 04793 101.6071 232.4155 0031175 318.8433  69.5245 12.53999256311423";

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
```


## Documentation

For excellent information on the underlying physics of orbits, visible satellite observations, current NORAD TLE data, and other related material, see www.celestrak.com which is maintained by Dr. T. S. Kelso. 


## TODO

I work on this project in my free time because I have my personal life and job.

- Provide more examples 
- look angle from an Earth ground site (Azimuth and elevation)
- Solar position


