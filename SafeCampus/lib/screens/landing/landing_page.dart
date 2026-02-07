// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../config/theme.dart';
//
// class LandingPage extends StatefulWidget {
//   const LandingPage({super.key});
//
//   @override
//   State<LandingPage> createState() => _LandingPageState();
// }
//
// class _LandingPageState extends State<LandingPage> {
//   String? selectedRole;
//
//   final List<RoleCard> roles = [
//     RoleCard(
//       id: 'student',
//       title: 'Student',
//       subtitle: 'Report incidents & receive alerts',
//       description: 'Real-time safety alerts, emergency SOS button, and anonymous incident reporting.',
//       icon: '👤',
//       color: AppColors.secondary,
//       route: '/student',
//     ),
//     RoleCard(
//       id: 'security',
//       title: 'Security Officer',
//       subtitle: 'Command & response operations',
//       description: 'Real-time incident map, dispatch management, and operational oversight.',
//       icon: '🛡️',
//       color: AppColors.accent,
//       route: '/security',
//     ),
//     RoleCard(
//       id: 'admin',
//       title: 'Administrator',
//       subtitle: 'Institution-level insights',
//       description: 'Analytics, user management, incident trends, and system monitoring.',
//       icon: '📊',
//       color: AppColors.successLight,
//       route: '/admin',
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               AppColors.primary,
//               AppColors.primaryLight,
//               AppColors.primaryLighter,
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Navigation Bar
//                 _buildNavBar(),
//
//                 // Hero Section
//                 _buildHeroSection(),
//
//                 // Role Selection Cards
//                 _buildRoleCards(),
//
//                 // Features Section
//                 _buildFeaturesSection(),
//
//                 // CTA Section
//                 _buildCTASection(),
//
//                 // Footer
//                 _buildFooter(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: AppColors.border.withOpacity(0.2)),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'SafeCampus AI',
//                 style: GoogleFonts.outfit(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           Text(
//             'Campus Safety Platform',
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: AppColors.foregroundLight,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeroSection() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           const SizedBox(height: 32),
//           Text(
//             'Campus Safety,\nPowered by Intelligence',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.outfit(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               height: 1.2,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'AI-driven crime prevention and emergency response system for Nigerian universities. Real-time incidents, smart alerts, and coordinated security operations.',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.inter(
//               fontSize: 16,
//               color: AppColors.foregroundLight,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRoleCards() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         children: roles.map((role) {
//           final isSelected = selectedRole == role.id;
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: GestureDetector(
//               onTap: () => context.go(role.route),
//               onTapDown: (_) => setState(() => selectedRole = role.id),
//               onTapUp: (_) => setState(() => selectedRole = null),
//               onTapCancel: () => setState(() => selectedRole = null),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? role.color.withOpacity(0.15)
//                       : AppColors.surface,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: isSelected ? role.color : AppColors.border,
//                     width: 2,
//                   ),
//                   boxShadow: isSelected
//                       ? [
//                           BoxShadow(
//                             color: role.color.withOpacity(0.3),
//                             blurRadius: 30,
//                             spreadRadius: 0,
//                           ),
//                         ]
//                       : [],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       role.icon,
//                       style: const TextStyle(fontSize: 40),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       role.title,
//                       style: GoogleFonts.outfit(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       role.subtitle,
//                       style: GoogleFonts.inter(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: role.color,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       role.description,
//                       style: GoogleFonts.inter(
//                         fontSize: 14,
//                         color: AppColors.foregroundLight,
//                         height: 1.5,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Text(
//                           'Access Dashboard',
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: role.color,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Icon(
//                           Icons.arrow_forward,
//                           color: role.color,
//                           size: 16,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildFeaturesSection() {
//     final features = [
//       _Feature('Real-Time Incident Map', 'Live campus visualization with incident markers and severity indicators', '🗺️'),
//       _Feature('AI Priority Queue', 'Intelligent incident prioritization based on severity and risk assessment', '⚡'),
//       _Feature('Emergency SOS Button', 'One-tap crisis alert with automatic location sharing and immediate dispatch', '🆘'),
//       _Feature('Smart Alerts', 'Personalized safety notifications based on proximity and incident type', '🔔'),
//       _Feature('Anonymous Reporting', 'Privacy-first incident submission with automatic anonymity masking', '🔒'),
//       _Feature('Analytics Dashboard', 'Institutional oversight with trend analysis and hotspot detection', '📈'),
//     ];
//
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           const SizedBox(height: 32),
//           Text(
//             'Core Features',
//             style: GoogleFonts.outfit(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ...features.map((feature) => Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     feature.icon,
//                     style: const TextStyle(fontSize: 32),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           feature.title,
//                           style: GoogleFonts.inter(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           feature.description,
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             color: AppColors.foregroundLight,
//                             height: 1.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCTASection() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Container(
//         padding: const EdgeInsets.all(32),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               AppColors.accent.withOpacity(0.2),
//               AppColors.secondary.withOpacity(0.2),
//             ],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.accent, width: 2),
//         ),
//         child: Column(
//           children: [
//             Text(
//               'Ready to Enhance Campus Safety?',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.outfit(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Select your role above to access the SafeCampus AI platform and start improving campus security immediately.',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 color: AppColors.foregroundLight,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => context.go('/student'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.secondary,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: Text(
//                       'Student Access',
//                       style: GoogleFonts.inter(
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => context.go('/security'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.accent,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: Text(
//                       'Security Dashboard',
//                       style: GoogleFonts.inter(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         border: Border(
//           top: BorderSide(color: AppColors.border.withOpacity(0.2)),
//         ),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'SafeCampus AI - Campus Safety Intelligence Platform',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: AppColors.foregroundLight,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Secure. Intelligent. Always Ready.',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: AppColors.foregroundLight,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class RoleCard {
//   final String id;
//   final String title;
//   final String subtitle;
//   final String description;
//   final String icon;
//   final Color color;
//   final String route;
//
//   RoleCard({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.description,
//     required this.icon,
//     required this.color,
//     required this.route,
//   });
// }
//
// class _Feature {
//   final String title;
//   final String description;
//   final String icon;
//
//   _Feature(this.title, this.description, this.icon);
// }

