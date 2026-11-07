const Map<String, String> _months = <String, String>{
  'January': 'มกราคม', 'February': 'กุมภาพันธ์', 'March': 'มีนาคม', 'April': 'เมษายน',
  'May': 'พฤษภาคม', 'June': 'มิถุนายน', 'July': 'กรกฎาคม', 'August': 'สิงหาคม',
  'September': 'กันยายน', 'October': 'ตุลาคม', 'November': 'พฤศจิกายน', 'December': 'ธันวาคม',
  'Jan': 'ม.ค.', 'Feb': 'ก.พ.', 'Mar': 'มี.ค.', 'Apr': 'เม.ย.', 'Jun': 'มิ.ย.', 'Jul': 'ก.ค.',
  'Aug': 'ส.ค.', 'Sep': 'ก.ย.', 'Oct': 'ต.ค.', 'Nov': 'พ.ย.', 'Dec': 'ธ.ค.',
};

const Map<String, String> _weekdays = <String, String>{
  'Monday': 'วันจันทร์', 'Tuesday': 'วันอังคาร', 'Wednesday': 'วันพุธ', 'Thursday': 'วันพฤหัสบดี',
  'Friday': 'วันศุกร์', 'Saturday': 'วันเสาร์', 'Sunday': 'วันอาทิตย์',
  'Mon': 'จ.', 'Tue': 'อ.', 'Wed': 'พ.', 'Thu': 'พฤ.', 'Fri': 'ศ.', 'Sat': 'ส.', 'Sun': 'อา.',
};

final RegExp _month = RegExp('\\b(\\d{1,2}) (${_months.keys.join('|')})\\b');
final RegExp _weekday = RegExp('\\b(${_weekdays.keys.join('|')}) (?=\\d)');

/// Changes the names in the date formats of the report's SQL and `DateText`,
/// for example 'Fri 16 October 2026'. Only a name next to a number changes, so
/// a person named 'May' stays. The year stays CE, as in the Flutter date picker.
String thaiDates(String text) => text
    .replaceAllMapped(_month, (Match m) => '${m[1]} ${_months[m[2]]}')
    .replaceAllMapped(_weekday, (Match m) => '${_weekdays[m[1]]} ');
