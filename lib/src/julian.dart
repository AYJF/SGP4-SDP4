import 'globals.dart';

const double EPOCH_JAN1_00H_1900 =
    2415019.5; // Jan 1.0 1900 = Jan 1 1900 00h UTC
const double EPOCH_JAN1_12H_1900 =
    2415020.0; // Jan 1.5 1900 = Jan 1 1900 12h UTC
const double EPOCH_JAN1_12H_2000 =
    2451545.0; // Jan 1.5 2000 = Jan 1 2000 12h UTC

class CDate {
  final int year; // Year : Includes the century.
  final int? month; // Month: 1..12
  final double? day; // Day  : 1..31 including fractional part

  CDate({
    required this.year,
    this.day,
    this.month,
  });
}

class Julian {
  late double _date; // Julian date

  /// Create a Julian date object from a year and day of year.
  /// Example parameters: year = 2001, day = 1.5 (Jan 1 12h)
  Julian(int year, double day) {
    initialize(year, day);
  }

  Julian.fromFullDate(
      int year, // i.e., 2004
      int mon, // 1..12
      int day, // 1..31
      int hour, // 0..23
      int min, // 0..59
      {double sec = 0.0}) {
    late int n;
    int f1 = ((275.0 * mon) / 9.0).round();
    int f2 = ((mon + 9.0) / 12.0).round();

    if (isLeapYear(year)) {
      // Leap year
      n = f1 - f2 + day - 30;
    } else {
      // Common year
      n = f1 - (2 * f2) + day - 30;
    }

    double dblDay = n + (hour + (min + (sec / 60.0)) / 60.0) / 24.0;

    initialize(year, dblDay);
  }

  void initialize(int year, double day) {
    // 1582 A.D.: 10 days removed from calendar
    // 3000 A.D.: Arbitrary error checking limit
    assert((year > 1582) && (year < 3000));
    assert((day >= 1.0) && (day < 367.0));

    // Now calculate Julian date

    year--;

    // Centuries are not leap years unless they divide by 400
    int A = (year / 100).round();
    int B = 2 - A + (A / 4).round();

    double newYears = (365.25 * year).round() +
        (30.6001 * 14).round() +
        1720994.5 +
        B; // 1720994.5 = Oct 30, year -1

    _date = newYears + day;
  }

  double fromJan1_00h_1900() {
    return _date - EPOCH_JAN1_00H_1900;
  }

  double fromJan1_12h_1900() {
    return _date - EPOCH_JAN1_12H_1900;
  }

  double fromJan1_12h_2000() {
    return _date - EPOCH_JAN1_12H_2000;
  }

  double date() {
    return _date;
  }

  static bool isLeapYear(int y) {
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
  }

  void addDay(double day) {
    _date += day;
  }

  void addHour(double hr) {
    _date += (hr / HR_PER_DAY);
  }

  void addMin(double min) {
    _date += (min / MIN_PER_DAY);
  }

  void addSec(double sec) {
    _date += (sec / SEC_PER_DAY);
  }

  double spanDay(Julian b) {
    return _date - b._date;
  }

  double spanHour(Julian b) {
    return spanDay(b) * HR_PER_DAY;
  }

  double spanMin(Julian b) {
    return spanDay(b) * MIN_PER_DAY;
  }

  double spanSec(Julian b) {
    return spanDay(b) * SEC_PER_DAY;
  }

  double getDate() {
    return _date;
  }

  /// getComponent()
  /// Return requested components of date.
  /// Year : Includes the century.
  /// Month: 1..12
  /// Day  : 1..31 including fractional part
  CDate getComponent(
      int pYear, int pMon /* = NULL */, double pDOM /* = NULL */) {
    double jdAdj = getDate() + 0.5;
    int Z = jdAdj.round(); // integer part
    double F = jdAdj - Z; // fractional part
    double alpha = ((Z - 1867216.25) / 36524.25);
    double A = Z + 1 + alpha - (alpha / 4.0);
    double B = A + 1524.0;
    int C = ((B - 122.1) / 365.25).round();
    int D = (C * 365.25).round();
    int E = ((B - D) / 30.6001).round();

    double DOM = B - D - (E * 30.6001) + F;
    int month = (E < 13.5) ? (E - 1) : (E - 13);
    int year = (month > 2.5) ? (C - 4716) : (C - 4715);

    //  *pYear = year;

    //  if (pMon != NULL)
    //     *pMon = month;

    //  if (pDOM != NULL)
    //     *pDOM = DOM;

    return CDate(
      year: year,
      month: month,
      day: DOM,
    );
  }

  /// toGmst()
  /// Calculate Greenwich Mean Sidereal Time for the Julian date. The return value
  /// is the angle, in radians, measuring eastward from the Vernal Equinox to the
  /// prime meridian. This angle is also referred to as "ThetaG" (Theta GMST).
  ///
  /// References:
  ///    The 1992 Astronomical Almanac, page B6.
  ///    Explanatory Supplement to the Astronomical Almanac, page 50.
  ///    Orbital Coordinate Systems, Part III, Dr. T.S. Kelso, Satellite Times,
  ///       Nov/Dec 1995
  double toGmst() {
    final double UT = (_date + 0.5).remainder(1.0);
    final double TU = (fromJan1_12h_2000() - UT) / 36525.0;

    double GMST =
        24110.54841 + TU * (8640184.812866 + TU * (0.093104 - TU * 6.2e-06));

    GMST = (GMST + SEC_PER_DAY * OMEGA_E * UT).remainder(SEC_PER_DAY);

    if (GMST < 0.0) GMST += SEC_PER_DAY; // "wrap" negative modulo value

    return (TWOPI * (GMST / SEC_PER_DAY));
  }

  /// toLmst()
  /// Calculate Local Mean Sidereal Time for given longitude (for this date).
  /// The longitude is assumed to be in radians measured west from Greenwich.
  /// The return value is the angle, in radians, measuring eastward from the
  /// Vernal Equinox to the given longitude.
  double toLmst(double lon) {
    return (toGmst() + lon).remainder(TWOPI);
  }
}
