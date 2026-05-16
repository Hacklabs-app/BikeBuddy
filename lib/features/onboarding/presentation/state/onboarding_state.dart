import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/onboarding_page.dart';

class OnboardingNotifier extends AutoDisposeAsyncNotifier<List<OnboardingPage>> {
  @override
  Future<List<OnboardingPage>> build() async {
    // In a real app, this might come from a datasource/Supabase
    return const [
      OnboardingPage(
        title: 'Find Nearest Bikes',
        subtitle: 'DISCOVER',
        description: 'Find real-time bike availability at stations within walking distance.',
      ),
      OnboardingPage(
        title: 'Seamless Rental',
        subtitle: 'SCAN & GO',
        description: 'No paper, no hassle. Show your unique QR code to start riding in seconds.',
      ),
      OnboardingPage(
        title: 'Ride Rewards',
        subtitle: 'LOYALTY',
        description: 'Every minute counts. Unlock free rides and exclusive discounts as you pedal.',
      ),
    ];
  }

  Future<void> completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setHasSeenOnboarding();
    // Update the reactive provider to trigger router rebuild
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }
}

final onboardingProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingNotifier, List<OnboardingPage>>(
        OnboardingNotifier.new);
