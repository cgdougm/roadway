import 'dart:io';

import 'package:metadata_fetch/metadata_fetch.dart';
import 'dart:async'; // Add this import

/// Fetch the metadata for the given URL

main() async {
  for (var myURL in ['https://cgdougm.design', 'https://adobe.com']) {
    try {
      var data = await MetadataFetch.extract(myURL).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException(
              'Failed to fetch metadata within the time limit');
        },
      );

      var dataAsMap = data?.toMap();
      print(dataAsMap);
      print('\n');
    } on TimeoutException catch (e) {
      print('Timeout error: ${e.message}');
      // Handle the timeout case
      exit(-1);
    } catch (e) {
      print('Error fetching metadata: $e');
      // Handle other potential errors
      exit(-2);
    }
  }
}
