import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/http_exception.dart';
import '../provider/auth.dart';

enum AuthMode { Signup, Login }

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();

  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();
  AnimationController? _animationController;
  Animation<Offset>? _slightAnimation;
  Animation<double>? _opacityAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _slightAnimation =
        Tween<Offset>(begin: Offset(0.0, -1.5), end: Offset(0.0, 0.0)).animate(
            CurvedAnimation(
                parent: _animationController!, curve: Curves.linear));
    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn));
    // _HeightContainer!.addListener(() => setState(() {}));
  }

  void _showErrorDialoge(String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('An Error Occured'),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Okay')),
              ],
            ));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        await Provider.of<Auth>(context, listen: false)
            .login(_authData['email']!, _authData['password']!);
      } else {
        await Provider.of<Auth>(context, listen: false)
            .signup(_authData['email']!, _authData['password']!);
      }
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage = 'This email address is already in use.';
      } else if (error.toString().contains('INVALID_EMAIL')) {
        errorMessage = 'This is not a valid email address';
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = 'This password is too weak.';
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage = 'Could not find a user with that email.';
      } else if (error.toString().contains('IVALID_PASSWORD')) {
        errorMessage = 'Invalid password.';
      }
      _showErrorDialoge(errorMessage);
    } catch (error) {
      const errorMessage = 'Could not authenticate you. Please try again Later';
      _showErrorDialoge(errorMessage);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
      _animationController!.forward();
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
      _animationController!.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -60,
            child: Container(
              height: 270,
              width: 270,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(135),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF00C9FF),
                        Color(0xFF92FE9D),
                      ])),
            ),
          ),
          Positioned(
            top: -120,
            left: -50,
            child: Container(
              height: 320,
              width: 320,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(160),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF00C9FF),
                        Color(0xFF92FE9D),
                      ])),
            ),
          ),
          Positioned(
            top: 300,
            width: deviceSize.width,
            child: Center(
              child: _authCard(deviceSize, context),
            ),
          ),
          Positioned(
              top: 200,
              width: deviceSize.width,
              child: const Center(
                child: Text(
                  'MY Shop',
                  style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 70,
                      fontFamily: 'Acme'),
                ),
              )),
        ],
      ),
    );
  }

  Card _authCard(Size deviceSize, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,

      shadowColor: const Color(0xFF92FE9D),
      // Color(0xFF92FE9D), ,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        height: _authMode == AuthMode.Signup ? 370 : 310,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 370 : 310),
        width: deviceSize.width * 0.75 + 50,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Color(0xFF00C9FF),
            // Color(0xFF92FE9D),
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.email,
                        color: Color(0xFF00C9FF),
                      ),
                      labelText: 'E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'Invalid email!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _authData['email'] = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.vpn_key,
                        color: Color(0xFF00C9FF),
                      ),
                      labelText: 'Password'),
                  obscureText: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 5) {
                      return 'Password is too short!';
                    }
                  },
                  onSaved: (value) {
                    _authData['password'] = value!;
                  },
                ),
                AnimatedContainer(
                  constraints: BoxConstraints(
                      minHeight: _authMode == AuthMode.Signup ? 60 : 0,
                      maxHeight: _authMode == AuthMode.Signup ? 120 : 0),
                  duration: const Duration(milliseconds: 300),
                  child: SlideTransition(
                    position: _slightAnimation!,
                    child: FadeTransition(
                      opacity: _opacityAnimation!,
                      child: TextFormField(
                        enabled: _authMode == AuthMode.Signup,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(
                            Icons.vpn_key,
                            color: Color(0xFF00C9FF),
                          ),
                        ),
                        obscureText: true,
                        validator: _authMode == AuthMode.Signup
                            ? (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match!';
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(colors: [
                          Color(0xFF00C9FF),
                          Color(0xFF92FE9D),
                        ])),
                    child: MaterialButton(
                      child: Text(
                        _authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _submit,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 8.0),
                      textColor:
                          Theme.of(context).primaryTextTheme.button!.color,
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  child: Text(
                      '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                  onPressed: _switchAuthMode,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textColor: const Color(0xFF00C9FF),
                  // Color(0xFF00C9FF),
                  // Color(0xFF92FE9D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
