import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'package:tapmate/Screen/home/home_screen.dart';
import 'package:tapmate/auth_provider.dart';

class AuthWrapper extends StatelessWidget {
	const AuthWrapper({super.key});

	@override
	Widget build(BuildContext context) {
		return Consumer<AuthProvider>(
			builder: (context, authProvider, _) {
				if (authProvider.isLoggedIn || authProvider.isGuest) {
					return const HomeScreen();
				}
				return const LoginScreen();
			},
		);
	}
}
