import 'globals.dart';

enum eField {
  FLD_NORADNUM,
  FLD_INTLDESC,
  FLD_SET, // TLE set number
  FLD_EPOCHYEAR, // Epoch: Last two digits of year
  FLD_EPOCHDAY, // Epoch: Fractional Julian Day of year
  FLD_ORBITNUM, // Orbit at epoch
  FLD_I, // Inclination
  FLD_RAAN, // R.A. ascending node
  FLD_E, // Eccentricity
  FLD_ARGPER, // Argument of perigee
  FLD_M, // Mean anomaly
  FLD_MMOTION, // Mean motion
  FLD_MMOTIONDT, // First time derivative of mean motion
  FLD_MMOTIONDT2, // Second time derivative of mean motion
  FLD_BSTAR, // BSTAR Drag
  FLD_LAST // MUST be last
}

enum eUnits {
  U_RAD, // radians
  U_DEG, // degrees
  U_NATIVE, // TLE format native units (no conversion)
  U_LAST // MUST be last
}

enum eTleLine { LINE_ZERO, LINE_ONE, LINE_TWO }

// Name
const int TLE_LEN_LINE_DATA = 69;
const int TLE_LEN_LINE_NAME = 22;

// Line 1
const int TLE1_COL_SATNUM = 2;
const int TLE1_LEN_SATNUM = 5;
const int TLE1_COL_INTLDESC_A = 9;
const int TLE1_LEN_INTLDESC_A = 2;
const int TLE1_COL_INTLDESC_B = 11;
const int TLE1_LEN_INTLDESC_B = 3;
const int TLE1_COL_INTLDESC_C = 14;
const int TLE1_LEN_INTLDESC_C = 3;
const int TLE1_COL_EPOCH_A = 18;
const int TLE1_LEN_EPOCH_A = 2;
const int TLE1_COL_EPOCH_B = 20;
const int TLE1_LEN_EPOCH_B = 12;
const int TLE1_COL_MEANMOTIONDT = 33;
const int TLE1_LEN_MEANMOTIONDT = 10;
const int TLE1_COL_MEANMOTIONDT2 = 44;
const int TLE1_LEN_MEANMOTIONDT2 = 8;
const int TLE1_COL_BSTAR = 53;
const int TLE1_LEN_BSTAR = 8;
const int TLE1_COL_EPHEMTYPE = 62;
const int TLE1_LEN_EPHEMTYPE = 1;
const int TLE1_COL_ELNUM = 64;
const int TLE1_LEN_ELNUM = 4;

// Line 2
const int TLE2_COL_SATNUM = 2;
const int TLE2_LEN_SATNUM = 5;
const int TLE2_COL_INCLINATION = 8;
const int TLE2_LEN_INCLINATION = 8;
const int TLE2_COL_RAASCENDNODE = 17;
const int TLE2_LEN_RAASCENDNODE = 8;
const int TLE2_COL_ECCENTRICITY = 26;
const int TLE2_LEN_ECCENTRICITY = 7;
const int TLE2_COL_ARGPERIGEE = 34;
const int TLE2_LEN_ARGPERIGEE = 8;
const int TLE2_COL_MEANANOMALY = 43;
const int TLE2_LEN_MEANANOMALY = 8;
const int TLE2_COL_MEANMOTION = 52;
const int TLE2_LEN_MEANMOTION = 11;
const int TLE2_COL_REVATEPOCH = 63;
const int TLE2_LEN_REVATEPOCH = 5;

///
/// TLE data format
///
/// [Reference: T.S. Kelso]
///
/// Two line element data consists of three lines in the following format:
///
///  AAAAAAAAAAAAAAAAAAAAAA
///  1 NNNNNU NNNNNAAA NNNNN.NNNNNNNN +.NNNNNNNN +NNNNN-N +NNNNN-N N NNNNN
///  2 NNNNN NNN.NNNN NNN.NNNN NNNNNNN NNN.NNNN NNN.NNNN NN.NNNNNNNNNNNNNN
///
///  Line 0 is a twenty-two-character name.
///
///   Lines 1 and 2 are the standard Two-Line Orbital Element Set Format identical
///   to that used by NORAD and NASA.  The format description is:
///
///     Line 1
///     Column    Description
///     01-01     Line Number of Element Data
///     03-07     Satellite Number
///     10-11     International Designator (Last two digits of launch year)
///     12-14     International Designator (Launch number of the year)
///     15-17     International Designator (Piece of launch)
///     19-20     Epoch Year (Last two digits of year)
///     21-32     Epoch (Julian Day and fractional portion of the day)
///     34-43     First Time Derivative of the Mean Motion
///               or Ballistic Coefficient (Depending on ephemeris type)
///     45-52     Second Time Derivative of Mean Motion (decimal point assumed;
///               blank if N/A)
///     54-61     BSTAR drag term if GP4 general perturbation theory was used.
///               Otherwise, radiation pressure coefficient.  (Decimal point assumed)
///     63-63     Ephemeris type
///     65-68     Element number
///     69-69     Check Sum (Modulo 10)
///               (Letters, blanks, periods, plus signs = 0; minus signs = 1)
///
///     Line 2
///     Column    Description
///     01-01     Line Number of Element Data
///     03-07     Satellite Number
///     09-16     Inclination [Degrees]
///     18-25     Right Ascension of the Ascending Node [Degrees]
///     27-33     Eccentricity (decimal point assumed)
///     35-42     Argument of Perigee [Degrees]
///     44-51     Mean Anomaly [Degrees]
///     53-63     Mean Motion [Revs per day]
///      64-68     Revolution number at epoch [Revs]
///      69-69     Check Sum (Modulo 10)
///
///     All other columns are blank or fixed.
///
/// Example:
///
/// NOAA 6
/// 1 11416U          86 50.28438588 0.00000140           67960-4 0  5293
/// 2 11416  98.5105  69.3305 0012788  63.2828 296.9658 14.24899292346978

class TLE {
  // Satellite name and two data lines
  late String strName;
  late String strLine1;
  late String strLine2;

  List<String> field = new List.generate(eField.FLD_LAST.index, (index) => '');

  int Key(eUnits u, eField f) {
    return (u.index * 100) + f.index;
  }

  Map<int, double> mapCache = {};

  TLE(String strName, String strLine1, String strLine2) {
    this.strName = strName;
    this.strLine1 = strLine1;
    this.strLine2 = strLine2;

    this.strName.trimRight();
    initialize();
  }

  String getName() {
    return strName;
  }

  String getLine1() {
    return strLine1;
  }

  String getLine2() {
    return strLine2;
  }

  /// getField()
  /// Return requested field as a double (function return value) or as a text
  /// string (*pstr) in the units requested (eUnit). Set 'bStrUnits' to true
  /// to have units appended to text string.
  ///
  /// Note: numeric return values are cached; asking for the same field more
  /// than once incurs minimal overhead.

  dynamic getField(
    eField fld, {
    eUnits units: eUnits.U_NATIVE,
    /* = U_NATIVE */
    String? pstr /* = NULL     */,
    bool bStrUnits: false /* = false    */,
  }) {
    assert((eField.FLD_NORADNUM.index <= fld.index) &&
        (fld.index < eField.FLD_LAST.index));
    assert((eUnits.U_RAD.index <= units.index) &&
        (units.index < eUnits.U_LAST.index));

    if (pstr != null) {
      // Return requested field in string form.
      pstr = field[fld.index];

      if (bStrUnits) {
        pstr += getUnits(fld)!;
      }

      return pstr;
    } else {
      // Return requested field in floating-point form.
      // Return cache contents if it exists, else populate cache
      int key = Key(units, fld);

      if (!mapCache.containsKey(key)) {
        // Value not in cache; add it
        double valNative = double.tryParse(field[fld.index])!;
        double valConv = convertUnits(valNative, fld, units);
        mapCache[key] = valConv;

        return valConv;
      } else {
        // return cached value
        return mapCache[key];
      }
    }
  }

  /// expToAtof()
  /// Converts TLE-style exponential notation of the form [ |-]00000[+|-]0 to a
  /// form that is parse-able by the C-runtime function atof(). Assumes implied
  /// decimal point to the left of the first number in the string, i.e.,
  ///       " 12345-3" =  0.12345e-3
  ///       "-23429-5" = -0.23429e-5
  ///       " 40436+1" =  0.40436e+1
  String expToAtof(String str) {
    const int COL_SIGN = 0;
    const int LEN_SIGN = 1;

    const int COL_MANTISSA = 1;
    const int LEN_MANTISSA = 5;

    const int COL_EXPONENT = 6;
    const int LEN_EXPONENT = 2;

    String sign = str.substring(COL_SIGN, COL_SIGN + LEN_SIGN);
    String mantissa = str.substring(COL_MANTISSA, COL_MANTISSA + LEN_MANTISSA);
    String exponent = str.substring(COL_EXPONENT, COL_EXPONENT + LEN_EXPONENT);

    return sign + "0." + mantissa + "e" + exponent;
  }

  /// Convert the given field into the requested units. It is assumed that
  /// the value being converted is in the TLE format's "native" form.
  double convertUnits(
      double valNative, // value to convert
      eField fld, // what field the value is
      eUnits units) // what units to convert to
  {
    switch (fld) {
      case eField.FLD_I:
      case eField.FLD_BSTAR:
      case eField.FLD_E:
      case eField.FLD_EPOCHDAY:
      case eField.FLD_EPOCHYEAR:
      case eField.FLD_I:
      case eField.FLD_INTLDESC:
      case eField.FLD_LAST:
      case eField.FLD_M:
      case eField.FLD_MMOTION:
      case eField.FLD_MMOTIONDT:
      case eField.FLD_MMOTIONDT2:
      case eField.FLD_NORADNUM:
      case eField.FLD_ORBITNUM:
      case eField.FLD_SET:
      case eField.FLD_RAAN:
      case eField.FLD_ARGPER:
      case eField.FLD_M:
        // The native TLE format is DEGREES
        if (units == eUnits.U_RAD) {
          return valNative * RADS_PER_DEG;
        }
        break;
    }

    return valNative; // return value in unconverted native format
  }

  String? getUnits(eField fld) {
    const String strDegrees = " degrees";
    const String strRevsPerDay = " revs / day";
    const String strNull = '';

    switch (fld) {
      case eField.FLD_I:
        break;
      case eField.FLD_RAAN:
        break;
      case eField.FLD_ARGPER:
        break;
      case eField.FLD_M:
        return strDegrees;

      case eField.FLD_MMOTION:
        return strRevsPerDay;

      default:
        return strNull;
    }
  }

  /// IsTleFormat()
  /// Returns true if "str" is a valid data line of a two-line element set,
  ///   else false.
  ///
  /// To be valid a line must:
  ///      Have as the first character the line number
  ///      Have as the second character a blank
  ///      Be TLE_LEN_LINE_DATA characters long
  ///      Have a valid checksum (note: no longer required as of 12/96)
  ///
  bool cIsValidLine(String str, eTleLine line) {
    str.trimLeft();
    str.trimRight();

    int nLen = str.length;

    if (nLen != TLE_LEN_LINE_DATA) {
      return false;
    }

    // First char in string must be line number
    if (str[0] != line.index.toString()) {
      return false;
    }

    // Second char in string must be blank
    if (str[1] != ' ') {
      return false;
    }

    /*
      NOTE: 12/96 
      The requirement that the last char in the line data must be a valid 
      checksum is too restrictive. 
      
      // Last char in string must be checksum
      int nSum = CheckSum(str);
     
      if (nSum != (str[TLE_LEN_LINE_DATA - 1] - '0'))
      {
         return false;
      }
   */

    return true;
  }

  /// Initialize()
  /// Initialize the string array.
  void initialize() {
    // Have we already been initialized?
    if (field[eField.FLD_NORADNUM.index].isNotEmpty) return;

    assert(strLine1.isNotEmpty);
    assert(strLine2.isNotEmpty);

    field[eField.FLD_NORADNUM.index] =
        strLine1.substring(TLE1_COL_SATNUM, TLE1_COL_SATNUM + TLE1_LEN_SATNUM);

    field[eField.FLD_INTLDESC.index] = strLine1.substring(
        TLE1_COL_INTLDESC_A,
        TLE1_COL_INTLDESC_A +
            TLE1_LEN_INTLDESC_A +
            TLE1_LEN_INTLDESC_B +
            TLE1_LEN_INTLDESC_C);

    field[eField.FLD_EPOCHYEAR.index] = strLine1.substring(
        TLE1_COL_EPOCH_A, TLE1_COL_EPOCH_A + TLE1_LEN_EPOCH_A);

    field[eField.FLD_EPOCHDAY.index] = strLine1.substring(
        TLE1_COL_EPOCH_B, TLE1_COL_EPOCH_B + TLE1_LEN_EPOCH_B);

    if (strLine1[TLE1_COL_MEANMOTIONDT] == '-') {
      // value is negative
      field[eField.FLD_MMOTIONDT.index] = "-0";
    } else {
      field[eField.FLD_MMOTIONDT.index] = "0";
    }

    field[eField.FLD_MMOTIONDT.index] += strLine1.substring(
        TLE1_COL_MEANMOTIONDT + 1,
        TLE1_COL_MEANMOTIONDT + 1 + TLE1_LEN_MEANMOTIONDT);

    // decimal point assumed; exponential notation
    field[eField.FLD_MMOTIONDT2.index] = expToAtof(strLine1.substring(
        TLE1_COL_MEANMOTIONDT2,
        TLE1_COL_MEANMOTIONDT2 + TLE1_LEN_MEANMOTIONDT2));

    // decimal point assumed; exponential notation
    field[eField.FLD_BSTAR.index] = expToAtof(
        strLine1.substring(TLE1_COL_BSTAR, TLE1_COL_BSTAR + TLE1_LEN_BSTAR));

    // TLE1_COL_EPHEMTYPE
    // TLE1_LEN_EPHEMTYPE
    field[eField.FLD_SET.index] =
        strLine1.substring(TLE1_COL_ELNUM, TLE1_COL_ELNUM + TLE1_LEN_ELNUM);

    field[eField.FLD_SET.index].trimLeft();

    // TLE2_COL_SATNUM
    // TLE2_LEN_SATNUM

    field[eField.FLD_I.index] = strLine2.substring(
        TLE2_COL_INCLINATION, TLE2_COL_INCLINATION + TLE2_LEN_INCLINATION);
    field[eField.FLD_I.index].trimLeft();

    field[eField.FLD_RAAN.index] = strLine2.substring(
        TLE2_COL_RAASCENDNODE, TLE2_COL_RAASCENDNODE + TLE2_LEN_RAASCENDNODE);
    field[eField.FLD_RAAN.index].trimLeft();

    // decimal point is assumed
    field[eField.FLD_E.index] = "0.";
    field[eField.FLD_E.index] += strLine2.substring(
        TLE2_COL_ECCENTRICITY, TLE2_COL_ECCENTRICITY + TLE2_LEN_ECCENTRICITY);

    field[eField.FLD_ARGPER.index] = strLine2.substring(
        TLE2_COL_ARGPERIGEE, TLE2_COL_ARGPERIGEE + TLE2_LEN_ARGPERIGEE);
    field[eField.FLD_ARGPER.index].trimLeft();

    field[eField.FLD_M.index] = strLine2.substring(
        TLE2_COL_MEANANOMALY, TLE2_COL_MEANANOMALY + TLE2_LEN_MEANANOMALY);
    field[eField.FLD_M.index].trimLeft();

    field[eField.FLD_MMOTION.index] = strLine2.substring(
        TLE2_COL_MEANMOTION, TLE2_COL_MEANMOTION + TLE2_LEN_MEANMOTION);
    field[eField.FLD_MMOTION.index].trimLeft();

    field[eField.FLD_ORBITNUM.index] = strLine2.substring(
        TLE2_COL_REVATEPOCH, TLE2_COL_REVATEPOCH + TLE2_LEN_REVATEPOCH);
    field[eField.FLD_ORBITNUM.index].trimLeft();
  }
}
