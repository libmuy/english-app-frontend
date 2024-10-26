import 'package:flutter/material.dart';
import '../domain/global.dart';
import '../providers/service_locator.dart';
import '../providers/auth_provider.dart';
import 'package:simple_logging/simple_logging.dart';
import 'register_page.dart';

final _log = Logger('LoginPage', level: LogLevel.debug);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _passwordFocusNode = FocusNode(); // Focus node for the password field
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordFocusNode.dispose(); // Dispose the focus node when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserIdField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: const Text('Login'),
                      onPressed: () => _login(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: const Text('Register'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegisterPage()));
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserIdField() {
    return TextFormField(
      controller: _userIdController,
      decoration: const InputDecoration(
        labelText: 'User ID',
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.username
      ], // Suggest username autofill
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      },
      validator: kUserIdlValidator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      decoration: const InputDecoration(
        labelText: 'Password',
      ),
      obscureText: true,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      textInputAction: TextInputAction.done,
      autofillHints: const [
        AutofillHints.password
      ], // Suggest password autofill
      onFieldSubmitted: (_) => _login(), // Trigger login on Enter key press
      validator: kPassowrdlValidator,
    );
  }

  void _login() async {
    _log.debug('login');
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = getIt<AuthProvider>();
      await authProvider.login(
        _userIdController.text,
        _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
      }
    }
  }
}
