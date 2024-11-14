import 'package:flutter_test/flutter_test.dart';

import 'package:roadway/core/unique_id.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  test('isFolder', () {
    expect(XFile('C:\\Users\\micro\\Documents\\Projects\\DartFlutter\\Cursor\\roadway\\assets\\testfiles\\content folder').isFolder(), true);
    expect(XFile('assets/testfiles/hello.txt').isFolder(), false);
    expect(XFile('assets/testfiles/Subfolder1').isFolder(), true);
    expect(XFile('C:\\').isFolder(), true);
  });
}
