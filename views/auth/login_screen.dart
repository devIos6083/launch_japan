import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/views/widgets/app_button.dart';
import 'package:launch/views/widgets/app_text_field.dart';
import 'package:launch/core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 이메일/비밀번호 로그인
  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // 카카오 로그인
  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.signInWithKakao();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // 카카오 로그인 취소 시 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오 로그인이 취소되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 회원가입 화면으로 이동
  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final errorMessage = authViewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 앱 로고 및 이름
                Center(
                  child: Column(
                    children: [
                      // 로고 (간단한 원형 + 숫자 10)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "10",
                            style: TextStyle(
                              fontFamily: 'jua',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 앱 이름 (흰색 -> 진한 색상으로 변경)
                      Text(
                        "LAUNCH MODE",
                        style: TextStyle(
                          fontFamily: 'jua',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor, // 흰색에서 주요 색상으로 변경
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // 로그인 폼
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이메일 입력 필드 - AppTextField를 직접 수정하지 않고 여기서 스타일 오버라이드
                      Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white, // 흰색 배경
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 2.0,
                              ),
                            ),
                            // 힌트 텍스트와 텍스트 입력 스타일 변경
                            hintStyle: TextStyle(
                              color: Colors.grey[500], // 더 진한 힌트 텍스트 색상
                              fontSize: 14,
                              fontFamily: 'jua',
                            ),
                            // 아이콘 색상 변경
                            prefixIconColor:
                                AppColors.primaryColor, // 아이콘 색상 변경
                            suffixIconColor:
                                AppColors.primaryColor, // 아이콘 색상 변경
                          ),
                          textTheme: TextTheme(
                            titleMedium: TextStyle(
                              color: Colors.black87, // 입력 텍스트 색상을 검정에 가깝게
                              fontSize: 14,
                              fontFamily: 'jua',
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 이메일 입력 필드
                            AppTextField(
                              controller: _emailController,
                              hintText: '이메일',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: Validators.validateEmail,
                              style:
                                  TextStyle(color: Colors.black87), // 직접 스타일 지정
                            ),
                            const SizedBox(height: 16),

                            // 비밀번호 입력 필드
                            AppTextField(
                              controller: _passwordController,
                              hintText: '비밀번호',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline,
                              style:
                                  TextStyle(color: Colors.black87), // 직접 스타일 지정
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.primaryColor, // 아이콘 색상 변경
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: Validators.validatePassword,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 비밀번호 찾기 링크 - 색상 강화
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // 비밀번호 재설정 다이얼로그 표시
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  _buildResetPasswordDialog(context),
                            );
                          },
                          child: Text(
                            '비밀번호를 잊으셨나요?',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold, // 더 굵게
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 에러 메시지
                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: AppColors.errorColor,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (errorMessage != null) const SizedBox(height: 16),

                      // 로그인 버튼
                      AppButton(
                        text: '로그인',
                        onPressed:
                            _isLoading ? null : _signInWithEmailAndPassword,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // 구분선 - 색상 더 진하게
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[600], // 더 진하게
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '또는',
                              style: TextStyle(
                                color: Colors.grey[300], // 더 밝게 (배경이 어두우므로)
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[600], // 더 진하게
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 카카오 로그인 이미지 버튼
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : GestureDetector(
                              onTap: _signInWithKakao,
                              child: Center(
                                child: Container(
                                  height: 48,
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    // 이미지 버튼이 더 잘 보이도록 그림자 추가
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.2), // 더 진한 그림자
                                        offset: const Offset(0, 1),
                                        blurRadius: 3.0,
                                      ),
                                    ],
                                  ),
                                  // 카카오 로그인 이미지 사용
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'img/kakao_login.png',
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),

                      // 회원가입 링크 - 색상 개선
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '계정이 없으신가요?',
                            style: TextStyle(
                              color: Colors.black54, // 더 밝게 (배경이 어두우므로)
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToRegister,
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// _LoginScreenState 클래스 안에 있는 _buildResetPasswordDialog 메소드를 다음과 같이 수정합니다.
  Widget _buildResetPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: Text(
            '비밀번호 재설정',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2.0,
                  ),
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontFamily: 'jua',
                ),
                prefixIconColor: AppColors.primaryColor,
              ),
            ),
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '가입한 이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.',
                    style: TextStyle(
                      color: AppColors.primaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: resetEmailController,
                    hintText: '이메일',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                    style: TextStyle(color: Colors.black87),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (dialogFormKey.currentState!.validate()) {
                        // 로딩 상태 변경
                        setState(() {
                          isLoading = true;
                        });

                        // 비밀번호 재설정 요청 전에 다이얼로그 context를 저장
                        final scaffoldContext = ScaffoldMessenger.of(context);
                        final email = resetEmailController.text.trim();

                        try {
                          // 비밀번호 재설정 요청
                          final authViewModel = Provider.of<AuthViewModel>(
                              context,
                              listen: false);
                          final success =
                              await authViewModel.resetPassword(email);

                          // 다이얼로그 닫기 (비동기 작업 후)
                          Navigator.of(context).pop();

                          // SnackBar 표시
                          scaffoldContext.showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '비밀번호 재설정 이메일이 발송되었습니다. 이메일을 확인해주세요.'
                                    : '비밀번호 재설정 요청에 실패했습니다. 다시 시도해주세요.',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } catch (e) {
                          // 오류 발생 시 다이얼로그 닫기
                          Navigator.of(context).pop();

                          // 오류 메시지 표시
                          scaffoldContext.showSnackBar(
                            SnackBar(
                              content: Text('오류가 발생했습니다: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(
                '전송',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
