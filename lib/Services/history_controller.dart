import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import '../Models/scan_result_model.dart';
import 'scan_repository.dart';

class HistoryController extends GetxController {
  final ScanRepository repository;

  HistoryController({required this.repository});

  final isLoading = false.obs;
  final items = <ScanResultModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      items.assignAll(await repository.getScans());
    } catch (e) {
      AppFeedback.error(e.toString(), title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }
}
