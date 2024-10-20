import 'package:metadata_fetch/metadata_fetch.dart';

/// Fetch the metadata for the given URL

main() async {
  final myURL = 'https://cgdougm.design';

  var data = await MetadataFetch.extract(myURL);

  print(': ${data?.title}');
  print(': ${data?.description}'); 
  print(': ${data?.image}');
  print(': ${data?.url}');

  var dataAsMap = data?.toMap();
  print(dataAsMap);
}
