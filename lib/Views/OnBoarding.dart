// Re-export the new luxury welcome & onboarding experience
export 'package:skincare/Views/Onboarding/welcome_landing_view.dart';
export 'package:skincare/Views/Onboarding/onboarding_questionnaire_view.dart';

import 'package:flutter/material.dart';
import 'package:skincare/Views/Onboarding/welcome_landing_view.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeLandingView();
  }
}
