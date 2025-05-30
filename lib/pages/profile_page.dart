import 'package:flutter/material.dart';
import '../domain/global.dart';
import '../providers/service_locator.dart';
import '../providers/auth_provider.dart';
import './learning_calendar_page.dart'; // Adjust path if necessary

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final userId = getIt<AuthProvider>().userName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $userId, you can change your profile here',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'New Password',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          return kPassowrdlValidator(value); // Perform validation if the field is not empty
        }
        return null; // If the field is empty, skip validation
      },
      onFieldSubmitted: (value) {
        _update(context);
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: const InputDecoration(
        labelText: 'Confirm Password',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      validator: (value) {
        if (_passwordController.text.isNotEmpty) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
        }
        return null; // Skip validation if the password field is empty
      },
      onFieldSubmitted: (value) {
        _update(context);
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'New Email',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          return kEmailValidator(value); // Perform validation if the field is not empty
        }
        return null; // If the field is empty, skip validation
      },
      onFieldSubmitted: (value) {
        _update(context);
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton( // Button to navigate to Learning Calendar Page
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LearningCalendarPage()),
            );
          },
          child: const Text('View Learning Calendar'),
        ),
        const SizedBox(height: 16), // Spacing
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: () => _update(context),
            child: const Text('Update Profile'), // Maybe rename from just "Update"
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _update(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.isEmpty && _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter either a new password or a new email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await getIt<AuthProvider>().updateUser(
        _passwordController.text.isNotEmpty ? _passwordController.text : '',
        _emailController.text.isNotEmpty ? _emailController.text : '',
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }
}
