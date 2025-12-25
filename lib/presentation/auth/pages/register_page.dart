import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/presentation/auth/blocs/register/register_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body:
          //userame,email,password
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  controller: _usernameController,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  controller: _emailController,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    state.when(
                      initial: () {},
                      loading: () {
                        return const CircularProgressIndicator();
                      },
                      success: () {
                        return const Text('Registration Successful');
                      },
                      failure: (errorMessage) {
                        return Text('Registration Failed: $errorMessage');
                      },
                    );
                    return ElevatedButton(
                      onPressed: () {
                        context.read<RegisterBloc>().add(
                          RegisterEvent.register(
                            username: _usernameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                          ),
                        );
                      },
                      child: const Text('Register'),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
