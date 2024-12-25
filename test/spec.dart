import './services/api_service_test.dart' as api_service_test;
import './services/network_test.dart' as network_test;
import './models/card_data_test.dart' as card_data_test;
import './models/deck_info_test.dart' as deck_info_test;
import './screens/login_test.dart' as login_test;
import './screens/page_carte_test.dart' as page_carte_test;
import './screens/page_garde_test.dart' as page_garde_test;
import './screens/recto_test.dart' as recto_test;
import './screens/splash_test.dart' as splash_test;
import './conf/apiconfig_test.dart' as apiconfig_test;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('All Tests', () {
    api_service_test.main();
    network_test.main();
    card_data_test.main();
    deck_info_test.main();
    login_test.main();
    page_carte_test.main();
    page_garde_test.main();
    recto_test.main();
    splash_test.main();
    apiconfig_test.main();
  });
}
