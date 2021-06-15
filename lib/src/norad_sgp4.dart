import 'dart:math';

import 'eci.dart';
import 'globals.dart';
import 'norad_base.dart';
import 'orbit.dart';

class NoradSGP4 extends NoradBase {
  late double m_c5;
  late double m_omgcof;
  late double m_xmcof;
  late double m_delmo;
  late double m_sinmo;

  @override
  dynamic clone(Orbit orbit) {
    return new NoradSGP4(orbit);
  }

  /// getPosition()
  /// This procedure returns the ECI position and velocity for the satellite
  /// in the orbit at the given number of minutes since the TLE epoch time
  /// using the NORAD Simplified General Perturbation 4, near earth orbit
  /// model.

  /// tsince - Time in minutes since the TLE epoch (GMT).
  /// eci    - ECI object to hold position information.
  ///          To convert the returned ECI position vector to km,
  ///           multiply each component by:
  ///              (XKMPER_WGS72 / AE).
  ///           To convert the returned ECI velocity vector to km/sec,
  ///           multiply each component by:
  ///              (XKMPER_WGS72 / AE) * (MIN_PER_DAY / 86400).
  @override
  Eci getPosition(double tsince) {
    // For m_perigee less than 220 kilometers, the isimp flag is set and
    // the equations are truncated to linear variation in sqrt a and
    // quadratic variation in mean anomaly.  Also, the m_c3 term, the
    // delta omega term, and the delta m term are dropped.
    bool isimp = false;

    if ((m_Orbit.semiMajor() * (1.0 - m_Orbit.eccentricity()) / AE) <
        (220.0 / XKMPER_WGS72 + AE)) {
      isimp = true;
    }

    double d2 = 0.0;
    double d3 = 0.0;
    double d4 = 0.0;

    double t3cof = 0.0;
    double t4cof = 0.0;
    double t5cof = 0.0;

    if (!isimp) {
      double c1sq = m_c1 * m_c1;

      d2 = 4.0 * m_Orbit.semiMajor() * m_tsi * c1sq;

      double temp = d2 * m_tsi * m_c1 / 3.0;

      d3 = (17.0 * m_Orbit.semiMajor() + m_s4) * temp;
      d4 = 0.5 *
          temp *
          m_Orbit.semiMajor() *
          m_tsi *
          (221.0 * m_Orbit.semiMajor() + 31.0 * m_s4) *
          m_c1;
      t3cof = d2 + 2.0 * c1sq;
      t4cof = 0.25 * (3.0 * d3 + m_c1 * (12.0 * d2 + 10.0 * c1sq));
      t5cof = 0.2 *
          (3.0 * d4 +
              12.0 * m_c1 * d3 +
              6.0 * d2 * d2 +
              15.0 * c1sq * (2.0 * d2 + c1sq));
    }

    // Update for secular gravity and atmospheric drag.
    double xmdf = m_Orbit.meanAnomaly() + m_xmdot * tsince;
    double omgadf = m_Orbit.argPerigee() + m_omgdot * tsince;
    double xnoddf = m_Orbit.raan() + m_xnodot * tsince;
    double omega = omgadf;
    double xmp = xmdf;
    double tsq = tsince * tsince;
    double xnode = xnoddf + m_xnodcf * tsq;
    double tempa = 1.0 - m_c1 * tsince;
    double tempe = m_Orbit.bStar() * m_c4 * tsince;
    double templ = m_t2cof * tsq;

    if (!isimp) {
      double delomg = m_omgcof * tsince;
      double delm = m_xmcof * (pow(1.0 + m_eta * cos(xmdf), 3.0) - m_delmo);
      double temp = delomg + delm;

      xmp = xmdf + temp;
      omega = omgadf - temp;

      double tcube = tsq * tsince;
      double tfour = tsince * tcube;

      tempa = tempa - d2 * tsq - d3 * tcube - d4 * tfour;
      tempe = tempe + m_Orbit.bStar() * m_c5 * (sin(xmp) - m_sinmo);
      templ = templ + t3cof * tcube + tfour * (t4cof + tsince * t5cof);
    }

    double a = m_Orbit.semiMajor() * sqr(tempa);
    double e = m_Orbit.eccentricity() - tempe;
    double xl = xmp + omega + xnode + m_Orbit.meanMotion() * templ;
    double xn = XKE / pow(a, 1.5);

    return finalPosition(
        m_Orbit.inclination(), omgadf, e, a, xl, xnode, xn, tsince);
  }

  NoradSGP4(Orbit orbit) {
    init(orbit);
    double etasq = m_eta * m_eta;

    m_c5 = 2.0 *
        m_coef1 *
        m_Orbit.semiMajor() *
        m_betao2 *
        (1.0 + 2.75 * (etasq + m_eeta) + m_eeta * etasq);
    m_omgcof = m_Orbit.bStar() * m_c3 * cos(m_Orbit.argPerigee());
    m_xmcof = -TWOTHRD * m_coef * m_Orbit.bStar() * AE / m_eeta;
    m_delmo = pow(1.0 + m_eta * cos(m_Orbit.meanAnomaly()), 3.0) as double;
    m_sinmo = sin(m_Orbit.meanAnomaly());
  }
}
