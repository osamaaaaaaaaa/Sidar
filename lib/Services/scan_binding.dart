import 'package:get/get.dart';
import 'scan_remote_source.dart';
import 'scan_repository.dart';
import 'scan_controller.dart';

class ScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanRemoteSource>(() => ScanRemoteSource());
    Get.lazyPut<ScanRepository>(() => ScanRepository(remote: Get.find()));
    Get.lazyPut<ScanController>(() => ScanController());
  }
}
