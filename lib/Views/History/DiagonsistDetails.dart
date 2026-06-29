// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'dart:ui';

// class DiagnosisDetailsView extends StatelessWidget {
//   const DiagnosisDetailsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFBF9F7),
//       body: Stack(
//         children: [
//           _buildBackgroundOrbs(),
//           CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               _buildSliverAppBar(),
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(25.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildMainScoreCard(),
//                       const SizedBox(height: 30),
//                       _buildSectionTitle("التحليل البصري للذكاء الاصطناعي"),
//                       _buildAIVisualAnalysis(),
//                       const SizedBox(height: 30),
//                       _buildSectionTitle("التوصيات الطبية والمنتجات"),
//                       _buildProductRecommendation(
//                         "سيروم ريتينول 0.5%",
//                         "450 EGP",
//                         "لعلاج المسام الواسعة",
//                       ),
//                       _buildProductRecommendation(
//                         "واقي شمس فيتشي",
//                         "890 EGP",
//                         "لحماية البشرة الحساسة",
//                       ),
//                       const SizedBox(height: 100), // مساحة إضافية
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           _buildBottomActionButtons(), // أزرار ثابتة في الأسفل
//         ],
//       ),
//     );
//   }

//   // --- المكونات الداخلية ---

//   Widget _buildSliverAppBar() {
//     return SliverAppBar(
//       expandedHeight: 200,
//       pinned: true,
//       backgroundColor: Colors.blueAccent,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Image.network(
//           "https://picsum.photos/400/200", // الصورة التي تم فحصها
//           fit: BoxFit.cover,
//         ),
//         title: const Text(
//           "تقرير الفحص الذكي",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   Widget _buildMainScoreCard() {
//     return Container(
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "حالة البشرة العامة",
//                 style: TextStyle(color: Colors.black45, fontSize: 13),
//               ),
//               SizedBox(height: 5),
//               Text(
//                 "جيدة جداً ✨",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           _buildCircularScore(85), // النتيجة 85%
//         ],
//       ),
//     );
//   }

//   Widget _buildCircularScore(int score) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         SizedBox(
//           width: 70,
//           height: 70,
//           child: CircularProgressIndicator(
//             value: score / 100,
//             strokeWidth: 8,
//             backgroundColor: Colors.grey[200],
//             color: Colors.greenAccent,
//           ),
//         ),
//         Text(
//           "$score%",
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//       ],
//     );
//   }

//   Widget _buildAIVisualAnalysis() {
//     return Container(
//       height: 150,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.blueAccent.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
//       ),
//       child: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.center_focus_weak_rounded,
//               color: Colors.blueAccent,
//               size: 40,
//             ),
//             SizedBox(height: 10),
//             Text(
//               "تم اكتشاف 3 مناطق تحتاج اهتمام",
//               style: TextStyle(
//                 color: Colors.blueAccent,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProductRecommendation(String name, String price, String reason) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 15),
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.5),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white),
//       ),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             backgroundColor: Colors.blueAccent,
//             child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 Text(
//                   reason,
//                   style: const TextStyle(fontSize: 11, color: Colors.black45),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             price,
//             style: const TextStyle(
//               color: Colors.green,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomActionButtons() {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(color: Colors.white.withOpacity(0.8)),
//         child: Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 icon: const Icon(
//                   Icons.chat_bubble_outline_rounded,
//                   color: Colors.white,
//                 ),
//                 label: const Text(
//                   "اسأل Gemini عن الحالة",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.share_outlined),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 15),
//       child: Text(
//         title,
//         style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildBackgroundOrbs() {
//     return Stack(
//       children: [
//         Positioned(
//           top: 200,
//           right: -100,
//           child: Container(
//             width: 300,
//             height: 300,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.blue[50],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
