// import 'package:flutter/material.dart';

// class ForgotPasswordView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFBF9F7),
//       appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: Colors.black87)),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.lock_reset_rounded, size: 80, color: Colors.blueAccent),
//             const SizedBox(height: 30),
//             const Text("استعادة كلمة المرور", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 15),
//             const Text(
//               "أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً لإعادة تعيين كلمة المرور الخاصة بك.",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.black45, fontSize: 14),
//             ),
//             const SizedBox(height: 40),
//             _buildGlassField(Icons.email_outlined, "بريدك الإلكتروني"),
//             const SizedBox(height: 30),
//             _buildActionButton("إرسال الرابط", () {
//               // منطق الإرسال
//               Get.snackbar("تم الإرسال", "يرجى التحقق من بريدك الإلكتروني", 
//                 backgroundColor: Colors.white.withOpacity(0.8), colorText: Colors.black);
//             }),
//           ],
//         ),
//       ),
//     );
//   }
  
//   // نستخدم نفس دوال التصميم السابقة لتوحيد الستايل
// }