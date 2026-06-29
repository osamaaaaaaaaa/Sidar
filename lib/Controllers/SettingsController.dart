// import 'package:get/get.dart';
// import 'package:skincare/Views/Auth/Login.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SettingsController extends GetxController {
//   final supabase = Supabase.instance.client;

//   RxBool isLoading = true.obs;

//   // User Data
//   RxString name = ''.obs;
//   RxString email = ''.obs;

//   // Stats
//   RxInt scansCount = 0.obs;

//   // Settings
//   RxBool autoEnvAnalysis = true.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadData();
//   }

//   Future<void> loadData() async {
//     try {
//       isLoading.value = true;

//       final user = supabase.auth.currentUser;

//       if (user != null) {
//         email.value = user.email ?? '';

//         /// 🔹 user profile
//         final profile = await supabase
//             .from('profiles')
//             .select()
//             .eq('id', user.id)
//             .single();

//         name.value = profile['name'] ?? 'User';

//         /// 🔹 scans count
//         final scans = await supabase
//             .from('scan_sessions')
//             .select('id')
//             .eq('user_id', user.id);

//         scansCount.value = scans.length;

//         /// 🔹 settings
//         final settings = await supabase
//             .from('user_settings')
//             .select()
//             .eq('user_id', user.id)
//             .maybeSingle();

//         if (settings != null) {
//           autoEnvAnalysis.value = settings['auto_env_analysis'] ?? true;
//         }
//       }
//     } catch (e) {
//       print(e);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> toggleAutoAnalysis(bool value) async {
//     autoEnvAnalysis.value = value;

//     final user = supabase.auth.currentUser;

//     await supabase.from('user_settings').upsert({
//       'user_id': user!.id,
//       'auto_env_analysis': value,
//     });
//   }

//   Future<void> logout() async {
//     await supabase.auth.signOut();
//     Get.offAll(() => LoginView());
//   }
// }
