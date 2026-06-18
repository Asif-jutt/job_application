import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/models/user_role.dart';
import '../model/app_user.dart';

void navigateToRoleHome(BuildContext context, AppUser user) {
  final route = switch (user.role) {
    UserRole.user => RouteConstants.userHome,
    UserRole.company => RouteConstants.companyHome,
    UserRole.admin => RouteConstants.adminHome,
  };
  context.go(route);
}

/// Routes user to role picker or home after sign-in.
void navigateAfterAuth(BuildContext context, AppUser user) {
  if (user.needsRoleSelection) {
    context.go(RouteConstants.googleRole);
    return;
  }
  navigateToRoleHome(context, user);
}
