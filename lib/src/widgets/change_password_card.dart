import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'animated_button.dart';
import 'animated_text_form_field.dart';
import '../models/login_data.dart';
import '../providers/auth.dart';
import '../providers/login_messages.dart';
import '../widget_helper.dart';
import '../paddings.dart';

class ChangePasswordCard extends StatefulWidget {
  ChangePasswordCard({
    Key key,
    @required this.passwordValidator,
    @required this.onBack,
    @required this.onSubmitCompleted,
  }) : super(key: key);

  final FormFieldValidator<String> passwordValidator;
  final Function onBack;
  final Function onSubmitCompleted;

  @override
  ChangePasswordCardState createState() => ChangePasswordCardState();
}

class ChangePasswordCardState extends State<ChangePasswordCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formRecoverKey = GlobalKey();

  final _confirmPasswordFocusNode = FocusNode();
  final _passwordController = TextEditingController();

  var _isSubmitting = false;

  AnimationController _submitController;

  @override
  void initState() {
    super.initState();

    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _submitController.dispose();
  }

  Future<bool> _submit() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (!_formRecoverKey.currentState.validate()) {
      return false;
    }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    final previousPassword = auth.password;
    _formRecoverKey.currentState.save();
    _submitController.forward();
    setState(() => _isSubmitting = true);
    final error = await auth.onChangePassword(previousPassword, LoginData(
      name: auth.email,
      password: auth.password,
    ));

    if (error != null) {
      showErrorToast(context, error);
      setState(() => _isSubmitting = false);
      _submitController.reverse();
      return false;
    }

    showSuccessToast(context, messages.changePasswordSuccess);
    setState(() => _isSubmitting = false);
    _submitController.reverse();
    widget?.onSubmitCompleted();
    return true;
  }

  Widget _buildPasswordField(double width, LoginMessages messages) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      labelText: messages.newPasswordHint,
      controller: _passwordController,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
      },
      validator: widget.passwordValidator,
      onSaved: (value) {
        final auth = Provider.of<Auth>(context, listen: false);
        auth.password = value;
      },
    );
  }

  Widget _buildConfirmPasswordField(double width, LoginMessages messages) {
    return AnimatedPasswordTextFormField(
        animatedWidth: width,
        labelText: messages.confirmNewPasswordHint,
        textInputAction: TextInputAction.done,
        focusNode: _confirmPasswordFocusNode,
        onFieldSubmitted: (value) => _submit(),
        validator: (value) {
          if (value != _passwordController.text) {
            return messages.confirmPasswordError;
          }
          return null;
        }
    );
  }

  Widget _buildSetPasswordButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.changePasswordButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(ThemeData theme, LoginMessages messages) {
    return FlatButton(
      child: Text(messages.goBackButton),
      onPressed: !_isSubmitting ? widget.onBack : null,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: theme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery
        .of(context)
        .size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formRecoverKey,
            child: Column(
              children: <Widget>[
                Text(
                  messages.changePasswordIntro,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.body1,
                ),
                SizedBox(height: 20),
                _buildPasswordField(textFieldWidth, messages),
                SizedBox(height: 20),
                _buildConfirmPasswordField(textFieldWidth, messages),
                SizedBox(height: 26),
                _buildSetPasswordButton(theme, messages),
                _buildBackButton(theme, messages),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
