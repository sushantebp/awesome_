import 'package:auto_route/auto_route.dart';
import 'package:awesome/core/routes/app_router.gr.dart';
import 'package:injectable/injectable.dart';

@injectable
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
  ];
}
