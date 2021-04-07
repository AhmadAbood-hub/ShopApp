import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:real_shop/screens/product_overview_screen.dart';
import '../models/http_exception.dart';
import '../providers/auth.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatelessWidget {
  static const routName = '/auth';

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
                      Color.fromRGBO(215, 188, 117, 1).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, 1])),
          ),
          SingleChildScrollView(
            child: Container(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                      child: Container(
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 94),
                    transform: Matrix4.rotationZ(-8 * pi / 180)
                      ..translate(-10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.deepOrange.shade900,
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 8,
                              color: Colors.black26,
                              offset: Offset(0, 2))
                        ]),
                    child: Text(
                      "My Shop",
                      style: TextStyle(
                          color:
                              Theme.of(context).accentTextTheme.headline6.color,
                          fontSize: 35,
                          fontFamily: 'Anton'),
                    ),
                  )),
                  Flexible(
                      child: AuthaCard(), flex: deviceSize.width > 600 ? 4 : 2)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AuthaCard extends StatefulWidget {
  @override
  _AuthaCardState createState() => _AuthaCardState();
}

enum AuthMode { Login, SignUp }

class _AuthaCardState extends State<AuthaCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();
  AnimationController _controller;
  Animation<Offset> _sliderAnimation;
  Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: Duration(microseconds: 300));
    _sliderAnimation = Tween<Offset>(
      begin: Offset(0, -0.15),
      end: Offset(0, 0),
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();

    _formKey.currentState.save();

    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        await Provider.of<Auth>(context, listen: false)
            .login(_authData['email'], _authData['password']);
      } else {
        await Provider.of<Auth>(context, listen: false)
            .signUp(_authData['email'], _authData['password']);
      }
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage = "this email address is already in use.";
      } else if (error.toString().contains('INVALID_EMAIL')) {
        errorMessage = "this is not a valid email address";
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = "this password is too weak";
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage = "Could not find a user with that email";
      } else if (error.toString().contains('INVALID_PASSWORD')) {
        errorMessage = "Invalid password";
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage = 'Could not authenticate you. please try agin later.';
      _showErrorDialog(errorMessage);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.SignUp;
      });
      _controller.forward();
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
      _controller.reverse();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('An Error Occurred'),
              content: Text(message),
              actions: [
                FlatButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('okay!'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 8.0,
      child: AnimatedContainer(
        duration: Duration(microseconds: 300),
        curve: Curves.easeIn,
        height: _authMode == AuthMode.SignUp ? 350 : 300,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.SignUp ? 320 : 260),
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                    decoration: InputDecoration(labelText: 'E_Mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val.isEmpty || !val.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      _authData['email'] = val;
                    }),
                TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    controller: _passwordController,
                    validator: (val) {
                      if (val.isEmpty || val.length < 5) {
                        return 'Password is too short!';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      _authData['password'] = val;
                    }),
                AnimatedContainer(
                  constraints: BoxConstraints(
                      minHeight: _authMode == AuthMode.SignUp ? 60 : 0,
                      maxHeight: _authMode == AuthMode.SignUp ? 120 : 0),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: SlideTransition(
                      position: _sliderAnimation,
                      child: TextFormField(
                        enabled: _authMode == AuthMode.SignUp ? true : false,
                        decoration:
                            InputDecoration(labelText: 'Confirm Password'),
                        obscureText: true,
                        validator: _authMode == AuthMode
                            ? (val) {
                                if (val != _passwordController.text) {
                                  return 'Password don\'t match';
                                }
                                return null;
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                if (_isLoading) CircularProgressIndicator(),
                RaisedButton(
                  child: Text(_authMode == AuthMode.Login ? 'LOGIN' : 'SIGNUP'),
                  onPressed: () {
                    //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ProductOverviewScreen()));
                    _submit();
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).primaryTextTheme.headline6.color,
                ),
                FlatButton(
                  onPressed: _switchAuthMode,
                  child: Text(
                    '${_authMode == AuthMode.Login ? 'SIGNUP ' : 'LOGIN  '}INSTEAD',
                    style: TextStyle(color: Colors.purple),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  textColor: Theme.of(context).primaryTextTheme.headline6.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
