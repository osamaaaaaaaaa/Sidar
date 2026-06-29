// import 'package:get/get.dart';
// import 'package:skincare/Views/Home/Home.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AuthController extends GetxController {
//   final supabase = Supabase.instance.client;

//   var isLoading = false.obs;

//   Future<void> login({required String email, required String password}) async {
//     try {
//       isLoading.value = true;

//       final res = await supabase.auth.signInWithPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       if (res.user != null) {
//         Get.offAll(() => HomeView());
//       }
//     } on AuthException catch (e) {
//       Get.snackbar(
//         'Login Failed',
//         e.message,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Something went wrong',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }
// }
