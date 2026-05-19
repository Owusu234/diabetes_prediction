import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../const/colors.dart';

/// Global navigator key to allow navigation from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Observer to track if the chat screen is currently open
class ChatbotRouteObserver extends NavigatorObserver {
  static final ChatbotRouteObserver instance = ChatbotRouteObserver();
  final ValueNotifier<bool> isChatOpen = ValueNotifier(false);

  void _updateState(Route? route) {
    // We hide the FAB if the current route is the chat screen
    isChatOpen.value = route?.settings.name == 'chat';
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateState(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _updateState(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateState(newRoute);
  }
}

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ChatbotRouteObserver.instance.isChatOpen,
      builder: (context, isChatOpen, child) {
        // Hide the FAB if the chat is already open
        if (isChatOpen) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          heroTag: 'chatbot_fab_global',
          onPressed: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'chat'),
                builder: (context) => const ChatScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.forum_rounded, color: Colors.white),
          label: const Text(
            'AI Assistant',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 4,
        );
      },
    );
  }
}

/// Custom location to position the FAB above the bottom navigation bar
class ChatbotFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double x = scaffoldGeometry.scaffoldSize.width - 
                     scaffoldGeometry.floatingActionButtonSize.width - 16;
    // Position it 100px from the bottom to clear the navigation bar on HomePage
    final double y = scaffoldGeometry.scaffoldSize.height - 
                     scaffoldGeometry.floatingActionButtonSize.height - 100;
    
    return Offset(x, y);
  }
}
