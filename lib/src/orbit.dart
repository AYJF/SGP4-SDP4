import 'dart:math';

import 'eci.dart';
import 'globals.dart';
import 'julian.dart';
import 'norad_sdp4.dart';
import 'norad_sgp4.dart';
import 'tle.dart';

class Orbit {
  late TLE m_tle;
  late Julian m_jdEpoch;
  dynamic m_pNoradModel;

  // Caching variables; note units are not necessarily the same as tle units
  late double m_secPeriod;

  // Caching variables recovered from the input TLE elements
  late double m_aeAxisSemiMajorRec; // semimajor axis, in AE units
  late double m_aeAxisSemiMinorRec; // semiminor axis, in AE units
  late double m_rmMeanMotionRec; // radians per minute
  late double m_kmPerigeeRec; // perigee, in km
  late double m_kmApogeeRec; // apogee, in km

  Orbit(TLE tle) : m_tle = tle {
    m_tle.initialize();

    int epochYear = m_tle.getField(eField.FLD_EPOCHYEAR).round();
    double epochDay = m_tle.getField(eField.FLD_EPOCHDAY);

    if (epochYear < 57)
      epochYear += 2000;
    else
      epochYear += 1900;

    m_jdEpoch = Julian(epochYear, epochDay);

    m_secPeriod = -1.0;

    // Recover the original mean motion and semimajor axis from the
    // input elements.
    double mm = meanMotionTle();
    double rpmin = mm * TWOPI / MIN_PER_DAY; // rads per minute

    double a1 = pow(XKE / rpmin, TWOTHRD) as double;
    double e = eccentricity();
    double i = inclination();
    double temp =
        (1.5 * CK2 * (3.0 * sqr(cos(i)) - 1.0) / pow(1.0 - e * e, 1.5));
    double delta1 = temp / (a1 * a1);
    double a0 = a1 *
        (1.0 - delta1 * ((1.0 / 3.0) + delta1 * (1.0 + 134.0 / 81.0 * delta1)));

    double delta0 = temp / (a0 * a0);

    m_rmMeanMotionRec = rpmin / (1.0 + delta0);
    m_aeAxisSemiMajorRec = a0 / (1.0 - delta0);
    m_aeAxisSemiMinorRec = m_aeAxisSemiMajorRec * sqrt(1.0 - (e * e));
    m_kmPerigeeRec = XKMPER_WGS72 * (m_aeAxisSemiMajorRec * (1.0 - e) - AE);
    m_kmApogeeRec = XKMPER_WGS72 * (m_aeAxisSemiMajorRec * (1.0 + e) - AE);

    if (TWOPI / m_rmMeanMotionRec >= 225.0) {
      // SDP4 - period >= 225 minutes.
      m_pNoradModel = new NoradSDP4(this);
    } else {
      // SGP4 - period < 225 minutes
      m_pNoradModel = new NoradSGP4(this);
    }
  }

  // "Recovered" from the input elements
  double semiMajor() {
    return m_aeAxisSemiMajorRec;
  }

  double semiMinor() {
    return m_aeAxisSemiMinorRec;
  }

  /// mean motion, rads/min
  double meanMotion() {
    return m_rmMeanMotionRec;
  }

  /// major axis in AE
  double major() {
    return 2.0 * semiMajor();
  }

  /// minor axis in AE
  double minor() {
    return 2.0 * semiMinor();
  }

  /// perigee in km
  double perigee() {
    return m_kmPerigeeRec;
  }

  /// apogee in km
  double apogee() {
    return m_kmApogeeRec;
  }

  /// return the field in radians
  double radGet(eField fld) {
    return m_tle.getField(fld, units: eUnits.U_RAD);
  }

  /// return the field in degree
  double degGet(eField fld) {
    return m_tle.getField(fld, units: eUnits.U_DEG);
  }

  /// return the inclination in radians
  double inclination() {
    return radGet(eField.FLD_I);
  }

  /// return the eccentricity
  double eccentricity() {
    return m_tle.getField(eField.FLD_E);
  }

  /// return the RAAN  in radians
  double raan() {
    return radGet(eField.FLD_RAAN);
  }

  /// return the Argument of Perigee in radians
  double argPerigee() {
    return radGet(eField.FLD_ARGPER);
  }

  double bStar() {
    return m_tle.getField(eField.FLD_BSTAR) / AE;
  }

  double drag() {
    return m_tle.getField(eField.FLD_MMOTIONDT);
  }

  double meanMotionTle() {
    return m_tle.getField(eField.FLD_MMOTION);
  }

  /// return the Mean Anonmoly in radians
  double meanAnomaly() {
    return radGet(eField.FLD_M);
  }

  /// getPosition()
  /// This procedure returns the ECI position and velocity for the satellite
  /// at "tsince" minutes from the (GMT) TLE epoch. The vectors returned in
  /// the ECI object are kilometer-based.
  /// tsince  - Time in minutes since the TLE epoch (GMT).
  Eci getPosition(double tsince) {
    Eci? eci = m_pNoradModel.getPosition(tsince);

    eci!.ae2Km();

    return eci;
  }

  /// Returns the mean anomaly in radians at given GMT.
  /// At epoch, the mean anomaly is given by the elements data.
  double meanAnomalyFromGmt(Julian gmt) {
    double span = tPlusEpoch(gmt);
    double P = period();

    assert(P != 0.0);

    return (meanAnomaly() + (TWOPI * (span / P))).remainder(TWOPI);
  }

  /// Return the period in seconds
  double period() {
    if (m_secPeriod < 0.0) {
      // Calculate the period using the recovered mean motion.
      if (m_rmMeanMotionRec == 0)
        m_secPeriod = 0.0;
      else
        m_secPeriod = TWOPI / m_rmMeanMotionRec * 60.0;
    }

    return m_secPeriod;
  }

  /// return the Julian object
  Julian epoch() {
    return m_jdEpoch;
  }

  /// Returns elapsed number of seconds from epoch to given time.
  /// Note: "Predicted" TLEs can have epochs in the future.
  double tPlusEpoch(Julian gmt) {
    return gmt.spanSec(epoch());
  }

  /// satName()
  /// Return the name of the satellite. If requested, the NORAD number is
  /// appended to the end of the name, i.e., "ISS (ZARYA) #25544".
  /// The name of the satellite with the NORAD number appended is important
  /// because many satellites, especially debris, have the same name and
  /// would otherwise appear to be the same satellite in ouput data.
  String satName({bool fAppendId: false /* = false */}) {
    String str = m_tle.getName();

    if (fAppendId) {
      str = str + " #" + satId();
    }

    return str;
  }

  /// satId()
  /// Return the NORAD number of the satellite.
  String satId() {
    return m_tle.getField(eField.FLD_NORADNUM,
        units: eUnits.U_NATIVE, pstr: '');
  }
}
